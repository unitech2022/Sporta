import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/event_chat_repository.dart';
import '../pages/event_chat_page.dart';

/// الزر العائم في صفحة تفاصيل الحدث: يفتح دردشة أعضائه ويعرض عدد الرسائل غير
/// المقروءة. لا يظهر إلا لعضو (المنشئ أو لاعب معتمد) — يتحقق من الخادم.
///
/// غيّر [key] حين تتغيّر العضوية (انضمام/انسحاب) ليُعاد التحقق.
class EventChatFab extends StatefulWidget {
  const EventChatFab({super.key, required this.matchId});

  final int matchId;

  @override
  State<EventChatFab> createState() => _EventChatFabState();
}

class _EventChatFabState extends State<EventChatFab> {
  bool _member = false;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    // الزائر بلا حساب لا دردشة له.
    if (getIt<AuthCubit>().user == null) return;
    try {
      final s = await getIt<EventChatRepository>().fetchSummary(widget.matchId);
      if (!mounted) return;
      setState(() {
        _member = s.isMember;
        _unread = s.unreadCount;
      });
    } catch (_) {
      // الدردشة مساعِدة: تعذّر الجلب ← لا زر.
    }
  }

  Future<void> _open() async {
    setState(() => _unread = 0);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EventChatPage(matchId: widget.matchId),
      ),
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!_member) return const SizedBox.shrink();
    return Tooltip(
      message: context.tr('دردشة الأعضاء'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            elevation: 6,
            shadowColor: AppColors.primary.withValues(alpha: 0.5),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _open,
              child: const SizedBox(
                width: 56,
                height: 56,
                child: Icon(
                  Icons.forum_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
          if (_unread > 0)
            PositionedDirectional(
              top: -4,
              end: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.destructive,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: Text(
                  _unread > 99 ? '99+' : '$_unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// يضع [EventChatFab] فوق [child] في زاوية النهاية السفلية (اليسار في
/// العربية) — داخل منطقة المحتوى فلا يغطّي شريط الانضمام أسفل الصفحة.
/// [membershipKey] يتغيّر مع العضوية ليُعاد التحقق من حق الدخول.
class WithEventChatFab extends StatelessWidget {
  const WithEventChatFab({
    super.key,
    required this.matchId,
    required this.membershipKey,
    required this.child,
  });

  final int? matchId;
  final Object membershipKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final id = matchId;
    if (id == null || id == 0) return child;
    return Stack(
      children: [
        Positioned.fill(child: child),
        PositionedDirectional(
          end: 16,
          bottom: 16,
          child: EventChatFab(
            key: ValueKey('chat-$id-$membershipKey'),
            matchId: id,
          ),
        ),
      ],
    );
  }
}
