/// A single bookable time slot for a court on a given day.
class CourtSlot {
  const CourtSlot({
    required this.time,
    required this.isBooked,
    required this.price,
    required this.isPeak,
  });

  final String time;
  final bool isBooked;
  final double price;
  final bool isPeak;

  factory CourtSlot.fromJson(Map<String, dynamic> json) => CourtSlot(
        time: json['time']?.toString() ?? '',
        isBooked: json['isBooked'] == true,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        isPeak: json['isPeak'] == true,
      );
}

/// مواعيد يوم واحد لملعب: القائمة قد تكون فارغة لأن الملعب مغلق في هذا اليوم
/// حسب دوام أسبوعه، وليس لأن كل المواعيد محجوزة.
class CourtDayAvailability {
  const CourtDayAvailability({
    required this.slots,
    this.isClosed = false,
    this.openHour = 0,
    this.closeHour = 0,
  });

  final List<CourtSlot> slots;
  final bool isClosed;
  final int openHour;
  final int closeHour;

  /// "06:00 - 24:00" — دوام هذا اليوم، أو فراغ حين يكون مغلقاً.
  String get rangeLabel => isClosed
      ? ''
      : '${openHour.toString().padLeft(2, '0')}:00 - '
          '${closeHour.toString().padLeft(2, '0')}:00';

  factory CourtDayAvailability.fromJson(Map<String, dynamic> json) =>
      CourtDayAvailability(
        slots: ((json['slots'] as List?) ?? const [])
            .map((e) => CourtSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
        isClosed: json['isClosed'] == true,
        openHour: (json['openHour'] as num?)?.toInt() ?? 0,
        closeHour: (json['closeHour'] as num?)?.toInt() ?? 0,
      );

  static const empty = CourtDayAvailability(slots: []);
}
