import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

/// White rounded input card with a leading circular icon, used for the login
/// phone/password fields.
class LoginIconInputCard extends StatelessWidget {
  const LoginIconInputCard({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: AppSizes.iconMd),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: AppSizes.xs),
                child,
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
