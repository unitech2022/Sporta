import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../auth/data/models/api_exception.dart';
import 'location_models.dart';

/// Talks to the public locations endpoints (Saudi cities + their districts).
class LocationRepository {
  LocationRepository(this._dio);

  final Dio _dio;

  Future<List<CityEntity>> fetchCities() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.cities);
      final data = _unwrap(res.data) as List;
      return data
          .map((e) => CityEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<List<DistrictEntity>> fetchDistricts(int cityId) async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.cityDistricts(cityId));
      final data = _unwrap(res.data) as List;
      return data
          .map((e) => DistrictEntity.fromJson(e as Map<String, dynamic>))
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
