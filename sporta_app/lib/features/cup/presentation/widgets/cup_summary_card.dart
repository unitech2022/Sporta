import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/money.dart';
import '../../domain/entities/cup_entity.dart';

/// ملخص البطولة قبل الإنشاء (من الخادم): الفرق، المباريات، المتأهلون،
/// المسار، سعة الجدول، وحصة اللاعب.
class CupSummaryCard extends StatelessWidget {
  const CupSummaryCard({
    super.key,
    required this.quote,
    required this.loading,
    required this.teamCount,
    required this.hostedByVenue,
  });

  final CupQuote? quote;
  final bool loading;
  final int teamCount;
  final bool hostedByVenue;

  @override
  Widget build(BuildContext context) {
    final q = quote;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_outlined,
                color: AppColors.brandGold,
                size: 20,
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                context.tr('ملخص البطولة'),
                style: AppTextStyles.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (loading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          if (q == null)
            Text(
              context.tr('اختر الملاعب والتاريخ ليظهر الملخص.'),
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
            )
          else ...[
            Row(
              children: [
                _stat(context, '${q.teamCount}', context.tr('فريق')),
                _stat(context, '${q.totalMatches}', context.tr('مباراة')),
                _stat(
                  context,
                  '${q.knockoutSize}',
                  context.tr('يتأهلون للإقصائيات'),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              q.pathText,
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: AppSizes.md),
            Container(
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: (q.fits ? AppColors.success : AppColors.destructive)
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    q.fits
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    size: AppSizes.iconSm,
                    color: q.fits ? AppColors.success : const Color(0xFFFCA5A5),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      q.fits
                          ? context.trArgs(
                              'الجدول يتّسع: {p0} خانة لعب لـ {p1} مباراة.',
                              {'p0': q.slotCapacity, 'p1': q.totalMatches},
                            )
                          : context.trArgs(
                              'الجدول لا يتّسع: {p0} خانة لعب فقط و{p1} مباراة — زد الأيام أو الملاعب أو النافذة اليومية.',
                              {'p0': q.slotCapacity, 'p1': q.totalMatches},
                            ),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    hostedByVenue
                        ? context.tr('حصة كل لاعب (تصلك صافيةً من نسبة سبورتا)')
                        : context.tr('حصة كل لاعب — تُخصم حصتك عند الإنشاء'),
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
                Text(
                  context.trArgs('{p0} ر.س', {'p0': money(q.pricePerPlayer)}),
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.brandGold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(color: Colors.white70),
        ),
      ],
    ),
  );
}
