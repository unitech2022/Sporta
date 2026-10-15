/// Action the owner chose on the court detail page.
enum CourtDetailAction { edit, delete }

/// An hourly slot for an owner's court on a given day.
class OwnerCourtSlot {
  const OwnerCourtSlot({
    required this.hour,
    required this.time,
    required this.isBooked,
    required this.isBlocked,
    required this.isAvailable,
  });

  final int hour;
  final String time; // "HH:00"
  final bool isBooked;
  final bool isBlocked;
  final bool isAvailable;

  factory OwnerCourtSlot.fromJson(Map<String, dynamic> json) => OwnerCourtSlot(
    hour: (json['hour'] as num?)?.toInt() ?? 0,
    time: json['time']?.toString() ?? '',
    isBooked: json['isBooked'] == true,
    isBlocked: json['isBlocked'] == true,
    isAvailable: json['isAvailable'] == true,
  );
}
