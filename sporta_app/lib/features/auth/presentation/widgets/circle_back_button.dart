import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

/// Round chevron back button used on auth screens. [dark] renders the
/// gray-on-light variant, otherwise white-on-translucent for gradients.
class CircleBackButton extends StatelessWidget {
  const CircleBackButton({super.key, required this.onTap, this.dark = false});

  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dark
          ? const Color(0xFFF3F4F6)
          : Colors.white.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.sm),
          child: Icon(
            // Chevron pointing "back" — auto-mirrored by Directionality.
            Icons.arrow_forward_ios,
            size: AppSizes.iconMd,
            textDirection: Directionality.of(context) == TextDirection.rtl
                ? TextDirection.ltr
                : TextDirection.rtl,
            color: dark ? AppColors.secondary : Colors.white,
          ),
        ),
      ),
    );
  }
}
