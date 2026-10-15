/// سطر واحد في محادثة الدعم.
class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.conversationId,
    required this.fromAdmin,
    required this.senderName,
    required this.body,
    required this.sentAt,
    this.readAt,
  });

  final int id;
  final int conversationId;

  /// true = من فريق الدعم، false = رسالتي.
  final bool fromAdmin;

  final String senderName;
  final String body;
  final DateTime sentAt;

  /// وقت قراءة الطرف الآخر لها (null = لم تُقرأ بعد).
  final DateTime? readAt;

  SupportMessage copyWith({DateTime? readAt}) => SupportMessage(
        id: id,
        conversationId: conversationId,
        fromAdmin: fromAdmin,
        senderName: senderName,
        body: body,
        sentAt: sentAt,
        readAt: readAt ?? this.readAt,
      );

  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
        id: (json['id'] as num?)?.toInt() ?? 0,
        conversationId: (json['conversationId'] as num?)?.toInt() ?? 0,
        fromAdmin: json['fromAdmin'] == true,
        senderName: json['senderName']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        sentAt: DateTime.tryParse(json['sentAt']?.toString() ?? '') ??
            DateTime.now(),
        readAt: DateTime.tryParse(json['readAt']?.toString() ?? ''),
      );
}

/// ملخّص محادثتي مع الدعم.
class SupportConversation {
  const SupportConversation({
    required this.id,
    required this.status,
    required this.lastMessageAt,
    required this.unreadForUser,
  });

  final int id;

  /// "Open" أو "Closed" — المغلقة تُفتح تلقائياً بأول رسالة جديدة.
  final String status;

  final DateTime lastMessageAt;
  final int unreadForUser;

  bool get isClosed => status == 'Closed';

  factory SupportConversation.fromJson(Map<String, dynamic> json) =>
      SupportConversation(
        id: (json['id'] as num?)?.toInt() ?? 0,
        status: json['status']?.toString() ?? 'Open',
        lastMessageAt:
            DateTime.tryParse(json['lastMessageAt']?.toString() ?? '') ??
                DateTime.now(),
        unreadForUser: (json['unreadForUser'] as num?)?.toInt() ?? 0,
      );
}

/// صفحة من سجل المحادثة كما يعيدها الخادم.
class SupportMessagePage {
  const SupportMessagePage({
    required this.exists,
    required this.conversation,
    required this.messages,
    required this.hasMore,
  });

  /// false = لم يبدأ المستخدم أي محادثة بعد.
  final bool exists;

  final SupportConversation? conversation;
  final List<SupportMessage> messages;

  /// هل توجد رسائل أقدم قبل أول عنصر في [messages]؟
  final bool hasMore;

  factory SupportMessagePage.fromJson(Map<String, dynamic> json) =>
      SupportMessagePage(
        exists: json['exists'] == true,
        conversation: json['conversation'] is Map<String, dynamic>
            ? SupportConversation.fromJson(
                json['conversation'] as Map<String, dynamic>)
            : null,
        messages: (json['messages'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(SupportMessage.fromJson)
            .toList(),
        hasMore: json['hasMore'] == true,
      );
}
