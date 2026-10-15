import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/secure_storage.dart';

typedef EventChatHandler = void Function(Map<String, dynamic> payload);

/// اتصال SignalR واحد بـ `/hubs/event-chat`. الشاشة تنادي [watch] عند فتح
/// دردشة حدث فتصلها رسائله فوراً، و[unwatch] عند إغلاقها. إن تعذّر الاتصال
/// تبقى الشاشة صالحة عبر REST (تحديث عند الإرسال والسحب).
///
/// الأحداث: MessageReceived (رسالة)، MessageDeleted { matchId, id }،
/// ReactionsUpdated { matchId, id, reactions }.
class EventChatHub {
  EventChatHub._();
  static final EventChatHub instance = EventChatHub._();

  static const _events = [
    'MessageReceived',
    'MessageDeleted',
    'ReactionsUpdated',
  ];

  HubConnection? _conn;
  Future<void>? _starting;

  /// الأحداث المفتوحة الآن — يُعاد الانضمام لبثّها بعد إعادة الاتصال
  /// (المجموعات لا تنجو من انقطاع المقبس).
  final Set<int> _watched = {};
  String? _connectedToken;

  final Map<String, List<EventChatHandler>> _handlers = {
    for (final e in _events) e: <EventChatHandler>[],
  };

  bool get isConnected =>
      _conn != null && _conn!.state == HubConnectionState.Connected;

  /// يشترك في حدث ويعيد دالة إلغاء الاشتراك.
  VoidCallback on(String event, EventChatHandler handler) {
    final list = _handlers[event];
    if (list == null) return () {};
    list.add(handler);
    return () => list.remove(handler);
  }

  /// يتصل (إن لزم) ثم ينضم لبثّ الحدث. لا يرمي أبداً.
  Future<void> watch(int matchId) async {
    _watched.add(matchId);
    try {
      await _connect();
      if (!isConnected) return;
      await _conn!.invoke('Watch', args: [matchId]);
    } catch (e) {
      debugPrint('EventChatHub: watch failed — $e');
    }
  }

  Future<void> unwatch(int matchId) async {
    _watched.remove(matchId);
    if (!isConnected) return;
    try {
      await _conn!.invoke('Unwatch', args: [matchId]);
    } catch (_) {}
  }

  Future<void> _connect() async {
    final token = await SecureStorage.getAccessToken();
    if (token == null || token.isEmpty) return;
    if (_conn != null && _connectedToken != token) await _disconnect();
    if (isConnected) return;
    if (_starting != null) return _starting;
    _starting = _start(token);
    try {
      await _starting;
    } finally {
      _starting = null;
    }
  }

  Future<void> _start(String token) async {
    try {
      final conn = HubConnectionBuilder()
          .withUrl(
            ApiEndpoints.eventChatHub,
            options: HttpConnectionOptions(
              accessTokenFactory: () async =>
                  await SecureStorage.getAccessToken() ?? token,
              transport: HttpTransportType.WebSockets,
              logMessageContent: false,
            ),
          )
          .withAutomaticReconnect(retryDelays: [0, 2000, 5000, 10000, 20000])
          .build();
      for (final event in _events) {
        conn.on(event, (args) => _dispatch(event, args));
      }
      conn.onreconnected(({connectionId}) {
        for (final id in _watched) {
          conn.invoke('Watch', args: [id]).catchError((_) => null);
        }
      });
      await conn.start();
      _conn = conn;
      _connectedToken = token;
    } catch (e) {
      debugPrint('EventChatHub: connect failed — $e');
      _conn = null;
      _connectedToken = null;
    }
  }

  Future<void> _disconnect() async {
    final conn = _conn;
    _conn = null;
    _connectedToken = null;
    try {
      await conn?.stop();
    } catch (_) {}
  }

  void _dispatch(String event, List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final raw = args.first;
    if (raw is! Map) return;
    final payload = Map<String, dynamic>.from(raw);
    for (final h in List<EventChatHandler>.from(_handlers[event]!)) {
      try {
        h(payload);
      } catch (_) {}
    }
  }
}
