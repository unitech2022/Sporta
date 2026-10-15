import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/paged.dart';
import '../../auth/data/models/api_exception.dart';
import '../domain/entities/notification_entity.dart';

/// Talks to the notifications REST endpoints.
class NotificationRepository {
  NotificationRepository(this._dio);

  final Dio _dio;

  /// Lists the user's notifications (paged, newest first).
  Future<Paged<NotificationEntity>> fetchAll({
    int page = 1,
    int pageSize = 20,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.notifications,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return Paged.fromJson(_unwrap(res.data), NotificationEntity.fromJson);
    });
  }

  Future<int> fetchUnreadCount() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.notificationsUnread);
      final data = _unwrap(res.data) as Map<String, dynamic>;
      return (data['count'] as num?)?.toInt() ?? 0;
    });
  }

  Future<void> markRead(int id) async {
    return _guard(() async => _dio.put(ApiEndpoints.notificationRead(id)));
  }

  Future<void> markAllRead() async {
    return _guard(() async => _dio.put(ApiEndpoints.notificationsReadAll));
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  dynamic _unwrap(dynamic body) =>
      body is Map<String, dynamic> ? (body['data'] ?? body) : body;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw e.response != null
          ? ApiException.fromResponse(e.response!)
          : ApiException.network;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException.unexpected;
    }
  }
}
