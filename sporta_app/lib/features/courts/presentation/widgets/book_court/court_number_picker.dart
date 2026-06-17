import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_text_styles.dart';

/// 5×2 grid of court numbers (1..10) to pick which physical court to book.
class CourtNumberPicker extends StatelessWidget {
  const CourtNumberPicker({
    super.key,
    required this.selected,
    required this.onSelect,
    this.count = 10,
  });

  final int? selected;
  final ValueChanged<int> onSelect;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر رقم الملعب',
          style: AppTextStyles.heading2.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSizes.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: AppSizes.sm,
            mainAxisSpacing: AppSizes.sm,
            childAspectRatio: 1,
          ),
          itemCount: count,
          itemBuilder: (context, index) {
            final number = index + 1;
            final isSelected = selected == number;
            return GestureDetector(
              onTap: () => onSelect(number),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.secondary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
