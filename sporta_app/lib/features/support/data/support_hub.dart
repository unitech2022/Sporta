import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/secure_storage.dart';

/// أحداث الخادم التي يستمع لها التطبيق.
///   MessageReceived     { conversationId, message }
///   ConversationUpdated { ...ملخّص المحادثة }
///   ConversationRead    { conversationId, byAdmin, readAt }
///   Typing              { conversationId, fromAdmin }
typedef SupportEventHandler = void Function(Map<String, dynamic> payload);

/// اتصال SignalR واحد لكل التطبيق بمسار `/hubs/support-chat`.
///
/// الـ hub يضع كل اتصال في مجموعة صاحبه، فاتصال واحد يكفي أي عدد من الشاشات؛
/// المشتركون يصفّون ما يهمّهم. لو تعذّرت المصافحة تبقى الشاشة صالحة عبر REST
/// (السجل كامل هناك) وتُعاد المحاولة عند فتحها مرة أخرى.
class SupportHub {
  SupportHub._();
  static final SupportHub instance = SupportHub._();

  static const _events = [
    'MessageReceived',
    'ConversationUpdated',
    'ConversationRead',
    'Typing',
  ];

  HubConnection? _conn;
  bool _starting = false;
  String? _connectedToken;

  final Map<String, List<SupportEventHandler>> _handlers = {
    for (final e in _events) e: <SupportEventHandler>[],
  };

  bool get isConnected =>
      _conn != null && _conn!.state == HubConnectionState.Connected;

  /// يشترك في حدث ويعيد دالة إلغاء الاشتراك (تُستدعى في dispose).
  VoidCallback on(String event, SupportEventHandler handler) {
    final list = _handlers[event];
    if (list == null) return () {};
    list.add(handler);
    return () => list.remove(handler);
  }

  /// يفتح الاتصال (أو يعيد استخدام القائم). آمن الاستدعاء من كل شاشة.
  Future<void> connect() async {
    if (_starting) return;

    final token = await SecureStorage.getAccessToken();
    if (token == null || token.isEmpty) return;

    // حساب مختلف سجّل الدخول ⇒ نُسقط المقبس القديم أولاً.
    if (_conn != null && _connectedToken != token) await disconnect();
    if (isConnected) return;

    _starting = true;
    try {
      final conn = HubConnectionBuilder()
          .withUrl(
            ApiEndpoints.supportChatHub,
            options: HttpConnectionOptions(
              // يُقرأ عند كل إعادة اتصال، فيلتقط التوكن المحدَّث بعد التجديد.
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

      await conn.start();
      _conn = conn;
      _connectedToken = token;
    } catch (e) {
      // الـ hub غير متاح (خادم قديم، أو بروكسي بلا WebSocket) — نكمل على REST.
      debugPrint('SupportHub: connect failed — $e');
      _conn = null;
      _connectedToken = null;
    } finally {
      _starting = false;
    }
  }

  Future<void> disconnect() async {
    final conn = _conn;
    _conn = null;
    _connectedToken = null;
    if (conn == null) return;
    try {
      await conn.stop();
    } catch (_) {
      // مغلق أصلاً.
    }
  }

  /// نبضة "يكتب الآن" — لا ترمي أبداً، ومكبوحة بنبضة كل 1.5 ثانية حتى لا
  /// يُغرق المستخدم سريع الكتابة الـ hub (مؤشّر الطرف الآخر ينطفئ وحده).
  DateTime? _lastTypingAt;
  void sendTyping(int conversationId) {
    if (!isConnected) return;
    final now = DateTime.now();
    if (_lastTypingAt != null &&
        now.difference(_lastTypingAt!) < const Duration(milliseconds: 1500)) {
      return;
    }
    _lastTypingAt = now;
    unawaited(_pingTyping(conversationId));
  }

  Future<void> _pingTyping(int conversationId) async {
    try {
      // targetUserId = 0: نبضة المستخدم تذهب لصندوق الإدارة كله.
      await _conn!.invoke('Typing', args: [conversationId, 0]);
    } catch (_) {
      // مؤشّر تجميلي — تجاهُل فشله مقصود.
    }
  }

  void _dispatch(String event, List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final raw = args.first;
    if (raw is! Map) return;
    final payload = Map<String, dynamic>.from(raw);

    // نسخة من القائمة: مشترك قد يلغي اشتراكه أثناء التوزيع.
    for (final handler in List<SupportEventHandler>.from(_handlers[event]!)) {
      try {
        handler(payload);
      } catch (_) {
        // مشترك واحد سيئ لا يمنع البقية.
      }
    }
  }
}
