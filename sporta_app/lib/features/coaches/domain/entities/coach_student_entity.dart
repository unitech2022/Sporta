/// One player the coach has trained (a paid session together) — for
/// إدارة الطلاب.
class CoachStudentEntity {
  const CoachStudentEntity({
    required this.playerId,
    required this.playerName,
    this.avatarUrl,
    required this.sessionsCount,
    required this.totalSpent,
    required this.lastSessionAt,
  });

  final int playerId;
  final String playerName;

  /// الصورة الشخصية للاعب (رابط نسبي من الخادم)، null إن لم يرفع صورة.
  final String? avatarUrl;
  final int sessionsCount;
  final double totalSpent;
  final DateTime lastSessionAt;

  factory CoachStudentEntity.fromJson(Map<String, dynamic> json) =>
      CoachStudentEntity(
        playerId: (json['playerId'] as num?)?.toInt() ?? 0,
        playerName: json['playerName']?.toString() ?? '',
        avatarUrl: json['avatarUrl']?.toString(),
        sessionsCount: (json['sessionsCount'] as num?)?.toInt() ?? 0,
        totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0,
        lastSessionAt:
            DateTime.tryParse(json['lastSessionAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}
