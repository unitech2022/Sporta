import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../domain/entities/court_entity.dart';
import '../../courts_helpers.dart';
import '../../../../../core/state/app_scope.dart';

/// The court profile header: cover photo (or the brand gradient when the venue
/// hasn't uploaded one) with the name, venue, rating and location on top.
class CourtDetailHero extends StatelessWidget {
  const CourtDetailHero({super.key, required this.court});

  final CourtEntity court;

  /// Height of the cover area, so the page can pin its back button over it.
  static const double height = 280;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _cover(),
          // Scrim: keeps the white text readable over any photo.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.secondary.withValues(alpha: 0.55),
                  AppColors.secondary.withValues(alpha: 0.25),
                  AppColors.secondary.withValues(alpha: 0.92),
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.pagePadding,
                vertical: AppSizes.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Room for the page's pinned back button, which floats
                      // above this header instead of scrolling with it.
                      const SizedBox(width: 36, height: 36),
                      const Spacer(),
                      Flexible(
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: AppSizes.xs,
                          runSpacing: AppSizes.xs,
                          children: [
                            _glassBadge(
                              icon: court.type == CourtType.indoor
                                  ? Icons.roofing_rounded
                                  : Icons.wb_sunny_outlined,
                              label: courtTypeLabel(court.type),
                            ),
                            _glassBadge(
                              icon: Icons.people_outline_rounded,
                              label: courtGenderLabel(court.gender),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    court.name,
                    style: AppTextStyles.heading1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (court.venueName.isNotEmpty &&
                      court.venueName != court.name) ...[
                    const SizedBox(height: 2),
                    _iconLine(Icons.stadium_outlined, court.venueName),
                  ],
                  const SizedBox(height: AppSizes.xs),
                  _iconLine(Icons.location_on_outlined, _locationLine()),
                  const SizedBox(height: AppSizes.md),
                  // Wrap, not Row: three badges with long labels would
                  // otherwise overflow on narrow phones.
                  Wrap(
                    spacing: AppSizes.xs,
                    runSpacing: AppSizes.xs,
                    children: [
                      if (court.rating > 0)
                        _glassBadge(
                          icon: Icons.star_rounded,
                          label: '${court.rating.toStringAsFixed(1)}'
                              ' (${court.reviews})',
                          iconColor: const Color(0xFFFACC15),
                        )
                      else
                        _glassBadge(
                          icon: Icons.star_border_rounded,
                          label: context.tr('جديد'),
                        ),
                      if (court.distance.isNotEmpty)
                        _glassBadge(
                          icon: Icons.near_me_outlined,
                          label: court.distance,
                        ),
                      if (court.courtCount > 1)
                        _glassBadge(
                          icon: Icons.grid_view_rounded,
                          label: context.trArgs('{p0} ملاعب', {'p0': court.courtCount}),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cover() {
    final url = court.imageUrl;
    if (url == null) return const _GradientCover();
    return Image.network(
      ApiEndpoints.fileUrl(url),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _GradientCover(),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const _GradientCover(),
    );
  }

  /// المدينة، الحي والعنوان — كل ما هو متوفر منها.
  String _locationLine() => [court.city, court.district, court.neighborhood]
      .where((s) => s.trim().isNotEmpty)
      .toSet()
      .join(' · ');

  Widget _iconLine(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, size: AppSizes.iconSm, color: Colors.white70),
        const SizedBox(width: AppSizes.xs),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _glassBadge({
    required IconData icon,
    required String label,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor ?? Colors.white, size: AppSizes.iconSm),
          const SizedBox(width: AppSizes.xs),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fallback cover for venues without a photo.
class _GradientCover extends StatelessWidget {
  const _GradientCover();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Center(
        child: Icon(
          Icons.sports_tennis_rounded,
          size: 72,
          color: Colors.white.withValues(alpha: 0.22),
        ),
      ),
    );
  }
}
