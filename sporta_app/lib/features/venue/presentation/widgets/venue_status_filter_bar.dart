import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

/// شريط رقائق الحالة الأفقي أسفل تبويبات النوع. كل خيار = (تسمية، قيمة
/// وسيط status أو null للكل).
class VenueStatusFilterBar extends StatelessWidget {
  const VenueStatusFilterBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<(String, String?)> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSizes.sm),
        itemBuilder: (_, i) {
          final (label, value) = options[i];
          final isSelected = value == selected;
          return Center(
            child: GestureDetector(
              onTap: () => onSelected(value),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.secondary,
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
