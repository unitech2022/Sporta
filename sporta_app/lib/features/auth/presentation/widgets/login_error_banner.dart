import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';

/// Login error banner. When the failure is "phone not registered" it also
/// offers a shortcut to the registration flow.
class LoginErrorBanner extends StatelessWidget {
  const LoginErrorBanner({
    super.key,
    required this.message,
    required this.errorCode,
    required this.onRegister,
  });

  final String message;
  final String? errorCode;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.destructive.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.destructive),
          ),
          if (errorCode == 'PHONE_NOT_REGISTERED') ...[
            const SizedBox(height: AppSizes.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRegister,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.destructive,
                  side: const BorderSide(color: AppColors.destructive),
                ),
                icon: const Icon(Icons.person_add_alt_1, size: AppSizes.iconSm),
                label: Text(context.tr('register')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
