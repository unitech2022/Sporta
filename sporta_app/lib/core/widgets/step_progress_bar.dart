import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Segmented progress bar for multi-step flows (registration, booking).
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.inactiveColor,
  });

  /// 1-based index of the active step.
  final int currentStep;
  final int totalSteps;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var step = 1; step <= totalSteps; step++) ...[
          if (step > 1) const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: step <= currentStep
                    ? AppColors.primary
                    : inactiveColor ?? Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
