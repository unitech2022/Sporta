import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';

/// Navy gradient header used at the top of most pages.
/// Shows an optional back button, title, trailing actions and an
/// optional [bottom] section (e.g. search bar or filters).
class GradientPageHeader extends StatelessWidget {
  const GradientPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget>? trailing;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.xxxl,
            AppSizes.pagePadding,
            AppSizes.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (onBack != null) ...[
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                      color: AppColors.onSecondary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(width: AppSizes.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.heading1
                              .copyWith(color: AppColors.onSecondary),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color:
                                  AppColors.onSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ...?trailing,
                ],
              ),
              if (bottom != null) ...[
                const SizedBox(height: AppSizes.lg),
                bottom!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
