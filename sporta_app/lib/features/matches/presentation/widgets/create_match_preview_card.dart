import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

/// "معاينة المباراة" card shown once the form becomes valid.
class CreateMatchPreviewCard extends StatelessWidget {
  const CreateMatchPreviewCard({
    super.key,
    required this.courtName,
    required this.date,
    required this.time,
    required this.typeLabel,
    required this.minLevel,
    required this.maxLevel,
    this.costPerPlayer = '',
  });

  final String courtName;
  final String date;
  final String time;
  final String typeLabel;
  final String minLevel;
  final String maxLevel;
  final String costPerPlayer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.sm,
                height: AppSizes.sm,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: AppSizes.sm),
              Text(
                'معاينة المباراة',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          _row('الملعب:', courtName),
          SizedBox(height: AppSizes.sm),
          _row('التاريخ:', date),
          SizedBox(height: AppSizes.sm),
          _row('الوقت:', time),
          SizedBox(height: AppSizes.sm),
          _row('النوع:', typeLabel),
          SizedBox(height: AppSizes.sm),
          _row('المستوى:', '$minLevel - $maxLevel'),
          if (costPerPlayer.isNotEmpty) ...[
            SizedBox(height: AppSizes.sm),
            _row('التكلفة:', '$costPerPlayer ر.س'),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.mutedForeground),
        ),
        Text(
          value,
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
        ),
      ],
    );
  }
}
