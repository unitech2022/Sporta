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
  });

  /// Numeric backend id (the API uses ints; [id] keeps the string form used
  /// across the UI and navigation).
  int get numericId => int.tryParse(id) ?? 0;

  factory CourtEntity.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => (v as num?)?.round() ?? 0;

    return CourtEntity(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      // Rating/reviews/facilities are not yet modelled on the backend.
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviews: asInt(json['reviews']),
      distance: json['distance']?.toString() ?? '',
      distanceValue: (json['distanceValue'] as num?)?.toDouble() ?? 0,
      city: json['city']?.toString() ?? '',
      neighborhood: json['neighborhood']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      type: json['type']?.toString() == 'outdoor'
          ? CourtType.outdoor
          : CourtType.indoor,
      gender: _genderFromString(json['gender']?.toString()),
      basePrice: asInt(json['basePrice']),
      peakHourPrice: asInt(json['peakHourPrice']),
      availableTimes: (json['availableTimes'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      availableDurations: (json['availableDurations'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [60, 90, 120],
      facilities: (json['facilities'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  static CourtGender _genderFromString(String? value) {
    switch (value) {
      case 'men':
        return CourtGender.men;
      case 'women':
        return CourtGender.women;
      case 'family':
        return CourtGender.family;
      default:
        return CourtGender.all;
    }
  }
}
