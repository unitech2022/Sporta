import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/models/api_exception.dart';
import '../../data/support_hub.dart';
import '../../data/support_repository.dart';
import '../../domain/entities/support_message.dart';

part 'support_chat_state.dart';

/// يقود شاشة الدعم: يحمّل السجل عبر REST، ثم يبقيه حيّاً بأحداث الـ hub.
///
/// REST هو مصدر الحقيقة؛ الـ hub إضافة فقط. لذلك تعمل الشاشة كاملة حتى لو
/// فشلت المصافحة — يفقد المستخدم الفورية لا المحتوى.
class SupportChatCubit extends Cubit<SupportChatState> {
  SupportChatCubit(this._repository, this._hub)
      : super(const SupportChatState());

  final SupportRepository _repository;
  final SupportHub _hub;

  final List<VoidCallback> _unsubscribe = [];
  Timer? _typingTimer;

  /// أول تحميل: السجل ثم الاتصال الفوري، وختم ردود الدعم كمقروءة.
  Future<void> load({bool isArabic = true}) async {
    emit(state.copyWith(status: SupportChatStatus.loading, error: null));
    try {
      final page = await _repository.fetchMine();
      emit(state.copyWith(
        status: SupportChatStatus.success,
        conversation: page.conversation,
        messages: page.messages,
        hasMore: page.hasMore,
      ));

      // القراءة بعد العرض: المستخدم يرى الشاشة الآن فعلاً.
      if (page.exists) await _markRead();

      await _listen();
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: SupportChatStatus.failure,
        error: e.display,
      ));
    }
  }

  /// يضيف الصفحة الأقدم إلى أعلى السجل.
  Future<void> loadOlder() async {
    if (!state.hasMore || state.loadingMore || state.messages.isEmpty) return;

    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _repository.fetchMine(before: state.messages.first.id);
      emit(state.copyWith(
        messages: [...page.messages, ...state.messages],
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } on ApiException {
      // نُبقي ما حُمّل؛ المستخدم يعيد المحاولة بسحبة أخرى.
      emit(state.copyWith(loadingMore: false));
    }
  }

  Future<void> send(String text, {bool isArabic = true}) async {
    final body = text.trim();
    if (body.isEmpty || state.sending) return;

    emit(state.copyWith(sending: true, error: null));
    try {
      final msg = await _repository.send(body);
      emit(state.copyWith(
        messages: _appendUnique(state.messages, msg),
        sending: false,
        // أول رسالة تُنشئ المحادثة على الخادم — نلتقط معرّفها من الرد.
        conversation: state.conversation ??
            SupportConversation(
              id: msg.conversationId,
              status: 'Open',
              lastMessageAt: msg.sentAt,
              unreadForUser: 0,
            ),
      ));

      // الاتصال يُفتح كسولاً: أول رسالة من مستخدم لم تكن له محادثة بعد.
      await _listen();
    } on ApiException catch (e) {
      emit(state.copyWith(sending: false, error: e.display));
    }
  }

  /// يبلّغ الإدارة أن المستخدم يكتب (بلا أثر على السجل).
  void notifyTyping() {
    final id = state.conversation?.id;
    if (id != null) _hub.sendTyping(id);
  }

  // ── الاتصال الفوري ─────────────────────────────────────────────────────────

  Future<void> _listen() async {
    if (_unsubscribe.isNotEmpty) return; // مشترك أصلاً

    await _hub.connect();
    if (isClosed) return;

    _unsubscribe.addAll([
      _hub.on('MessageReceived', _onMessageReceived),
      _hub.on('ConversationRead', _onConversationRead),
      _hub.on('Typing', _onTyping),
    ]);

    emit(state.copyWith(live: _hub.isConnected));
  }

  void _onMessageReceived(Map<String, dynamic> payload) {
    final raw = payload['message'];
    if (raw is! Map) return;

    final msg = SupportMessage.fromJson(Map<String, dynamic>.from(raw));
    emit(state.copyWith(
      messages: _appendUnique(state.messages, msg),
      adminTyping: false,
    ));

    // الشاشة مفتوحة أمام المستخدم ⇒ رد الدعم مقروء فور وصوله.
    if (msg.fromAdmin) unawaited(_markRead());
  }

  void _onConversationRead(Map<String, dynamic> payload) {
    if (payload['byAdmin'] != true) return;

    // الإدارة فتحت المحادثة ⇒ رسائلي صارت مقروءة.
    final readAt =
        DateTime.tryParse(payload['readAt']?.toString() ?? '') ?? DateTime.now();
    emit(state.copyWith(
      messages: state.messages
          .map((m) => !m.fromAdmin && m.readAt == null
              ? m.copyWith(readAt: readAt)
              : m)
          .toList(),
    ));
  }

  void _onTyping(Map<String, dynamic> payload) {
    if (payload['fromAdmin'] != true) return;

    emit(state.copyWith(adminTyping: true));
    // المؤشّر تلميح لا حالة يملكها الخادم — نتركه ينطفئ وحده.
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 4), () {
      if (!isClosed) emit(state.copyWith(adminTyping: false));
    });
  }

  Future<void> _markRead() async {
    try {
      await _repository.markRead();
    } on ApiException {
      // شارة العدّاد تُصحَّح في التحميل التالي.
    }
  }

  static List<SupportMessage> _appendUnique(
    List<SupportMessage> current,
    SupportMessage msg,
  ) =>
      current.any((m) => m.id == msg.id) ? current : [...current, msg];

  @override
  Future<void> close() {
    for (final off in _unsubscribe) {
      off();
    }
    _unsubscribe.clear();
    _typingTimer?.cancel();
    // المقبس نفسه يبقى مفتوحاً: شارة العدّاد في شاشات أخرى تعتمد عليه،
    // ويُغلق عند تسجيل الخروج.
    return super.close();
  }
}
