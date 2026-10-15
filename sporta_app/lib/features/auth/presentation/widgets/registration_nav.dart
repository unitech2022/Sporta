import 'package:sporta_app/core/widgets/directional_icon.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/sporta_logo.dart';
import '../../../../core/widgets/step_progress_bar.dart';
import 'circle_back_button.dart';
import 'language_toggle_button.dart';

/// Gradient header for the registration flow with the step progress bar.
class RegistrationHeader extends StatelessWidget {
  const RegistrationHeader({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.onBack,
  });

  final int step;
  final int totalSteps;
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
            AppSizes.lg,
            AppSizes.pagePadding,
            AppSizes.lg,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleBackButton(onTap: onBack),
                  Text(
                    context.tr('register'),
                    style:
                        AppTextStyles.heading3.copyWith(color: Colors.white),
                  ),
                  // تبديل اللغة في مكانه: لا يضيع ما كتبه في خطوات التسجيل.
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LanguageToggleButton(compact: true, inPlace: true),
                      SizedBox(width: AppSizes.sm),
                      SportaLogo(width: 56, white: true),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              StepProgressBar(currentStep: step, totalSteps: totalSteps),
              const SizedBox(height: AppSizes.sm),
              Text(
                '${context.tr('step')} $step ${context.tr('of')} $totalSteps',
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

/// Back / next (or create-account) footer for the registration flow.
class RegistrationFooter extends StatelessWidget {
  const RegistrationFooter({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.canProceed,
    required this.isLoading,
    required this.onNext,
    required this.onBack,
  });

  final int step;
  final int totalSteps;
  final bool canProceed;
  final bool isLoading;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.md,
            AppSizes.pagePadding,
            AppSizes.md,
          ),
          child: Row(
            children: [
              if (step > 1) ...[
                _buildBackButton(context),
                const SizedBox(width: AppSizes.md),
              ],
              Expanded(child: _buildNextButton(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return TextButton.icon(
      onPressed: isLoading ? null : onBack,
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFF3F4F6),
        foregroundColor: AppColors.secondary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.xxl,
          vertical: AppSizes.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
      ),
      icon: DirectionalIcon(rtl: Icons.chevron_right, ltr: Icons.chevron_left, size: AppSizes.iconMd),
      label: Text(context.tr('back')),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    return ElevatedButton(
      onPressed: (canProceed && !isLoading) ? onNext : null,
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  step == totalSteps
                      ? context.tr('createAccount')
                      : context.tr('next'),
                ),
                if (step < totalSteps)
                  DirectionalIcon(rtl: Icons.chevron_left, ltr: Icons.chevron_right, size: AppSizes.iconMd),
              ],
            ),
    );
  }
}
