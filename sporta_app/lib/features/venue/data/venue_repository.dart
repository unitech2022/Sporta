import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/paged.dart';
import '../../auth/data/models/api_exception.dart';
import '../domain/entities/owner_court_slot.dart';
import '../domain/entities/owner_venue.dart';
import '../domain/entities/venue_dashboard.dart';
import '../domain/entities/venue_match_request.dart';
import '../domain/entities/venue_match_request_detail.dart';

/// Talks to the venue REST endpoints (dashboard + owner management).
class VenueRepository {
  VenueRepository(this._dio);

  final Dio _dio;

  /// Approved venues as a minimal list (public, for pickers like coach
  /// registration's "preferred training venue" field).
  Future<List<VenueOption>> fetchOptions() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.venueOptions);
      final data = _unwrap(res.data) as List;
      return data
          .map((e) => VenueOption.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<VenueDashboard> fetchDashboard() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.venueDashboard);
      return VenueDashboard.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// Financial report for one period. [periodType] is "month" | "week";
  /// [offset] counts periods back from the current one (0 = current).
  Future<VenueRevenueReport> fetchRevenueReport({
    required String periodType,
    int offset = 0,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.venueRevenue,
        queryParameters: {'type': periodType, 'offset': offset},
      );
      return VenueRevenueReport.fromJson(
        _unwrap(res.data) as Map<String, dynamic>,
      );
    });
  }

  Future<List<OwnerVenue>> fetchMyVenues() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.myVenues);
      final data = _unwrap(res.data) as List;
      return data
          .map((e) => OwnerVenue.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// Court bookings across the owner's venues (paged + optional status filter).
  Future<Paged<VenueBooking>> fetchVenueBookings({
    int page = 1,
    int pageSize = 10,
    String? status,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.venueBookings,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (status != null) 'status': status,
        },
      );
      return Paged.fromJson(_unwrap(res.data), VenueBooking.fromJson);
    });
  }

  /// Owner approves/rejects a booking on one of their courts.
  Future<void> respondToBooking(int bookingId, bool approve) async {
    return _guard(() async {
      await _dio.post(
        ApiEndpoints.respondVenueBooking(bookingId),
        data: {'approve': approve},
      );
    });
  }

  /// Match-hosting requests on the owner's courts (paged + optional status).
  /// [status] may hold several statuses separated by commas ("Open,Full");
  /// [kind] narrows to 'match' | 'americano' | 'tournament'.
  Future<Paged<VenueMatchRequest>> fetchMatchRequests({
    int page = 1,
    int pageSize = 10,
    String? status,
    bool mine = false,
    String? kind,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.venueMatchRequests,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (status != null) 'status': status,
          if (mine) 'mine': true,
          if (kind != null) 'kind': kind,
        },
      );
      return Paged.fromJson(_unwrap(res.data), VenueMatchRequest.fromJson);
    });
  }

  /// One match request in full — players, creator contact and the owner payout.
  Future<VenueMatchRequestDetail> fetchMatchRequest(int matchId) async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.venueMatchRequest(matchId));
      return VenueMatchRequestDetail.fromJson(
        _unwrap(res.data) as Map<String, dynamic>,
      );
    });
  }

  /// Owner approves/rejects a match hosted on one of their courts.
  Future<void> respondToMatchRequest(int matchId, bool approve) async {
    return _guard(() async {
      await _dio.post(
        ApiEndpoints.respondVenueMatchRequest(matchId),
        data: {'approve': approve},
      );
    });
  }

  Future<OwnerVenue> createVenue({
    required String name,
    String? nameEn,
    String? city,
    String? district,
    required int cityId,
    required int districtId,
    required String address,
    double? latitude,
    double? longitude,
    List<String> imageUrls = const [],
    int courtCount = 1,
    double pricePerHour = 0,
    List<CourtTier> bookingTiers = const [],
  }) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.createVenue,
        data: {
          'name': name,
          if (nameEn != null && nameEn.isNotEmpty) 'nameEn': nameEn,
          if (city != null && city.isNotEmpty) 'city': city,
          if (district != null && district.isNotEmpty) 'district': district,
          // المعرّفات هي مصدر الموقع لدى الخادم؛ الأسماء أعلاه للعرض فقط.
          'cityId': cityId,
          'districtId': districtId,
          'address': address,
          'latitude': ?latitude,
          'longitude': ?longitude,
          'imageUrls': imageUrls,
          'courtCount': courtCount,
          'pricePerHour': pricePerHour,
          'bookingTiers': [for (final t in bookingTiers) t.toJson()],
        },
      );
      return OwnerVenue.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  Future<OwnerCourt> addCourt({
    required int venueId,
    required String name,
    required String type,
    required double pricePerHour,
    int courtCount = 1,
    String? imageUrl,
    double? latitude,
    double? longitude,
    List<CourtTier> bookingTiers = const [],
  }) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.addCourt(venueId),
        data: {
          'name': name,
          'type': type,
          'courtCount': courtCount,
          'pricePerHour': pricePerHour,
          'imageUrl': ?imageUrl,
          'latitude': ?latitude,
          'longitude': ?longitude,
          'bookingTiers': [for (final t in bookingTiers) t.toJson()],
        },
      );
      return OwnerCourt.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  Future<OwnerCourt> updateCourt({
    required int courtId,
    required double pricePerHour,
    required bool isAvailable,
    int courtCount = 1,
    String? imageUrl,
    double? latitude,
    double? longitude,
    List<CourtTier> bookingTiers = const [],
  }) async {
    return _guard(() async {
      final res = await _dio.put(
        ApiEndpoints.updateCourt(courtId),
        data: {
          'courtCount': courtCount,
          'pricePerHour': pricePerHour,
          'isAvailable': isAvailable,
          'imageUrl': ?imageUrl,
          'latitude': ?latitude,
          'longitude': ?longitude,
          'bookingTiers': [for (final t in bookingTiers) t.toJson()],
        },
      );
      return OwnerCourt.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// حفظ دوام أسبوع الملعب وقواعد تسعيره حسب اليوم والوقت (تستبدل الموجود).
  Future<OwnerCourt> updateCourtSchedule({
    required int courtId,
    required List<CourtOpeningHour> openingHours,
    required List<CourtPriceRule> priceRules,
  }) async {
    return _guard(() async {
      final res = await _dio.put(
        ApiEndpoints.courtSchedule(courtId),
        data: {
          'openingHours': [for (final h in openingHours) h.toJson()],
          'priceRules': [for (final r in priceRules) r.toJson()],
        },
      );
      return OwnerCourt.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// أسعار النادي حسب الوقت: ملاعبه بأسعارها الأساسية وقواعدها الحالية.
  Future<VenuePricing> fetchVenuePricing(int venueId) => _guard(() async {
    final res = await _dio.get(ApiEndpoints.venuePricing(venueId));
    return VenuePricing.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  /// يطبّق النطاقات نفسها على الملاعب المختارة (فارغة = كل ملاعب النادي).
  Future<VenuePricing> updateVenuePricing({
    required int venueId,
    required List<int> courtIds,
    required List<CourtPriceRule> priceRules,
  }) => _guard(() async {
    final res = await _dio.put(
      ApiEndpoints.venuePricing(venueId),
      data: {
        'courtIds': courtIds,
        'priceRules': [for (final r in priceRules) r.toJson()],
      },
    );
    return VenuePricing.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  });

  Future<void> deleteCourt(int courtId) async {
    return _guard(() async {
      await _dio.delete(ApiEndpoints.deleteCourt(courtId));
    });
  }

  Future<List<OwnerCourtSlot>> fetchCourtSlots(int courtId, String date) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.courtSlots(courtId),
        queryParameters: {'date': date},
      );
      final data = (_unwrap(res.data) as Map<String, dynamic>)['slots'] as List;
      return data
          .map((e) => OwnerCourtSlot.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<List<OwnerCourtSlot>> toggleCourtSlot(
    int courtId,
    String date,
    int hour,
  ) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.toggleCourtSlot(courtId),
        data: {'date': date, 'hour': hour},
      );
      final data = (_unwrap(res.data) as Map<String, dynamic>)['slots'] as List;
      return data
          .map((e) => OwnerCourtSlot.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// يوقف أو يتيح عدة مواعيد دفعة واحدة — الخادم يتخطى المحجوز بصمت.
  Future<List<OwnerCourtSlot>> setCourtSlots(
    int courtId,
    String date,
    List<int> hours, {
    required bool available,
  }) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.bulkCourtSlots(courtId),
        data: {'date': date, 'hours': hours, 'available': available},
      );
      final data = (_unwrap(res.data) as Map<String, dynamic>)['slots'] as List;
      return data
          .map((e) => OwnerCourtSlot.fromJson(e as Map<String, dynamic>))
          .toList();
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
