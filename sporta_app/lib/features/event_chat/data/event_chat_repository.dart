import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../auth/data/models/api_exception.dart';
import '../domain/event_chat.dart';

/// نقاط `/api/event-chat/{matchId}` — REST مصدر الحقيقة، والـ hub يدفع الجديد.
class EventChatRepository {
  EventChatRepository(this._dio);

  final Dio _dio;

  Future<EventChatSummary> fetchSummary(int matchId) => _guard(() async {
    final res = await _dio.get(ApiEndpoints.eventChat(matchId));
    return EventChatSummary.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  /// صفحة من السجل (الأقدم أولاً) قبل [beforeId].
  Future<List<EventChatMessage>> fetchMessages(
    int matchId, {
    int? beforeId,
    int limit = 30,
  }) => _guard(() async {
    final res = await _dio.get(
      ApiEndpoints.eventChatMessages(matchId),
      queryParameters: {'limit': limit, 'beforeId': ?beforeId},
    );
    return (_unwrap(res.data) as List)
        .map((e) => EventChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  Future<EventChatMessage> send(
    int matchId, {
    String? body,
    int? replyToId,
    EventChatAttachment? attachment,
    List<int> mentionedUserIds = const [],
  }) => _guard(() async {
    final res = await _dio.post(
      ApiEndpoints.eventChatMessages(matchId),
      data: {
        'body': ?body,
        'replyToId': ?replyToId,
        if (attachment != null) 'attachment': attachment.toJson(),
        if (mentionedUserIds.isNotEmpty) 'mentionedUserIds': mentionedUserIds,
      },
    );
    return EventChatMessage.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  /// يرفع صورة أو ملفاً (حتى 10 م.ب) ويعيده جاهزاً للإرسال.
  Future<EventChatAttachment> upload(int matchId, String path, String name) =>
      _guard(() async {
        final form = FormData.fromMap({
          'file': await MultipartFile.fromFile(path, filename: name),
        });
        final res = await _dio.post(
          ApiEndpoints.eventChatAttachments(matchId),
          data: form,
          options: Options(sendTimeout: const Duration(minutes: 2)),
        );
        return EventChatAttachment.fromJson(
          _unwrap(res.data) as Map<String, dynamic>,
        );
      });

  /// تفاعل المستخدم (رمز واحد؛ إرسال الرمز نفسه أو null يزيله).
  Future<EventChatMessage> react(int matchId, int messageId, String? emoji) =>
      _guard(() async {
        final res = await _dio.post(
          ApiEndpoints.eventChatReaction(matchId, messageId),
          data: {'emoji': emoji},
        );
        return EventChatMessage.fromJson(
          _unwrap(res.data) as Map<String, dynamic>,
        );
      });

  Future<void> delete(int matchId, int messageId) => _guard(() async {
    await _dio.delete(ApiEndpoints.eventChatMessage(matchId, messageId));
  });

  Future<void> markRead(int matchId) => _guard(() async {
    await _dio.post(ApiEndpoints.eventChatRead(matchId));
  });

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
