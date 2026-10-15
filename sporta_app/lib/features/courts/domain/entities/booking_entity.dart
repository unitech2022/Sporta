import '../../../../core/localization/tr_global.dart';
import 'package:sporta_app/core/utils/server_time.dart';

/// A court booking belonging to the current user (from `/bookings/me`).
class BookingEntity {
  const BookingEntity({
    required this.id,
    required this.courtId,
    required this.courtName,
    required this.venueName,
    required this.city,
    required this.startTime,
    required this.durationMinutes,
    required this.totalPrice,
    required this.status,
    required this.paidFullAmount,
  });

  final int id;
  final int courtId;
  final String courtName;
  final String venueName;
  final String city;
  final DateTime startTime;
  final int durationMinutes;
  final int totalPrice;

  /// "Pending" | "Confirmed" | "Cancelled" | "Completed".
  final String status;
  final bool paidFullAmount;

  /// حجز مؤكَّد لم يبدأ بعد — يظهر له زرّ «أضف إلى التقويم».
  bool get isUpcomingConfirmed =>
      status == 'Confirmed' && startTime.isAfter(ksaNow());

  /// يُلغى الحجز فقط قبل بدايته (والخادم يرفض ما بعدها بـ BOOKING_STARTED).
  bool get canCancel =>
      (status == 'Confirmed' || status == 'Pending') &&
      startTime.isAfter(ksaNow());

  factory BookingEntity.fromJson(Map<String, dynamic> json) => BookingEntity(
    id: (json['id'] as num?)?.toInt() ?? 0,
    courtId: (json['courtId'] as num?)?.toInt() ?? 0,
    courtName: localizedServerName(json['courtName'], json['courtNameEn']),
    venueName: localizedServerName(json['venueName'], json['venueNameEn']),
    city: localizedServerName(json['city'], json['cityEn']),
    startTime:
        DateTime.tryParse(json['startTime']?.toString() ?? '') ??
        DateTime.now(),
    durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
    totalPrice: (json['totalPrice'] as num?)?.round() ?? 0,
    status: json['status']?.toString() ?? '',
    paidFullAmount: json['paidFullAmount'] == true,
  );
}
