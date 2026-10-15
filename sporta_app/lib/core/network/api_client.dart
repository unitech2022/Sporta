import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// Invoked when the server reports the account is suspended (403
  /// ACCOUNT_SUSPENDED). The app uses this to show the suspended screen.
  static void Function()? onAccountSuspended;

  /// Invoked when a request sent *with* a session token got 401 and the session
  /// can't be renewed (the server rejected the refresh token, or there is none
  /// because "remember me" was off). The app ends the session and returns to
  /// login — otherwise it stays on home with every request failing.
  static void Function()? onSessionExpired;

  late final Dio dio = _buildDio();

  Dio _buildDio() {
    final d = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {'Content-Type': 'application/json'},
      ),
    );
    d.interceptors.add(_AuthInterceptor(d));

    // Verbose request/response logging in debug builds only.
    if (kDebugMode) {
      d.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }

    return d;
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);

  final Dio _dio;

  /// In-flight token refresh shared by every request that 401s at the same
  /// time. Completes with the new access token, or null if the refresh failed.
  /// Without this, only the first concurrent 401 would refresh and the rest
  /// would fail — leaving cards stuck loading on screens that fire several
  /// requests at once (e.g. the profile page).
  Future<_RefreshResult>? _refreshing;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Account deactivated by an admin → notify the app to show the suspended
    // screen (the backend blocks every authenticated request with 403).
    if (err.response?.statusCode == 403) {
      final data = err.response?.data;
      final code = data is Map ? data['code'] : null;
      if (code == 'ACCOUNT_SUSPENDED') {
        ApiClient.onAccountSuspended?.call();
        handler.next(err);
        return;
      }
    }

    final is401 = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra['_retry'] == true;

    if (!is401 || alreadyRetried) {
      handler.next(err);
      return;
    }

    // Share a single refresh across all requests that 401 concurrently: the
    // first one starts it, the rest await the same future, then everyone
    // retries with the new token.
    _refreshing ??= _refreshTokens();
    final result = await _refreshing!;
    final newAccess = result.accessToken;

    if (newAccess == null) {
      // A guest's 401 carried no token — there is no session to end.
      final hadSession =
          err.requestOptions.headers['Authorization'] != null;
      if (result.sessionDead && hadSession) {
        ApiClient.onSessionExpired?.call();
      }
      handler.next(err);
      return;
    }

    try {
      err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccess'
        ..extra['_retry'] = true;
      final retry = await _dio.fetch(err.requestOptions);
      handler.resolve(retry);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Refreshes the token pair once. Cleared from [_refreshing] when done so the
  /// next expiry triggers a fresh refresh.
  ///
  /// The session is only declared dead (stored tokens cleared) when the server
  /// actually rejects it. A timeout or lost connection keeps the refresh token
  /// so the next request can try again once the network is back.
  Future<_RefreshResult> _refreshTokens() async {
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null) return const _RefreshResult.dead();

      // Fresh Dio (no interceptors) for the refresh call to avoid loops.
      final refreshDio = Dio(BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));
      final res = await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      final data = (res.data['data'] ?? res.data) as Map<String, dynamic>;
      final newAccess = data['accessToken'].toString();
      final newRefresh = data['refreshToken'].toString();

      await SecureStorage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
        rememberMe: true,
      );
      return _RefreshResult.ok(newAccess);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // لا ردّ (شبكة/مهلة) أو خطأ خادم 5xx: الجلسة قد تكون سليمة، فلا نمسحها.
      if (status == null || status >= 500) return const _RefreshResult.retry();
      // سقطت الجلسة لا الجهاز: يبقى موثوقاً ليعود صاحبه ببصمته.
      await SecureStorage.clearSession();
      return const _RefreshResult.dead();
    } catch (_) {
      // ردّ تعذّرت قراءته: الخادم دوّر التوكن فالقديم لم يعد صالحاً.
      await SecureStorage.clearSession();
      return const _RefreshResult.dead();
    } finally {
      _refreshing = null;
    }
  }
}

/// Outcome of a token refresh: a new access token, or why there is none.
class _RefreshResult {
  const _RefreshResult.ok(String token)
      : accessToken = token,
        sessionDead = false;

  /// The server rejected the session (or there was no refresh token).
  const _RefreshResult.dead()
      : accessToken = null,
        sessionDead = true;

  /// Network/server trouble — the session may still be valid.
  const _RefreshResult.retry()
      : accessToken = null,
        sessionDead = false;

  final String? accessToken;
  final bool sessionDead;
}
