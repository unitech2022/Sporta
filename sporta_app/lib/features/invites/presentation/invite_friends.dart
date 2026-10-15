import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/state/app_scope.dart';
import '../../auth/data/models/api_exception.dart';
import '../../auth/presentation/state/auth_scope.dart';
import '../../auth/presentation/widgets/login_required_sheet.dart';
import '../../friends/presentation/widgets/player_picker_sheet.dart';
import '../data/event_invite_repository.dart';
import '../domain/event_invite.dart';
import 'package:sporta_app/core/utils/server_time.dart';

/// زر الدعوة في ترويسة الحدث: دعوة لاعبين للمشاركة (بعدد المقاعد الشاغرة)،
/// ومعها «دعوة زميل لفريقك» في أحداث الفرق حين يمرَّر [onInvitePartner]
/// (يصير الزميل في فريق الداعي نفسه بعد قبوله).
Future<void> showEventInviteMenu(
  BuildContext context, {
  required InviteKind kind,
  required int targetId,
  required DateTime startsAt,
  required int maxCount,
  VoidCallback? onInvitePartner,
}) async {
  if (await guestBlocked(context)) return;
  if (!context.mounted) return;
  if (onInvitePartner == null) {
    await inviteFriendsToEvent(context,
        kind: kind, targetId: targetId, startsAt: startsAt, maxCount: maxCount);
    return;
  }
  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
    ),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sheet.tr('دعوة'),
                style: AppTextStyles.heading3.copyWith(color: AppColors.secondary)),
            const SizedBox(height: AppSizes.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.group_add_outlined, color: AppColors.primary),
              title: Text(sheet.tr('دعوة زميل لفريقك')),
              subtitle: Text(sheet.tr('يصله طلب الانضمام إلى فريقك، ويصبح شريكك في الفريق نفسه')),
              onTap: () => Navigator.of(sheet).pop('partner'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_add_alt_1_outlined, color: AppColors.primary),
              title: Text(sheet.tr('دعوة لاعبين للمشاركة')),
              subtitle: Text(maxCount > 0
                  ? sheet.trArgs('حتى {p0} لاعبين — كلٌّ ينضم بنفسه ويختار مكانه', {'p0': maxCount})
                  : sheet.tr('لا توجد مقاعد شاغرة')),
              enabled: maxCount > 0,
              onTap: () => Navigator.of(sheet).pop('players'),
            ),
          ],
        ),
      ),
    ),
  );
  if (!context.mounted) return;
  if (choice == 'partner') {
    onInvitePartner();
  } else if (choice == 'players') {
    await inviteFriendsToEvent(context,
        kind: kind, targetId: targetId, startsAt: startsAt, maxCount: maxCount);
  }
}

/// «دعوة زميل»: اختيار صديق واحد يُدعى إلى فريق الداعي عبر [invite]
/// (تُرجع رسالة خطأ أو null).
Future<void> invitePartnerFlow(
  BuildContext context, {
  required Future<String?> Function(int userId) invite,
}) async {
  if (await guestBlocked(context)) return;
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final sent = context.tr('أُرسلت دعوة الزميل — يصبح في فريقك بعد قبوله');
  final picked = await showPlayerPicker(
    context,
    count: 1,
    minCount: 1,
    title: context.tr('اختر زميلك'),
  );
  if (picked == null || picked.isEmpty || !context.mounted) return;
  final error = await invite(picked.first.userId);
  messenger.showSnackBar(SnackBar(content: Text(error ?? sent)));
}

/// دعوة أصدقاء إلى حدث: اختيار الأصدقاء (حتى [maxCount] بعدد المقاعد
/// الشاغرة) ← مدة صلاحية الدعوة ← إرسال. تصل كلٌّ منهم كإشعار يفتح الحدث.
Future<void> inviteFriendsToEvent(
  BuildContext context, {
  required InviteKind kind,
  required int targetId,
  required DateTime startsAt,
  int maxCount = 20,
}) async {
  if (await guestBlocked(context)) return;
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  if (maxCount <= 0) {
    messenger.showSnackBar(SnackBar(content: Text(context.tr('لا توجد مقاعد شاغرة'))));
    return;
  }

  final picked = await showPlayerPicker(
    context,
    count: maxCount.clamp(1, 50),
    minCount: 1,
    title: context.trArgs('ادعُ أصدقاءك (حتى {p0})', {'p0': maxCount.clamp(1, 50)}),
  );
  if (picked == null || picked.isEmpty || !context.mounted) return;

  final minutes = await _pickExpiry(context, startsAt);
  if (minutes == null || !context.mounted) return;

  try {
    final result = await getIt<EventInviteRepository>().send(
      kind: kind,
      targetId: targetId,
      userIds: picked.map((p) => p.userId).toList(),
      expiresInMinutes: minutes == _untilStart ? null : minutes,
    );
    if (!context.mounted) return;
    final lines = <String>[
      if (result.sent > 0)
        context.trArgs('أُرسلت الدعوة إلى {p0}', {'p0': result.sent}),
      for (final (name, reason) in result.skipped) '$name: $reason',
    ];
    messenger.showSnackBar(SnackBar(
      content: Text(lines.isEmpty ? context.tr('لم تُرسل أي دعوة') : lines.join('\n')),
    ));
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.display)));
  }
}

