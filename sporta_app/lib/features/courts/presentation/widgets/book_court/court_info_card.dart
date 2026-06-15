import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../domain/entities/court_entity.dart';
import '../../courts_helpers.dart';

/// Header card on the booking screen: court name, rating, location and the
/// base/peak price strip.
class CourtInfoCard extends StatelessWidget {
  const CourtInfoCard({super.key, required this.court});

  final CourtEntity court;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            court.name,
            style: AppTextStyles.heading2.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  size: AppSizes.iconSm, color: Color(0xFFFACC15)),
              const SizedBox(width: 3),
              Text(
                court.rating.toStringAsFixed(1),
                style:
                    AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                '(${court.reviews} تقييم)',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedForeground),
              ),
              const SizedBox(width: AppSizes.md),
              const Icon(Icons.location_on_outlined,
                  size: AppSizes.iconSm, color: AppColors.mutedForeground),
              const SizedBox(width: 2),
              Text(
                court.distance,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedForeground),
              ),
              const SizedBox(width: AppSizes.md),
              _SmallBadge(label: courtTypeLabel(court.type)),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _PriceStrip(
                    label: 'السعر الاعتيادي',
                    price: court.basePrice,
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.border),
                Expanded(
                  child: _PriceStrip(
                    label: 'ساعة الذروة',
                    price: court.peakHourPrice,
                    isPeak: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PriceStrip extends StatelessWidget {
  const _PriceStrip({
    required this.label,
    required this.price,
    this.isPeak = false,
  });

  final String label;
  final int price;
  final bool isPeak;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isPeak) ...[
                const Icon(Icons.bolt_rounded,
                    size: 12, color: Color(0xFFFB923C)),
                const SizedBox(width: 2),
              ],
              Text(
                '$price ر.س',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPeak
                      ? const Color(0xFFFB923C)
                      : const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
