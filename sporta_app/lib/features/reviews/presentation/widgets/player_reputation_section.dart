import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../data/review_repository.dart';
import '../../domain/review_models.dart';
import 'review_widgets.dart';

/// «تقييمك كلاعب» في حسابي: متوسط ما منحه إياه اللاعبون والمدربون وأصحاب
/// الملاعب، وأكثر ما يُمدح فيه — بلا أسماء ولا تعليقات.
class PlayerReputationSection extends StatefulWidget {
  const PlayerReputationSection({
    super.key,
    required this.userId,
    this.padding,
  });

  final int userId;
  final EdgeInsetsGeometry? padding;

  @override
  State<PlayerReputationSection> createState() =>
      _PlayerReputationSectionState();
}

class _PlayerReputationSectionState extends State<PlayerReputationSection> {
  PlayerReputation? _rep;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.userId == 0) return;
    try {
      final r = await getIt<ReviewRepository>().fetchReputation(widget.userId);
      if (mounted) setState(() => _rep = r);
    } catch (_) {
      // لا قسم عند تعذّر الجلب.
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _rep;
    if (r == null) return const SizedBox.shrink();
    final roleParts = <String>[
      if ((r.byRole['player'] ?? 0) > 0)
        context.trArgs('{p0} من لاعبين', {'p0': r.byRole['player']}),
      if ((r.byRole['coach'] ?? 0) > 0)
        context.trArgs('{p0} من مدربين', {'p0': r.byRole['coach']}),
      if ((r.byRole['venue'] ?? 0) > 0)
        context.trArgs('{p0} من ملاعب', {'p0': r.byRole['venue']}),
    ];
    final card = Container(
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
              const Icon(
                Icons.verified_outlined,
                color: AppColors.primary,
                size: AppSizes.iconMd,
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  context.tr('تقييمك كلاعب'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          if (r.count == 0)
            Text(
              context.tr(
                'لا تقييمات بعد — يقيّمك اللاعبون والمدربون وأصحاب الملاعب بعد كل تجربة',
              ),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.mutedForeground,
              ),
            )
          else ...[
            RatingOverview(
              average: r.average,
              count: r.count,
              distribution: r.distribution,
            ),
            if (roleParts.isNotEmpty) ...[
              const SizedBox(height: AppSizes.sm),
              Text(
                roleParts.join(' · '),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
            if (r.topPraised.isNotEmpty) ...[
              const SizedBox(height: AppSizes.md),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in r.topPraised)
                    if (ReviewTag.find(ReviewTargetType.player, t.tag)
                        case final tag?)
                      ReviewTagChip(tag: tag, score: 5, count: t.count),
                ],
              ),
            ],
          ],
        ],
      ),
    );
    return widget.padding == null
        ? card
        : Padding(padding: widget.padding!, child: card);
  }
}
