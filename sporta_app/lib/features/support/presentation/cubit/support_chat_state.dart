part of 'support_chat_cubit.dart';

enum SupportChatStatus { initial, loading, success, failure }

class SupportChatState extends Equatable {
  const SupportChatState({
    this.status = SupportChatStatus.initial,
    this.conversation,
    this.messages = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.sending = false,
    this.live = false,
    this.adminTyping = false,
    this.error,
  });

  final SupportChatStatus status;

  /// null قبل إرسال أول رسالة — المحادثة تُنشأ عند أول إرسال.
  final SupportConversation? conversation;

  /// السجل بترتيب زمني (الأقدم أولاً).
  final List<SupportMessage> messages;

  /// هل يوجد سجل أقدم قبل [messages] الأولى؟
  final bool hasMore;
  final bool loadingMore;
  final bool sending;

  /// true عندما يصل الجديد عبر الـ hub بدل التحديث اليدوي.
  final bool live;

  final bool adminTyping;
  final String? error;

  SupportChatState copyWith({
    SupportChatStatus? status,
    SupportConversation? conversation,
    List<SupportMessage>? messages,
    bool? hasMore,
    bool? loadingMore,
    bool? sending,
    bool? live,
    bool? adminTyping,
    String? error,
  }) {
    return SupportChatState(
      status: status ?? this.status,
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      sending: sending ?? this.sending,
      live: live ?? this.live,
      adminTyping: adminTyping ?? this.adminTyping,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        conversation,
        messages,
        hasMore,
        loadingMore,
        sending,
        live,
        adminTyping,
        error,
      ];
}
