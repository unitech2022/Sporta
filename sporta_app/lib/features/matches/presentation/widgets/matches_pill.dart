import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Small rounded pill (px-3 py-1, text-xs) used for match statuses and
/// match-type tags. Optionally shows a leading icon and a tooltip.
class MatchesPill extends StatelessWidget {
  const MatchesPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.tooltip,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            SizedBox(width: AppSizes.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );

    if (tooltip == null) return pill;
    return Tooltip(message: tooltip!, child: pill);
  }
}
