import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../auth/data/models/api_exception.dart';
import '../domain/pulse_item.dart';

/// Talks to the community-pulse REST endpoint.
class PulseRepository {
  PulseRepository(this._dio);

  final Dio _dio;

  Future<List<PulseItem>> fetchPulse() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.pulse);
      final data = _unwrap(res.data) as List;
      return data
          .map((e) => PulseItem.fromJson(e as Map<String, dynamic>))
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
