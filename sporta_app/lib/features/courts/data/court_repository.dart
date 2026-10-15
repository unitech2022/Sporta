import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/paged.dart';
import '../../auth/data/models/api_exception.dart';
import '../domain/entities/booking_entity.dart';
import '../domain/entities/court_entity.dart';
import 'models/booking_quote.dart';
import 'models/booking_result.dart';
import 'models/court_slot.dart';

/// Talks to the courts/booking REST endpoints. All API logic lives here so the
/// cubits only orchestrate calls and never touch [Dio] directly.
class CourtRepository {
  CourtRepository(this._dio);

  final Dio _dio;

  /// Lists courts (paged), optionally filtered server-side by city/type/gender.
  /// [slotDate] يفعّل البحث بالوقت: كل ملعب يعود بمواعيده الفارغة التي تبدأ
  /// في [fromHour]..[toHour] بالمدة [durationMinutes]، ومن له مواعيد أولاً.
  Future<Paged<CourtEntity>> fetchCourts({
    String? city,
    String? type,
    String? gender,
    int page = 1,
    int pageSize = 20,
    DateTime? slotDate,
    int fromHour = 0,
    int toHour = 24,
    int durationMinutes = 60,
    bool onlyAvailable = false,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.courts,
        queryParameters: {
          if (city != null && city.isNotEmpty) 'city': city,
          if (type != null) 'type': type,
          if (gender != null) 'gender': gender,
          'page': page,
          'pageSize': pageSize,
          if (slotDate != null) ...{
            'date': _formatDate(slotDate),
            'fromHour': fromHour,
            'toHour': toHour,
            'duration': durationMinutes,
            'onlyAvailable': onlyAvailable,
          },
        },
      );
      return Paged.fromJson(_unwrap(res.data), CourtEntity.fromJson);
    });
  }

  /// ملاعب صاحب الملعب نفسه — يستضيف عليها مبارياته وأمريكانوه، فلا تصلح
  /// قائمةُ اللاعب العامة (مقصورة على مدينته ولا تضمن ملكيته للملعب).
  /// تُقرأ المعرّفات من `/venues/mine` ثم يُجلب كل ملعب ببطاقته الكاملة، لأن
  /// حمولة النادي مختصرة ولا تحمل الأسعار والدوام بالشكل الذي تتوقعه البطاقة.
  Future<List<CourtEntity>> fetchMyCourts() async {
    final ids = await _guard(() async {
      final res = await _dio.get(ApiEndpoints.myVenues);
      final venues = (_unwrap(res.data) as List).cast<Map<String, dynamic>>();
      return [
        for (final v in venues)
          for (final c in ((v['courts'] as List?) ?? const [])
              .cast<Map<String, dynamic>>())
            (c['id'] as num).toInt(),
      ];
    });

    final courts = <CourtEntity>[];
    for (final id in ids) {
      try {
        courts.add(await fetchCourtById(id));
      } catch (_) {
        // ملعب تعذّر جلبه لا يُسقط القائمة كلها.
      }
    }
    return courts;
  }

  Future<CourtEntity> fetchCourtById(int id) async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.court(id));
      return CourtEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// الملاعب المفضّلة للمستخدم (مقسّمة لصفحات)، الأحدث إضافةً أولاً.
  Future<Paged<CourtEntity>> fetchFavoriteCourts({
    int page = 1,
    int pageSize = 20,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.favoriteCourts,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return Paged.fromJson(_unwrap(res.data), CourtEntity.fromJson);
    });
  }

  /// يضيف الملعب للمفضّلة أو يزيله. يُرجع الحالة كما أقرّها الخادم.
  Future<bool> toggleCourtFavorite(int id, bool favorite) async {
    return _guard(() async {
      final res = await _dio.put(
        ApiEndpoints.courtFavorite(id),
        data: {'favorite': favorite},
      );
      final data = _unwrap(res.data);
      return (data is Map && data['favorite'] is bool)
          ? data['favorite'] as bool
          : favorite;
    });
  }

  /// Cancels one of the user's court bookings; returns the updated booking.
  Future<BookingEntity> cancelBooking(int id, {String? reason}) async {
    return _guard(() async {
      final res = await _dio.put(
        ApiEndpoints.cancelBooking(id),
        data: {if (reason != null && reason.isNotEmpty) 'reason': reason},
      );
      return BookingEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// The current user's court bookings (paged + optional status filter).
  Future<Paged<BookingEntity>> fetchMyBookings({
    int page = 1,
    int pageSize = 10,
    String? status,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.myBookings,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (status != null) 'status': status,
        },
      );
      return Paged.fromJson(_unwrap(res.data), BookingEntity.fromJson);
    });
  }

  /// Per-slot availability for [courtId] on [date], stepped by
  /// [durationMinutes] — e.g. a 120-minute session offers slots every two
  /// hours instead of every hour.
  /// [endDate] (اختياري): آخر يوم في مدى متعدد الأيام — البطولة تشغل نفس
  /// الموعد من كل يوم، فلا يعود الموعد متاحاً إلا إذا كان فارغاً فيها كلها.
  Future<CourtDayAvailability> fetchAvailability(
    int courtId,
    DateTime date, {
    int durationMinutes = 60,
    DateTime? endDate,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.courtAvailability(courtId),
        queryParameters: {
          'date': _formatDate(date),
          'durationMinutes': durationMinutes,
          if (endDate != null) 'endDate': _formatDate(endDate),
        },
      );
      return CourtDayAvailability.fromJson(
          _unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// تسعير الحجز من الخادم قبل التأكيد — هو نفسه ما سيُخصم، فيشمل قواعد تسعير
  /// المالك وخصم باقة اللاعب. لا يُنشئ حجزاً ولا يخصم رصيداً.
  /// [endDate] (اختياري): آخر يوم في مدى يشغل الملعب في نفس الموعد من كل يوم
  /// (البطولة) — السعر يعود مجموع أيام المدى لا سعر يوم البداية وحده.
  Future<BookingQuote> quoteBooking({
    required int courtId,
    required DateTime startTime,
    required int durationMinutes,
    DateTime? endDate,
  }) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.bookingQuote,
        data: {
          'courtId': courtId,
          'startTime': _formatDateTime(startTime),
          'durationMinutes': durationMinutes,
          if (endDate != null) 'endDate': _formatDate(endDate),
        },
      );
      return BookingQuote.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// Creates a booking and returns the confirmed result.
  Future<BookingResult> createBooking({
    required int courtId,
    required DateTime startTime,
    required int durationMinutes,
    bool paidFullAmount = true,
  }) async {
    return _guard(() async {
      final res = await _dio.post(
        ApiEndpoints.bookings,
        data: {
          'courtId': courtId,
          'startTime': _formatDateTime(startTime),
          'durationMinutes': durationMinutes,
          'paidFullAmount': paidFullAmount,
        },
      );
      return BookingResult.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  /// Unwraps the `{ success, data }` envelope used by the API.
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

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _formatDateTime(DateTime d) =>
      '${_formatDate(d)}T${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}:00';
}
