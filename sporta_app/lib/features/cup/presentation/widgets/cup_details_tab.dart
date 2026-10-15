import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/money.dart';
import '../../domain/entities/cup_entity.dart';

/// تبويب «التفاصيل» في صفحة البطولة: النظام والفرق والملاعب والمواعيد
/// والمستوى والحصة والحالة — في بطاقة واحدة من صفوف.
class CupDetailsTab extends StatelessWidget {
  const CupDetailsTab({super.key, required this.cup});

  final CupEntity cup;

  String _status(BuildContext context) => switch (cup.status) {
    'pendingApproval' => context.tr('بانتظار موافقة الملعب'),
    'open' => context.tr('التسجيل مفتوح'),
    'full' => context.tr('اكتمل العدد'),
    'inProgress' => context.tr('جارية'),
    'completed' => context.tr('انتهت'),
    _ => context.tr('ملغاة'),
  };

  @override
  Widget build(BuildContext context) {
    final c = cup;
    final end = c.scheduledAt.add(Duration(minutes: c.durationMinutes));
    final rows = <(IconData, String, String)>[
      (
        Icons.confirmation_number_outlined,
        context.tr('رقم البطولة'),
        '#${c.id}',
      ),
      (Icons.emoji_events_outlined, context.tr('النظام'), c.formatLabel),
      (
        Icons.groups_2_outlined,
        context.tr('الفرق'),
        context.trArgs('{p0} من {p1} فرق مكتملة', {
          'p0': c.completeTeamCount,
          'p1': c.teamCount,
        }),
      ),
      if (c.pathText.isNotEmpty)
        (Icons.route_outlined, context.tr('مسار البطولة'), c.pathText),
      if (c.venueName != null)
        (Icons.stadium_outlined, context.tr('الملعب'), c.venueName!),
      if (c.city != null) (Icons.map_outlined, context.tr('المدينة'), c.city!),
      if (c.courts.isNotEmpty)
        (
          Icons.sports_tennis_outlined,
          context.tr('الملاعب'),
          c.courts.map((x) => x.name).join('، '),
        ),
      (
        Icons.event_outlined,
        context.tr('التاريخ'),
        AppDates.dayMonth(c.scheduledAt),
      ),
      if (c.endDate != null)
        (
          Icons.event_available_outlined,
          context.tr('آخر يوم'),
          AppDates.dayMonth(c.endDate!),
        ),
      (
        Icons.access_time,
        context.tr('الوقت'),
        '${AppDates.time12(c.scheduledAt)} — ${AppDates.time12(end)}',
      ),
      (
        Icons.timelapse,
        context.tr('المدة'),
        c.endDate == null
            ? context.trArgs('{p0} دقيقة', {'p0': c.durationMinutes})
            : context.trArgs('{p0} دقيقة في كل يوم', {'p0': c.durationMinutes}),
      ),
      (
        Icons.timer_outlined,
        context.tr('مدة المباراة'),
        context.trArgs('{p0} دقيقة', {'p0': c.matchMinutes}),
      ),
      (
        Icons.bar_chart,
        context.tr('المستوى'),
        '${c.minLevel.toStringAsFixed(0)} - ${c.maxLevel.toStringAsFixed(0)}',
      ),
      (
        Icons.payments_outlined,
        context.tr('الحصة للاعب'),
        c.pricePerPlayer <= 0
            ? context.tr('مجاناً')
            : '${money(c.pricePerPlayer)} ${context.tr('ر.س')}',
      ),
      (Icons.info_outline, context.tr('الحالة'), _status(context)),
      if (c.championName != null)
        (
          Icons.military_tech_outlined,
          context.tr('البطل'),
          [
            c.championName!,
            if (c.championPlayers?.isNotEmpty == true) c.championPlayers!,
          ].join(' · '),
        ),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: AppSizes.xl),
            _row(rows[i].$1, rows[i].$2, rows[i].$3),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: AppSizes.iconSm, color: AppColors.mutedForeground),
      const SizedBox(width: AppSizes.md),
      Text(label, style: AppTextStyles.caption),
      const SizedBox(width: AppSizes.md),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}
