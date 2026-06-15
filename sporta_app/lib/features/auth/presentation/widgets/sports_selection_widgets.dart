import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Decorative starfield painted behind the sports-selection screen.
class SportsStarsBackground extends StatelessWidget {
  const SportsStarsBackground({super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _StarsPainter());
}

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < 20; i++) {
      final dx = size.width * ((3 + (i * 17.3) % 94) / 100);
      final dy = size.height * ((5 + (i * 13.7) % 80) / 100);
      paint.color = Colors.white.withValues(alpha: 0.3 + (i % 4) * 0.15);
      canvas.drawCircle(Offset(dx, dy), i % 3 == 0 ? 1.5 : 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) => false;
}

/// Pill badge shown at the top of the sports-selection screen.
class SportsHeaderBadge extends StatelessWidget {
  const SportsHeaderBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Text(
              label,
              style: AppTextStyles.caption
                  .copyWith(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A selectable sport card. Unavailable sports are dimmed and not tappable.
class SportCard extends StatelessWidget {
  const SportCard({
    super.key,
    required this.emoji,
    required this.nameAr,
    required this.nameEn,
    required this.available,
    this.onTap,
  });

  final String emoji;
  final String nameAr;
  final String nameEn;
  final bool available;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: available
          ? AppColors.primary.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl + 8),
        side: BorderSide(
          color: available
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl + 8),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xxl),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _AvailabilityTag(available: available),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: AppSizes.md),
              Text(
                nameAr,
                style: AppTextStyles.body.copyWith(
                  color: available
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ),
              Text(
                nameEn,
                style: AppTextStyles.caption.copyWith(
                  color: available
                      ? AppColors.primary.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return available ? card : Opacity(opacity: 0.7, child: card);
  }
}

class _AvailabilityTag extends StatelessWidget {
  const _AvailabilityTag({required this.available});

  final bool available;

  @override
  Widget build(BuildContext context) {
    final color =
        available ? AppColors.primary : Colors.white.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: available
            ? AppColors.primary.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(
          color: available
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        available ? 'متاح' : 'قريباً',
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }
}

/// "Coming soon" row teasing additional sports.
class ComingSoonRow extends StatelessWidget {
  const ComingSoonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.xs,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFA855F7).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              border: Border.all(
                color: const Color(0xFFA855F7).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'قريباً',
              style:
                  AppTextStyles.caption.copyWith(color: const Color(0xFFD8B4FE)),
            ),
          ),
          Row(
            children: [
              const _MiniSportCircle(emoji: '🎾', color: Color(0xFFEAB308)),
              const SizedBox(width: AppSizes.xs),
              const _MiniSportCircle(emoji: '🏀', color: Color(0xFFF97316)),
              const SizedBox(width: AppSizes.xs),
              const _MiniSportCircle(emoji: '🏊', color: Color(0xFF3B82F6)),
              const SizedBox(width: AppSizes.xs),
              _MiniSportCircle(
                emoji: '+',
                color: Colors.white.withValues(alpha: 0.4),
              ),
              const SizedBox(width: AppSizes.md),
              Text(
                'رياضات أخرى',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniSportCircle extends StatelessWidget {
  const _MiniSportCircle({required this.emoji, required this.color});

  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 16)),
    );
  }
}
