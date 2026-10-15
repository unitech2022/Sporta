import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/paged.dart';
import '../../auth/data/models/api_exception.dart';
import '../../level/domain/level_assessment_item.dart';
import '../domain/entities/coach_dashboard.dart';
import '../domain/entities/coach_entity.dart';
import '../domain/entities/coach_offer_entity.dart';
import '../domain/entities/coach_revenue.dart';
import '../domain/entities/coach_session_entity.dart';
import '../domain/entities/coach_specialization_entity.dart';
import '../domain/entities/coach_student_entity.dart';
import '../domain/entities/my_coach_profile_entity.dart';

/// Talks to the coaches REST endpoints. All API logic lives here so the cubit
/// only orchestrates calls and never touches [Dio] directly.
class CoachRepository {
  CoachRepository(this._dio);

  final Dio _dio;

  /// Active training specializations (public, for the coach registration
  /// picker) — admin-managed via `/admin/coach-specializations`.
  Future<List<CoachSpecializationEntity>> fetchSpecializations() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.coachSpecializations);
      final data = _unwrap(res.data) as List;
      return data
          .map(
            (e) =>
                CoachSpecializationEntity.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    });
  }

  /// Lists coaches (paged), optionally filtered server-side by city and
  /// gender ("male" | "female").
  Future<Paged<CoachEntity>> fetchCoaches({
    String? city,
    String? gender,
    int page = 1,
    int pageSize = 20,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.coaches,
        queryParameters: {
          if (city != null && city.isNotEmpty) 'city': city,
          if (gender != null && gender.isNotEmpty) 'gender': gender,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return Paged.fromJson(_unwrap(res.data), CoachEntity.fromJson);
    });
  }

  Future<CoachEntity> fetchCoachById(int id) async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.coach(id));
      return CoachEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// Books a training session with [coachId]. Returns nothing useful beyond
  /// success (throws [ApiException] on failure).
  Future<void> bookSession({
    required int coachId,
    required DateTime scheduledAt,
    int durationMinutes = 60,
    List<String> domains = const [],
    int? courtId,
  }) async {
    return _guard(() async {
      await _dio.post(
        ApiEndpoints.coachSessions(coachId),
        data: {
          'scheduledAt': _formatDateTime(scheduledAt),
          'durationMinutes': durationMinutes,
          if (domains.isNotEmpty) 'domains': domains,
          'courtId': ?courtId,
        },
      );
    });
  }

  /// Coach rates the player (1..5) after a paid, ended session; an optional
  /// review can be attached. A good rating raises the player's level.
  Future<void> rateSession(int sessionId, int rating, String? review) async {
    return _guard(() async {
      await _dio.post(
        ApiEndpoints.rateCoachSession(sessionId),
        data: {
          'rating': rating,
          if (review != null && review.isNotEmpty) 'review': review,
        },
      );
    });
  }

  /// Player rates the coach (1..5) after a paid, ended session. Player ratings
  /// feed the coach's displayed rating and the automatic "معتمد" badge.
  Future<void> rateCoach(int sessionId, int rating, String? review) async {
    return _guard(() async {
      await _dio.post(
        ApiEndpoints.rateCoachOfSession(sessionId),
        data: {
          'rating': rating,
          if (review != null && review.isNotEmpty) 'review': review,
        },
      );
    });
  }

  /// Lists the current player's booked sessions.
  Future<Paged<CoachSessionEntity>> fetchMySessions({
    int page = 1,
    int pageSize = 10,
    String? status,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.myCoachSessions,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (status != null) 'status': status,
        },
      );
      return Paged.fromJson(_unwrap(res.data), CoachSessionEntity.fromJson);
    });
  }

  /// Pending session booking requests for the signed-in coach (paged).
  Future<Paged<CoachSessionEntity>> fetchSessionRequests({
    int page = 1,
    int pageSize = 10,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.coachSessionRequests,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return Paged.fromJson(_unwrap(res.data), CoachSessionEntity.fromJson);
    });
  }

  /// All of the signed-in coach's bookings (paged + optional status filter).
  Future<Paged<CoachSessionEntity>> fetchCoachBookings({
    int page = 1,
    int pageSize = 10,
    String? status,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.coachBookings,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (status != null) 'status': status,
        },
      );
      return Paged.fromJson(_unwrap(res.data), CoachSessionEntity.fromJson);
    });
  }

  /// The signed-in coach's own full profile (for the "my profile" screen).
  Future<MyCoachProfileEntity> fetchMyCoachProfile() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.coachMe);
      return MyCoachProfileEntity.fromJson(
        _unwrap(res.data) as Map<String, dynamic>,
      );
    });
  }

  /// Updates the signed-in coach's profile fields.
  Future<MyCoachProfileEntity> updateMyCoachProfile({
    String? firstName,
    String? lastName,
    String? city,
    String? bio,
    String? specialization,
    int? sportId,
    double? hourlyRate,
    String? certifications,
    String? experienceLevel,
    String? targetGender,
    double? packagePrice,
    int? preferredVenueId,
    List<String>? availableDays,
    String? residency,
    String? nationalIdFrontUrl,
    String? nationalIdBackUrl,
    List<int>? specializationIds,
  }) async {
    return _guard(() async {
      final res = await _dio.put(
        ApiEndpoints.coachMe,
        data: {
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (city != null) 'city': city,
          if (bio != null) 'bio': bio,
          if (specialization != null) 'specialization': specialization,
          if (sportId != null) 'sportId': sportId,
          if (hourlyRate != null) 'hourlyRate': hourlyRate,
          if (certifications != null) 'certifications': certifications,
          if (experienceLevel != null) 'experienceLevel': experienceLevel,
          if (targetGender != null) 'targetGender': targetGender,
          if (packagePrice != null) 'packagePrice': packagePrice,
          // 0 clears the preferred venue.
          if (preferredVenueId != null) 'preferredVenueId': preferredVenueId,
          if (availableDays != null) 'availableDays': availableDays,
          if (residency != null) 'residency': residency,
          if (nationalIdFrontUrl != null)
            'nationalIdFrontUrl': nationalIdFrontUrl,
          if (nationalIdBackUrl != null) 'nationalIdBackUrl': nationalIdBackUrl,
          if (specializationIds != null) 'specializationIds': specializationIds,
        },
      );
      return MyCoachProfileEntity.fromJson(
        _unwrap(res.data) as Map<String, dynamic>,
      );
    });
  }

  /// Coach approves/rejects a session booking request.
  Future<void> respondToSessionRequest(int sessionId, bool approve) async {
    return _guard(() async {
      await _dio.post(
        ApiEndpoints.respondCoachSession(sessionId),
        data: {'approve': approve},
      );
    });
  }

  /// Pending level assessments this coach can review (paged).
  Future<Paged<LevelAssessmentItem>> fetchPendingAssessments({
    int page = 1,
    int pageSize = 20,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.coachPendingAssessments,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return Paged.fromJson(_unwrap(res.data), LevelAssessmentItem.fromJson);
    });
  }

  /// Assigns a level (1..7) to a pending assessment.
  Future<void> assignAssessment(
    int assessmentId,
    int level,
    String? notes,
  ) async {
    return _guard(() async {
      await _dio.post(
        ApiEndpoints.assignAssessment(assessmentId),
        data: {
          'level': level,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
    });
  }

  Future<CoachDashboard> fetchDashboard() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.coachDashboard);
      return CoachDashboard.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// The signed-in coach's students (paged) — إدارة الطلاب.
  Future<Paged<CoachStudentEntity>> fetchStudents({
    int page = 1,
    int pageSize = 20,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.coachStudents,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return Paged.fromJson(_unwrap(res.data), CoachStudentEntity.fromJson);
    });
  }

  /// Earnings report for one period ("month" | "week") — التقارير.
  Future<CoachRevenueReport> fetchRevenueReport({
    required String periodType,
    int offset = 0,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.coachRevenue,
        queryParameters: {'type': periodType, 'offset': offset},
      );
      return CoachRevenueReport.fromJson(
        _unwrap(res.data) as Map<String, dynamic>,
      );
    });
  }

  /// All of the signed-in coach's offers (active, inactive, expired) —
  /// العروض والخصومات management.
  Future<List<CoachOfferEntity>> fetchMyOffers() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.coachOffers);
      return CoachOfferEntity.listFrom(_unwrap(res.data));
    });
  }

  Future<CoachOfferEntity> createOffer({
    required String title,
    required int discountPercent,
    required String targetLabel,
    required DateTime expiresAt,
  }) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.coachOffers,
        data: {
          'title': title,
          'discountPercent': discountPercent,
          'targetLabel': targetLabel,
          'expiresAt': _formatDateTime(expiresAt),
        },
      );
      return CoachOfferEntity.fromJson(
        _unwrap(res.data) as Map<String, dynamic>,
      );
    });
  }

  Future<CoachOfferEntity> setOfferActive(int offerId, bool isActive) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.setCoachOfferActive(offerId),
        data: {'isActive': isActive},
      );
      return CoachOfferEntity.fromJson(
        _unwrap(res.data) as Map<String, dynamic>,
      );
    });
  }

  Future<void> deleteOffer(int offerId) async {
    return _guard(() async {
      await _dio.delete(ApiEndpoints.coachOffer(offerId));
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

  String _formatDateTime(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}T'
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}:00';
}
