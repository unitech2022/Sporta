import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../domain/entities/subscription_entity.dart';

/// بطاقة نوع اشتراك واحد: الاسم والنوع (شهري/سنوي) والسعر (والسعر قبل الخصم
/// إن وُجد) والمزايا وزر الاشتراك. يُبرَز الاشتراك الحالي بإطار ملوّن بدل الزر.
class PackageCard extends StatelessWidget {
  const PackageCard({
    super.key,
    required this.package,
    required this.isCurrent,
    required this.busy,
    required this.onSubscribe,
  });

  final PackageEntity package;
  final bool isCurrent;
  final bool busy;

  /// null يعني الزر معطّل (اشتراك حالي أو عملية جارية).
  final VoidCallback? onSubscribe;

  @override
  Widget build(BuildContext context) {
    final benefits = package.allBenefits;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: isCurrent ? AppColors.primary : AppColors.border,
          width: isCurrent ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(package.name,
                        style: AppTextStyles.heading3
                            .copyWith(color: AppColors.secondary)),
                    const SizedBox(height: 2),
                    Text(
                        package.isCommission
                            ? '${context.tr('بالنسبة')} · ${context.tr('بلا تاريخ انتهاء')}'
                            : '${context.tr(package.periodLabel)} · '
                                '${package.durationDays} ${context.tr('يوم')}',
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  child: Text(context.tr('اشتراكك الحالي'),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primary)),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          _price(context),
          if (benefits.isNotEmpty) ...[
            const SizedBox(height: AppSizes.md),
            for (final b in benefits)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: AppSizes.iconSm),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(child: Text(b, style: AppTextStyles.bodySmall)),
                  ],
                ),
              ),
          ],
          const SizedBox(height: AppSizes.md),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: busy ? null : onSubscribe,
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Text(isCurrent
                      ? context.tr('مشترك حالياً')
                      : context.tr('اشترك الآن')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _price(BuildContext context) {
    final riyal = context.tr('ر.س');
    // «بالنسبة» بلا سعر: المقابل هو نسبة سبورتا من كل عملية.
    if (package.isCommission) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${PackageEntity.fmt(package.commissionPercent)}%',
            style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
          ),
          const SizedBox(width: AppSizes.sm),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(context.tr('من كل عملية'),
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.mutedForeground)),
          ),
        ],
      );
    }
    if (!package.hasDiscount) {
      return Text(
        '${PackageEntity.fmt(package.price)} $riyal',
        style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${PackageEntity.fmt(package.priceAfterDiscount)} $riyal',
          style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
        ),
        const SizedBox(width: AppSizes.sm),
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            '${PackageEntity.fmt(package.price)} $riyal',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.mutedForeground,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: Text(
            '-${PackageEntity.fmt(package.discountPercent)}%',
            style: AppTextStyles.caption.copyWith(color: AppColors.success),
          ),
        ),
      ],
    );
  }
}
