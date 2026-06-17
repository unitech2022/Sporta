import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../auth/data/models/api_exception.dart';
import '../domain/entities/court_entity.dart';
import 'models/booking_result.dart';
import 'models/court_slot.dart';

/// Talks to the courts/booking REST endpoints. All API logic lives here so the
/// cubits only orchestrate calls and never touch [Dio] directly.
class CourtRepository {
  CourtRepository(this._dio);

  final Dio _dio;

  /// Lists courts, optionally filtered server-side by city/type/gender.
  Future<List<CourtEntity>> fetchCourts({
    String? city,
    String? type,
    String? gender,
  }) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.courts,
        queryParameters: {
          if (city != null && city.isNotEmpty) 'city': city,
          if (type != null) 'type': type,
          if (gender != null) 'gender': gender,
        },
      );
      final data = _unwrap(res.data) as List;
      return data
          .map((e) => CourtEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<CourtEntity> fetchCourtById(int id) async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.court(id));
      return CourtEntity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
    });
  }

  /// Per-slot availability for [courtId] on [date].
  Future<List<CourtSlot>> fetchAvailability(int courtId, DateTime date) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.courtAvailability(courtId),
        queryParameters: {'date': _formatDate(date)},
      );
      final data = _unwrap(res.data) as Map<String, dynamic>;
      final slots = (data['slots'] as List?) ?? const [];
      return slots
          .map((e) => CourtSlot.fromJson(e as Map<String, dynamic>))
          .toList();
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
