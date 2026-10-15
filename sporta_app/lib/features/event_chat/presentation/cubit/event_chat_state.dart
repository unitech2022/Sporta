part of 'event_chat_cubit.dart';

enum EventChatStatus { initial, loading, success, failure }

class EventChatState extends Equatable {
  const EventChatState({
    this.status = EventChatStatus.initial,
    this.summary,
    this.messages = const [],
    this.hasOlder = false,
    this.loadingOlder = false,
    this.sending = false,
    this.uploading = false,
    this.replyingTo,
    this.error,
  });

  final EventChatStatus status;
  final EventChatSummary? summary;

  /// الأقدم أولاً.
  final List<EventChatMessage> messages;
  final bool hasOlder;
  final bool loadingOlder;
  final bool sending;

  /// رفع مرفق جارٍ (يُعرض شريط تقدّم فوق الحقل).
  final bool uploading;

  /// الرسالة التي سيُردّ عليها.
  final EventChatMessage? replyingTo;
  final String? error;

  EventChatState copyWith({
    EventChatStatus? status,
    EventChatSummary? summary,
    List<EventChatMessage>? messages,
    bool? hasOlder,
    bool? loadingOlder,
    bool? sending,
    bool? uploading,
    EventChatMessage? replyingTo,
    bool clearReply = false,
    String? error,
  }) => EventChatState(
    status: status ?? this.status,
    summary: summary ?? this.summary,
    messages: messages ?? this.messages,
    hasOlder: hasOlder ?? this.hasOlder,
    loadingOlder: loadingOlder ?? this.loadingOlder,
    sending: sending ?? this.sending,
    uploading: uploading ?? this.uploading,
    replyingTo: clearReply ? null : (replyingTo ?? this.replyingTo),
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    summary,
    messages,
    hasOlder,
    loadingOlder,
    sending,
    uploading,
    replyingTo,
    error,
  ];
}
