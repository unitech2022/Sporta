import '../../../core/localization/tr_global.dart';
import '../../../core/utils/server_time.dart';

/// A level-assessment record (self / video / coach paths) with its status.
class LevelAssessmentItem {
  const LevelAssessmentItem({
    required this.id,
    required this.type,
    required this.status,
    required this.videoUrl,
    required this.playerName,
    required this.coachName,
    required this.assignedLevel,
    required this.assignedLevelName,
    required this.createdAt,
  });

  final int id;

  /// "self" | "video" | "coach".
  final String type;

  /// "pending" | "completed".
  final String status;
  final String? videoUrl;
  final String? playerName;
  final String? coachName;
  final int? assignedLevel;
  final String? assignedLevelName;
  final DateTime createdAt;

  bool get isPending => status == 'pending';

  String get typeLabel => switch (type) {
        'video' => trg('تقييم بالفيديو'),
        'coach' => trg('تقييم عبر مدرب'),
        _ => trg('تقييم ذاتي'),
      };

  factory LevelAssessmentItem.fromJson(Map<String, dynamic> json) =>
      LevelAssessmentItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        type: json['type']?.toString() ?? 'self',
        status: json['status']?.toString() ?? 'pending',
        videoUrl: json['videoUrl']?.toString(),
        playerName: json['playerName']?.toString(),
        coachName: json['coachName']?.toString(),
        assignedLevel: (json['assignedLevel'] as num?)?.toInt(),
        assignedLevelName: json['assignedLevelName']?.toString(),
        createdAt: parseServerUtc(json['createdAt']) ?? DateTime.now(),
      );
}
