import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/push/push_service.dart';
import '../../data/notification_repository.dart';
import '../pages/notifications_page.dart';

/// A bell icon with an unread badge that opens the notifications screen.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key, this.color = AppColors.secondary});

  final Color color;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with WidgetsBindingObserver {
  final _repo = getIt<NotificationRepository>();
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A push received while the app is open means a new unread notification.
    PushService.foregroundPushes.addListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    PushService.foregroundPushes.removeListener(_refresh);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from the background: pushes may have arrived meanwhile.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final count = await _repo.fetchUnreadCount();
      if (mounted) setState(() => _unread = count);
    } catch (_) {
      // ignore — badge stays hidden
    }
  }

  Future<void> _open() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            NotificationsPage(onBack: () => Navigator.of(context).pop()),
      ),
    );
    _refresh(); // counts may have changed (marked read)
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: _open,
          icon: Icon(Icons.notifications_outlined, color: widget.color),
          tooltip: context.tr('الإشعارات'),
        ),
        if (_unread > 0)
          PositionedDirectional(
            end: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: const BoxDecoration(
                color: AppColors.destructive,
                shape: BoxShape.circle,
              ),
              child: Text(
                _unread > 9 ? '9+' : '$_unread',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
