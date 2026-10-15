import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../auth/data/models/api_exception.dart';
import '../domain/ad_entity.dart';

/// Talks to the ads REST endpoint (in-app promo banners).
class AdRepository {
  AdRepository(this._dio);

  final Dio _dio;

  /// [page] هو مكان الظهور ("home" | "courts" | "matches" | "coaches").
  /// بدونه يرجّع السيرفر كل الإعلانات النشطة.
  Future<List<AdEntity>> fetchAds({String? page}) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.ads,
        queryParameters: page == null ? null : {'page': page},
      );
      final data = _unwrap(res.data) as List;
      return data
          .map((e) => AdEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

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
