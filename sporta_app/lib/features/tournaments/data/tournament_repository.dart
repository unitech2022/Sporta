import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../auth/data/models/api_exception.dart';
import '../domain/tournament_entity.dart';

/// Talks to the tournaments REST endpoint.
class TournamentRepository {
  TournamentRepository(this._dio);

  final Dio _dio;

  Future<List<TournamentEntity>> fetchTournaments() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.tournaments);
      final data = _unwrap(res.data) as List;
      return data
          .map((e) => TournamentEntity.fromJson(e as Map<String, dynamic>))
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
