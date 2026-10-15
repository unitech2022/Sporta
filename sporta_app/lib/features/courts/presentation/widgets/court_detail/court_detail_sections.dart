import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../domain/entities/court_entity.dart';
import '../../courts_helpers.dart';
import 'court_detail_shared.dart';
import '../../../../../core/state/app_scope.dart';
import '../../../../../core/localization/tr_global.dart';
import 'package:sporta_app/core/utils/server_time.dart';

/// Three at-a-glance tiles: price, category and booking availability.
class CourtSummaryTiles extends StatelessWidget {
  const CourtSummaryTiles({super.key, required this.court});

  final CourtEntity court;

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight gives the row a bounded height so the tiles can stretch
    // to the tallest one — plain `stretch` inside a sliver list would be laid
    // out against unbounded height and throw.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Tile(
              icon: Icons.payments_outlined,
              color: const Color(0xFF16A34A),
              value: context.trArgs('{p0} ر.س', {'p0': court.lowestPrice}),
              label: context.tr('يبدأ من / ساعة'),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: _Tile(
              icon: Icons.people_outline_rounded,
              color: const Color(0xFF2563EB),
              value: courtGenderLabel(court.gender),
              label: context.tr('الفئة'),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: _Tile(
              icon: court.isAvailable
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
              color: court.isAvailable
                  ? AppColors.success
                  : AppColors.destructive,
              value: court.isAvailable ? trg('متاح') : trg('مغلق'),
              label: context.tr('الحالة'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
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
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.md,
        horizontal: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: AppSizes.iconMd),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

/// Hourly rates plus the owner's duration→price tiers. Every figure already
/// includes نسبة سبورتا — it's what the player actually pays.
class CourtPricingSection extends StatelessWidget {
  const CourtPricingSection({super.key, required this.court});

  final CourtEntity court;

  @override
  Widget build(BuildContext context) {
    final tiers = court.bookingPrices;
    // Peak/lowest are only worth a row when they actually differ from the
    // standard rate; a flat-priced court would otherwise show three identical
    // lines.
    final showLowest = court.lowestPrice != court.totalPrice;
    final showPeak = court.peakHourPrice > court.totalPrice;

    return DetailSectionCard(
      title: context.tr('الأسعار'),
      icon: Icons.payments_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailKeyValueRow(
            label: context.tr('السعر العادي / ساعة'),
            value: context.trArgs('{p0} ر.س', {'p0': court.totalPrice}),
          ),
          if (showLowest)
            DetailKeyValueRow(
              label: context.tr('أقل سعر (ساعات الخصم)'),
              value: context.trArgs('{p0} ر.س', {'p0': court.lowestPrice}),
              valueColor: AppColors.success,
            ),
          if (showPeak)
            DetailKeyValueRow(
              label: context.tr('وقت الذروة'),
              value: context.trArgs('{p0} ر.س', {'p0': court.peakHourPrice}),
              valueColor: AppColors.warning,
            ),
          // فترات المالك: سعر الساعة لكل وقت من اليوم.
          if (court.priceBands.isNotEmpty) ...[
            const Divider(height: AppSizes.xl, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.only(
                right: AppSizes.md,
                left: AppSizes.md,
                bottom: AppSizes.xs,
              ),
              child: Text(
                context.tr('الأسعار حسب الوقت / ساعة'),
                style: AppTextStyles.caption,
              ),
            ),
            for (final b in court.priceBands)
              DetailKeyValueRow(
                label: b.day == null
                    ? b.rangeLabel
                    : '${b.dayLabel} · ${b.rangeLabel}',
                value: context.trArgs('{p0} ر.س', {'p0': b.playerRate.round()}),
                valueColor: b.playerRate < court.totalPrice
                    ? AppColors.success
                    : b.playerRate > court.totalPrice
                    ? AppColors.warning
                    : null,
                leading: const Icon(
                  Icons.schedule_rounded,
                  size: AppSizes.iconSm,
                  color: AppColors.mutedForeground,
                ),
              ),
          ],
          if (tiers.isNotEmpty) ...[
            const Divider(height: AppSizes.xl, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.only(
                right: AppSizes.md,
                left: AppSizes.md,
                bottom: AppSizes.xs,
              ),
              child: Text(
                context.tr('مدد الحجز'),
                style: AppTextStyles.caption,
              ),
            ),
            for (final tier in tiers)
              DetailKeyValueRow(
                label: context.trArgs('{p0} دقيقة', {
                  'p0': tier.durationMinutes,
                }),
                value: context.trArgs('{p0} ر.س', {'p0': tier.price.round()}),
                leading: const Icon(
                  Icons.schedule_rounded,
                  size: AppSizes.iconSm,
                  color: AppColors.mutedForeground,
                ),
              ),
          ] else if (court.availableDurations.isNotEmpty) ...[
            const Divider(height: AppSizes.xl, color: AppColors.divider),
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: [
                for (final d in court.availableDurations)
                  DetailPill(
                    icon: Icons.schedule_rounded,
                    label: context.trArgs('{p0} دقيقة', {'p0': d}),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSizes.sm),
          Text(
            context.tr('الأسعار شاملة رسوم سبورتا.'),
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

/// The venue's weekly opening hours, with today's row highlighted.
class CourtScheduleSection extends StatelessWidget {
  const CourtScheduleSection({super.key, required this.court});

  final CourtEntity court;

  @override
  Widget build(BuildContext context) {
    // DateTime.weekday is 1 = Monday … 7 = Sunday; the API numbers days
    // 0 = Sunday … 6 = Saturday.
    final today = ksaNow().weekday % 7;

    return DetailSectionCard(
      title: context.tr('دوام الملعب'),
      icon: Icons.calendar_month_outlined,
      child: Column(
        children: [
          for (final day in court.openingHours)
            DetailKeyValueRow(
              label: day.day == today
                  ? context.trArgs('{p0} (اليوم)', {'p0': day.dayLabel})
                  : day.dayLabel,
              value: day.rangeLabel,
              highlighted: day.day == today && !day.isClosed,
              valueColor: day.isClosed ? AppColors.destructive : null,
            ),
        ],
      ),
    );
  }
}

/// Start times the court opens for, across the week.
class CourtTimesSection extends StatelessWidget {
  const CourtTimesSection({super.key, required this.court});

  final CourtEntity court;

  @override
  Widget build(BuildContext context) {
    return DetailSectionCard(
      title: context.tr('أوقات البدء المتاحة'),
      icon: Icons.access_time_rounded,
      child: Wrap(
        spacing: AppSizes.sm,
        runSpacing: AppSizes.sm,
        children: [
          for (final time in court.availableTimes)
            DetailPill(
              icon: Icons.schedule_rounded,
              label: time,
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }
}

/// Venue facilities, when the venue lists any.
class CourtFacilitiesSection extends StatelessWidget {
  const CourtFacilitiesSection({super.key, required this.court});

  final CourtEntity court;

  @override
  Widget build(BuildContext context) {
    return DetailSectionCard(
      title: context.tr('المرافق'),
      icon: Icons.check_circle_outline,
      child: Wrap(
        spacing: AppSizes.sm,
        runSpacing: AppSizes.sm,
        children: [
          for (final facility in court.facilities)
            DetailPill(
              icon: Icons.check_rounded,
              label: facility,
              color: AppColors.success,
            ),
        ],
      ),
    );
  }
}

/// Court type, gender policy and the number of identical physical courts.
class CourtAboutSection extends StatelessWidget {
  const CourtAboutSection({super.key, required this.court});

  final CourtEntity court;

  @override
  Widget build(BuildContext context) {
    return DetailSectionCard(
      title: context.tr('عن الملعب'),
      icon: Icons.info_outline_rounded,
      child: Column(
        children: [
          DetailKeyValueRow(
            label: context.tr('نوع الملعب'),
            value: courtTypeLabel(court.type),
          ),
          DetailKeyValueRow(
            label: context.tr('الفئة المسموحة'),
            value: courtGenderLabel(court.gender),
          ),
          DetailKeyValueRow(
            label: context.tr('عدد الملاعب'),
            value: '${court.courtCount}',
          ),
          if (court.venueName.isNotEmpty)
            DetailKeyValueRow(
              label: context.tr('النادي'),
              value: court.venueName,
            ),
        ],
      ),
    );
  }
}
