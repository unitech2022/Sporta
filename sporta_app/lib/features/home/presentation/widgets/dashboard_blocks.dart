import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/sporta_logo.dart';
import '../../../../core/widgets/tinted_card.dart';

/// Colored gradient header for coach/venue dashboards with the user
/// identity and three quick stats.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.gradient,
    required this.userName,
    required this.roleLabel,
    required this.stats,
  });

  final Gradient gradient;
  final String userName;
  final String roleLabel;
  final List<(String value, String label)> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(gradient: gradient),
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
              const SportaLogo(width: 80, white: true),
              SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.9))),
                    Text(roleLabel,
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              Material(
                color: Colors.white.withValues(alpha: 0.2),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () {},
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(AppSizes.sm),
                    child: Icon(Icons.notifications_outlined,
                        size: AppSizes.iconMd, color: Colors.white),
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
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
                    child: Column(
                      children: [
                        Text(value,
                            style: AppTextStyles.heading1
                                .copyWith(color: Colors.white)),
                        Text(label,
                            style: AppTextStyles.caption.copyWith(
                                color:
                                    Colors.white.withValues(alpha: 0.8))),
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
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TintedCard(
      tint: color,
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          SizedBox(height: AppSizes.sm),
          Text(value,
              style: AppTextStyles.heading1
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
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

/// Two quick-action buttons at the bottom of coach/venue dashboards.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({
    super.key,
    required this.primaryIcon,
    required this.primaryLabel,
    required this.secondaryIcon,
    required this.secondaryLabel,
  });

  final IconData primaryIcon;
  final String primaryLabel;
  final IconData secondaryIcon;
  final String secondaryLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  children: [
                    Icon(primaryIcon, size: 32, color: Colors.white),
                    SizedBox(height: AppSizes.sm),
                    Text(primaryLabel,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              side: const BorderSide(color: AppColors.border, width: 2),
            ),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  children: [
                    Icon(secondaryIcon, size: 32, color: AppColors.primary),
                    SizedBox(height: AppSizes.sm),
                    Text(secondaryLabel,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
