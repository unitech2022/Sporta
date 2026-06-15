import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../data/match_result_mock_data.dart';

/// Gradient celebration banner shown at the top of the Americano
/// success screens: trophy, champion name, avatars and a stats strip.
class MatchResultWinnerBanner extends StatelessWidget {
  const MatchResultWinnerBanner({
    super.key,
    required this.gradient,
    required this.lightTextColor,
    required this.caption,
    required this.championTitle,
    required this.championAvatars,
    required this.points,
    required this.percent,
    required this.matchesCount,
    required this.onBack,
    this.championSubtitle,
  });

  final List<Color> gradient;

  /// purple-200 / teal-200.
  final Color lightTextColor;

  /// e.g. 'الفائز بالأمريكانو'.
  final String caption;
  final String championTitle;
  final String? championSubtitle;
  final Widget championAvatars;
  final int points;
  final int percent;
  final int matchesCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: gradient,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // دوائر زخرفية
          PositionedDirectional(
              top: -32, start: -32, child: _circle(160)),
          PositionedDirectional(top: 16, end: -24, child: _circle(96)),
          Positioned(
            bottom: -180,
            left: 0,
            right: 0,
            child: Center(child: _circle(256)),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                AppSizes.xxxl,
                AppSizes.pagePadding,
                40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: onBack,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(AppSizes.sm),
                        child: Icon(Icons.arrow_back,
                            size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  Center(
                    child: Column(
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 44)),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          caption,
                          style: TextStyle(
                            fontSize: 12,
                            color: lightTextColor,
                            letterSpacing: 3,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          championTitle,
                          style: const TextStyle(
                              fontSize: 30, color: Colors.white, height: 1.3),
                        ),
                        if (championSubtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            championSubtitle!,
                            style: TextStyle(
                                fontSize: 14,
                                color: lightTextColor,
                                height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),
                  Center(child: championAvatars),
                  const SizedBox(height: AppSizes.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _stat('$points', 'نقطة'),
                        _divider(),
                        _stat('$percent%', 'من المجموع'),
                        _divider(),
                        _stat('$matchesCount', 'مباراة'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.05),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
                fontSize: 20, color: MRColors.yellow300, height: 1.4),
          ),
          Text(
            label,
            style:
                TextStyle(fontSize: 12, color: lightTextColor, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}
