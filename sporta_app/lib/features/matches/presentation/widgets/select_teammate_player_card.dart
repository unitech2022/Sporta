import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/player.dart';

const Color _green100 = Color(0xFFDCFCE7);
const Color _green500 = Color(0xFF22C55E);
const Color _green600 = Color(0xFF16A34A);
const Color _gray50 = Color(0xFFF9FAFB);
const Color _yellow500 = Color(0xFFEAB308);

/// Selectable player card with stats
/// (converted from the player list item in SelectTeammatePage.tsx).
class SelectTeammatePlayerCard extends StatelessWidget {
  const SelectTeammatePlayerCard({
    super.key,
    required this.player,
    required this.selected,
    required this.onTap,
  });

  final Player player;
  final bool selected;
  final VoidCallback onTap;

  /// Stable pseudo-rating between 3.0 and 4.9 (the TSX shows a random
  /// rating; a stable one avoids flicker on rebuild).
  String get _rating =>
      (3.0 + (player.id.hashCode.abs() % 20) / 10).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.05)
          : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // حالة الاتصال
              if (player.isOnline)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Tooltip(
                    message: 'اللاعب متصل الآن ويمكنه الرد بسرعة',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                        vertical: AppSizes.xs,
                      ),
                      decoration: BoxDecoration(
                        color: _green100,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: _green500,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: AppSizes.xs),
                          Text(
                            'متصل',
                            style: AppTextStyles.caption
                                .copyWith(color: _green600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          player.level,
                          style: AppTextStyles.heading2
                              .copyWith(color: Colors.white),
                        ),
                      ),
                      if (selected)
                        PositionedDirectional(
                          bottom: -4,
                          start: -4,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: AppSizes.xs),
                        Row(
                          children: [
                            const Icon(
                              Icons.trending_up,
                              size: 12,
                              color: AppColors.mutedForeground,
                            ),
                            SizedBox(width: AppSizes.xs),
                            Text('مستوى ${player.level}',
                                style: AppTextStyles.caption),
                            Text(' • ', style: AppTextStyles.caption),
                            Text('${player.gamesPlayed} مباراة',
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.md),
              // الإحصائيات
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: _gray50,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Tooltip(
                      message: 'نسبة المباريات المكسوبة',
                      child: Column(
                        children: [
                          Text('نسبة الفوز',
                              style: AppTextStyles.caption),
                          Text(
                            '${player.winRate?.toStringAsFixed(0) ?? '-'}%',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: _green600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 32, color: AppColors.border),
                    Tooltip(
                      message: 'تقييم اللاعب من المباريات السابقة',
                      child: Column(
                        children: [
                          Text('التقييم', style: AppTextStyles.caption),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  size: 12, color: _yellow500),
                              SizedBox(width: 2),
                              Text(
                                _rating,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 32, color: AppColors.border),
                    Tooltip(
                      message: 'عدد المباريات التي شارك فيها',
                      child: Column(
                        children: [
                          Text('المباريات',
                              style: AppTextStyles.caption),
                          Text(
                            '${player.gamesPlayed}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
