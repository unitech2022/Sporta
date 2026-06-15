import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../data/match_result_mock_data.dart';

const List<String> mrMedals = [
  '🥇',
  '🥈',
  '🥉',
  '4️⃣',
  '5️⃣',
  '6️⃣',
  '7️⃣',
  '8️⃣',
];

/// One ranked row of the live standings card.
class MatchResultStandingsEntry {
  const MatchResultStandingsEntry({
    required this.id,
    required this.leading,
    required this.title,
    required this.points,
    required this.fraction,
    this.badgeText,
    this.badgeColors,
  });

  final String id;
  final Widget leading;
  final String title;
  final int points;

  /// 0..1 width of the progress bar.
  final double fraction;
  final String? badgeText;
  final TeamAccentColors? badgeColors;
}

/// Live "ترتيب الفرق / ترتيب اللاعبين" card shown once any score is
/// entered (TSX live standings with progress bars).
class MatchResultStandingsCard extends StatelessWidget {
  const MatchResultStandingsCard({
    super.key,
    required this.title,
    required this.entries,
    required this.accent,
    required this.accentLight,
    required this.accentBorder,
    required this.accentText,
    required this.rankGradients,
    this.showCompleteNotice = false,
  });

  final String title;
  final List<MatchResultStandingsEntry> entries;

  /// purple-600 / teal-600.
  final Color accent;

  /// purple-50 / teal-50.
  final Color accentLight;

  /// purple-200 / teal-200.
  final Color accentBorder;

  /// purple-700 / teal-700.
  final Color accentText;

  /// Bar gradient per rank index; ranks beyond the list use gray.
  final List<List<Color>> rankGradients;
  final bool showCompleteNotice;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: accentBorder, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.xl, vertical: AppSizes.md),
            decoration: BoxDecoration(
              color: accentLight,
              border: Border(bottom: BorderSide(color: accentBorder)),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events_outlined, size: 16, color: accent),
                const SizedBox(width: AppSizes.sm),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.secondary, height: 1.4),
                ),
                const Spacer(),
                const Text(
                  'يتحدث تلقائياً',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                      height: 1.4),
                ),
              ],
            ),
          ),
          for (var i = 0; i < entries.length; i++) _row(i),
          if (showCompleteNotice)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg, vertical: AppSizes.md),
              decoration: BoxDecoration(
                color: accentLight,
                border: Border(top: BorderSide(color: accentBorder)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 14, color: accentText),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'اكتملت جميع المباريات — جاهز لتسجيل النتيجة النهائية',
                      style: TextStyle(
                          fontSize: 12, color: accentText, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(int i) {
    final e = entries[i];
    final leadingTop = i == 0 && e.points > 0;
    final gradient = leadingTop
        ? const [MRColors.yellow400, MRColors.yellow500]
        : i < rankGradients.length
            ? rankGradients[i]
            : const [MRColors.gray300, MRColors.gray300];

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: 14),
      decoration: BoxDecoration(
        color: leadingTop ? MRColors.yellow50 : null,
        border: i == 0
            ? null
            : const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Center(
              child: e.points > 0
                  ? Text(mrMedals[i], style: const TextStyle(fontSize: 18))
                  : Text(
                      '${i + 1}',
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.mutedForeground,
                          height: 1.4),
                    ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          e.leading,
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        e.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.secondary,
                            height: 1.4),
                      ),
                    ),
                    if (e.badgeText != null) ...[
                      const SizedBox(width: AppSizes.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color:
                              e.badgeColors?.background ?? MRColors.gray100,
                          border: Border.all(
                              color: e.badgeColors?.border ??
                                  AppColors.border),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                        ),
                        child: Text(
                          e.badgeText!,
                          style: TextStyle(
                            fontSize: 10,
                            color: e.badgeColors?.text ??
                                AppColors.mutedForeground,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  child: Container(
                    height: 7,
                    color: MRColors.gray100,
                    child: FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: e.fraction.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: AlignmentDirectional.centerStart,
                            end: AlignmentDirectional.centerEnd,
                            colors: gradient,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Text.rich(
            TextSpan(
              text: '${e.points}',
              style: TextStyle(
                fontSize: 14,
                color: leadingTop ? MRColors.yellow600 : AppColors.secondary,
                height: 1.4,
              ),
              children: const [
                TextSpan(
                  text: ' نقطة',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
