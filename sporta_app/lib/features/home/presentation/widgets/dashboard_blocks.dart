import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/sporta_logo.dart';
import '../../../../core/widgets/tinted_card.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';

/// Colored gradient header for coach/venue dashboards with the user
/// identity and three quick stats.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.gradient,
    required this.userName,
    required this.roleLabel,
    required this.stats,
    this.foregroundColor = Colors.white,
    this.logoWhite = true,
    this.border,
  });

  final Gradient gradient;
  final String userName;
  final String roleLabel;
  final List<(String value, String label)> stats;

  /// Text/icon color drawn on top of [gradient]. Defaults to white for the
  /// colored gradients; pass a dark color when [gradient] is light/white.
  final Color foregroundColor;

  /// Whether the Sporta logo uses its white variant. Set false on light
  /// backgrounds.
  final bool logoWhite;

  /// Optional border, useful when the background is white and needs
  /// separation from the page background.
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(gradient: gradient, border: border),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pagePadding,
        AppSizes.xxxl,
        AppSizes.pagePadding,
        AppSizes.xxl,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SportaLogo(width: 80, white: logoWhite),
              SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: foregroundColor.withValues(alpha: 0.9))),
                    Text(roleLabel,
                        style: AppTextStyles.caption.copyWith(
                            color: foregroundColor.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              Material(
                color: foregroundColor.withValues(alpha: 0.2),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => NotificationsPage(
                        onBack: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    child: Icon(Icons.notifications_outlined,
                        size: AppSizes.iconMd, color: foregroundColor),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.xxl),
          Row(
            children: [
              for (final (value, label) in stats) ...[
                if ((value, label) != stats.first)
                  SizedBox(width: AppSizes.md),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: foregroundColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
                    child: Column(
                      children: [
                        Text(value,
                            style: AppTextStyles.heading1
                                .copyWith(color: foregroundColor)),
                        Text(label,
                            style: AppTextStyles.caption.copyWith(
                                color: foregroundColor.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Overview stat card (icon + big colored value + caption).
class OverviewStatCard extends StatelessWidget {
  const OverviewStatCard({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.backgroundColor,
    this.valueColor,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  /// Card background. Defaults to a soft tint of [color]; pass
  /// [Colors.white] for a plain white card.
  final Color? backgroundColor;

  /// Value text color. Defaults to [color].
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return TintedCard(
      tint: color,
      backgroundColor: backgroundColor,
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          SizedBox(height: AppSizes.sm),
          Text(value,
              style: AppTextStyles.heading1.copyWith(
                  color: valueColor ?? color, fontWeight: FontWeight.w700)),
          SizedBox(height: AppSizes.xs),
          Text(label,
              textAlign: TextAlign.center, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

/// Card with a header row, a divider, then a time + price footer row —
/// the recurring booking/session card shape.
class BookingInfoCard extends StatelessWidget {
  const BookingInfoCard({
    super.key,
    required this.header,
    required this.time,
    required this.price,
    this.priceColor = AppColors.primary,
    this.tint,
    this.borderColor,
  });

  final Widget header;
  final String time;
  final String price;
  final Color priceColor;
  final Color? tint;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        header,
        SizedBox(height: AppSizes.md),
        const Divider(height: 1),
        SizedBox(height: AppSizes.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: AppSizes.iconSm, color: AppColors.mutedForeground),
                SizedBox(width: AppSizes.sm),
                Text(time,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.secondary)),
              ],
            ),
            Text(price,
                style: AppTextStyles.bodySmall.copyWith(
                    color: priceColor, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );

    if (tint != null) {
      return TintedCard(tint: tint!, borderWidth: 2, child: body);
    }
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: body,
    );
  }
}
