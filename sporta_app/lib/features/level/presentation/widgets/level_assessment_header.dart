import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/sporta_logo.dart';
import '../../../../core/widgets/step_progress_bar.dart';
import '../../../auth/presentation/widgets/circle_back_button.dart';

/// Gradient header for the level assessment: logo, title and step progress.
class LevelAssessmentHeader extends StatelessWidget {
  const LevelAssessmentHeader({
    super.key,
    required this.step,
    required this.total,
    required this.onBack,
  });

  final int step;
  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleBackButton(onTap: onBack),
                  const SportaLogo(width: 64, white: true),
                  const SizedBox(width: 36),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                context.tr('levelAssessmentTitle'),
                style: AppTextStyles.heading3.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                context.tr('levelAssessmentSubtitle'),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: AppSizes.lg),
              StepProgressBar(currentStep: step, totalSteps: total),
              const SizedBox(height: AppSizes.sm),
              Text(
                '${context.tr('step')} $step ${context.tr('of')} $total',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
