import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../domain/entities/cup_entity.dart';
import 'cup_fixture_card.dart';

/// تبويب الإقصائيات: الأدوار من الأول إلى النهائي، وكل مباراة تمتلئ
/// تلقائياً بالفائز من الدور السابق.
class CupBracketTab extends StatelessWidget {
  const CupBracketTab({
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
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          context.tr(
            'تُبنى شجرة الإقصائيات تلقائياً بالقرعة عند اكتمال الفرق.',
          ),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.mutedForeground,
          ),
        ),
      );
    }
    final rounds = cup.knockoutRounds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cup.isGroupsFormat
              ? context.tr(
                  'تمتلئ المواجهات تلقائياً عند اكتمال مباريات كل مجموعة، ويتقدّم الفائز للدور التالي.',
                )
              : context.tr(
                  'يتقدّم الفائز من كل مباراة إلى الدور التالي تلقائياً.',
                ),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        for (final r in rounds) ...[
          _round(
            context,
            cup.knockoutFixtures.where((f) => f.round == r).toList(),
          ),
          const SizedBox(height: AppSizes.md),
        ],
      ],
    );
  }

  Widget _round(BuildContext context, List<CupFixture> fixtures) {
    final playable = fixtures.where((f) => !f.isBye).toList();
    final done = playable.where((f) => f.isCompleted).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              fixtures.first.roundName,
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              playable.length == 1
                  ? context.tr('مباراة واحدة')
                  : context.trArgs('{p0}/{p1} مباريات', {
                      'p0': done,
                      'p1': playable.length,
                    }),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        for (final f in fixtures) ...[
          CupFixtureCard(
            fixture: f,
            myTeam: myTeam,
            saving: savingFixtureId == f.id,
            onSubmit: (a, b) => onSubmit(f.id, a, b),
            onRespond: (accept) => onRespond(f.id, accept),
            onResolve: onResolve == null
                ? null
                : (a, b) => onResolve!(f.id, a, b),
            onRecord: onRecord == null
                ? null
                : (a, b, w) => onRecord!(f.id, a, b, w),
            eventStart: cup.scheduledAt,
          ),
          const SizedBox(height: AppSizes.sm),
        ],
      ],
    );
  }
}
