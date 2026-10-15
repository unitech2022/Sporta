import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../domain/entities/cup_entity.dart';
import 'cup_fixture_card.dart';

/// تبويب النتائج: بطاقة البطل والترتيب النهائي بعد الاكتمال، ثم النتائج
/// مقسّمة بالمرحلة — دور المجموعات (تحت عنوان كل مجموعة)، ثم كل دور إقصائي
/// (دور الـ16، ربع النهائي، نصف النهائي، النهائي) — بشريط اختيار للمرحلة.
class CupResultsTab extends StatefulWidget {
  const CupResultsTab({super.key, required this.cup});

  final CupEntity cup;

  @override
  State<CupResultsTab> createState() => _CupResultsTabState();
}

/// مرحلة في شريط النتائج: دور المجموعات أو دور إقصائي واحد.
class _Stage {
  const _Stage(this.key, this.label, this.fixtures);

  /// 'group' أو 'ko-{round}'.
  final String key;
  final String label;
  final List<CupFixture> fixtures;
}

class _CupResultsTabState extends State<CupResultsTab> {
  String? _selected;

  CupEntity get cup => widget.cup;

  /// المراحل التي فيها نتيجة واحدة على الأقل، بترتيب البطولة.
  List<_Stage> _stages(BuildContext context) {
    final done = cup.completedFixtures;
    final stages = <_Stage>[];
    final group = done.where((f) => f.isGroup).toList();
    if (group.isNotEmpty) {
      stages.add(_Stage('group', context.tr('دور المجموعات'), group));
    }
    for (final r in cup.knockoutRounds) {
      final list = done.where((f) => !f.isGroup && f.round == r).toList()
        ..sort((a, b) => a.index.compareTo(b.index));
      if (list.isEmpty) continue;
      stages.add(_Stage('ko-$r', list.first.roundName, list));
    }
    return stages;
  }

  @override
  Widget build(BuildContext context) {
    final stages = _stages(context);
    // الافتراضي: آخر مرحلة لُعبت — أحدث النتائج أولاً.
    final current = stages.isEmpty
        ? null
        : stages.firstWhere(
            (s) => s.key == _selected,
            orElse: () => stages.last,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cup.isCompleted && cup.championName != null) ...[
          _championCard(context),
          const SizedBox(height: AppSizes.lg),
        ],
        if (cup.ranking.isNotEmpty) ...[
          Text(
            context.tr('الترتيب النهائي'),
            style: AppTextStyles.heading3.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.sm),
          _rankingCard(context),
          const SizedBox(height: AppSizes.lg),
        ],
        Row(
          children: [
            Text(
              context.tr('النتائج'),
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.secondary,
              ),
            ),
            const Spacer(),
            Text(
              '${cup.playedMatches} / ${cup.totalMatches}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        if (current == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              context.tr('لم تُسجَّل أي نتيجة بعد.'),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          )
        else ...[
          _stageChips(stages, current),
          const SizedBox(height: AppSizes.md),
          if (current.key == 'group')
            ..._groupSections(context, current.fixtures)
          else
            for (final f in current.fixtures) ...[
              CupFixtureCard(fixture: f, saving: false, onSubmit: (_, _) {}),
              const SizedBox(height: AppSizes.sm),
            ],
        ],
      ],
    );
  }

  /// شريط المراحل: حبّة لكل مرحلة مع عدد نتائجها.
  Widget _stageChips(List<_Stage> stages, _Stage current) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final s in stages) ...[
              ChoiceChip(
                label: Text('${s.label} (${s.fixtures.length})'),
                selected: s.key == current.key,
                onSelected: (_) => setState(() => _selected = s.key),
                selectedColor: AppColors.primary,
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  color: s.key == current.key
                      ? Colors.white
                      : AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: s.key == current.key
                      ? AppColors.primary
                      : AppColors.border,
                ),
                showCheckmark: false,
              ),
              const SizedBox(width: AppSizes.sm),
            ],
          ],
        ),
      );

  /// نتائج دور المجموعات: عنوان لكل مجموعة ثم مبارياتها بترتيب الجولات.
  List<Widget> _groupSections(BuildContext context, List<CupFixture> fixtures) {
    final byGroup = <int, List<CupFixture>>{};
    for (final f in fixtures) {
      byGroup.putIfAbsent(f.groupIndex ?? 0, () => []).add(f);
    }
    final keys = byGroup.keys.toList()..sort();
    return [
      for (final g in keys) ...[
        Padding(
          padding: const EdgeInsets.only(top: AppSizes.sm, bottom: AppSizes.sm),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                context.trArgs('المجموعة {p0}', {
                  'p0': byGroup[g]!.first.groupLetter ?? '',
                }),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        for (final f
            in (byGroup[g]!..sort(
              (a, b) => a.round != b.round
                  ? a.round.compareTo(b.round)
                  : a.index.compareTo(b.index),
            ))) ...[
          CupFixtureCard(
            fixture: f,
            saving: false,
            label: f.roundName,
            onSubmit: (_, _) {},
          ),
          const SizedBox(height: AppSizes.sm),
        ],
      ],
    ];
  }

  Widget _championCard(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSizes.lg),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFF7DB), Color(0xFFFDE9A6)],
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
      ),
      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      border: Border.all(color: AppColors.brandGold),
    ),
    child: Row(
      children: [
        const Icon(Icons.emoji_events, color: Color(0xFFB8860B), size: 40),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('بطل البطولة'),
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFF8A6508),
                ),
              ),
              Text(
                context.trArgs('فريق {p0}', {'p0': cup.championName!}),
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              if ((cup.championPlayers ?? '').isNotEmpty)
                Text(
                  cup.championPlayers!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF8A6508),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _rankingCard(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        for (var i = 0; i < cup.ranking.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          _rankRow(context, cup.ranking[i]),
        ],
      ],
    ),
  );

  Widget _rankRow(BuildContext context, CupRankingRow r) {
    final color = switch (r.rank) {
      1 => AppColors.brandGold,
      2 => const Color(0xFF9CA3AF),
      3 => const Color(0xFFCD7F32),
      _ => AppColors.muted,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              '${r.rank}',
              style: AppTextStyles.bodySmall.copyWith(
                color: r.rank <= 3 ? Colors.white : AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (r.playerNames.isNotEmpty)
                  Text(
                    r.playerNames,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                Text(
                  r.note,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
