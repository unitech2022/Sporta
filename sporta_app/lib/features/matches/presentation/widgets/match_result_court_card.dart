import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../data/match_result_mock_data.dart';
import 'match_result_score_input.dart';

/// One court inside an Americano round: header (ملعب + فرق المستوى),
/// score entry (time mode) or set rows (sets mode) and the winner line.
/// Side A is tinted with the page accent, side B with orange.
class MatchResultCourtCard extends StatelessWidget {
  const MatchResultCourtCard({
    super.key,
    required this.label,
    required this.levelDiffLabel,
    required this.mode,
    required this.match,
    required this.sideA,
    required this.sideB,
    required this.winnerALabel,
    required this.winnerBLabel,
    required this.accent,
    required this.accentLight,
    required this.accentSoftBg,
    required this.accentText,
    required this.onScoreAChanged,
    required this.onScoreBChanged,
    required this.onSetChanged,
  });

  final String label;
  final String levelDiffLabel;
  final MatchResultMode mode;
  final AmericanoMatch match;
  final Widget sideA;
  final Widget sideB;

  /// Label used in the "🏆 فاز ..." line for each side.
  final String winnerALabel;
  final String winnerBLabel;

  /// purple-400 / teal-400 (winning border).
  final Color accent;

  /// purple-50 / teal-50 (winning fill).
  final Color accentLight;

  /// purple-100 / teal-100 (winner line background).
  final Color accentSoftBg;

  /// purple-700 / teal-700 (winning text).
  final Color accentText;

  final ValueChanged<String> onScoreAChanged;
  final ValueChanged<String> onScoreBChanged;
  final void Function(int setIndex, bool isSideA, String value) onSetChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _courtHeader(),
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (mode == MatchResultMode.time) _timeEntry(),
                if (mode == MatchResultMode.sets) _setsEntry(),
                ..._winnerLine(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _courtHeader() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 8),
      decoration: const BoxDecoration(
        color: MRColors.gray50,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.mutedForeground, height: 1.4),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Text(
              'فرق المستوى: $levelDiffLabel',
              style: const TextStyle(
                  fontSize: 10, color: AppColors.mutedForeground, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeEntry() {
    final hasBoth = match.scoreA.isNotEmpty && match.scoreB.isNotEmpty;
    final a = int.tryParse(match.scoreA) ?? 0;
    final b = int.tryParse(match.scoreB) ?? 0;

    Color? borderA;
    Color? fillA;
    Color? textA;
    Color? borderB;
    Color? fillB;
    Color? textB;
    if (hasBoth) {
      if (a > b) {
        borderA = accent;
        fillA = accentLight;
        textA = accentText;
        borderB = MRColors.gray200;
        textB = MRColors.gray400;
      } else if (b > a) {
        borderB = MRColors.orange400;
        fillB = MRColors.orange50;
        textB = MRColors.orange700;
        borderA = MRColors.gray200;
        textA = MRColors.gray400;
      } else {
        borderA = MRColors.gray200;
        borderB = MRColors.gray200;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            children: [
              sideA,
              const SizedBox(height: AppSizes.sm),
              MatchResultScoreInput(
                key: ValueKey('${match.id}-A'),
                value: match.scoreA,
                onChanged: onScoreAChanged,
                focusBorderColor: accent,
                borderColor: borderA,
                fillColor: fillA,
                textColor: textA,
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.sm),
          child: Column(
            children: [
              Icon(Icons.sports_kabaddi,
                  size: 16, color: AppColors.mutedForeground),
              SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'vs',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                      height: 1.4),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              sideB,
              const SizedBox(height: AppSizes.sm),
              MatchResultScoreInput(
                key: ValueKey('${match.id}-B'),
                value: match.scoreB,
                onChanged: onScoreBChanged,
                focusBorderColor: MRColors.orange400,
                borderColor: borderB,
                fillColor: fillB,
                textColor: textB,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _setsEntry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Center(child: sideA)),
            const Expanded(
              child: Icon(Icons.sports_kabaddi,
                  size: 16, color: AppColors.mutedForeground),
            ),
            Expanded(child: Center(child: sideB)),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        for (var si = 0; si < match.sets.length; si++) ...[
          _setRow(si),
          if (si != match.sets.length - 1) const SizedBox(height: AppSizes.sm),
        ],
      ],
    );
  }

  Widget _setRow(int si) {
    final s = match.sets[si];
    final filled = s.sA.isNotEmpty && s.sB.isNotEmpty;
    final aWin =
        filled && (int.tryParse(s.sA) ?? 0) > (int.tryParse(s.sB) ?? 0);
    final bWin =
        filled && (int.tryParse(s.sB) ?? 0) > (int.tryParse(s.sA) ?? 0);

    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: aWin
            ? accentLight
            : bWin
                ? MRColors.orange50
                : MRColors.gray50,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: MatchResultScoreInput(
              key: ValueKey('${match.id}-s$si-A'),
              value: s.sA,
              onChanged: (v) => onSetChanged(si, true, v),
              focusBorderColor: accent,
              borderColor: aWin ? accent : AppColors.border,
              textColor: aWin ? accentText : AppColors.secondary,
              large: false,
              maxLength: 2,
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Text(
                  'ش ${si + 1}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                      height: 1.4),
                ),
              ),
            ),
          ),
          Expanded(
            child: MatchResultScoreInput(
              key: ValueKey('${match.id}-s$si-B'),
              value: s.sB,
              onChanged: (v) => onSetChanged(si, false, v),
              focusBorderColor: MRColors.orange400,
              borderColor: bWin ? MRColors.orange400 : AppColors.border,
              textColor: bWin ? MRColors.orange700 : AppColors.secondary,
              large: false,
              maxLength: 2,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _winnerLine() {
    if (!match.hasScores(mode)) return const [];
    final aTotal = match.totalA(mode);
    final bTotal = match.totalB(mode);

    final Color bg;
    final Color fg;
    final String text;
    if (aTotal > bTotal) {
      bg = accentSoftBg;
      fg = accentText;
      text = '🏆 فاز $winnerALabel ($aTotal – $bTotal)';
    } else if (bTotal > aTotal) {
      bg = MRColors.orange100;
      fg = MRColors.orange700;
      text = '🏆 فاز $winnerBLabel ($bTotal – $aTotal)';
    } else {
      bg = MRColors.gray100;
      fg = AppColors.mutedForeground;
      text = 'تعادل ($aTotal – $bTotal)';
    }

    return [
      const SizedBox(height: AppSizes.sm),
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12,
              color: fg,
              fontWeight: FontWeight.w500,
              height: 1.4),
        ),
      ),
    ];
  }
}
