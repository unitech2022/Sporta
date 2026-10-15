import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../domain/entities/player_summary.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/widgets/network_circle_avatar.dart';

/// A single "suggested friend" row with an add / sent action.
/// Used on the home dashboard and the suggested-friends page.
class SuggestionTile extends StatelessWidget {
  const SuggestionTile({
    super.key,
    required this.player,
    required this.avatarColor,
    required this.sent,
    required this.onAdd,
  });

  final PlayerSummary player;
  final Color avatarColor;
  final bool sent;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final levelText = player.isCoach
        ? trg('مدرب')
        : (player.level != null ? trgArgs('مستوى {p0}', {'p0': player.level}) : trg('لاعب'));
    final meta = [
      levelText,
      if (player.city != null && player.city!.isNotEmpty) player.city!,
    ].join('  •  ');

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NetworkCircleAvatar(
            imageUrl: player.avatarUrl,
            radius: 24,
            backgroundColor: avatarColor,
            child: Text(player.name.characters.firstOrNull ?? context.tr('؟'),
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: AppSizes.xs),
                Row(
                  children: [
                    const Icon(Icons.star,
                        size: AppSizes.iconSm, color: Color(0xFFEAB308)),
                    const SizedBox(width: AppSizes.xs),
                    Flexible(
                      child: Text(meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (sent)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Text(context.tr('تم الإرسال'),
                  style: AppTextStyles.caption
                      .copyWith(color: const Color(0xFF4B5563))),
            )
          else
            Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              child: InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_add_alt,
                          size: 12, color: Colors.white),
                      const SizedBox(width: AppSizes.xs),
                      Text(context.tr('إضافة'),
                          style: AppTextStyles.caption
                              .copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
