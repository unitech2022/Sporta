import 'package:flutter/foundation.dart';

import '../../../../core/localization/app_translations.dart';
import '../../../../core/state/app_settings.dart';
import '../../../../core/storage/local_prefs.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/models/api_exception.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/registration_data.dart';

class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._settings) : _repo = AuthRepository();

  final AppSettings _settings;
  final AuthRepository _repo;

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  String? _errorCode;
  bool _isCheckingSession = true;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get errorCode => _errorCode;
  bool get isAuthenticated => _user != null;
  bool get isCheckingSession => _isCheckingSession;

  void clearError() {
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();
  }

  // ── session restore ───────────────────────────────────────────────────────

  Future<void> checkSavedSession() async {
    _isCheckingSession = true;
    notifyListeners();

    try {
      final hasRemember = await SecureStorage.hasRememberMe();
      if (!hasRemember) return;

      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null) return;

      final response = await _repo.refreshToken(refreshToken);
      await SecureStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        rememberMe: true,
      );
      await LocalPrefs.setUserJson(response.user.toJsonString());
      _user = response.user;
      _applyUserPreferences();
    } catch (_) {
      // Refresh failed — try cached user + existing access token.
      final cachedJson = LocalPrefs.getUserJson();
      final accessToken = await SecureStorage.getAccessToken();
      if (cachedJson != null && accessToken != null) {
        try {
          _user = UserModel.fromJsonString(cachedJson);
          _applyUserPreferences();
        } catch (_) {
          await _clearSession();
        }
      } else {
        await _clearSession();
      }
    } finally {
      _isCheckingSession = false;
      notifyListeners();
    }
  }

  // ── login ─────────────────────────────────────────────────────────────────

  Future<bool> login({
    required String phone,
    required String password,
    required bool rememberMe,
  }) async {
    _setLoading(true);
    try {
      final response = await _repo.login(phone, password);
      await SecureStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        rememberMe: rememberMe,
      );
      await LocalPrefs.setUserJson(response.user.toJsonString());
      _user = response.user;
      _applyUserPreferences();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.localized(_isAr);
      _errorCode = e.code;
      return false;
    } catch (_) {
      _errorMessage = _isAr ? 'حدث خطأ غير متوقع' : 'An unexpected error occurred';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── register ──────────────────────────────────────────────────────────────

  Future<bool> register(RegistrationData data) async {
    _setLoading(true);
    try {
      final response = await _repo.register(data, _settings.language.name);
      await SecureStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        rememberMe: true,
      );
      await LocalPrefs.setUserJson(response.user.toJsonString());
      _user = response.user;
      _applyUserPreferences();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.localized(_isAr);
      return false;
    } catch (_) {
      _errorMessage = _isAr ? 'حدث خطأ غير متوقع' : 'An unexpected error occurred';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── forgot password ───────────────────────────────────────────────────────

  Future<bool> forgotPassword(String phone) async {
    _setLoading(true);
    try {
      await _repo.forgotPassword(phone);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.localized(_isAr);
      return false;
    } catch (_) {
      _errorMessage = _isAr ? 'حدث خطأ غير متوقع' : 'An unexpected error occurred';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    _setLoading(true);
    try {
      await _repo.verifyOtp(phone, otp);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.localized(_isAr);
      return false;
    } catch (_) {
      _errorMessage = _isAr ? 'حدث خطأ غير متوقع' : 'An unexpected error occurred';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(
    String phone,
    String otp,
    String newPassword,
  ) async {
    _setLoading(true);
    try {
      await _repo.resetPassword(phone, otp, newPassword);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.localized(_isAr);
      return false;
    } catch (_) {
      _errorMessage = _isAr ? 'حدث خطأ غير متوقع' : 'An unexpected error occurred';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── favorite sport ──────────────────────────────────────────────────────────

  /// Persists the user's favorite sport on the backend and locally.
  Future<bool> setFavoriteSport(String sport) async {
    _setLoading(true);
    try {
      await _repo.setFavoriteSport(sport);
      if (_user != null) {
        _user = _user!.copyWith(favoriteSport: sport);
        await LocalPrefs.setUserJson(_user!.toJsonString());
      }
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.localized(_isAr);
      return false;
    } catch (_) {
      _errorMessage = _isAr ? 'حدث خطأ غير متوقع' : 'An unexpected error occurred';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── player level ────────────────────────────────────────────────────────────

  /// Updates the cached user after a level self-assessment and persists it.
  Future<void> applyPlayerLevel(int level) async {
    if (_user == null) return;
    _user = _user!.copyWith(level: level, levelAssessed: true);
    await LocalPrefs.setUserJson(_user!.toJsonString());
    notifyListeners();
  }

  // ── language ──────────────────────────────────────────────────────────────

  Future<void> updateLanguage(AppLanguage lang) async {
    _settings.setLanguage(lang);
    await LocalPrefs.setLanguage(lang.name);
    if (_user != null) {
      try {
        await _repo.updateLanguage(lang);
      } catch (_) {
        // Best-effort; local change already applied.
      }
    }
  }

  // ── logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  // ── private ───────────────────────────────────────────────────────────────

  bool get _isAr => _settings.language == AppLanguage.ar;

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) {
      _errorMessage = null;
      _errorCode = null;
    }
    notifyListeners();
  }

  void _applyUserPreferences() {
    if (_user == null) return;
    final lang = _user!.language == 'en' ? AppLanguage.en : AppLanguage.ar;
    _settings.setLanguage(lang);
    LocalPrefs.setLanguage(_user!.language);
    if (_user!.roles.isNotEmpty) {
      _settings.setRole(_user!.roles.first);
    }
  }

  Future<void> _clearSession() async {
    _user = null;
    await SecureStorage.clearAll();
    await LocalPrefs.clearUser();
  }
}
