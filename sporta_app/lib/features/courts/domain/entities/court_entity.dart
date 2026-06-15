enum CourtType { indoor, outdoor }

enum CourtGender { all, men, women, family }

class TimeSlot {
  final String time;
  final bool isBooked;

  const TimeSlot({required this.time, required this.isBooked});
}

class CourtEntity {
  final String id;
  final String name;
  final double rating;
  final int reviews;
  final String distance;
  final double distanceValue;
  final String city;
  final String neighborhood;
  final String country;
  final CourtType type;
  final CourtGender gender;
  final int basePrice;
  final int peakHourPrice;
  final List<String> availableTimes;
  final List<int> availableDurations;
  final List<String> facilities;
  bool isFavorite;

  CourtEntity({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.distanceValue,
    required this.city,
    required this.neighborhood,
    required this.country,
    required this.type,
    required this.gender,
    required this.basePrice,
    required this.peakHourPrice,
    required this.availableTimes,
    required this.availableDurations,
    required this.facilities,
    this.isFavorite = false,
  });
}
