import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../../features/notifications/presentation/notification_router.dart';

/// Thin wrapper around OneSignal. The OneSignal App ID is a public client
/// identifier (it ships inside the app binary anyway), so it defaults to the
/// Sporta app id; override per-build with `--dart-define=ONESIGNAL_APP_ID=...`.
class PushService {
  PushService._();

  static const String _appId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: '45dba2ea-4af4-487e-9fe1-e5c39fa24598',
  );

  /// Attached to [MaterialApp] so a tapped push can navigate without a
  /// BuildContext (the click handler fires outside the widget tree).
  ///
  /// Not final: a GlobalKey preserves the navigator's route stack across
  /// rebuilds, so `AppSettings.restartApp` must swap it for a fresh key —
  /// otherwise the "relaunched" app keeps every open page (e.g. the language
  /// settings page stayed on screen after a language change).
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Discards the old navigator (and its route stack) on app restart.
  static void resetNavigatorKey() => navigatorKey = GlobalKey<NavigatorState>();

  /// OneSignal ships no web implementation, so every call would throw a
  /// MissingPluginException there — disable push entirely on web.
  static bool get isEnabled => !kIsWeb && _appId.isNotEmpty;

  /// Initialise the SDK, request permission, and route notification taps.
  /// Call once at startup.
  static Future<void> init() async {
    if (!isEnabled) return;
    OneSignal.initialize(_appId);
    OneSignal.Notifications.addClickListener(_onClick);
    OneSignal.Notifications.addForegroundWillDisplayListener(_onForeground);
    // يُطلب الإذن مرة واحدة فقط (قبل أن يحسمه المستخدم): بعد الرفض كان
    // fallbackToSettings يُظهر «افتح الإعدادات» عند كل تشغيل.
    if (await OneSignal.Notifications.canRequest()) {
      await OneSignal.Notifications.requestPermission(false);
    }
  }

  /// Bumped whenever a push arrives while the app is in the foreground, so
  /// widgets such as the notification bell can refresh their unread count.
  static final ValueNotifier<int> foregroundPushes = ValueNotifier<int>(0);

  static void _onForeground(OSNotificationWillDisplayEvent event) {
    // Don't call preventDefault — the system banner is still shown.
    foregroundPushes.value++;
  }

  /// Deep-links a tapped notification. Pushes carry `{ type, referenceId }`
  /// data and open the same screen as tapping the notification in the in-app
  /// list (see [openNotificationTarget]).
  static void _onClick(OSNotificationClickEvent event) {
    final data = event.notification.additionalData;
    if (data == null) return;
    final type = data['type']?.toString() ?? '';
    if (type.isEmpty) return;
    final referenceId =
        (data['referenceId'] as num?)?.toInt() ??
        int.tryParse(data['referenceId']?.toString() ?? '');
    // The tap also means a new notification exists — refresh badges.
    foregroundPushes.value++;
    _openWhenReady(type, referenceId, 0);
  }

  /// A tap that cold-starts the app can fire before [MaterialApp] has built
  /// its navigator; retry on the next frames (for up to ~5 s) until it exists.
  static void _openWhenReady(String type, int? referenceId, int attempt) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null && navigatorKey.currentState != null) {
      openNotificationTarget(ctx, type: type, referenceId: referenceId);
      return;
    }
    if (attempt >= 50) return;
    Future<void>.delayed(
      const Duration(milliseconds: 100),
      () => _openWhenReady(type, referenceId, attempt + 1),
    );
  }

  /// Links the device to the signed-in user (backend targets this external id).
  static Future<void> login(String userId) async {
    if (!isEnabled || userId.isEmpty) return;
    await OneSignal.login(userId);
  }

  /// Unlinks the device on sign-out.
  static Future<void> logout() async {
    if (!isEnabled) return;
    await OneSignal.logout();
  }
}
