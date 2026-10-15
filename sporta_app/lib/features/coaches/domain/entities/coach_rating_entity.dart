/// A player's rating of the coach for one completed session (آخر التقييمات).
class CoachRatingEntity {
  const CoachRatingEntity({
    required this.sessionId,
    required this.playerName,
    required this.rating,
    required this.review,
    required this.scheduledAt,
  });

  final int sessionId;
  final String playerName;
  final int rating;
  final String? review;
  final DateTime scheduledAt;

  factory CoachRatingEntity.fromJson(Map<String, dynamic> json) =>
      CoachRatingEntity(
        sessionId: (json['sessionId'] as num?)?.toInt() ?? 0,
        playerName: json['playerName']?.toString() ?? '',
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        review: json['review']?.toString(),
        scheduledAt:
            DateTime.tryParse(json['scheduledAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}
