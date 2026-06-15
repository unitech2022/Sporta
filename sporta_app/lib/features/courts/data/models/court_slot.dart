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
  final int price;
  final bool isPeak;

  factory CourtSlot.fromJson(Map<String, dynamic> json) => CourtSlot(
        time: json['time']?.toString() ?? '',
        isBooked: json['isBooked'] == true,
        price: (json['price'] as num?)?.round() ?? 0,
        isPeak: json['isPeak'] == true,
      );
}
