import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_text_styles.dart';

/// Shown when loading the courts list fails; offers a retry.
class CourtsErrorView extends StatelessWidget {
  const CourtsErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: AppColors.mutedForeground.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.body.copyWith(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: AppSizes.lg),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when no courts match the current search/filters.
class CourtsEmptyView extends StatelessWidget {
  const CourtsEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_tennis_rounded,
            size: 64,
            color: AppColors.mutedForeground.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSizes.lg),
          Text(
            'لا توجد ملاعب',
            style: AppTextStyles.heading2
                .copyWith(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'جرّب تغيير معايير البحث أو الفلاتر',
            style: AppTextStyles.body.copyWith(color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}
