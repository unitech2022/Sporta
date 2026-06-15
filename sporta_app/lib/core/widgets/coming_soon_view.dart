import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import '../state/app_scope.dart';

/// Temporary placeholder shown for feature pages that are not yet
/// converted. Removed once every feature is implemented.
class ComingSoonView extends StatelessWidget {
  const ComingSoonView({super.key, required this.title, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.construction,
            size: 48,
            color: AppColors.mutedForeground,
          ),
          SizedBox(height: AppSizes.lg),
          Text(title, style: AppTextStyles.heading2),
          SizedBox(height: AppSizes.sm),
          Text(
            context.tr('comingSoon'),
            style: AppTextStyles.body
                .copyWith(color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}
