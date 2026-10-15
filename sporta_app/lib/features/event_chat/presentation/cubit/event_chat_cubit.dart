import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/models/api_exception.dart';
import '../../data/event_chat_hub.dart';
import '../../data/event_chat_repository.dart';
import '../../domain/event_chat.dart';

part 'event_chat_state.dart';

/// شاشة دردشة حدث: يجلب الرأس والسجل عبر REST، ويستقبل الجديد من
/// [EventChatHub]، ويعلّم المقروء ما دامت الشاشة مفتوحة.
class EventChatCubit extends Cubit<EventChatState> {
  EventChatCubit(this._repo, this.matchId) : super(const EventChatState());

  final EventChatRepository _repo;
  final int matchId;

  static const _pageSize = 30;

  final _hub = EventChatHub.instance;
  final List<VoidCallback> _subs = [];
  Timer? _readDebounce;

  Future<void> load() async {
    emit(state.copyWith(status: EventChatStatus.loading, error: null));
    try {
      final results = await Future.wait([
        _repo.fetchSummary(matchId),
        _repo.fetchMessages(matchId, limit: _pageSize),
      ]);
      final summary = results[0] as EventChatSummary;
      final messages = results[1] as List<EventChatMessage>;
      emit(
        state.copyWith(
          status: EventChatStatus.success,
          summary: summary,
          messages: messages,
          hasOlder: messages.length >= _pageSize,
        ),
      );
      _markRead();
      _listen();
    } on ApiException catch (e) {
      emit(state.copyWith(status: EventChatStatus.failure, error: e.display));
    }
  }

  void _listen() {
    if (_subs.isNotEmpty) return;
    _subs
      ..add(
        _hub.on('MessageReceived', (p) {
          final msg = EventChatMessage.fromJson(p);
          if (msg.matchId != matchId) return;
          _insert(msg);
          _markRead();
        }),
      )
      ..add(
        _hub.on('ReactionsUpdated', (p) {
          if ((p['matchId'] as num?)?.toInt() != matchId) return;
          final id = (p['id'] as num?)?.toInt();
          final reactions = EventChatReaction.listFrom(p['reactions']);
          emit(
            state.copyWith(
              messages: [
                for (final m in state.messages)
                  m.id == id ? m.copyWith(reactions: reactions) : m,
              ],
            ),
          );
        }),
      )
      ..add(
        _hub.on('MessageDeleted', (p) {
          if ((p['matchId'] as num?)?.toInt() != matchId) return;
          final id = (p['id'] as num?)?.toInt();
          emit(
            state.copyWith(
              messages: [
                for (final m in state.messages) m.id == id ? m.asDeleted() : m,
              ],
            ),
          );
        }),
      );
    unawaited(_hub.watch(matchId));
  }

  /// يضيف رسالة إن لم تكن موجودة (الإرسال يعيدها والـ hub يبثّها أيضاً).
  void _insert(EventChatMessage msg) {
    if (state.messages.any((m) => m.id == msg.id)) return;
    emit(state.copyWith(messages: [...state.messages, msg]));
  }

  Future<void> loadOlder() async {
    if (!state.hasOlder || state.loadingOlder || state.messages.isEmpty) return;
    emit(state.copyWith(loadingOlder: true));
    try {
      final older = await _repo.fetchMessages(
        matchId,
        beforeId: state.messages.first.id,
        limit: _pageSize,
      );
      emit(
        state.copyWith(
          messages: [...older, ...state.messages],
          hasOlder: older.length >= _pageSize,
          loadingOlder: false,
        ),
      );
    } on ApiException {
      emit(state.copyWith(loadingOlder: false));
    }
  }

  /// الرسالة التي سيُردّ عليها (يظهر اقتباسها فوق الحقل).
  void startReply(EventChatMessage msg) =>
      emit(state.copyWith(replyingTo: msg));

  void cancelReply() => emit(state.copyWith(clearReply: true));

  /// يرسل نصاً (مع الرد والإشارات الحالية). يعيد رسالة الخطأ أو null.
  Future<String?> send(
    String body, {
    List<int> mentionedUserIds = const [],
  }) async {
    final text = body.trim();
    if (text.isEmpty || state.sending) return null;
    return _post(body: text, mentionedUserIds: mentionedUserIds);
  }

