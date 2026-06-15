import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_translations.dart';
import '../../../../core/state/app_settings.dart';
import '../../../../core/storage/local_prefs.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/models/api_exception.dart';
import '../../data/models/auth_response.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/registration_data.dart';

part 'auth_state.dart';

/// Owns the authentication session and exposes the same getters/methods the UI
/// used before (so screens keep calling `context.auth.login(...)`, etc.).
/// All HTTP work is delegated to [AuthRepository].
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo, this._settings) : super(const AuthState());

  final AuthRepository _repo;
  final AppSettings _settings;

  // ── convenience getters (used across the UI) ───────────────────────────────
  UserModel? get user => state.user;
  bool get isLoading => state.isLoading;
  String? get errorMessage => state.errorMessage;
  String? get errorCode => state.errorCode;
  bool get isAuthenticated => state.isAuthenticated;
  bool get isCheckingSession => state.isCheckingSession;

  void clearError() => emit(state.copyWith(clearError: true));

  // ── session restore ─────────────────────────────────────────────────────────

  Future<void> checkSavedSession() async {
    emit(state.copyWith(isCheckingSession: true));
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
      emit(state.copyWith(user: response.user));
      _applyUserPreferences(response.user);
    } catch (_) {
      // Refresh failed — try cached user + existing access token.
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
    } finally {
      emit(state.copyWith(isCheckingSession: false));
    }
  }

  // ── login / register ──────────────────────────────────────────────────────

  Future<bool> login({
    required String phone,
    required String password,
    required bool rememberMe,
  }) {
    return _authenticate(() async {
      final response = await _repo.login(phone, password);
      await _persistSession(response, rememberMe: rememberMe);
      return response.user;
    });
  }

  Future<bool> register(RegistrationData data) {
    return _authenticate(() async {
      final response = await _repo.register(data, _settings.language.name);
      await _persistSession(response, rememberMe: true);
      return response.user;
    });
  }

  // ── forgot password ───────────────────────────────────────────────────────

  Future<bool> forgotPassword(String phone) =>
      _runVoid(() => _repo.forgotPassword(phone));

  Future<bool> verifyOtp(String phone, String otp) =>
      _runVoid(() => _repo.verifyOtp(phone, otp));

  Future<bool> resetPassword(String phone, String otp, String newPassword) =>
      _runVoid(() => _repo.resetPassword(phone, otp, newPassword));

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
    _settings.setLanguage(lang);
    await LocalPrefs.setLanguage(lang.name);
    if (state.user != null) {
      try {
        await _repo.updateLanguage(lang);
      } catch (_) {
        // Best-effort; the local change is already applied.
      }
    }
  }

  // ── logout ──────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _clearSession();
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
    final lang = user.language == 'en' ? AppLanguage.en : AppLanguage.ar;
    _settings.setLanguage(lang);
    LocalPrefs.setLanguage(user.language);
    if (user.roles.isNotEmpty) {
      _settings.setRole(user.roles.first);
    }
  }

  Future<void> _clearSession() async {
    await SecureStorage.clearAll();
    await LocalPrefs.clearUser();
    emit(state.copyWith(clearUser: true));
  }

  String get _unexpected =>
      _isAr ? 'حدث خطأ غير متوقع' : 'An unexpected error occurred';
}
