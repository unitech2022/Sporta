import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Small navy form label with an optional leading primary icon,
/// used above every field on the create-match form.
class CreateMatchFieldLabel extends StatelessWidget {
  const CreateMatchFieldLabel({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppSizes.iconSm, color: AppColors.primary),
          SizedBox(width: AppSizes.sm),
        ],
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
        ),
      ],
    );
  }
}
