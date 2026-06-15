import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

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
    return d;
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);

  final Dio _dio;
  bool _isRefreshing = false;

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
    final is401 = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra['_retry'] == true;

    if (is401 && !alreadyRetried && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await SecureStorage.getRefreshToken();
        if (refreshToken == null) {
          handler.next(err);
          return;
        }

        // Use a fresh Dio (no interceptors) for the refresh call to avoid loops.
        final refreshDio = Dio(
          BaseOptions(baseUrl: ApiEndpoints.baseUrl),
        );
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

        // Retry the original request with new token.
        err.requestOptions
          ..headers['Authorization'] = 'Bearer $newAccess'
          ..extra['_retry'] = true;

        final retry = await _dio.fetch(err.requestOptions);
        handler.resolve(retry);
      } catch (_) {
        await SecureStorage.clearAll();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }
}
