import 'package:sporta_app/core/utils/server_time.dart';

/// A training session the player booked with a coach (from `coaches/sessions/me`).
class CoachSessionEntity {
  final int id;
  final int coachId;
  final String coachName;
  final DateTime scheduledAt;
  final int durationMinutes;
  final double price;
  final String title;
  final String? description;
  final bool isPaid;

  /// The coach's rating of the player (set after a paid, ended session).
  final int? coachRating;
  final String? coachReview;

  /// The player's rating of the coach — feeds the coach's displayed rating
  /// and the automatic "معتمد" badge.
  final int? playerRating;
  final String? playerReview;

  /// "pending" | "Upcoming" | "rejected" | "Completed".
  final String status;

  /// The booking player's name (populated in the coach's requests view).
  final String? playerName;

  bool get isRated => coachRating != null;

  /// جلسة مؤكَّدة لم تبدأ — يظهر لها «أضف إلى التقويم».
  bool get canAddToCalendar =>
      status == 'Upcoming' && scheduledAt.isAfter(ksaNow());

  CoachSessionEntity({
    required this.id,
    required this.coachId,
    required this.coachName,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.price,
    required this.title,
    required this.description,
    required this.isPaid,
    required this.coachRating,
    this.coachReview,
    this.playerRating,
    this.playerReview,
    required this.status,
    this.playerName,
  });

  bool get isCompleted => status == 'Completed';

  /// Whether the session's scheduled time window has passed.
  bool get hasEnded => ksaNow().isAfter(
    scheduledAt.add(Duration(minutes: durationMinutes)),
  );

  /// The coach may rate the player only after payment and the session's end.
  bool get canCoachRate =>
      status == 'Upcoming' && isPaid && hasEnded && !isRated;

  /// The player may rate the coach after payment and the session's end
  /// (once). Rejected/pending sessions are never ratable.
  bool get canPlayerRate =>
      status != 'pending' &&
      status != 'rejected' &&
      isPaid &&
      hasEnded &&
      playerRating == null;

  CoachSessionEntity _copy({
    int? coachRating,
    String? coachReview,
    int? playerRating,
    String? playerReview,
    String? status,
  }) => CoachSessionEntity(
    id: id,
    coachId: coachId,
    coachName: coachName,
    scheduledAt: scheduledAt,
    durationMinutes: durationMinutes,
    price: price,
    title: title,
    description: description,
    isPaid: isPaid,
    coachRating: coachRating ?? this.coachRating,
    coachReview: coachReview ?? this.coachReview,
    playerRating: playerRating ?? this.playerRating,
    playerReview: playerReview ?? this.playerReview,
    status: status ?? this.status,
    playerName: playerName,
  );

  /// Returns a copy with a new [status] (used after accept/reject).
  CoachSessionEntity copyWithStatus(String newStatus) =>
      _copy(status: newStatus);

  /// Returns a copy marked completed with the coach's rating (after rating).
  CoachSessionEntity copyWithRating(int rating, String? review) =>
      _copy(coachRating: rating, coachReview: review, status: 'Completed');

  /// Returns a copy carrying the player's rating of the coach.
  CoachSessionEntity copyWithPlayerRating(int rating, String? review) =>
      _copy(playerRating: rating, playerReview: review);

  factory CoachSessionEntity.fromJson(Map<String, dynamic> json) {
    return CoachSessionEntity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      coachId: (json['coachId'] as num?)?.toInt() ?? 0,
      coachName: json['coachName']?.toString() ?? '',
      scheduledAt:
          DateTime.tryParse(json['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 60,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      isPaid: json['isPaid'] == true,
      coachRating: (json['coachRating'] as num?)?.toInt(),
      coachReview: json['coachReview']?.toString(),
      playerRating: (json['playerRating'] as num?)?.toInt(),
      playerReview: json['playerReview']?.toString(),
      status: json['status']?.toString() ?? 'Upcoming',
      playerName: json['playerName']?.toString(),
    );
  }
}
