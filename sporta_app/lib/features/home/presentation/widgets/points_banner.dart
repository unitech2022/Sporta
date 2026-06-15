import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Dark starry banner on the player home that opens the points system.
class PointsBanner extends StatelessWidget {
  const PointsBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  static const nightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration:
              const BoxDecoration(gradient: nightGradient),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _BannerStarsPainter()),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Row(
                  children: [
                    Icon(Icons.chevron_left,
                        size: AppSizes.iconMd,
                        color: Colors.white.withValues(alpha: 0.6)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('استكشف نظام النقاط',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: Colors.white)),
                          SizedBox(height: 2),
                          Text('اكسب نقاطاً وارتقِ للمستويات الأعلى ✨',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                  color: const Color(0xFFFACC15))),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFACC15), Color(0xFFF97316)],
                        ),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLg),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEAB308)
                                .withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.emoji_events,
                          color: Colors.white, size: AppSizes.iconLg),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerStarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7);
    for (var i = 0; i < 6; i++) {
      final dx = size.width * ((10 + (i * 14) % 75) / 100);
      final dy = size.height * ((15 + (i * 15) % 70) / 100);
      canvas.drawCircle(Offset(dx, dy), 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BannerStarsPainter oldDelegate) => false;
}
