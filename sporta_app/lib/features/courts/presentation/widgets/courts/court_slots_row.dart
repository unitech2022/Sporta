import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/state/app_scope.dart';

/// صف المواعيد الفارغة في بطاقة الملعب (البحث بالوقت): زر لكل موعد يفتح
/// الحجز عليه مباشرة، أو تنبيه حين لا يبقى موعد فارغ في النافذة.
class CourtSlotsRow extends StatelessWidget {
  const CourtSlotsRow({super.key, required this.slots, this.onSlotTap});

  final List<String> slots;
  final ValueChanged<String>? onSlotTap;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) return const _NoSlotsNote();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: slots.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSizes.sm),
        itemBuilder: (context, index) {
          final time = slots[index];
          return Material(
            color: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              side: const BorderSide(color: AppColors.border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              onTap: onSlotTap == null ? null : () => onSlotTap!(time),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                child: Center(
                  // الوقت أرقام لاتينية دائماً؛ اتجاه LTR يمنع قلب "23:00".
                  child: Text(
                    time,
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NoSlotsNote extends StatelessWidget {
  const _NoSlotsNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded,
              size: AppSizes.iconMd, color: AppColors.primary),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              context.tr('لا توجد مواعيد متاحة في هذا الوقت'),
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}
