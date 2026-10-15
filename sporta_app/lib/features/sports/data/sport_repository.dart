import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../auth/data/models/api_exception.dart';
import 'sport_models.dart';

/// Talks to the public sports endpoint (active sports list).
class SportRepository {
  SportRepository(this._dio);

  final Dio _dio;

  Future<List<SportEntity>> fetchSports() async {
    try {
      final res = await _dio.get(ApiEndpoints.sports);
      final body = res.data;
      final data =
          (body is Map<String, dynamic> ? (body['data'] ?? body) : body)
              as List;
      return data
          .map((e) => SportEntity.fromJson(e as Map<String, dynamic>))
          .toList();
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