  /// يرفع مرفقاً ثم يرسله (بتعليق اختياري). يعيد رسالة الخطأ أو null.
  Future<String?> sendAttachment(
    String path,
    String name, {
    String? caption,
  }) async {
    if (state.sending) return null;
    emit(state.copyWith(sending: true, uploading: true));
    try {
      final att = await _repo.upload(matchId, path, name);
      emit(state.copyWith(uploading: false));
      return _post(body: caption, attachment: att, alreadySending: true);
    } on ApiException catch (e) {
      emit(state.copyWith(sending: false, uploading: false));
      return e.display;
    }
  }

  Future<String?> _post({
    String? body,
    EventChatAttachment? attachment,
    List<int> mentionedUserIds = const [],
    bool alreadySending = false,
  }) async {
    if (!alreadySending) emit(state.copyWith(sending: true));
    try {
      final msg = await _repo.send(
        matchId,
        body: (body == null || body.trim().isEmpty) ? null : body.trim(),
        replyToId: state.replyingTo?.id,
        attachment: attachment,
        mentionedUserIds: mentionedUserIds,
      );
      _insert(msg);
      emit(state.copyWith(sending: false, clearReply: true));
      return null;
    } on ApiException catch (e) {
      emit(state.copyWith(sending: false));
      // انتهى الحدث أثناء الكتابة أو خرج العضو: يُحدَّث الرأس فيختفي الإدخال.
      if (e.code == 'CHAT_READ_ONLY' || e.code == 'CHAT_NOT_MEMBER') {
        unawaited(_refreshSummary());
      }
      return e.display;
    }
  }

  /// تفاعل [userId] برمز؛ اختيار تفاعله نفسه يلغيه. تحديث فوري ثم من الخادم.
  Future<String?> react(EventChatMessage msg, String emoji, int userId) async {
    final current = msg.reactionOf(userId);
    final next = current == emoji ? null : emoji;
    _replaceReactions(msg.id, _applyLocal(msg.reactions, userId, next));
    try {
      final updated = await _repo.react(matchId, msg.id, next);
      _replaceReactions(msg.id, updated.reactions);
      return null;
    } on ApiException catch (e) {
      _replaceReactions(msg.id, msg.reactions);
      return e.display;
    }
  }

  static List<EventChatReaction> _applyLocal(
    List<EventChatReaction> list,
    int userId,
    String? emoji,
  ) {
    final map = <String, List<int>>{
      for (final r in list)
        r.emoji: r.userIds.where((u) => u != userId).toList(),
    };
    if (emoji != null) (map[emoji] ??= []).add(userId);
    return [
      for (final e in map.entries)
        if (e.value.isNotEmpty)
          EventChatReaction(emoji: e.key, userIds: e.value),
    ];
  }

  void _replaceReactions(int id, List<EventChatReaction> reactions) => emit(
    state.copyWith(
      messages: [
        for (final m in state.messages)
          m.id == id ? m.copyWith(reactions: reactions) : m,
      ],
    ),
  );

  Future<String?> delete(EventChatMessage msg) async {
    try {
      await _repo.delete(matchId, msg.id);
      emit(
        state.copyWith(
          messages: [
            for (final m in state.messages) m.id == msg.id ? m.asDeleted() : m,
          ],
        ),
      );
      return null;
    } on ApiException catch (e) {
      return e.display;
    }
  }

  Future<void> _refreshSummary() async {
    try {
      emit(state.copyWith(summary: await _repo.fetchSummary(matchId)));
    } on ApiException {
      // يبقى الرأس القديم.
    }
  }

  void _markRead() {
    _readDebounce?.cancel();
    _readDebounce = Timer(const Duration(milliseconds: 600), () {
      _repo.markRead(matchId).catchError((_) {});
    });
  }

  @override
  Future<void> close() {
    _readDebounce?.cancel();
    for (final unsub in _subs) {
      unsub();
    }
    unawaited(_hub.unwatch(matchId));
    return super.close();
  }
}

typedef VoidCallback = void Function();
