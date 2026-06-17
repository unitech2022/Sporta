import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../data/level_repository.dart';

/// Final screen showing the computed level and a "start now" action.
class LevelResultView extends StatelessWidget {
  const LevelResultView({
    super.key,
    required this.result,
    required this.onStart,
  });

  final LevelAssessmentResult result;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final lang = context.appSettings.language;
    final name = lang.isRtl ? result.levelNameAr : result.levelNameEn;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${result.level}',
                    style: AppTextStyles.heading1.copyWith(
                      color: Colors.white,
                      fontSize: 56,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.xxl),
              Text(
                context.tr('yourLevelIs'),
                style: AppTextStyles.body
                    .copyWith(color: AppColors.mutedForeground),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                name,
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.secondary,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                context.tr('levelResultHint'),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.mutedForeground),
              ),
              const SizedBox(height: AppSizes.xxxl),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onStart,
                  child: Text(context.tr('startNow')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
