import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../auth/data/models/api_exception.dart';
import '../domain/entities/support_message.dart';

/// REST جانب المستخدم من دردشة الدعم — وهو مصدر الحقيقة للسجل. الـ SignalR
/// في [SupportHub] يدفع الجديد فقط، فتبقى الشاشة صحيحة حتى لو انقطع الاتصال.
class SupportRepository {
  SupportRepository(this._dio);

  final Dio _dio;

  /// محادثتي وأحدث صفحة من رسائلها. مرّر [before] (معرّف أقدم رسالة محمّلة)
  /// لجلب الأقدم منها.
  Future<SupportMessagePage> fetchMine({int? before, int limit = 30}) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.supportChatMine,
        queryParameters: {
          'before': ?before,
          'limit': limit,
        },
      );
      return SupportMessagePage.fromJson(
        _unwrap(res.data) as Map<String, dynamic>,
      );
    });
  }

  Future<SupportMessage> send(String body) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.supportChatSend,
        data: {'body': body},
      );
      return SupportMessage.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  Future<void> markRead() async {
    return _guard(() async => _dio.post(ApiEndpoints.supportChatRead));
  }

  Future<int> fetchUnreadCount() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.supportChatUnread);
      final data = _unwrap(res.data) as Map<String, dynamic>;
      return (data['count'] as num?)?.toInt() ?? 0;
    });
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
