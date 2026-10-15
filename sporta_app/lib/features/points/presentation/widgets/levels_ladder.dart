import 'package:flutter/material.dart';
import 'package:sporta_app/core/state/app_scope.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/points_entity.dart';

/// سُلَّم المستويات (3.0 → 7.0) كما يضبطه الأدمن، مع تمييز مستوى اللاعب.
class LevelsLadder extends StatelessWidget {
  const LevelsLadder({super.key, required this.levels, this.myLevel});

  final List<LevelDefinitionEntity> levels;

  /// مستوى اللاعب الرقمي (1..7) — يُميَّز الصف الذي تساوي قيمته إياه.
  final int? myLevel;

  @override
  Widget build(BuildContext context) {
    if (levels.isEmpty) return const SizedBox.shrink();
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
              const Icon(Icons.stairs_rounded,
                  color: AppColors.secondary, size: 22),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(context.tr('سُلَّم المستويات'),
                    style: AppTextStyles.heading3),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          for (var i = 0; i < levels.length; i++) ...[
            _LevelRow(
              level: levels[i],
              isMine: myLevel != null && levels[i].value == myLevel!.toDouble(),
              isLast: i == levels.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow(
      {required this.level, required this.isMine, required this.isLast});

  final LevelDefinitionEntity level;
  final bool isMine;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    // اللون يتدرّج من الأخضر (مبتدئ) إلى الذهبي (نخبة).
    final t = ((level.value - 3.0) / 4.0).clamp(0.0, 1.0);
    final tint = Color.lerp(AppColors.primary, const Color(0xFFEAB308), t)!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 44,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isMine ? tint : tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(level.valueLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: isMine ? Colors.white : tint,
                        fontWeight: FontWeight.w700)),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(level.title,
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700)),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: AppSizes.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: tint.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: Text(context.tr('مستواك'),
                              style: AppTextStyles.caption
                                  .copyWith(color: tint)),
                        ),
                      ],
                    ],
                  ),
                  if (level.description.isNotEmpty)
                    Text(level.description,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.mutedForeground)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
