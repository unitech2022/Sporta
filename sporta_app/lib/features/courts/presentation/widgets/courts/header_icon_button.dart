import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';

/// Square icon button used in the courts header (map toggle / filters toggle).
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: isActive
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
          ),
          child: Icon(icon, color: Colors.white, size: AppSizes.iconMd),
        ),
      ),
    );
  }
}
