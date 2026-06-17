/// Result of a confirmed court booking.
class BookingResult {
  const BookingResult({
    required this.id,
    required this.courtName,
    required this.totalPrice,
    required this.status,
  });

  final int id;
  final String courtName;
  final int totalPrice;
  final String status;

  factory BookingResult.fromJson(Map<String, dynamic> json) => BookingResult(
        id: (json['id'] as num?)?.toInt() ?? 0,
        courtName: json['courtName']?.toString() ?? '',
        totalPrice: (json['totalPrice'] as num?)?.round() ?? 0,
        status: json['status']?.toString() ?? '',
      );
}
