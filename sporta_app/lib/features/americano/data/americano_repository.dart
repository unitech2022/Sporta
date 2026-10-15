import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/paged.dart';
import '../../auth/data/models/api_exception.dart';
import '../domain/entities/americano_entity.dart';
import '../../matches/domain/entities/pending_result.dart';
import '../../matches/domain/entities/withdrawal.dart';
import '../../matches/domain/entities/waitlist.dart';

/// Talks to the americano REST endpoints.
class AmericanoRepository {
  AmericanoRepository(this._dio);

  final Dio _dio;

  /// Lists americano events (paged, newest first). [kind] filters server-side:
  /// 'americano' | 'tournament'; null returns both.
  Future<Paged<AmericanoEntity>> fetchAll({
    int page = 1,
    int pageSize = 20,
    String? kind,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.americano,
        queryParameters: {'page': page, 'pageSize': pageSize, 'kind': ?kind},
      );
      return Paged.fromJson(_unwrap(res.data), AmericanoEntity.fromJson);
    });
  }

  /// ما أنشأه المستخدم أو هو فيه من أمريكانو/بطولات (الأحدث أولاً). [kind]
  /// كما في [fetchAll]؛ [activeOnly] يُسقط المنتهي والملغى.
  Future<Paged<AmericanoEntity>> fetchMine({
    int page = 1,
    int pageSize = 20,
    String? kind,
    bool activeOnly = false,
    bool finishedOnly = false,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.myAmericano,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          'kind': ?kind,
          if (activeOnly) 'active': true,
          if (finishedOnly) 'finished': true,
        },
      );
      return Paged.fromJson(_unwrap(res.data), AmericanoEntity.fromJson);
    });
  }

  Future<AmericanoEntity> fetchById(int id) async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.americanoById(id));
      return AmericanoEntity.fromJson(
        _unwrap(res.data) as Map<String, dynamic>,
      );
    });
  }

  /// Joins an open americano. For a teams americano pass [team] (and optionally
  /// [partnerId] to invite a friend as partner). Returns the refreshed americano.
  Future<AmericanoEntity> join(int id, {int? team, int? partnerId}) async {
    return _guard(() async {
      final body = <String, dynamic>{'team': ?team, 'partnerId': ?partnerId};
      final res = await _dio.post(
        ApiEndpoints.americanoJoin(id),
        data: body.isEmpty ? null : body,
      );
      return AmericanoEntity.fromJson(
        _unwrap(res.data) as Map<String, dynamic>,
      );
    });
  }

  /// Teams americano: a captain invites a friend to their team.
  Future<AmericanoEntity> invitePartner(int id, int userId) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.americanoInvite(id),
        data: {'userId': userId},
      );
      return AmericanoEntity.fromJson(
        _unwrap(res.data) as Map<String, dynamic>,
      );
    });
  }

  /// The invited partner accepts or declines their team invitation.
  Future<AmericanoEntity> respondToInvite(int id, bool accept) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.americanoInviteRespond(id),
        data: {'accept': accept},
      );
      return AmericanoEntity.fromJson(
        _unwrap(res.data) as Map<String, dynamic>,
      );
    });
  }

  /// انسحاب من أمريكانو/بطولة: مباشر قبل 48 ساعة من الموعد، وإلا طلب ينتظر
  /// المنظّم (وطلب الانضمام المعلّق يُلغى). يعيد النتيجة والحدث بعدها.
  Future<(WithdrawalOutcome, AmericanoEntity)> withdraw(int id) async {
    return _guard(() async {
      final res = await _dio.post(ApiEndpoints.americanoWithdraw(id));
      final data = _unwrap(res.data) as Map<String, dynamic>;
      return (
        WithdrawalOutcome.parse(data['outcome']),
        AmericanoEntity.fromJson(data['event'] as Map<String, dynamic>),
      );
    });
  }

  /// المنظّم يقبل طلب انسحاب متأخراً أو يرفضه.
  Future<AmericanoEntity> respondToWithdrawal(
    int id, {
    required int userId,
    required bool approve,
  }) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.americanoWithdrawRespond(id),
        data: {'userId': userId, 'approve': approve},
      );
      return AmericanoEntity.fromJson(
        _unwrap(res.data) as Map<String, dynamic>,
      );
    });
  }

  /// المنظّم يحسم خلافاً على نتيجة جولة بإدخالها نهائيةً.
  Future<AmericanoEntity> resolveRoundScore({
    required int roundId,
    required int team1Score,
    required int team2Score,
  }) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.americanoRoundScoreResolve(roundId),
        data: {'team1Score': team1Score, 'team2Score': team2Score},
      );
      return AmericanoEntity.fromJson(
        _unwrap(res.data) as Map<String, dynamic>,
      );
    });
  }

  /// المنظّم يقبل طلب انضمام لاعب أو يرفضه (يُردّ للاعب ما حُجز من حصته).
  Future<AmericanoEntity> respondToJoinRequest(
    int id, {
    required int userId,
    required bool approve,
  }) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.americanoRequestRespond(id),
        data: {'userId': userId, 'approve': approve},
      );
      return AmericanoEntity.fromJson(
        _unwrap(res.data) as Map<String, dynamic>,
      );
    });
  }

  /// لاعب من الجولة يُدخل نتيجتها فتبقى مقترحة حتى يؤكدها الفريق الآخر.
  Future<AmericanoEntity> submitRoundScore({
    required int roundId,
    required int team1Score,
    required int team2Score,
  }) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.americanoRoundScore(roundId),
        data: {'team1Score': team1Score, 'team2Score': team2Score},
      );
      return AmericanoEntity.fromJson(
        _unwrap(res.data) as Map<String, dynamic>,
      );
    });
  }

  /// لاعب من الفريق الآخر في الجولة يؤكد النتيجة المقترحة أو يرفضها.
  Future<AmericanoEntity> respondRoundScore({
    required int roundId,
    required bool accept,
    PendingResult? seen,
  }) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.americanoRoundScoreRespond(roundId),
        data: {
          'accept': accept,
          'team1Score': ?seen?.team1Score,
          'team2Score': ?seen?.team2Score,
        },
      );
      return AmericanoEntity.fromJson(
        _unwrap(res.data) as Map<String, dynamic>,
      );
    });
  }

  Future<AmericanoEntity> create({
    int? courtId,
    required String type,
    required DateTime scheduledAt,
    int durationMinutes = 90,
    double minLevel = 1,
    double maxLevel = 7,
    List<int> playerIds = const [],
    int playerCount = 4,
    int teamCount = 2,
    int creatorTeam = 1,
    int? partnerId,
    bool isTournament = false,
    DateTime? endDate,
    bool hostedByVenue = false,
  }) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.americano,
        data: {
          'courtId': ?courtId,
          'hostedByVenue': hostedByVenue,
          'type': type,
          'scheduledAt': _formatDateTime(scheduledAt),
          'durationMinutes': durationMinutes,
          'minLevel': minLevel,
          'maxLevel': maxLevel,
          'playerIds': playerIds,
          'playerCount': playerCount,
          'teamCount': teamCount,
          'creatorTeam': creatorTeam,
          'partnerId': ?partnerId,
          'isTournament': isTournament,
          if (endDate != null) 'endDate': _formatDateTime(endDate),
        },
      );
      return AmericanoEntity.fromJson(
        _unwrap(res.data) as Map<String, dynamic>,
      );
    });
  }

  /// حالة قائمة الانتظار للمستخدم الحالي.
  Future<WaitlistStatus> fetchWaitlist(int id) => _guard(() async {
    final res = await _dio.get(ApiEndpoints.americanoWaitlist(id));
    return WaitlistStatus.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  /// التسجيل في قائمة الانتظار (مجاني — الحصة تُخصم عند طلب الانضمام).
  Future<WaitlistStatus> joinWaitlist(int id) => _guard(() async {
    final res = await _dio.post(ApiEndpoints.americanoWaitlist(id));
    return WaitlistStatus.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  /// مغادرة قائمة الانتظار.
  Future<WaitlistStatus> leaveWaitlist(int id) => _guard(() async {
    final res = await _dio.delete(ApiEndpoints.americanoWaitlist(id));
    return WaitlistStatus.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

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

  String _formatDateTime(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}T'
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}:00';
}
