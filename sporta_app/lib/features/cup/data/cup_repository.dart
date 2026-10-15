import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../auth/data/models/api_exception.dart';
import '../domain/entities/cup_entity.dart';
import '../../matches/domain/entities/pending_result.dart';

/// نقاط البطولة الإقصائية. الانضمام ودعوة الشريك تمرّ عبر
/// [AmericanoRepository] (البطولة أمريكانو فرق بنظام إقصائي).
class CupRepository {
  CupRepository(this._dio);

  final Dio _dio;

  Future<CupEntity> fetchById(int id) => _guard(() async {
    final res = await _dio.get(ApiEndpoints.cupById(id));
    return CupEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  Future<CupQuote> quote({
    required String format,
    required int teamCount,
    required List<int> courtIds,
    required DateTime scheduledAt,
    DateTime? endDate,
    required int durationMinutes,
    required int matchMinutes,
  }) => _guard(() async {
    final res = await _dio.post(
      ApiEndpoints.cupQuote,
      data: {
        'format': format,
        'teamCount': teamCount,
        'courtIds': courtIds,
        'scheduledAt': _formatDateTime(scheduledAt),
        if (endDate != null) 'endDate': _formatDateTime(endDate),
        'durationMinutes': durationMinutes,
        'matchMinutes': matchMinutes,
      },
    );
    return CupQuote.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  Future<CupEntity> create({
    required String name,
    required String format,
    required int teamCount,
    required List<int> courtIds,
    required DateTime scheduledAt,
    DateTime? endDate,
    required int durationMinutes,
    required int matchMinutes,
    double minLevel = 1,
    double maxLevel = 7,
    int? partnerId,
    bool hostedByVenue = false,
  }) => _guard(() async {
    final res = await _dio.post(
      ApiEndpoints.cups,
      data: {
        'hostedByVenue': hostedByVenue,
        'name': name,
        'format': format,
        'teamCount': teamCount,
        'courtIds': courtIds,
        'scheduledAt': _formatDateTime(scheduledAt),
        if (endDate != null) 'endDate': _formatDateTime(endDate),
        'durationMinutes': durationMinutes,
        'matchMinutes': matchMinutes,
        'minLevel': minLevel,
        'maxLevel': maxLevel,
        'partnerId': ?partnerId,
      },
    );
    return CupEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  Future<CupEntity> submitScore({
    required int fixtureId,
    required int team1Score,
    required int team2Score,
  }) => _guard(() async {
    final res = await _dio.post(
      ApiEndpoints.cupFixtureScore(fixtureId),
      data: {'team1Score': team1Score, 'team2Score': team2Score},
    );
    return CupEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  /// المنظّم يحسم خلافاً على نتيجة مباراة بإدخالها نهائيةً.
  Future<CupEntity> resolveScore({
    required int fixtureId,
    required int team1Score,
    required int team2Score,
  }) => _guard(() async {
    final res = await _dio.post(
      ApiEndpoints.cupFixtureScoreResolve(fixtureId),
      data: {'team1Score': team1Score, 'team2Score': team2Score},
    );
    return CupEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  /// المنظّم يسجّل نتيجة مباراة مرّ موعدها بلا اعتماد (تُعتمد نهائيةً)،
  /// أو فوزاً إدارياً بالانسحاب [walkover] عند غياب فريق.
  Future<CupEntity> recordScore({
    required int fixtureId,
    required int team1Score,
    required int team2Score,
    bool walkover = false,
  }) => _guard(() async {
    final res = await _dio.post(
      ApiEndpoints.cupFixtureScoreOrganizer(fixtureId),
      data: {
        'team1Score': team1Score,
        'team2Score': team2Score,
        'walkover': walkover,
      },
    );
    return CupEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  /// لاعب من الفريق الآخر يؤكد النتيجة المقترحة أو يرفضها.
  Future<CupEntity> respondScore({
    required int fixtureId,
    required bool accept,
    PendingResult? seen,
  }) => _guard(() async {
    final res = await _dio.post(
      ApiEndpoints.cupFixtureScoreRespond(fixtureId),
      data: {
        'accept': accept,
        'team1Score': ?seen?.team1Score,
        'team2Score': ?seen?.team2Score,
      },
    );
    return CupEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  /// تسمية فريق؛ الاسم الفارغ يعيده إلى حرفه (A، B…).
  Future<CupEntity> renameTeam(int id, int team, String name) =>
      _guard(() async {
        final res = await _dio.put(
          ApiEndpoints.cupTeamName(id, team),
          data: {'name': name},
        );
        return CupEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
      });

  Future<CupEntity> startWithCurrent(int id) => _guard(() async {
    final res = await _dio.post(ApiEndpoints.cupStart(id));
    return CupEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  Future<CupEntity> postpone(int id, DateTime newStart) => _guard(() async {
    final res = await _dio.post(
      ApiEndpoints.cupPostpone(id),
      data: {'scheduledAt': _formatDateTime(newStart)},
    );
    return CupEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  Future<CupEntity> cancel(int id) => _guard(() async {
    final res = await _dio.post(ApiEndpoints.cupCancel(id));
    return CupEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
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

  String _formatDateTime(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}T'
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}:00';
}
