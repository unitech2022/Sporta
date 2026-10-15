import '../../../../core/localization/tr_global.dart';

/// A player as shown in search / picker / friends lists.
class PlayerSummary {
  const PlayerSummary({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.level,
    required this.city,
    this.userType = 'player',
    required this.relation,
    required this.isFollowing,
    this.isFavorite = false,
  });

  final int userId;
  final String name;

  /// الصورة الشخصية للاعب (رابط نسبي من الخادم)، null إن لم يرفع صورة.
  final String? avatarUrl;

  final int? level;
  final String? city;

  /// "player" | "coach".
  final String userType;

  bool get isCoach => userType == 'coach';

  /// "self" | "none" | "pending_sent" | "pending_received" | "friends".
  final String relation;

  /// Whether the current user follows this player.
  final bool isFollowing;

  /// Whether the current user marked this friend as a favorite partner.
  final bool isFavorite;

  bool get isFriend => relation == 'friends';
  bool get isPending => relation == 'pending_sent' || relation == 'pending_received';

  PlayerSummary copyWith({bool? isFavorite}) => PlayerSummary(
        userId: userId,
        name: name,
        avatarUrl: avatarUrl,
        level: level,
        city: city,
        userType: userType,
        relation: relation,
        isFollowing: isFollowing,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '؟';
    return parts.take(2).map((p) => p.substring(0, 1)).join('.');
  }

  factory PlayerSummary.fromJson(Map<String, dynamic> json) => PlayerSummary(
        userId: (json['userId'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        avatarUrl: json['avatarUrl']?.toString(),
        level: (json['level'] as num?)?.toInt(),
        city: localizedServerName(json['city'], json['cityEn']),
        userType: json['userType']?.toString() ?? 'player',
        relation: json['relation']?.toString() ?? 'none',
        isFollowing: json['isFollowing'] == true,
        isFavorite: json['isFavorite'] == true,
      );
}

/// An incoming friend request.
class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromName,
    this.avatarUrl,
    required this.level,
    required this.city,
  });

  final int id;
  final int fromUserId;
  final String fromName;

  /// الصورة الشخصية لمرسل الطلب، null إن لم يرفع صورة.
  final String? avatarUrl;

  final int? level;
  final String? city;

  factory FriendRequest.fromJson(Map<String, dynamic> json) => FriendRequest(
        id: (json['id'] as num?)?.toInt() ?? 0,
        fromUserId: (json['fromUserId'] as num?)?.toInt() ?? 0,
        fromName: json['fromName']?.toString() ?? '',
        avatarUrl: json['avatarUrl']?.toString(),
        level: (json['level'] as num?)?.toInt(),
        city: localizedServerName(json['city'], json['cityEn']),
      );
}
