class BookingDetails {
  const BookingDetails({
    required this.courtName,
    required this.date,
    required this.time,
    required this.duration,
    required this.totalPrice,
  });

  final String courtName;
  final String date;
  final String time;
  final String duration;
  final int totalPrice;
}
