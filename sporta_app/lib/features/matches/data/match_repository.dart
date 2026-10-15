import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/paged.dart';
import '../../auth/data/models/api_exception.dart';
import '../domain/entities/match_entity.dart';
import '../domain/entities/pending_result.dart';
import '../domain/entities/withdrawal.dart';
import '../domain/entities/waitlist.dart';

/// Talks to the matches REST endpoints. All API logic lives here so the cubit
/// only orchestrates calls and never touches [Dio] directly.
class MatchRepository {
  MatchRepository(this._dio);

  final Dio _dio;

  /// Lists open/full matches (paged), optionally filtered server-side by city
  /// and joiners' gender ("male" | "female").
  Future<Paged<MatchEntity>> fetchMatches({
    String? city,
    String? gender,
    int page = 1,
    int pageSize = 20,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.matches,
        queryParameters: {
          if (city != null && city.isNotEmpty) 'city': city,
          if (gender != null && gender.isNotEmpty) 'gender': gender,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return Paged.fromJson(_unwrap(res.data), MatchEntity.fromJson);
    });
  }

  /// The user's approved matches starting within 30 minutes (through to their
  /// end). Drives the "upcoming match" card on the home page.
  Future<List<MatchEntity>> fetchUpcomingMatches() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.upcomingMatches);
      final data = _unwrap(res.data) as List;
      return data
          .map((e) => MatchEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<MatchEntity> fetchMatchById(int id) async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.match(id));
      return MatchEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// Joins a match and returns the updated match.
  /// صاحب الملعب يلغي حدثاً يستضيفه: تُردّ حصص المسجّلين وتُخصم منه.
  Future<MatchEntity> cancelHostedMatch(int id) async {
    return _guard(() async {
      final res = await _dio.post(ApiEndpoints.cancelMatch(id));
      return MatchEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// المنشئ يحوّل مباراته الخاصة إلى عامة.
  Future<MatchEntity> makeMatchPublic(int id) async {
    return _guard(() async {
      final res = await _dio.post(ApiEndpoints.makeMatchPublic(id));
      return MatchEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  Future<MatchEntity> joinMatch(int id) async {
    return _guard(() async {
      final res = await _dio.post(ApiEndpoints.joinMatch(id));
      return MatchEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// Invites a friend to a match (pending their acceptance); returns the match.
  Future<MatchEntity> invitePlayer(int matchId, int userId) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.inviteMatch(matchId),
        data: {'userId': userId},
      );
      return MatchEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// The invited player accepts/declines an invitation; returns the updated match.
  Future<MatchEntity> respondToInvite(int matchId, bool accept) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.respondMatchInvite(matchId),
        data: {'accept': accept},
      );
      return MatchEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// Pending join requests for a match (creator only).
  Future<List<MatchPlayerEntity>> fetchJoinRequests(int matchId) async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.matchRequests(matchId));
      final data = _unwrap(res.data) as List;
      return data
          .map((e) => MatchPlayerEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// Creator approves/rejects a pending join request; returns the updated match.
  Future<MatchEntity> respondToJoinRequest(
    int matchId,
    int userId,
    bool approve,
  ) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.respondMatchRequest(matchId),
        data: {'userId': userId, 'approve': approve},
      );
      return MatchEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// انسحاب اللاعب: مباشر قبل 24 ساعة من الموعد، وإلا طلب ينتظر المنشئ
  /// (وطلب الانضمام المعلّق يُلغى). يعيد النتيجة والمباراة بعدها.
  Future<(WithdrawalOutcome, MatchEntity)> withdraw(int matchId) async {
    return _guard(() async {
      final res = await _dio.post(ApiEndpoints.withdrawMatch(matchId));
      final data = _unwrap(res.data) as Map<String, dynamic>;
      return (
        WithdrawalOutcome.parse(data['outcome']),
        MatchEntity.fromJson(data['event'] as Map<String, dynamic>),
      );
    });
  }

  /// المنشئ يقبل طلب انسحاب متأخراً أو يرفضه؛ يعيد المباراة بعده.
  Future<MatchEntity> respondToWithdrawal(
    int matchId,
    int userId,
    bool approve,
  ) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.respondMatchWithdrawal(matchId),
        data: {'userId': userId, 'approve': approve},
      );
      return MatchEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// Creates a match and returns it.
  Future<MatchEntity> createMatch({
    int? courtId,
    required String matchType,
    required String gender,
    required DateTime scheduledAt,
    int durationMinutes = 90,
    int maxPlayers = 4,
    double minLevel = 1,
    double maxLevel = 7,
    double pricePerPlayer = 0,
    String paymentMode = 'share',
    String? notes,
    bool hostedByVenue = false,
    bool isPrivate = false,
  }) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.matches,
        data: {
          'courtId': ?courtId,
          'hostedByVenue': hostedByVenue,
          'isPrivate': isPrivate,
          'matchType': matchType,
          'gender': gender,
          'scheduledAt': _formatDateTime(scheduledAt),
          'durationMinutes': durationMinutes,
          'maxPlayers': maxPlayers,
          'minLevel': minLevel,
          'maxLevel': maxLevel,
          'pricePerPlayer': pricePerPlayer,
          'paymentMode': paymentMode,
          'notes': ?notes,
        },
      );
      return MatchEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// يُدخل نتيجة المباراة + تقييمات اللاعبين. تُحفظ مقترحةً حتى يؤكدها لاعب
  /// من الفريق الآخر (أو تُعتمد فوراً إن طابقت ما أدخله الفريق الآخر).
  Future<MatchEntity> submitResult({
    required int matchId,
    required int team1Score,
    required int team2Score,
    required List<({int ratedUserId, int score})> ratings,
    List<int> team1PlayerIds = const [],
  }) async {
    return _guard(() async {
      final res = await _dio.post(
        '${ApiEndpoints.match(matchId)}/result',
        data: {
          'team1Score': team1Score,
          'team2Score': team2Score,
          // توزيع الفريقين — الخادم يحتسب به نقاط المستوى.
          'team1PlayerIds': team1PlayerIds,
          'ratings': [
            for (final r in ratings)
              {'ratedUserId': r.ratedUserId, 'score': r.score},
          ],
        },
      );
      return MatchEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// لاعب من الفريق الآخر يؤكد النتيجة المقترحة (فتُعتمد) أو يرفضها.
  Future<MatchEntity> respondResult({
    required int matchId,
    required bool accept,
    List<({int ratedUserId, int score})> ratings = const [],
    PendingResult? seen,
  }) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.matchResultRespond(matchId),
        data: {
          'accept': accept,
          // ما رآه المؤكِّد: الخادم يرفض إن تغيّر الاقتراح في الأثناء.
          'team1Score': ?seen?.team1Score,
          'team2Score': ?seen?.team2Score,
          'ratings': [
            for (final r in ratings)
              {'ratedUserId': r.ratedUserId, 'score': r.score},
          ],
        },
      );
      return MatchEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// المنظّم يحسم خلافاً (بعد رفض نتيجة مقترحة) بإدخال النتيجة نهائيةً.
  Future<MatchEntity> resolveResult({
    required int matchId,
    required int team1Score,
    required int team2Score,
  }) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.matchResultResolve(matchId),
        data: {'team1Score': team1Score, 'team2Score': team2Score},
      );
      return MatchEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// مبارياتي (أنشأتها أو أنا فيها)، الأحدث موعداً أولاً. [activeOnly] يُسقط
  /// المنتهية والملغاة، و[matchesOnly] يُسقط الأمريكانو والبطولات، و
  /// [newestFirst] يرتّب بالأحدث إنشاءً — كلها لقسم «مبارياتي» و«عرض الكل».
  /// [finishedOnly] للعكس: المنتهية والملغاة وحدها (صفحة «المنتهية»).
  Future<Paged<MatchEntity>> fetchMyMatches({
    int page = 1,
    int pageSize = 10,
    String? status,
    bool activeOnly = false,
    bool matchesOnly = false,
    bool newestFirst = false,
    bool finishedOnly = false,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.myMatches,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (status != null) 'status': status,
          if (activeOnly) 'active': true,
          if (matchesOnly) 'matchesOnly': true,
          if (newestFirst) 'sort': 'newest',
          if (finishedOnly) 'finished': true,
        },
      );
      return Paged.fromJson(_unwrap(res.data), MatchEntity.fromJson);
    });
  }

  /// حالة قائمة الانتظار للمستخدم الحالي.
  Future<WaitlistStatus> fetchWaitlist(int id) => _guard(() async {
    final res = await _dio.get(ApiEndpoints.matchWaitlist(id));
    return WaitlistStatus.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  /// التسجيل في قائمة الانتظار (مجاني — الحصة تُخصم عند طلب الانضمام).
  Future<WaitlistStatus> joinWaitlist(int id) => _guard(() async {
    final res = await _dio.post(ApiEndpoints.matchWaitlist(id));
    return WaitlistStatus.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  /// مغادرة قائمة الانتظار.
  Future<WaitlistStatus> leaveWaitlist(int id) => _guard(() async {
    final res = await _dio.delete(ApiEndpoints.matchWaitlist(id));
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
