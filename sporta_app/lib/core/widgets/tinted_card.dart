import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';

/// Soft-tinted rounded card (Tailwind's `from-<color>-50 border-<color>-200`
/// pattern) used for activity feeds, stats and highlighted info boxes.
class TintedCard extends StatelessWidget {
  const TintedCard({
    super.key,
    required this.tint,
    required this.child,
    this.padding = const EdgeInsets.all(AppSizes.lg),
    this.radius = AppSizes.radiusXl,
    this.borderWidth = 1,
    this.onTap,
  });

  final Color tint;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double borderWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    return Material(
      color: Color.alphaBlend(tint.withValues(alpha: 0.08), Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(
          color: tint.withValues(alpha: 0.3),
          width: borderWidth,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
