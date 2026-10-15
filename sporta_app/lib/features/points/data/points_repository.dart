import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/paged.dart';
import '../../auth/data/models/api_exception.dart';
import '../domain/entities/points_entity.dart';

/// Talks to the loyalty-points REST endpoints.
class PointsRepository {
  PointsRepository(this._dio);

  final Dio _dio;

  /// Summary (balance + rules) together with a page of the ledger.
  Future<(PointsSummaryEntity, Paged<PointsTransactionEntity>)> fetchSummary({
    int page = 1,
    int pageSize = 20,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.points,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      final data = _unwrap(res.data) as Map<String, dynamic>;
      final summary = PointsSummaryEntity.fromJson(data);
      final txs = Paged.fromJson(
        data['transactions'] as Map<String, dynamic>? ?? const {},
        PointsTransactionEntity.fromJson,
      );
      return (summary, txs);
    });
  }

  /// Converts [points] into wallet credit; returns the refreshed summary.
  Future<(PointsSummaryEntity, Paged<PointsTransactionEntity>)> redeem(
      int points) async {
    return _guard(() async {
      final res = await _dio
          .post(ApiEndpoints.pointsRedeem, data: {'points': points});
      final data = _unwrap(res.data) as Map<String, dynamic>;
      final summary = PointsSummaryEntity.fromJson(data);
      final txs = Paged.fromJson(
        data['transactions'] as Map<String, dynamic>? ?? const {},
        PointsTransactionEntity.fromJson,
      );
      return (summary, txs);
    });
  }

  /// أعلى الحاصلين على النقاط: [kind] 'reward' | 'level'،
  /// [period] 'all' | 'daily' | 'weekly' | 'monthly'.
  Future<LeaderboardEntity> fetchLeaderboard({
    required String kind,
    required String period,
    int limit = 10,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.pointsLeaderboard,
        queryParameters: {'kind': kind, 'period': period, 'limit': limit},
      );
      return LeaderboardEntity.fromJson(
          _unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// سُلَّم المستويات النشط كما ضبطه الأدمن.
  Future<List<LevelDefinitionEntity>> fetchLevels() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.levels);
      final list = _unwrap(res.data) as List? ?? const [];
      return [
        for (final e in list)
          LevelDefinitionEntity.fromJson(e as Map<String, dynamic>),
      ];
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
