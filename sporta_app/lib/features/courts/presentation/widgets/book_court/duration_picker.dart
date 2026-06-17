import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_text_styles.dart';

/// Row of session-duration options (minutes) offered by the court.
class DurationPicker extends StatelessWidget {
  const DurationPicker({
    super.key,
    required this.durations,
    required this.selected,
    required this.onSelect,
  });

  final List<int> durations;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر المدة',
          style: AppTextStyles.heading2.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          children: durations.map((dur) {
            final isSelected = selected == dur;
            return Padding(
              padding: const EdgeInsets.only(left: AppSizes.sm),
              child: GestureDetector(
                onTap: () => onSelect(dur),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                    vertical: AppSizes.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.card,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    '$dur دقيقة',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.secondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
