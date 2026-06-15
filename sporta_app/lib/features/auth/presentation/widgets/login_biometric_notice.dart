import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import 'glass_panel.dart';

/// Decorative (not yet wired) biometric-login opt-in shown on the login screen.
class LoginBiometricNotice extends StatelessWidget {
  const LoginBiometricNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: AppSizes.radiusLg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: false,
              activeColor: AppColors.primary,
              onChanged: null,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('biometricTitle'),
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  context.tr('biometricDesc'),
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
