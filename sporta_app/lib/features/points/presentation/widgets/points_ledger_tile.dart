import 'package:flutter/material.dart';
import 'package:sporta_app/core/state/app_scope.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/points_entity.dart';

/// صف واحد في سجل النقاط — يميّز حركات المستوى عن المكافآت بأيقونة.
class PointsLedgerTile extends StatelessWidget {
  const PointsLedgerTile({super.key, required this.transaction});

  final PointsTransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final earn = t.isEarn;
    final color = earn ? AppColors.success : AppColors.destructive;
    final d = t.createdAt;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              t.isLevel
                  ? (earn ? Icons.trending_up_rounded : Icons.trending_down_rounded)
                  : (earn ? Icons.add_rounded : Icons.remove_rounded),
              color: color,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.description ?? _typeLabel(context, t.type),
                  style: AppTextStyles.bodyMedium,
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm, vertical: 1),
                      decoration: BoxDecoration(
                        color: (t.isLevel ? AppColors.primary : const Color(0xFFEAB308))
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Text(
                        t.isLevel ? context.tr('مستوى') : context.tr('مكافآت'),
                        style: AppTextStyles.caption.copyWith(
                            color: t.isLevel
                                ? AppColors.primary
                                : const Color(0xFFB45309)),
                      ),
                    ),
                    if (d != null) ...[
                      const SizedBox(width: AppSizes.sm),
                      Text(
                        '${d.day}/${d.month}/${d.year}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.mutedForeground),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${earn ? '+' : ''}${t.amount}',
            style: AppTextStyles.heading3.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  static String _typeLabel(BuildContext context, String type) =>
      switch (type.toLowerCase()) {
        'bookingconfirmed' => context.tr('نقاط حجز ملعب'),
        'matchcompleted' => context.tr('نقاط إتمام مباراة'),
        'coachsessionconfirmed' => context.tr('نقاط جلسة مدرب'),
        'subscriptionbonus' => context.tr('نقاط ترحيبية للاشتراك'),
        'profilebonus' => context.tr('مكافأة الملف الشخصي'),
        'redeemed' => context.tr('استبدال نقاط'),
        'adminadjustment' => context.tr('تعديل إداري'),
        'reversal' => context.tr('عكس نقاط'),
        'matchcreated' => context.tr('نقاط إنشاء مباراة'),
        'americanoorganized' => context.tr('نقاط تنظيم أمريكانو'),
        'tournamentorganized' => context.tr('نقاط تنظيم بطولة'),
        'coachrated' => context.tr('نقاط تقييم مدرب'),
        'courtrated' => context.tr('نقاط تقييم ملعب'),
        'friendinvited' => context.tr('نقاط دعوة صديق'),
        'levelmatchresult' => context.tr('نقاط مستوى — نتيجة مباراة'),
        'levelamericanoround' => context.tr('نقاط مستوى — جولة أمريكانو'),
        'withdrawalpenalty' => context.tr('خصم انسحاب من حدث'),
        _ => type,
      };
}
