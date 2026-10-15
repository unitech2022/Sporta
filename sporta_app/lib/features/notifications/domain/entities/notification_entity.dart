import '../../../../core/utils/server_time.dart';

/// A user notification.
class NotificationEntity {
  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String body;

  /// e.g. "friend_request" | "friend_accepted" | "follow" | "match_join" | "coach_session".
  final String? type;
  final int? referenceId;
  final bool isRead;
  final DateTime createdAt;

  NotificationEntity copyWith({bool? isRead}) => NotificationEntity(
        id: id,
        title: title,
        body: body,
        type: type,
        referenceId: referenceId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  factory NotificationEntity.fromJson(Map<String, dynamic> json) =>
      NotificationEntity(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        type: json['type']?.toString(),
        referenceId: (json['referenceId'] as num?)?.toInt(),
        isRead: json['isRead'] == true,
        createdAt: parseServerUtc(json['createdAt']) ?? DateTime.now(),
      );
}
