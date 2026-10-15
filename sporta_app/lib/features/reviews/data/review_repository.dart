import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../auth/data/models/api_exception.dart';
import '../domain/review_models.dart';

/// التقييم المتبادل بعد التجربة — `/api/reviews/...`.
class ReviewRepository {
  ReviewRepository(this._dio);

  final Dio _dio;

  Future<ReviewSession> fetchSession(
    ReviewContext context,
    int id,
  ) => _guard(() async {
    final res = await _dio.get(ApiEndpoints.reviewSession(context.apiName, id));
    return ReviewSession.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  /// يرسل دفعة تقييمات (أو يعدّلها) ويعيد الحالة المحدّثة.
  Future<ReviewSession> submit(
    ReviewContext context,
    int id,
    List<ReviewDraft> reviews,
  ) => _guard(() async {
    final res = await _dio.post(
      ApiEndpoints.reviewSession(context.apiName, id),
      data: {
        'reviews': [for (final r in reviews) r.toJson()],
      },
    );
    return ReviewSession.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  Future<List<PendingReview>> fetchPending() => _guard(() async {
    final res = await _dio.get(ApiEndpoints.pendingReviews);
    return [
      for (final e in (_unwrap(res.data) as List? ?? const []))
        PendingReview.fromJson(e as Map<String, dynamic>),
    ];
  });

  Future<CourtRatingsSummary> fetchCourtRatings(
    int courtId, {
    int page = 1,
    int pageSize = 10,
  }) => _guard(() async {
    final res = await _dio.get(
      ApiEndpoints.courtRatings(courtId),
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return CourtRatingsSummary.fromJson(
      _unwrap(res.data) as Map<String, dynamic>,
    );
  });

  Future<PlayerReputation> fetchReputation(int userId) => _guard(() async {
    final res = await _dio.get(ApiEndpoints.playerReputation(userId));
    return PlayerReputation.fromJson(_unwrap(res.data) as Map<String, dynamic>);
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
