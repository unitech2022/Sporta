import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../data/match_result_mock_data.dart';

/// Expandable round card for the Americano schedules: header with the
/// round number / time slot / "مكتملة" badge, then the court cards and
/// an optional "next round" shortcut.
class MatchResultRoundCard extends StatelessWidget {
  const MatchResultRoundCard({
    super.key,
    required this.round,
    required this.mode,
    required this.isOpen,
    required this.onToggle,
    required this.accent,
    required this.accentLight,
    required this.accentBorder,
    required this.accentText,
    required this.courts,
    this.nextRoundLabel,
    this.onNextRound,
  });

  final AmericanoRound round;
  final MatchResultMode mode;
  final bool isOpen;
  final VoidCallback onToggle;

  /// purple-600 / teal-600.
  final Color accent;

  /// purple-50 / teal-50.
  final Color accentLight;

  /// purple-400 / teal-400.
  final Color accentBorder;

  /// purple-600 / teal-600 text used on the next-round button.
  final Color accentText;

  final List<Widget> courts;
  final String? nextRoundLabel;
  final VoidCallback? onNextRound;

  @override
  Widget build(BuildContext context) {
    final done = round.isComplete(mode);
    final borderColor = done
        ? MRColors.green300
        : isOpen
            ? accentBorder
            : AppColors.border;
    final headerColor = done
        ? MRColors.green50
        : isOpen
            ? accentLight
            : MRColors.gray50;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: borderColor, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: headerColor,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? MRColors.green500 : accent,
                      ),
                      alignment: Alignment.center,
                      child: done
                          ? const Icon(Icons.check_circle_outline,
                              size: 16, color: Colors.white)
                          : Text(
                              '${round.roundNum}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  height: 1),
                            ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الجولة ${round.roundNum}',
                            style: TextStyle(
                              fontSize: 14,
                              color: done
                                  ? MRColors.green700
                                  : AppColors.secondary,
                              height: 1.4,
                            ),
                          ),
                          Text(
                            round.timeSlot,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground,
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    if (done)
                      Container(
                        margin:
                            const EdgeInsetsDirectional.only(end: AppSizes.sm),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: MRColors.green100,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                        ),
                        child: const Text(
                          'مكتملة',
                          style: TextStyle(
                              fontSize: 12,
                              color: MRColors.green600,
                              height: 1.4),
                        ),
                      ),
                    Icon(
                      isOpen
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.mutedForeground,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isOpen)
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < courts.length; i++) ...[
                    courts[i],
                    if (i != courts.length - 1)
                      const SizedBox(height: AppSizes.lg),
                  ],
                  if (nextRoundLabel != null && onNextRound != null) ...[
                    const SizedBox(height: AppSizes.lg),
                    Material(
                      color: accentLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        side: BorderSide(
                            color: accentBorder.withValues(alpha: 0.5)),
                      ),
                      child: InkWell(
                        onTap: onNextRound,
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: AppSizes.sm),
                          child: Center(
                            child: Text(
                              nextRoundLabel!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: accentText,
                                  height: 1.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
