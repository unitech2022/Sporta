import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/auth/biometric_service.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/push/push_service.dart';
import '../../../../core/state/app_settings.dart';
import '../../../../core/storage/local_prefs.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../support/data/support_hub.dart';
import '../../data/models/api_exception.dart';
import '../../data/models/auth_response.dart';
import '../../data/models/otp_models.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/registration_data.dart';

part 'auth_state.dart';

/// نتيجة محاولة الدخول من جهاز موثوق.
enum DeviceLoginResult {
  success,

  /// ألغى المستخدم فحص البصمة أو فشل فيه — لا رسالة خطأ، يعيد المحاولة متى شاء.
  cancelled,

  /// الهاتف ليس موثوقاً لهذا الرقم — على الشاشة أن تسقط إلى رمز واتساب.
  notTrusted,

  /// خطأ من الخادم/الشبكة؛ الرسالة في [AuthState.errorMessage].
  failed,
}

/// Owns the authentication session and exposes the same getters/methods the UI
/// used before (so screens keep calling `context.auth.login(...)`, etc.).
/// All HTTP work is delegated to [AuthRepository].
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo, this._settings, {void Function()? onSessionCleared})
      : _onSessionCleared = onSessionCleared,
        super(const AuthState()) {
    // The API client fires this when any request returns 403 ACCOUNT_SUSPENDED
    // (account deactivated by an admin) — show the blocked screen immediately.
    ApiClient.onAccountSuspended = markAccountDisabled;
    // A request with a session token got 401 and the session couldn't be
    // renewed — end it so the app returns to login instead of a dead home.
    ApiClient.onSessionExpired = _onSessionExpired;
  }

  final AuthRepository _repo;
  final AppSettings _settings;

  /// يُستدعى بعد مسح الجلسة ليصفّر الحالة المشتركة خارج هذا الـ cubit
  /// (مثل المحفظة) — يُحقن من service_locator حتى لا يعتمد auth على بقية الميزات.
  final void Function()? _onSessionCleared;

  // ── convenience getters (used across the UI) ───────────────────────────────
  UserModel? get user => state.user;
  bool get isLoading => state.isLoading;
  String? get errorMessage => state.errorMessage;
  String? get errorCode => state.errorCode;
  bool get isAuthenticated => state.isAuthenticated;
  bool get isCheckingSession => state.isCheckingSession;
  bool get accountDisabled => state.accountDisabled;
  bool get isGuest => state.isGuest;
  bool get justRegistered => state.justRegistered;

  void clearError() => emit(state.copyWith(clearError: true));

  /// Marks the session as suspended (blocked screen). Safe to call anytime.
  void markAccountDisabled() {
    if (state.accountDisabled) return;
    emit(state.copyWith(accountDisabled: true, isCheckingSession: false));
  }

  bool _expiring = false;

  /// Ends a session the server no longer accepts. Several requests can 401 at
  /// once, so concurrent calls collapse into one.
  Future<void> _onSessionExpired() async {
    if (_expiring || state.user == null) return;
    _expiring = true;
    try {
      await _clearSession();
      emit(state.copyWith(sessionExpired: true));
    } finally {
      _expiring = false;
    }
  }

  /// Called by the app root once it has returned to login after an expiry.
  void acknowledgeSessionExpired() =>
      emit(state.copyWith(sessionExpired: false));

  /// Leaves the suspended screen back to login (e.g. after re-activation).
  Future<void> exitSuspended() async {
    await _clearSession();
    emit(state.copyWith(accountDisabled: false));
  }

  // ── session restore ─────────────────────────────────────────────────────────

  Future<void> checkSavedSession() async {
    emit(state.copyWith(isCheckingSession: true));
    // Keep the splash on screen for at least a moment, even when the session
    // check finishes instantly (e.g. no saved session after a language change).
    final minSplash = Future<void>.delayed(const Duration(milliseconds: 900));
    try {
      // جلسة حُفظت لخادم آخر (إنتاج ↔ محلي): كأنها غير موجودة.
      if (await SecureStorage.discardSessionFromOtherApi()) {
        await LocalPrefs.clearUser();
        return;
      }

      final hasRemember = await SecureStorage.hasRememberMe();
      if (!hasRemember) return;

      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null) return;

      // المستودع يحفظ الزوج الجديد بنفسه قبل قراءة المستخدم.
      final response = await _repo.refreshToken(refreshToken);
      await LocalPrefs.setUserJson(response.user.toJsonString());
      emit(state.copyWith(user: response.user));
      _applyUserPreferences(response.user);
    } on ApiException catch (e) {
      // الخادم رفض الجلسة (توكن تجديد منتهٍ/ملغى/حساب محذوف): لا نعود للمستخدم
      // المخزّن بتوكن منتهٍ — كل طلب سيُرفض والرئيسية تبقى بلا بيانات.
      final status = e.statusCode;
      if (status != null && status >= 400 && status < 500) {
        await _clearSession();
      } else {
        await _restoreCachedUser();
      }
    } catch (_) {
      await _restoreCachedUser();
    } finally {
      await minSplash;
      emit(state.copyWith(isCheckingSession: false));
    }
  }

  /// Offline start (or a server hiccup): reopen with the cached user so the app
  /// works from cache. If the session turns out to be invalid, the first 401
  /// ends it through [_onSessionExpired].
  Future<void> _restoreCachedUser() async {
    final cachedJson = LocalPrefs.getUserJson();
    final accessToken = await SecureStorage.getAccessToken();
    if (cachedJson != null && accessToken != null) {
      try {
        final cached = UserModel.fromJsonString(cachedJson);
        emit(state.copyWith(user: cached));
        _applyUserPreferences(cached);
      } catch (_) {
        await _clearSession();
      }
    } else {
      await _clearSession();
    }
  }

  // ── login / register ──────────────────────────────────────────────────────

  /// يطلب رمز تحقق على واتساب. يُرجِع تفاصيل الإرسال عند النجاح، و`null` عند
  /// الفشل بعد وضع الرسالة في [errorMessage] لتعرضها الشاشة.
  Future<OtpRequested?> requestOtp(String phone, OtpPurpose purpose) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final result = await _repo.requestOtp(phone, purpose);
      emit(state.copyWith(isLoading: false));
      return result;
    } on ApiException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.localized(_settings.language.isRtl),
        errorCode: e.code,
      ));
      return null;
    }
  }

  // ── الجهاز الموثوق (بصمة) ──────────────────────────────────────────────────

  /// الرقم الذي سُجّل هذا الهاتف له، أو `null` إن لم يُسجَّل بعد.
  Future<String?> trustedDevicePhone() async =>
      (await SecureStorage.getDeviceCredential())?.phone;

  /// الدخول اليومي: بصمة النظام تُفرج عن سرّ الجهاز، ثم الرقم + السرّ للخادم.
  /// لا رمز واتساب. [DeviceLoginResult.notTrusted] يعني أن على الشاشة أن تسقط
  /// إلى مسار الرمز (الخادم لم يعد يعرف الجهاز، أو الرقم ليس رقمه).
  Future<DeviceLoginResult> loginWithDevice({
    required String phone,
    bool rememberMe = true,
  }) async {
    final cred = await SecureStorage.getDeviceCredential();
    if (cred == null || cred.phone != phone) return DeviceLoginResult.notTrusted;

    final ok = await BiometricService.confirmOwner(_biometricReason);
    if (!ok) {
      if (!await BiometricService.hasDeviceLock()) {
        emit(state.copyWith(errorMessage: _deviceLockRequired));
      }
      return DeviceLoginResult.cancelled;
    }

    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final response =
          await _repo.loginWithDevice(phone, cred.deviceId, cred.secret);
      await _persistSession(response, rememberMe: rememberMe);
      emit(state.copyWith(user: response.user, isLoading: false));
      _applyUserPreferences(response.user);
      return DeviceLoginResult.success;
    } on ApiException catch (e) {
      if (e.code == 'DEVICE_NOT_TRUSTED') {
        // سرّ لم يعد صالحاً (أُعيد تسجيل الجهاز من مكان آخر، أو أُلغي):
        // يُمسح كي لا تُعاد المحاولة به، ويُطلب رمز واتساب.
        await SecureStorage.clearDeviceCredential();
        emit(state.copyWith(isLoading: false));
        return DeviceLoginResult.notTrusted;
      }
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.localized(_isAr),
        errorCode: e.code,
        accountDisabled: e.code == 'ACCOUNT_SUSPENDED' ? true : null,
      ));
      return DeviceLoginResult.failed;
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: _unexpected));
      return DeviceLoginResult.failed;
    }
  }

  /// يسجّل هذا الهاتف جهازاً موثوقاً للحساب الحالي: بصمة النظام أولاً، ثم
  /// يُصدر الخادم سرّاً يُحفظ في التخزين الآمن لهذا الجهاز وحده. يُرجِع رسالة
  /// الخطأ عند الفشل، و`null` عند النجاح.
  Future<String?> enrollThisDevice() async {
    final user = state.user;
    if (user == null) return _unexpected;

    final ok = await BiometricService.confirmOwner(_biometricReason);
    if (!ok) {
      if (!await BiometricService.hasDeviceLock()) return _deviceLockRequired;
      return _isAr
          ? 'لم يتم التحقق من البصمة، حاول مرة أخرى'
          : 'Biometric check was not completed, try again';
    }

    try {
      final deviceId = await SecureStorage.getOrCreateDeviceId();
      final (id, secret) = await _repo.enrollDevice(
        deviceId: deviceId,
        deviceName: Platform.operatingSystem,
        platform: Platform.operatingSystem,
      );
      await SecureStorage.saveDeviceCredential(DeviceCredential(
        deviceId: id,
        secret: secret,
        phone: user.phone.trim(),
      ));
      return null;
    } on ApiException catch (e) {
      return e.localized(_isAr);
    } catch (_) {
      return _unexpected;
    }
  }

  String get _biometricReason =>
      _isAr ? 'تحقّق من هويتك للدخول إلى حسابك' : 'Verify it\'s you to sign in';

  /// التحقق إلزامي: هاتفٌ بلا بصمة ولا قفل شاشة لا يدخل ولا يُسجَّل، فتُقال
  /// له الخطوة المطلوبة بدل ترك الشاشة صامتة.
  String get _deviceLockRequired => _isAr
      ? 'التحقق إلزامي للدخول. فعّل البصمة أو قفل الشاشة من إعدادات هاتفك ثم أعد المحاولة.'
      : 'Verification is required to sign in. Enable biometrics or a screen lock in your phone settings, then try again.';

  /// دخول برمز واتساب — للهاتف غير الموثوق. بعد نجاحه تسجّل الشاشة البصمة
  /// عبر [enrollThisDevice] فيصير الهاتف موثوقاً.
  Future<bool> loginWithOtp({
    required String phone,
    required String otp,
    bool rememberMe = true,
  }) {
    return _authenticate(() async {
      final response = await _repo.loginWithOtp(phone, otp);
      await _persistSession(response, rememberMe: rememberMe);
      return response.user;
    });
  }

  /// يُبدّل الرمز بتذكرة للخطوة التالية. يُرجِع التذكرة أو `null` عند الفشل.
  Future<String?> verifyOtpForPurpose(
    String phone,
    String otp,
    OtpPurpose purpose,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final token = await _repo.verifyOtpForPurpose(phone, otp, purpose);
      emit(state.copyWith(isLoading: false));
      return token;
    } on ApiException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.localized(_settings.language.isRtl),
        errorCode: e.code,
      ));
      return null;
    }
  }

  Future<bool> register(RegistrationData data) async {
    final ok = await _authenticate(() async {
      final response = await _repo.register(data, _settings.language.name);
      await _persistSession(response, rememberMe: true);
      // Upload the chosen profile photo now that we're authenticated
      // (best-effort — a failed upload must not fail registration).
      if (data.avatarPath != null && data.avatarPath!.isNotEmpty) {
        try {
          return await _repo.uploadAvatar(data.avatarPath!);
        } catch (_) {}
      }
      return response.user;
    });
    // شاشة «تم إنشاء حسابك» يعرضها `_AppEntry` بعد تسجيل الجهاز.
    if (ok) emit(state.copyWith(justRegistered: true));
    return ok;
  }

  /// يُطوى إشعار نجاح التسجيل بعد أن يراه صاحبه ويضغط «ابدأ».
  void acknowledgeRegistration() => emit(state.copyWith(justRegistered: false));

  // ── favorite sport / level ──────────────────────────────────────────────────

  Future<bool> setFavoriteSport(String sport) {
    return _runVoid(() async {
      await _repo.setFavoriteSport(sport);
      final current = state.user;
      if (current != null) {
        final updated = current.copyWith(favoriteSport: sport);
        await LocalPrefs.setUserJson(updated.toJsonString());
        emit(state.copyWith(user: updated));
      }
    });
  }

  /// Adds a role (+ its details) to the current account. Returns an error
  /// message on failure (null on success); updates the cached user + roles.
  Future<String?> addRole(RegistrationData data) async {
    try {
      final updated = await _repo.addRole(data);
      await LocalPrefs.setUserJson(updated.toJsonString());
      emit(state.copyWith(user: updated));
      return null;
    } on ApiException catch (e) {
      return e.localized(_settings.language.isRtl);
    }
  }

  /// يحذف دوراً من الحساب (حذف ناعم على الخادم). يُرجِع رسالة الخطأ عند الفشل
  /// و`null` عند النجاح، ويستبدل الجلسة بالتوكن الجديد الخالي من الدور.
  Future<String?> deleteRole(UserRole role) async {
    try {
      final response = await _repo.deleteRole(role.name);
      await _persistSession(
        response,
        rememberMe: await SecureStorage.hasRememberMe(),
      );
      emit(state.copyWith(user: response.user));
      return null;
    } on ApiException catch (e) {
      return e.localized(_isAr);
    }
  }

  /// Saves the user's location. Returns an error message on failure (null on
  /// success); updates the cached user.
  Future<String?> updateLocation(double latitude, double longitude) async {
    try {
      final updated = await _repo.updateLocation(latitude, longitude);
      await LocalPrefs.setUserJson(updated.toJsonString());
      emit(state.copyWith(user: updated));
      return null;
    } on ApiException catch (e) {
      return e.localized(_settings.language.isRtl);
    }
  }

  /// Updates the cached user after a level self-assessment and persists it.
  Future<void> applyPlayerLevel(int level) async {
    final current = state.user;
    if (current == null) return;
    final updated = current.copyWith(level: level, levelAssessed: true);
    await LocalPrefs.setUserJson(updated.toJsonString());
    emit(state.copyWith(user: updated));
  }

  // ── language ──────────────────────────────────────────────────────────────

  Future<void> updateLanguage(AppLanguage lang) async {
    // Apply the language and relaunch the UI FIRST: nothing below (prefs I/O,
    // network) may fail or stall in a way that leaves the user stuck on the
    // language page.
    _settings.setLanguage(lang);
    _settings.restartApp();
    try {
      await LocalPrefs.setLanguage(lang.name);
      final current = state.user;
      if (current != null) {
        // Keep the cached user in the new language so an offline session
        // restore doesn't revert it.
        final updated = current.copyWith(language: lang.name);
        await LocalPrefs.setUserJson(updated.toJsonString());
        emit(state.copyWith(user: updated));
        // Best-effort server sync, deliberately NOT awaited: the local change
        // is already applied, and awaiting a slow/unreachable API here kept
        // the user stuck until the request timed out.
        unawaited(_repo.updateLanguage(lang).catchError((_) {}));
      }
    } finally {
      // Re-run the splash logic for the freshly rebuilt tree.
      await checkSavedSession();
    }
  }

  // ── profile / password ────────────────────────────────────────────────────────

  /// Updates the profile; on success refreshes the cached user. Returns an error
  /// message on failure (null on success).
  Future<String?> updateProfile({
    required String firstName,
    required String lastName,
    String? gender,
    String? city,
    String? district,
    int? cityId,
    int? districtId,
  }) async {
    try {
      final updated = await _repo.updateProfile(
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        city: city,
        district: district,
        cityId: cityId,
        districtId: districtId,
      );
      await LocalPrefs.setUserJson(updated.toJsonString());
      emit(state.copyWith(user: updated));
      _applyUserPreferences(updated);
      return null;
    } on ApiException catch (e) {
      return e.localized(_isAr);
    } catch (_) {
      return _unexpected;
    }
  }

  /// Uploads an avatar; on success refreshes the cached user. Returns an error
  /// message on failure (null on success).
  Future<String?> uploadAvatar(String filePath) async {
    try {
      final updated = await _repo.uploadAvatar(filePath);
      await LocalPrefs.setUserJson(updated.toJsonString());
      emit(state.copyWith(user: updated));
      return null;
    } on ApiException catch (e) {
      return e.localized(_isAr);
    } catch (_) {
      return _unexpected;
    }
  }

  // ── logout ──────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _clearSession();
  }

  // ── guest mode ──────────────────────────────────────────────────────────────

  /// يدخل التطبيق بلا حساب: تصفّح الملاعب والمدربين والمباريات فقط. أي إجراء
  /// يخص حساباً (حجز، انضمام، مفضلة) يطلب تسجيل الدخول عند لمسه.
  void continueAsGuest() => emit(state.copyWith(isGuest: true));

  /// يترك وضع الزائر ويعود لشاشة الترحيب (تسجيل دخول/إنشاء حساب).
  void exitGuest() => emit(state.copyWith(isGuest: false));

  // ── delete account ──────────────────────────────────────────────────────────

  /// يحذف الحساب نهائياً بعد تأكيده برمز واتساب، ثم ينهي الجلسة محلياً.
  /// يعيد رسالة الخطأ عند الفشل، و`null` عند النجاح.
  Future<String?> deleteAccount(String verificationToken, {String? reason}) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _repo.deleteAccount(verificationToken, reason: reason);
      await _clearSession();
      // الحساب لم يعد موجوداً — لا معنى لبقاء الجهاز «موثوقاً» له.
      await SecureStorage.clearAll();
      emit(state.copyWith(isLoading: false, isGuest: false));
      return null;
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false));
      return e.localized(_isAr);
    } catch (_) {
      emit(state.copyWith(isLoading: false));
      return _unexpected;
    }
  }

  // ── private helpers ──────────────────────────────────────────────────────────

  bool get _isAr => _settings.language == AppLanguage.ar;

  /// Runs an authenticating call, managing loading/error state and emitting the
  /// resulting user. Returns true on success.
  Future<bool> _authenticate(Future<UserModel> Function() run) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = await run();
      emit(state.copyWith(user: user, isLoading: false));
      _applyUserPreferences(user);
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.localized(_isAr),
        errorCode: e.code,
        accountDisabled: e.code == 'ACCOUNT_SUSPENDED' ? true : null,
      ));
      return false;
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: _unexpected));
      return false;
    }
  }

  /// Runs a fire-and-forget call (OTP, reset, …) with loading/error handling.
  Future<bool> _runVoid(Future<void> Function() run) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await run();
      emit(state.copyWith(isLoading: false));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.localized(_isAr)));
      return false;
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: _unexpected));
      return false;
    }
  }

  Future<void> _persistSession(
    AuthResponse response, {
    required bool rememberMe,
  }) async {
    await SecureStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      rememberMe: rememberMe,
    );
    await LocalPrefs.setUserJson(response.user.toJsonString());
  }

  void _applyUserPreferences(UserModel user) {
    // اللغة المحفوظة محلياً هي المرجع، لا نسخة الخادم: مزامنة اللغة مع الخادم
    // تجري في الخلفية، فقد يعيد تجديد الجلسة مستخدماً بلغته القديمة — وتطبيقها
    // هنا كان يلغي التغيير من أول مرة.
    final savedLang = LocalPrefs.getLanguage();
    final langName = savedLang ?? user.language;
    _settings.setLanguage(langName == 'en' ? AppLanguage.en : AppLanguage.ar);
    if (savedLang == null) LocalPrefs.setLanguage(user.language);
    if (user.roles.isNotEmpty) {
      // الحساب الذي اختاره آخر مرة («تبديل الحساب») إن بقي على الحساب، وإلا الأول.
      final saved = LocalPrefs.getActiveRole();
      final restored = user.roles.where((r) => r.name == saved).firstOrNull;
      _settings.setRole(restored ?? user.roles.first);
    }
    // Link this device to the user for push notifications (OneSignal).
    PushService.login(user.id);
  }

  Future<void> _clearSession() async {
    // مقبس دردشة الدعم مُصادَق بالتوكن الذي نمسحه الآن — نُسقطه أولاً حتى لا
    // يبقى مفتوحاً على هوية الحساب السابق.
    await SupportHub.instance.disconnect();
    // الـ cubits المشتركة (singletons) تحتفظ ببيانات الحساب السابق — تُصفَّر
    // هنا حتى لا يراها من يدخل بعده.
    _onSessionCleared?.call();
    // الجلسة تُمسح والجهاز يبقى موثوقاً: من خرج يعود ببصمته لا برمز جديد.
    await SecureStorage.clearSession();
    await LocalPrefs.clearUser();
    await PushService.logout();
    emit(state.copyWith(
        clearUser: true, isGuest: false, justRegistered: false));
  }

  String get _unexpected =>
      _isAr ? 'حدث خطأ غير متوقع' : 'An unexpected error occurred';
}
