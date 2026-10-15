import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_text_styles.dart';

/// A titled white card — the building block of the court profile body.
class DetailSectionCard extends StatelessWidget {
  const DetailSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.action,
  });

  final String title;
  final IconData icon;
  final Widget child;

  /// Optional trailing control (e.g. "الاتجاهات").
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSizes.iconMd, color: AppColors.primary),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: AppSizes.md),
          child,
        ],
      ),
    );
  }
}

/// A label→value row used inside the price and schedule cards.
class DetailKeyValueRow extends StatelessWidget {
  const DetailKeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.highlighted = false,
    this.valueColor,
    this.leading,
  });

  final String label;
  final String value;

  /// Draws the row on a tinted background (today's schedule row).
  final bool highlighted;

  final Color? valueColor;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      margin: const EdgeInsets.only(bottom: AppSizes.xs),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: AppSizes.sm)],
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: highlighted ? AppColors.primary : AppColors.secondary,
                fontWeight: highlighted ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: valueColor ??
                  (highlighted ? AppColors.primary : AppColors.secondary),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small rounded pill (icon + text) for at-a-glance facts.
class DetailPill extends StatelessWidget {
  const DetailPill({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.mutedForeground;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: tint.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tint),
          const SizedBox(width: AppSizes.xs),
          Text(
            label,
            style: AppTextStyles.caption
                .copyWith(color: tint, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
