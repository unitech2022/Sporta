import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../auth/data/models/api_exception.dart';
import '../domain/event_invite.dart';

class EventInviteRepository {
  EventInviteRepository(this._dio);

  final Dio _dio;

  /// [expiresInMinutes] null = حتى موعد الحدث.
  Future<SendInviteResult> send({
    required InviteKind kind,
    required int targetId,
    required List<int> userIds,
    int? expiresInMinutes,
  }) =>
      _guard(() async {
        final res = await _dio.post(ApiEndpoints.invites, data: {
          'kind': kind.wire,
          'targetId': targetId,
          'userIds': userIds,
          'expiresInMinutes': ?expiresInMinutes,
        });
        return SendInviteResult.fromJson(_unwrap(res.data) as Map<String, dynamic>);
      });

  /// دعوتي إلى هذا الحدث (أحدثها)، أو null.
  Future<EventInvite?> mine(InviteKind kind, int targetId) => _guard(() async {
        final res = await _dio.get(ApiEndpoints.invitesMine,
            queryParameters: {'kind': kind.wire, 'targetId': targetId});
        final data = _unwrap(res.data);
        return data is Map<String, dynamic> ? EventInvite.fromJson(data) : null;
      });

  Future<EventInvite> decline(int id) => _guard(() async {
        final res = await _dio.post(ApiEndpoints.inviteDecline(id));
        return EventInvite.fromJson(_unwrap(res.data) as Map<String, dynamic>);
      });

  dynamic _unwrap(dynamic body) =>
      body is Map<String, dynamic> && body.containsKey('success') ? body['data'] : body;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw e.response != null ? ApiException.fromResponse(e.response!) : ApiException.network;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException.unexpected;
    }
  }
}
