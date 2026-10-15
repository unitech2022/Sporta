import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../domain/entities/cup_entity.dart';
import 'cup_fixture_card.dart';

/// تبويب المجموعات: لكل مجموعة جدول ترتيب (لعب/فاز/نقاط) ثم مبارياتها.
class CupGroupsTab extends StatelessWidget {
  const CupGroupsTab({
    super.key,
    required this.cup,
    required this.myTeam,
    required this.savingFixtureId,
    required this.onSubmit,
    required this.onRespond,
    this.onResolve,
    this.onRecord,
  });

  final CupEntity cup;

  /// فريق المستخدم في البطولة — لاعبو طرفَي المباراة فقط يُدخلون نتيجتها.
  final int? myTeam;
  final int? savingFixtureId;
  final void Function(int fixtureId, int t1, int t2) onSubmit;
  final void Function(int fixtureId, bool accept) onRespond;

  /// للمنظّم فقط: حسم خلاف على نتيجة مباراة.
  final void Function(int fixtureId, int t1, int t2)? onResolve;

  /// للمنظّم فقط: تسجيل نتيجة مباراة مرّ موعدها أو فوز بالانسحاب.
  final void Function(int fixtureId, int t1, int t2, bool walkover)? onRecord;

  @override
  Widget build(BuildContext context) {
    if (!cup.isDrawn) {
      return _note(
        context,
        context.tr('تُشكَّل المجموعات تلقائياً بالقرعة عند اكتمال الفرق.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cup.pathText,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        for (final g in cup.groups) ...[
          _GroupCard(
            group: g,
            fixtures: cup.groupFixtures
                .where((f) => f.groupIndex == g.index)
                .toList(),
            myTeam: myTeam,
            savingFixtureId: savingFixtureId,
            onSubmit: onSubmit,
            onRespond: onRespond,
            onResolve: onResolve,
            onRecord: onRecord,
            eventStart: cup.scheduledAt,
          ),
          const SizedBox(height: AppSizes.md),
        ],
      ],
    );
  }

  static Widget _note(BuildContext context, String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSizes.lg),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(
      text,
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.mutedForeground),
    ),
  );
}

class _GroupCard extends StatefulWidget {
  const _GroupCard({
    required this.group,
    required this.fixtures,
    required this.myTeam,
    required this.savingFixtureId,
    required this.onSubmit,
    required this.onRespond,
    this.onResolve,
    this.onRecord,
    this.eventStart,
  });

  final CupGroup group;
  final List<CupFixture> fixtures;
  final int? myTeam;
  final int? savingFixtureId;
  final void Function(int fixtureId, int t1, int t2) onSubmit;
  final void Function(int fixtureId, bool accept) onRespond;

  /// للمنظّم فقط: حسم خلاف على نتيجة مباراة.
  final void Function(int fixtureId, int t1, int t2)? onResolve;

  /// للمنظّم فقط: تسجيل نتيجة مباراة مرّ موعدها أو فوز بالانسحاب.
  final void Function(int fixtureId, int t1, int t2, bool walkover)? onRecord;

  /// موعد البطولة — بديل موعد المباراة غير المحدَّد.
  final DateTime? eventStart;

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  bool _showMatches = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.lg,
              AppSizes.md,
              AppSizes.lg,
              AppSizes.sm,
            ),
            child: Row(
              children: [
                Text(
                  g.title,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: g.isComplete
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.muted,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    g.isComplete ? context.tr('اكتملت') : context.tr('جارية'),
                    style: AppTextStyles.caption.copyWith(
                      color: g.isComplete
                          ? AppColors.success
                          : AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _table(context, g),
          const Divider(height: 1),
          InkWell(
            onTap: () => setState(() => _showMatches = !_showMatches),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg,
                vertical: AppSizes.sm,
              ),
              child: Row(
                children: [
                  Text(
                    context.trArgs('المباريات · {p0} من {p1}', {
                      'p0': g.played,
                      'p1': g.total,
                    }),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _showMatches ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_showMatches)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.md,
                0,
                AppSizes.md,
                AppSizes.md,
              ),
              child: Column(
                children: [
                  for (final f in widget.fixtures) ...[
                    CupFixtureCard(
                      fixture: f,
                      myTeam: widget.myTeam,
                      saving: widget.savingFixtureId == f.id,
                      onSubmit: (a, b) => widget.onSubmit(f.id, a, b),
                      onRespond: (accept) => widget.onRespond(f.id, accept),
                      onResolve: widget.onResolve == null
                          ? null
                          : (a, b) => widget.onResolve!(f.id, a, b),
                      onRecord: widget.onRecord == null
                          ? null
                          : (a, b, w) => widget.onRecord!(f.id, a, b, w),
                      eventStart: widget.eventStart,
                    ),
                    const SizedBox(height: AppSizes.sm),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _table(BuildContext context, CupGroup g) {
    final head = AppTextStyles.caption.copyWith(
      color: AppColors.mutedForeground,
    );
    Widget cell(
      String s, {
      TextStyle? style,
      int flex = 1,
      TextAlign align = TextAlign.center,
    }) => Expanded(
      flex: flex,
      child: Text(s, textAlign: align, style: style),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.lg,
        0,
        AppSizes.lg,
        AppSizes.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(width: 24, child: Text('#', style: head)),
              cell(
                context.tr('الفريق'),
                style: head,
                flex: 5,
                align: TextAlign.start,
              ),
              cell(context.tr('لعب'), style: head),
              cell(context.tr('فاز'), style: head),
              cell(context.tr('فارق'), style: head),
              cell(context.tr('نقاط'), style: head),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          for (final r in g.standings)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: r.qualified
                    ? AppColors.success.withValues(alpha: 0.1)
                    : (r.position <= 2
                          ? AppColors.background
                          : Colors.transparent),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${r.position}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedForeground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: r.qualified
                                ? FontWeight.w800
                                : FontWeight.w700,
                          ),
                        ),
                        if (r.playerNames.isNotEmpty)
                          Text(
                            r.playerNames,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                      ],
                    ),
                  ),
                  cell(
                    '${r.played}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                  cell(
                    '${r.wins}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                  cell(
                    r.diff > 0 ? '+${r.diff}' : '${r.diff}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                  cell(
                    '${r.points}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
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
