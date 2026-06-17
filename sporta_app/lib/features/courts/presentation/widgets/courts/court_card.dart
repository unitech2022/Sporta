import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../domain/entities/court_entity.dart';
import '../../courts_helpers.dart';

/// A court summary card in the courts list with a favorite toggle and a
/// "book now" action.
class CourtCard extends StatelessWidget {
  const CourtCard({
    super.key,
    required this.court,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onBookTap,
  });

  final CourtEntity court;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onBookTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: AppCard(
        padding: EdgeInsets.zero,
        radius: AppSizes.radiusXl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCover(),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildCover() {
    return Stack(
      children: [
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppSizes.radiusXl),
              topRight: Radius.circular(AppSizes.radiusXl),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sports_tennis_rounded,
                  size: 48,
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  court.name,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: AppSizes.sm,
          left: AppSizes.sm,
          child: GestureDetector(
            onTap: onFavoriteTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: AppSizes.iconMd,
                color: isFavorite ? Colors.red : AppColors.mutedForeground,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            court.name,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  size: AppSizes.iconSm, color: Color(0xFFFACC15)),
              const SizedBox(width: 2),
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
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Wrap(
            spacing: AppSizes.xs,
            runSpacing: AppSizes.xs,
            children: [
              _InfoBadge(
                icon: Icons.location_on_outlined,
                label: '${court.distance} · ${court.city}',
              ),
              _InfoBadge(
                icon: court.type == CourtType.indoor
                    ? Icons.roofing_rounded
                    : Icons.wb_sunny_outlined,
                label: courtTypeLabel(court.type),
              ),
              _InfoBadge(
                icon: Icons.people_outline_rounded,
                label: courtGenderLabel(court.gender),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'يبدأ من',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedForeground),
                  ),
                  Text(
                    '${court.basePrice} ر.س',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: onBookTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                    vertical: AppSizes.sm,
                  ),
                ),
                child: const Text('احجز الآن'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.mutedForeground),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
