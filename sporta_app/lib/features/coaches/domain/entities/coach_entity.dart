class CoachEntity {
  final String id;
  final String name;
  final String avatarInitials;
  final double rating;
  final int reviews;
  final int students;
  final int levelMin;
  final int levelMax;
  final String location;
  final double distanceKm;
  final int price;
  final List<String> specialties;
  final String badgeLabel;
  final String badgeType;
  final List<String> avatarGradientColors;
  bool isBooked;

  CoachEntity({
    required this.id,
    required this.name,
    required this.avatarInitials,
    required this.rating,
    required this.reviews,
    required this.students,
    required this.levelMin,
    required this.levelMax,
    required this.location,
    required this.distanceKm,
    required this.price,
    required this.specialties,
    required this.badgeLabel,
    required this.badgeType,
    required this.avatarGradientColors,
    this.isBooked = false,
  });
}
