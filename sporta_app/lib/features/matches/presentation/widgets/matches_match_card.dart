import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Shared scaffold for the match / americano cards:
/// badges + level row, location block, custom [body] and a footer with
/// the time and an action button, separated by a top border.
class MatchesMatchCard extends StatelessWidget {
  const MatchesMatchCard({
    super.key,
    required this.badges,
    required this.level,
    this.levelTooltip,
    required this.venue,
    this.venueDetail,
    this.venueBold = false,
    this.locationIconColor = AppColors.primary,
    this.body,
    this.backgroundColor = AppColors.card,
    this.backgroundGradient,
    this.borderColor = AppColors.border,
    this.borderWidth = 1,
    this.dividerColor = AppColors.border,
    required this.time,
    this.timeIconColor = AppColors.primary,
    required this.actionLabel,
    this.actionColor = AppColors.primary,
    this.actionIcon,
    this.onAction,
    this.onTap,
  });

  /// Status / type pills shown at the top start of the card.
  final List<Widget> badges;

  /// Level text shown at the top end (e.g. 'مستوى: 5.0 - 6.0').
  final String level;
  final String? levelTooltip;

  final String venue;
  final String? venueDetail;
  final bool venueBold;
  final Color locationIconColor;

  /// Card-specific middle content (avatars, stats grid, teams...).
  final Widget? body;

  final Color backgroundColor;
  final Gradient? backgroundGradient;
  final Color borderColor;
  final double borderWidth;
  final Color dividerColor;

  final String time;
  final Color timeIconColor;

  final String actionLabel;
  final Color actionColor;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSizes.radiusXl);

    Widget levelText = Text(
      level,
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
    );
    if (levelTooltip != null) {
      levelText = Tooltip(message: levelTooltip!, child: levelText);
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundGradient == null ? backgroundColor : null,
        gradient: backgroundGradient,
        borderRadius: radius,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: AppSizes.sm,
                        runSpacing: AppSizes.sm,
                        children: badges,
                      ),
                    ),
                    SizedBox(width: AppSizes.sm),
                    levelText,
                  ],
                ),
                SizedBox(height: AppSizes.lg),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: AppSizes.iconSm,
                      color: locationIconColor,
                    ),
                    SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        venue,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight:
                              venueBold ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                if (venueDetail != null) ...[
                  SizedBox(height: AppSizes.xs),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: AppSizes.xxl,
                    ),
                    child: Text(venueDetail!, style: AppTextStyles.caption),
                  ),
                ],
                if (body != null) ...[
                  const SizedBox(height: AppSizes.lg),
                  body!,
                ],
                SizedBox(height: AppSizes.lg),
                Container(
                  padding: const EdgeInsets.only(top: AppSizes.md),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: dividerColor)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: AppSizes.iconSm,
                        color: timeIconColor,
                      ),
                      SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          time,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.secondary),
                        ),
                      ),
                      _ActionButton(
                        label: actionLabel,
                        color: actionColor,
                        icon: actionIcon,
                        onPressed: onAction,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    this.icon,
    this.onPressed,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      elevation: 1,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.xl,
            vertical: AppSizes.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSizes.iconSm, color: Colors.white),
                SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
