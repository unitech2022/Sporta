import '../../../core/localization/tr_global.dart';

/// اقتباس الرسالة المردود عليها.
class EventChatReply {
  const EventChatReply({
    required this.id,
    required this.senderName,
    required this.body,
    this.attachmentType,
    this.isDeleted = false,
  });

  final int id;
  final String senderName;
  final String body;
  final String? attachmentType;
  final bool isDeleted;

  factory EventChatReply.fromJson(Map<String, dynamic> j) => EventChatReply(
    id: (j['id'] as num?)?.toInt() ?? 0,
    senderName: j['senderName']?.toString() ?? '',
    body: j['body']?.toString() ?? '',
    attachmentType: j['attachmentType']?.toString(),
    isDeleted: j['isDeleted'] == true,
  );
}

/// تفاعل مجمّع: الرمز ومن تفاعل به.
class EventChatReaction {
  const EventChatReaction({required this.emoji, required this.userIds});

  final String emoji;
  final List<int> userIds;

  factory EventChatReaction.fromJson(Map<String, dynamic> j) =>
      EventChatReaction(
        emoji: j['emoji']?.toString() ?? '',
        userIds: (j['userIds'] as List? ?? [])
            .map((e) => (e as num).toInt())
            .toList(),
      );

  static List<EventChatReaction> listFrom(Object? raw) => (raw as List? ?? [])
      .map(
        (e) => EventChatReaction.fromJson(Map<String, dynamic>.from(e as Map)),
      )
      .toList();
}

/// مرفق مرفوع جاهز للإرسال، أو مرفق رسالة.
class EventChatAttachment {
  const EventChatAttachment({
    required this.url,
    required this.name,
    required this.type,
    required this.size,
  });

  final String url;
  final String name;

  /// "image" | "file".
  final String type;
  final int size;

  bool get isImage => type == 'image';

  Map<String, dynamic> toJson() => {
    'url': url,
    'name': name,
    'type': type,
    'size': size,
  };

  factory EventChatAttachment.fromJson(Map<String, dynamic> j) =>
      EventChatAttachment(
        url: j['url']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        type: j['type']?.toString() ?? 'file',
        size: (j['size'] as num?)?.toInt() ?? 0,
      );
}

/// رسالة في دردشة الحدث (`EventChatMessageDto`).
class EventChatMessage {
  const EventChatMessage({
    required this.id,
    required this.matchId,
    required this.senderUserId,
    required this.senderName,
    required this.senderAvatarUrl,
    required this.senderRole,
    required this.isSystem,
    required this.isDeleted,
    required this.body,
    required this.createdAt,
    this.replyTo,
    this.attachment,
    this.mentionedUserIds = const [],
    this.reactions = const [],
  });

  final int id;
  final int matchId;

  /// null لرسائل النظام.
  final int? senderUserId;
  final String senderName;
  final String? senderAvatarUrl;

  /// "organizer" | "venue" | "player" | null.
  final String? senderRole;
  final bool isSystem;
  final bool isDeleted;
  final String body;

  /// وقت الإرسال بساعة التطبيق (محلي ساذج).
  final DateTime createdAt;

  final EventChatReply? replyTo;
  final EventChatAttachment? attachment;
  final List<int> mentionedUserIds;
  final List<EventChatReaction> reactions;

  /// رمز تفاعل [userId] إن وُجد.
  String? reactionOf(int userId) {
    for (final r in reactions) {
      if (r.userIds.contains(userId)) return r.emoji;
    }
    return null;
  }

  EventChatMessage copyWith({
    bool? isDeleted,
    List<EventChatReaction>? reactions,
  }) {
    final deleted = isDeleted ?? this.isDeleted;
    return EventChatMessage(
      id: id,
      matchId: matchId,
      senderUserId: senderUserId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      senderRole: senderRole,
      isSystem: isSystem,
      isDeleted: deleted,
      body: deleted ? '' : body,
      createdAt: createdAt,
      replyTo: replyTo,
      attachment: deleted ? null : attachment,
      mentionedUserIds: deleted ? const [] : mentionedUserIds,
      reactions: deleted ? const [] : (reactions ?? this.reactions),
    );
  }

