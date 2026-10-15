import 'coach_rating_entity.dart';
import 'coach_session_entity.dart';

/// Coach home dashboard stats.
class CoachDashboard {
  const CoachDashboard({
    required this.activeStudents,
    required this.rating,
    required this.totalSessions,
    required this.monthRevenue,
    required this.totalRevenue,
    required this.weekSessions,
    required this.upcomingSessions,
    required this.recentRatings,
  });

  final int activeStudents;
  final double rating;
  final int totalSessions;
  final double monthRevenue;
  final double totalRevenue;
  final int weekSessions;
  final List<CoachSessionEntity> upcomingSessions;
  final List<CoachRatingEntity> recentRatings;

  factory CoachDashboard.fromJson(Map<String, dynamic> json) => CoachDashboard(
    activeStudents: (json['activeStudents'] as num?)?.toInt() ?? 0,
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
    monthRevenue: (json['monthRevenue'] as num?)?.toDouble() ?? 0,
    totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
    weekSessions: (json['weekSessions'] as num?)?.toInt() ?? 0,
    upcomingSessions:
        (json['upcomingSessions'] as List?)
            ?.map((e) => CoachSessionEntity.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    recentRatings:
        (json['recentRatings'] as List?)
            ?.map((e) => CoachRatingEntity.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}
