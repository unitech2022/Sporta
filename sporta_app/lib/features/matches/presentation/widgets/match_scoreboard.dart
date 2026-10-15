import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/state/app_scope.dart';
import '../../domain/entities/match_entity.dart';

/// نتيجة اللاعب في مباراة معتمدة: فوز أو خسارة أو تعادل، وnull إن لم يكن
/// فيها أو لم تُعرف فرقها.
enum MatchOutcome { win, loss, draw }

MatchOutcome? outcomeFor(MatchEntity m, int userId) {
  final s1 = m.team1Score, s2 = m.team2Score;
  if (s1 == null || s2 == null) return null;
  final team = m.players.where((p) => p.userId == userId).firstOrNull?.team;
  if (team == null) return null;
  if (s1 == s2) return MatchOutcome.draw;
  return (s1 > s2) == (team == 1) ? MatchOutcome.win : MatchOutcome.loss;
}

/// لوحة النتيجة المعتمدة: الفريقان بأسماء لاعبيهما ونتيجة كل منهما، والفائز
/// مُبرَز، وشارة «فزت/خسرت» للاعب نفسه.
class MatchScoreboard extends StatelessWidget {
  const MatchScoreboard({
    super.key,
    required this.match,
    required this.currentUserId,
  });

  final MatchEntity match;
  final int currentUserId;

  String _names(BuildContext context, int team) {
    final names = match.players
        .where((p) => p.status == 'approved' && p.team == team)
        .map((p) => p.userId == currentUserId ? context.tr('أنت') : p.name)
        .toList();
    return names.isEmpty
        ? trgArgs('الفريق {n}', {'n': team})
        : names.join(trg(' و '));
  }

  @override
  Widget build(BuildContext context) {
    final s1 = match.team1Score ?? 0, s2 = match.team2Score ?? 0;
    final winner = s1 == s2 ? null : (s1 > s2 ? 1 : 2);
    final outcome = outcomeFor(match, currentUserId);
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.scoreboard_outlined,
                size: AppSizes.iconSm,
                color: AppColors.success,
              ),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: Text(
                  context.tr('النتيجة النهائية'),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (outcome != null) OutcomePill(outcome: outcome),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          _row(context, 1, s1, winner == 1),
          const SizedBox(height: AppSizes.sm),
          _row(context, 2, s2, winner == 2),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, int team, int score, bool won) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: won
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          if (won) ...[
            const Icon(
              Icons.emoji_events,
              size: AppSizes.iconSm,
              color: AppColors.brandGold,
            ),
            const SizedBox(width: AppSizes.xs),
          ],
          Expanded(
            child: Text(
              _names(context, team),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondary,
                fontWeight: won ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$score',
            style: AppTextStyles.heading2.copyWith(
              color: won ? AppColors.success : AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// شارة «فزت / خسرت / تعادل».
class OutcomePill extends StatelessWidget {
  const OutcomePill({super.key, required this.outcome});

  final MatchOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (outcome) {
      MatchOutcome.win => (context.tr('فزت'), AppColors.success),
      MatchOutcome.loss => (context.tr('خسرت'), AppColors.destructive),
      MatchOutcome.draw => (context.tr('تعادل'), AppColors.mutedForeground),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
