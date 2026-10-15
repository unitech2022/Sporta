import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../auth/data/models/api_exception.dart';
import '../domain/entities/membership.dart';

/// عضويات الأندية: إدارة المالك لخططه، واشتراك اللاعب وعضوياته.
class MembershipRepository {
  MembershipRepository(this._dio);

  final Dio _dio;

  // ── المالك ──

  Future<VenueMembers> fetchVenueAdmin(int venueId) => _guard(() async {
    final res = await _dio.get(ApiEndpoints.venueMemberships(venueId));
    return VenueMembers.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  Future<MembershipPlan> savePlan({
    required int venueId,
    int? planId,
    required String name,
    String? nameEn,
    String? description,
    required double monthlyPrice,
    required double discountPercent,
    int? monthlyDiscountHours,
    required int priorityDays,
    required bool isActive,
  }) => _guard(() async {
    final body = {
      'name': name,
      'nameEn': nameEn,
      'description': description,
      'monthlyPrice': monthlyPrice,
      'discountPercent': discountPercent,
      'monthlyDiscountHours': monthlyDiscountHours,
      'priorityDays': priorityDays,
      'isActive': isActive,
    };
    final res = planId == null
        ? await _dio.post(
            ApiEndpoints.venueMembershipPlans(venueId),
            data: body,
          )
        : await _dio.put(ApiEndpoints.membershipPlan(planId), data: body);
    return MembershipPlan.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  Future<void> deletePlan(int planId) => _guard(() async {
    await _dio.delete(ApiEndpoints.membershipPlan(planId));
  });

  /// [days] = null يلغي النافذة (الحجز مفتوح بلا حد).
  Future<void> setBookingWindow(int venueId, int? days) => _guard(() async {
    await _dio.put(
      ApiEndpoints.venueBookingWindow(venueId),
      data: {'days': days},
    );
  });

  // ── اللاعب ──

  Future<VenueMembership> fetchForVenue(int venueId) => _guard(() async {
    final res = await _dio.get(ApiEndpoints.membershipForVenue(venueId));
    return VenueMembership.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  Future<Membership> subscribe(int planId, {required bool autoRenew}) =>
      _guard(() async {
        final res = await _dio.post(
          ApiEndpoints.membershipSubscribe,
          data: {'planId': planId, 'autoRenew': autoRenew},
        );
        return Membership.fromJson(_unwrap(res.data) as Map<String, dynamic>);
      });

  Future<Membership> setAutoRenew(int membershipId, bool autoRenew) =>
      _guard(() async {
        final res = await _dio.put(
          ApiEndpoints.membershipAutoRenew(membershipId),
          data: {'autoRenew': autoRenew},
        );
        return Membership.fromJson(_unwrap(res.data) as Map<String, dynamic>);
      });

  /// حصتي في حدث قائم (مباراة بـ [matchId] أو أمريكانو/بطولة بـ [americanoId]).
  Future<MemberShareQuote> fetchEventShare({int? matchId, int? americanoId}) =>
      _guard(() async {
        final res = await _dio.get(
          ApiEndpoints.membershipEventShare,
          queryParameters: {'matchId': ?matchId, 'americanoId': ?americanoId},
        );
        return MemberShareQuote.fromJson(
          _unwrap(res.data) as Map<String, dynamic>,
        );
      });

  /// حصتي كمنشئ حدث جديد على ملعب قبل إنشائه.
  Future<MemberShareQuote> fetchCourtShare({
    required int courtId,
    required double price,
    required int minutes,
  }) => _guard(() async {
    final res = await _dio.get(
      ApiEndpoints.membershipCourtShare,
      queryParameters: {'courtId': courtId, 'price': price, 'minutes': minutes},
    );
    return MemberShareQuote.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  Future<List<Membership>> fetchMine() => _guard(() async {
    final res = await _dio.get(ApiEndpoints.myMemberships);
    return [
      for (final e in (_unwrap(res.data) as List? ?? const []))
        Membership.fromJson(e as Map<String, dynamic>),
    ];
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
}
