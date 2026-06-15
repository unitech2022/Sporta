import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../data/match_result_mock_data.dart';

/// Gradient "جدول المباريات" summary card with the round pills
/// (shared by both Americano variants).
class MatchResultScheduleHeader extends StatelessWidget {
  const MatchResultScheduleHeader({
    super.key,
    required this.gradient,
    required this.lightTextColor,
    required this.subtitle,
    required this.schedule,
    required this.mode,
    required this.expandedRound,
    required this.onRoundTap,
    required this.onEdit,
  });

  final List<Color> gradient;

  /// purple-200 / teal-200.
  final Color lightTextColor;
  final String subtitle;
  final List<AmericanoRound> schedule;
  final MatchResultMode mode;
  final int? expandedRound;
  final ValueChanged<int> onRoundTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'جدول المباريات',
                      style: TextStyle(
                          fontSize: 14, color: Colors.white, height: 1.4),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                          fontSize: 12, color: lightTextColor, height: 1.4),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md, vertical: 6),
                    child: Text(
                      'تعديل',
                      style: TextStyle(
                          fontSize: 12, color: lightTextColor, height: 1.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              for (var ri = 0; ri < schedule.length; ri++) ...[
                Expanded(child: _roundPill(ri)),
                if (ri != schedule.length - 1)
                  const SizedBox(width: AppSizes.sm),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundPill(int ri) {
    final round = schedule[ri];
    final done = round.isComplete(mode);
    final isOpen = expandedRound == ri;

    final Color background;
    final Color borderColor;
    final Color textColor;
    if (done) {
      background = MRColors.green500.withValues(alpha: 0.3);
      borderColor = MRColors.green400.withValues(alpha: 0.5);
      textColor = Colors.white;
    } else if (isOpen) {
      background = Colors.white.withValues(alpha: 0.3);
      borderColor = Colors.white.withValues(alpha: 0.5);
      textColor = Colors.white;
    } else {
      background = Colors.white.withValues(alpha: 0.1);
      borderColor = Colors.white.withValues(alpha: 0.2);
      textColor = lightTextColor;
    }

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: () => onRoundTap(ri),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Text(
                'جولة ${round.roundNum}',
                style: TextStyle(fontSize: 12, color: textColor, height: 1.4),
              ),
              if (mode == MatchResultMode.time) ...[
                const SizedBox(height: 2),
                Text(
                  round.timeSlot,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: textColor.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
              if (done) ...[
                const SizedBox(height: 4),
                const Icon(Icons.check_circle_outline,
                    size: 12, color: MRColors.green300),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
