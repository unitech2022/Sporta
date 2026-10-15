import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../domain/entities/cup_entity.dart';
import '../cubit/cup_detail_cubit.dart';
import 'package:sporta_app/core/utils/server_time.dart';

/// قائمة المنظّم في الترويسة: تأجيل / إلغاء (والبدء بالعدد الحالي قبل القرعة).
class CupOrganizerMenu extends StatelessWidget {
  const CupOrganizerMenu({super.key, required this.cup, required this.busy});

  final CupEntity cup;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      enabled: !busy,
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (v) => switch (v) {
        'start' => startWithCurrent(context, cup),
        'postpone' => postpone(context, cup),
        _ => cancel(context, cup),
      },
      itemBuilder: (_) => [
        if (!cup.isDrawn && cup.isOpen)
          PopupMenuItem(
            value: 'start',
            child: Text(context.tr('البدء بالفرق المكتملة الحالية')),
          ),
        PopupMenuItem(
          value: 'postpone',
          child: Text(context.tr('تأجيل البطولة')),
        ),
        PopupMenuItem(
          value: 'cancel',
          child: Text(
            context.tr('إلغاء البطولة'),
            style: const TextStyle(color: AppColors.destructive),
          ),
        ),
      ],
    );
  }

  static Future<void> startWithCurrent(
    BuildContext context,
    CupEntity cup,
  ) async {
    final cubit = context.read<CupDetailCubit>();
    final missing = cup.teamCount - cup.completeTeamCount;
    final ok = await _confirm(
      context,
      title: context.tr('البدء بالفرق الحالية'),
      body: context.trArgs(
        'ستبدأ البطولة بـ {p0} فرق مكتملة وتُحذف {p1} فرق ناقصة (يُردّ ما دفعه لاعبوها)، ثم تُجرى القرعة فوراً.',
        {'p0': cup.completeTeamCount, 'p1': missing},
      ),
      action: context.tr('ابدأ الآن'),
    );
    if (!ok || !context.mounted) return;
    final error = await cubit.startWithCurrent();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? context.tr('أُجريت القرعة وبدأت البطولة')),
        ),
      );
    }
  }

  static Future<void> postpone(BuildContext context, CupEntity cup) async {
    final cubit = context.read<CupDetailCubit>();
    final now = ksaNow();
    final date = await showDatePicker(
      context: context,
      initialDate: cup.scheduledAt.isAfter(now) ? cup.scheduledAt : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(cup.scheduledAt),
    );
    if (time == null || !context.mounted) return;
    final start = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final error = await cubit.postpone(start);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? context.tr('تأجّلت البطولة وانتقلت مبارياتها'),
          ),
        ),
      );
    }
  }

  static Future<void> cancel(BuildContext context, CupEntity cup) async {
    final cubit = context.read<CupDetailCubit>();
    final paid = cup.players.where((p) => !p.isInvited).length;
    final ok = await _confirm(
      context,
      title: context.tr('إلغاء البطولة'),
      body: paid > 0
          ? context.trArgs(
              'ستُلغى البطولة ويُردّ ما دفعه {p0} لاعباً إلى محافظهم.',
              {'p0': paid},
            )
          : context.tr('ستُلغى البطولة ولن تعود متاحة للتسجيل.'),
      action: context.tr('إلغاء البطولة'),
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final error = await cubit.cancel();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? context.tr('أُلغيت البطولة وأُعيدت الحصص')),
        ),
      );
    }
  }

  static Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
    bool destructive = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: Text(d.tr('تراجع')),
          ),
          TextButton(
            onPressed: () => Navigator.of(d).pop(true),
            style: destructive
                ? TextButton.styleFrom(foregroundColor: AppColors.destructive)
                : null,
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }
}

/// للمنظّم قبل القرعة: كم فريقاً اكتمل، وخياراته إن لم يكتمل العدد.
class CupIncompleteBanner extends StatelessWidget {
  const CupIncompleteBanner({super.key, required this.cup, required this.busy});

  final CupEntity cup;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final canStart = cup.completeTeamCount >= 2;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hourglass_top,
                size: AppSizes.iconSm,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  context.trArgs(
                    'اكتمل {p0} من {p1} فرق — تُجرى القرعة تلقائياً عند الاكتمال.',
                    {'p0': cup.completeTeamCount, 'p1': cup.teamCount},
                  ),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            context.tr(
              'إن لم يكتمل العدد قبل الموعد يمكنك البدء بالفرق المكتملة، أو التأجيل، أو الإلغاء من القائمة أعلاه.',
            ),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
          if (canStart) ...[
            const SizedBox(height: AppSizes.sm),
            SizedBox(
              height: 38,
              child: OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () => CupOrganizerMenu.startWithCurrent(context, cup),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: Text(
                  context.trArgs('ابدأ الآن بـ {p0} فرق', {
                    'p0': cup.completeTeamCount,
                  }),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// دعوة شريك معلّقة للمستخدم الحالي.
class CupInviteBanner extends StatelessWidget {
  const CupInviteBanner({
    super.key,
    required this.cup,
    required this.team,
    required this.responding,
    required this.onAccept,
    required this.onReject,
  });

  final CupEntity cup;
  final int? team;
  final bool responding;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.primary, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.trArgs('دعوة للانضمام إلى الفريق {p0}', {'p0': team ?? ''}),
            style: AppTextStyles.body.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            context.trArgs(
              'دعاك صديقك للعب معه في بطولة «{p0}». اقبل لتُخصم حصتك وتنضم لفريقه.',
              {'p0': cup.name},
            ),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: responding ? null : onAccept,
                  child: Text(context.tr('قبول')),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: OutlinedButton(
                  onPressed: responding ? null : onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.destructive,
                    side: const BorderSide(color: AppColors.destructive),
                  ),
                  child: Text(context.tr('رفض')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