  EventChatMessage asDeleted() => copyWith(isDeleted: true);

  factory EventChatMessage.fromJson(Map<String, dynamic> j) {
    final url = j['attachmentUrl']?.toString();
    return EventChatMessage(
      id: (j['id'] as num?)?.toInt() ?? 0,
      matchId: (j['matchId'] as num?)?.toInt() ?? 0,
      senderUserId: (j['senderUserId'] as num?)?.toInt(),
      senderName: j['senderName']?.toString() ?? '',
      senderAvatarUrl: j['senderAvatarUrl']?.toString(),
      senderRole: j['senderRole']?.toString(),
      isSystem: j['isSystem'] == true,
      isDeleted: j['isDeleted'] == true,
      body: j['body']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
      replyTo: j['replyTo'] is Map
          ? EventChatReply.fromJson(
              Map<String, dynamic>.from(j['replyTo'] as Map),
            )
          : null,
      attachment: url == null || url.isEmpty
          ? null
          : EventChatAttachment(
              url: url,
              name: j['attachmentName']?.toString() ?? '',
              type: j['attachmentType']?.toString() ?? 'file',
              size: (j['attachmentSize'] as num?)?.toInt() ?? 0,
            ),
      mentionedUserIds: (j['mentionedUserIds'] as List? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      reactions: EventChatReaction.listFrom(j['reactions']),
    );
  }
}

class EventChatMember {
  const EventChatMember({
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.role,
  });

  final int userId;
  final String name;
  final String? avatarUrl;

  /// "organizer" | "venue" | "player".
  final String role;

  factory EventChatMember.fromJson(Map<String, dynamic> j) => EventChatMember(
    userId: (j['userId'] as num?)?.toInt() ?? 0,
    name: j['name']?.toString() ?? '',
    avatarUrl: j['avatarUrl']?.toString(),
    role: j['role']?.toString() ?? 'player',
  );
}

/// رأس الدردشة (`EventChatSummaryDto`).
class EventChatSummary {
  const EventChatSummary({
    required this.matchId,
    required this.kind,
    required this.refId,
    required this.title,
    required this.venueName,
    required this.scheduledAt,
    required this.isMember,
    required this.canWrite,
    required this.canModerate,
    required this.unreadCount,
    required this.members,
  });

  final int matchId;

  /// "match" | "americano" | "tournament".
  final String kind;
  final int refId;
  final String title;
  final String? venueName;
  final DateTime scheduledAt;
  final bool isMember;
  final bool canWrite;
  final bool canModerate;
  final int unreadCount;
  final List<EventChatMember> members;

  /// «دردشة المباراة» / «دردشة الأمريكانو» / «دردشة البطولة».
  String get chatTitle => switch (kind) {
    'americano' => trg('دردشة الأمريكانو'),
    'tournament' => trg('دردشة البطولة'),
    _ => trg('دردشة المباراة'),
  };

  factory EventChatSummary.fromJson(Map<String, dynamic> j) => EventChatSummary(
    matchId: (j['matchId'] as num?)?.toInt() ?? 0,
    kind: j['kind']?.toString() ?? 'match',
    refId: (j['refId'] as num?)?.toInt() ?? 0,
    title: j['title']?.toString() ?? '',
    venueName: j['venueName'] == null
        ? null
        : localizedServerName(j['venueName'], j['venueNameEn']),
    scheduledAt:
        DateTime.tryParse(j['scheduledAt']?.toString() ?? '') ?? DateTime.now(),
    isMember: j['isMember'] == true,
    canWrite: j['canWrite'] == true,
    canModerate: j['canModerate'] == true,
    unreadCount: (j['unreadCount'] as num?)?.toInt() ?? 0,
    members: (j['members'] as List? ?? [])
        .map((e) => EventChatMember.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