/// قيمة داخلية تعني «حتى موعد الحدث».
const int _untilStart = -1;

Future<int?> _pickExpiry(BuildContext context, DateTime startsAt) {
  final left = startsAt.difference(ksaNow()).inMinutes;
  final options = <(int, String)>[
    (60, context.tr('ساعة')),
    (360, context.tr('6 ساعات')),
    (1440, context.tr('24 ساعة')),
    (4320, context.tr('3 أيام')),
  ].where((o) => o.$1 < left).toList()
    ..add((_untilStart, context.tr('حتى موعد الحدث')));

  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
    ),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sheet.tr('مدة صلاحية الدعوة'),
                style: AppTextStyles.heading3.copyWith(color: AppColors.secondary)),
            const SizedBox(height: AppSizes.xs),
            Text(
              sheet.tr('بعدها تنتهي الدعوة، ولا تتجاوز موعد الحدث.'),
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: AppSizes.md),
            for (final (minutes, label) in options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timer_outlined, color: AppColors.primary),
                title: Text(label),
                onTap: () => Navigator.of(sheet).pop(minutes),
              ),
          ],
        ),
      ),
    ),
  );
}

/// زر «دعوة صديق» للترويسة الداكنة في صفحات الأحداث.
class InviteFriendsHeaderButton extends StatelessWidget {
  const InviteFriendsHeaderButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: context.tr('دعوة صديق'),
        onPressed: onPressed,
        icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.white),
      );
}

/// بطاقة الدعوة في صفحة الحدث لمن دُعي إليه: من دعاه، وكم بقي على انتهائها،
/// وزر الاعتذار. الانضمام نفسه من زر الانضمام المعتاد في الصفحة.
class EventInviteBanner extends StatefulWidget {
  const EventInviteBanner({super.key, required this.kind, required this.targetId});

  final InviteKind kind;
  final int targetId;

  @override
  State<EventInviteBanner> createState() => _EventInviteBannerState();
}

class _EventInviteBannerState extends State<EventInviteBanner> {
  final _repo = getIt<EventInviteRepository>();
  EventInvite? _invite;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (context.auth.isGuest) return;
    try {
      final invite = await _repo.mine(widget.kind, widget.targetId);
      if (mounted) setState(() => _invite = invite);
    } catch (_) {
      // لا بطاقة إن تعذّر الجلب — الحدث نفسه يبقى قابلاً للانضمام.
    }
  }

  Future<void> _decline() async {
    final messenger = ScaffoldMessenger.of(context);
    final done = context.tr('اعتذرتَ عن الدعوة');
    setState(() => _busy = true);
    try {
      final updated = await _repo.decline(_invite!.id);
      if (!mounted) return;
      setState(() {
        _invite = updated;
        _busy = false;
      });
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  String _left(BuildContext context, DateTime at) {
    final d = at.difference(ksaNow());
    if (d.inMinutes < 60) {
      return context.trArgs('تنتهي خلال {p0} دقيقة', {'p0': d.inMinutes.clamp(1, 59)});
    }
    if (d.inHours < 48) return context.trArgs('تنتهي خلال {p0} ساعة', {'p0': d.inHours});
    return context.trArgs('تنتهي خلال {p0} يوم', {'p0': d.inDays});
  }

  @override
  Widget build(BuildContext context) {
    final i = _invite;
    if (i == null || i.status == 'accepted') return const SizedBox.shrink();

    final active = i.isPending;
    final color = active ? AppColors.primary : AppColors.mutedForeground;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(active ? Icons.mail_outline : Icons.timer_off_outlined, color: color),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.trArgs('دعاك {p0} إلى هذا الحدث', {'p0': i.senderName}),
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary, fontWeight: FontWeight.w700),
                ),
                Text(
                  active
                      ? '${_left(context, i.expiresAt)} — ${context.tr('انضم من زر الانضمام في الصفحة')}'
                      : i.isExpired
                          ? context.tr('انتهت صلاحية الدعوة')
                          : context.tr('اعتذرتَ عن هذه الدعوة'),
                  style: AppTextStyles.caption.copyWith(color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          if (active)
            TextButton(
              onPressed: _busy ? null : _decline,
              style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
              child: Text(context.tr('اعتذار')),
            ),
        ],
      ),
    );
  }
}
