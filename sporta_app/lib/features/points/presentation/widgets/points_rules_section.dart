import 'package:flutter/material.dart';
import 'package:sporta_app/core/state/app_scope.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/points_entity.dart';

/// «كيف أكسب نقاط المكافآت؟» — شبكة بطاقات لكل نشاط وقيمته من الخادم.
class RewardRulesSection extends StatelessWidget {
  const RewardRulesSection({super.key, required this.summary});

  final PointsSummaryEntity summary;

  static IconData _iconFor(String key) => switch (key) {
        'reward_points_booking' => Icons.calendar_month_rounded,
        'reward_points_coach_session' => Icons.school_rounded,
        'reward_points_match_created' => Icons.sports_tennis_rounded,
        'reward_points_americano' => Icons.sync_alt_rounded,
        'reward_points_tournament' => Icons.emoji_events_rounded,
        'reward_points_invite_friend' => Icons.person_add_alt_1_rounded,
        'reward_points_rate_court' => Icons.star_rate_rounded,
        'reward_points_rate_coach' => Icons.rate_review_rounded,
        _ => Icons.add_circle_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final rules = summary.rewardRules.where((r) => r.points > 0).toList();
    return _Card(
      icon: Icons.stars_rounded,
      iconColor: const Color(0xFFEAB308),
      title: context.tr('كيف أكسب نقاط المكافآت؟'),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            primary: false,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSizes.sm,
              crossAxisSpacing: AppSizes.sm,
              childAspectRatio: 2.4,
            ),
            itemCount: rules.length,
            itemBuilder: (context, i) => _RewardTile(
              icon: _iconFor(rules[i].key),
              label: rules[i].label,
              points: rules[i].points,
            ),
          ),
          const Divider(height: AppSizes.xl),
          Row(
            children: [
              const Icon(Icons.swap_horiz_rounded,
                  size: 20, color: AppColors.secondary),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Text(
                  context.trArgs('{p0} نقطة تتحول إلى {p1} ريال رصيداً في المحفظة', {
                    'p0': summary.minRedeemPoints,
                    'p1': summary.redeemPointsPerRiyal <= 0
                        ? 0
                        : (summary.minRedeemPoints / summary.redeemPointsPerRiyal)
                            .round(),
                  }),
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile(
      {required this.icon, required this.label, required this.points});

  final IconData icon;
  final String label;
  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.secondary)),
          ),
          Text('+$points',
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.success, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// «نقاط المستوى» — عمودا الفوز والخسارة بحسب فرق المستوى، وشرط اعتماد المدرب.
class LevelRulesSection extends StatelessWidget {
  const LevelRulesSection({super.key, required this.summary});

  final PointsSummaryEntity summary;

  @override
  Widget build(BuildContext context) {
    final wins = summary.levelRules
        .where((r) => r.key.startsWith('level_points_win'))
        .toList();
    final losses = summary.levelRules
        .where((r) => r.key.startsWith('level_points_loss'))
        .toList();

    return _Card(
      icon: Icons.trending_up_rounded,
      iconColor: AppColors.primary,
      title: context.tr('نقاط المستوى'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary.levelPointsRequireCoachVerification)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.md),
              margin: const EdgeInsets.only(bottom: AppSizes.md),
              decoration: BoxDecoration(
                color: (summary.levelCoachVerified
                        ? AppColors.success
                        : const Color(0xFFF59E0B))
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Row(
                children: [
                  Icon(
                    summary.levelCoachVerified
                        ? Icons.verified_rounded
                        : Icons.lock_outline_rounded,
                    size: 20,
                    color: summary.levelCoachVerified
                        ? AppColors.success
                        : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      summary.levelCoachVerified
                          ? context.tr('مستواك معتمد من مدرب — نتائج مباراتك تحرّك نقاط مستواك')
                          : context.tr('لدخول نظام نقاط المستوى يلزم اعتماد مستواك من أحد المدربين في التطبيق'),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.secondary),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            context.tr('تُحسب بحسب فرق المستوى بينك وبين خصمك؛ وفي الزوجي يُقارن متوسط مستوى الفريقين.'),
            style: AppTextStyles.caption.copyWith(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _RuleColumn(title: context.tr('فوز'), rules: wins, positive: true)),
              const SizedBox(width: AppSizes.sm),
              Expanded(child: _RuleColumn(title: context.tr('خسارة'), rules: losses, positive: false)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RuleColumn extends StatelessWidget {
  const _RuleColumn(
      {required this.title, required this.rules, required this.positive});

  final String title;
  final List<PointsRuleEntity> rules;
  final bool positive;

  /// «فوز على خصم بنفس المستوى» → «بنفس المستوى»: العنوان يحمل النتيجة.
  static String _short(String label) => label
      .replaceFirst(RegExp(r'^(فوز على خصم|خسارة أمام خصم|Win vs|Loss vs)\s*'), '')
      .trim();

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppColors.success : AppColors.destructive;
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.xs, vertical: AppSizes.xs),
            child: Text(title,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: color, fontWeight: FontWeight.w700)),
          ),
          for (final r in rules)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.xs, vertical: AppSizes.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_short(r.label),
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.secondary)),
                  ),
                  Text(r.points > 0 ? '+${r.points}' : '${r.points}',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: color, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: AppSizes.sm),
              Expanded(child: Text(title, style: AppTextStyles.heading3)),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          child,
        ],
      ),
    );
  }
}
