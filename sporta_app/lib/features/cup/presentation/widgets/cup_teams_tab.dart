import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../americano/domain/entities/americano_entity.dart';
import '../../domain/entities/cup_entity.dart';

/// تبويب الفرق: بطاقة لكل فريق (لاعبان) مع مجموعته بعد القرعة. الانضمام
/// من بطاقة «انضم للبطولة» أعلى الصفحة، والنظام يختار المقعد الشاغر.
class CupTeamsTab extends StatelessWidget {
  const CupTeamsTab({
    super.key,
    required this.cup,
    required this.currentUserId,
    required this.onRename,
  });

  final CupEntity cup;
  final int currentUserId;

  /// أيقونة التعديل بجانب اسم الفريق (لاعبوه أو المنظّم).
  final void Function(CupTeam team) onRename;

  @override
  Widget build(BuildContext context) {
    final alreadyIn = cup.hasPlayer(currentUserId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.trArgs('الفرق المشاركة ({p0})', {'p0': cup.teamCount}),
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.secondary,
              ),
            ),
            const Spacer(),
            Text(
              context.trArgs('{p0} مكتمل', {'p0': cup.completeTeamCount}),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          cup.isDrawn
              ? context.tr('أُجريت القرعة عشوائياً وتوزّعت الفرق.')
              : context.tr(
                  'كل فريق يتكوّن من لاعبَين. تُجرى القرعة تلقائياً عند اكتمال العدد.',
                ),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.mutedForeground,
          ),
        ),
        if (alreadyIn) ...[
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: AppSizes.iconSm,
                color: AppColors.success,
              ),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: Text(
                  cup.isDrawn
                      ? context.tr('أنت مشارك في هذه البطولة')
                      : context.tr('أنت مشارك — بانتظار اكتمال بقية الفرق'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSizes.md),
        for (final team in cup.teams) ...[
          _TeamCard(
            team: team,
            creatorId: cup.creatorId,
            isMine: team.players.any((p) => p.userId == currentUserId),
            onRename: cup.canRename(team, currentUserId)
                ? () => onRename(team)
                : null,
          ),
          const SizedBox(height: AppSizes.sm),
        ],
      ],
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.team,
    required this.creatorId,
    required this.isMine,
    this.onRename,
  });

  final CupTeam team;
  final int creatorId;
  final bool isMine;

  /// null = لا يحق للمستخدم تسمية هذا الفريق.
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    final color = isMine ? AppColors.primary : AppColors.secondary;
    final hasCustom = team.customName != null && team.customName!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: isMine ? AppColors.primary : AppColors.border,
          width: isMine ? 1.4 : 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSizes.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شارة الحرف الثابت (A، B، C…) — تبقى حتى لو سُمّي الفريق.
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Text(
              team.letter,
              style: AppTextStyles.body.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // السطر كله (الاسم + القلم) هدف واحد للضغط — القلم وحده صغير.
                InkWell(
                  onTap: onRename,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            hasCustom
                                ? team.name
                                : context.trArgs('فريق {p0}', {
                                    'p0': team.letter,
                                  }),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (onRename != null) ...[
                          const SizedBox(width: AppSizes.sm),
                          const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                for (var i = 0; i < 2; i++)
                  i < team.players.length
                      ? _player(context, team.players[i])
                      : Text(
                          context.tr('مقعد شاغر'),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.mutedForeground,
                          ),
                        ),
              ],
            ),
          ),
          if (team.groupLetter != null)
            _tag(
              context,
              context.trArgs('مجموعة {p0}', {'p0': team.groupLetter!}),
              AppColors.brandGold,
            ),
        ],
      ),
    );
  }

  Widget _player(BuildContext context, AmericanoPlayer p) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Row(
      children: [
        const Icon(
          Icons.person_outline,
          size: 14,
          color: AppColors.mutedForeground,
        ),
        const SizedBox(width: AppSizes.xs),
        Flexible(
          child: Text(
            p.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ),
        if (p.userId == creatorId) ...[
          const SizedBox(width: AppSizes.xs),
          _tag(context, context.tr('المنظّم'), AppColors.brandGold),
        ],
        if (p.isPending) ...[
          const SizedBox(width: AppSizes.xs),
          _tag(
            context,
            context.tr('بانتظار موافقة المنظّم'),
            AppColors.warning,
          ),
        ],
        if (p.isInvited) ...[
          const SizedBox(width: AppSizes.xs),
          _tag(
            context,
            context.tr('بانتظار القبول'),
            AppColors.mutedForeground,
          ),
        ],
      ],
    ),
  );

  Widget _tag(BuildContext context, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
    ),
    child: Text(label, style: AppTextStyles.caption.copyWith(color: color)),
  );
}

/// حوار تسمية الفريق: اسم جديد، أو العودة إلى الحرف. يعيد null عند الإلغاء.
Future<String?> showRenameTeamDialog(BuildContext context, CupTeam team) {
  return showDialog<String>(
    context: context,
    builder: (_) => _RenameTeamDialog(team: team),
  );
}

class _RenameTeamDialog extends StatefulWidget {
  const _RenameTeamDialog({required this.team});

  final CupTeam team;

  @override
  State<_RenameTeamDialog> createState() => _RenameTeamDialogState();
}

class _RenameTeamDialogState extends State<_RenameTeamDialog> {
  late final _ctrl = TextEditingController(text: widget.team.customName ?? '');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.team;
    return AlertDialog(
      title: Text(context.trArgs('اسم الفريق {p0}', {'p0': t.letter})),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (t.playerNames.isNotEmpty) ...[
            Text(
              t.playerNames,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: AppSizes.md),
          ],
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLength: 30,
            textInputAction: TextInputAction.done,
            onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
            decoration: InputDecoration(
              hintText: context.tr('مثال: النسور'),
              helperText: context.trArgs('اتركه فارغاً ليعود إلى {p0}', {
                'p0': t.letter,
              }),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('إلغاء')),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text.trim()),
          child: Text(context.tr('حفظ')),
        ),
      ],
    );
  }
}
