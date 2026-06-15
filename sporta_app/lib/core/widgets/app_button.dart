import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, destructive }

/// Standard app button with the design-system variants.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expanded = true,
    this.height = AppSizes.buttonHeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expanded;
  final double height;

  @override
  Widget build(BuildContext context) {
    final button = switch (variant) {
      AppButtonVariant.primary => _filled(AppColors.primary, AppColors.onPrimary),
      AppButtonVariant.secondary =>
        _filled(AppColors.secondary, AppColors.onSecondary),
      AppButtonVariant.destructive =>
        _filled(AppColors.destructive, Colors.white),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: onPressed,
          child: _content(),
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: onPressed,
          child: _content(),
        ),
    };

    final sized = SizedBox(height: height, child: button);
    return expanded ? SizedBox(width: double.infinity, child: sized) : sized;
  }

  Widget _filled(Color background, Color foreground) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
      ),
      child: _content(),
    );
  }

  Widget _content() {
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: AppSizes.iconMd),
        const SizedBox(width: AppSizes.sm),
        Text(label),
      ],
    );
  }
}
