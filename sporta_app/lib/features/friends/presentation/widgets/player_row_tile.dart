import '../../../../core/widgets/level_avatar.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../domain/entities/player_summary.dart';

/// صف لاعب: الصورة، الاسم، المدينة تحته، وزرّ الإضافة.
class PlayerRowTile extends StatelessWidget {
  const PlayerRowTile({
    super.key,
    required this.player,
    required this.avatarColor,
    required this.sent,
    required this.onAdd,
  });

  final PlayerSummary player;
  final Color avatarColor;

  /// أُرسل طلب الصداقة في هذه الجلسة.
  final bool sent;

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final city = player.city ?? '';
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          PlayerAvatar(player: player, color: avatarColor, radius: 24),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (city.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.xs),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: AppSizes.iconSm,
                        color: AppColors.mutedForeground,
                      ),
                      const SizedBox(width: AppSizes.xs),
                      Flexible(
                        child: Text(
                          city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          AddFriendButton(player: player, sent: sent, onAdd: onAdd),
        ],
      ),
    );
  }
}

/// صورة اللاعب، وإلا أول حرف من اسمه على لون ثابت له.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.player,
    required this.color,
    this.radius = 24,
  });

  final PlayerSummary player;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    // إطار ودائرة بلون مستوى اللاعب؛ المدرب بلا شارة مستوى.
    return LevelAvatar(
      name: player.name,
      imageUrl: player.avatarUrl,
      level: player.isCoach ? null : player.level,
      radius: radius,
      fallbackColor: color,
    );
  }
}

/// زرّ «إضافة» بحالاته: صديق بالفعل، أو طلب مُرسَل، أو قابل للإرسال.
class AddFriendButton extends StatelessWidget {
  const AddFriendButton({
    super.key,
    required this.player,
    required this.sent,
    required this.onAdd,
    this.compact = false,
  });

  final PlayerSummary player;
  final bool sent;
  final VoidCallback onAdd;

  /// نسخة أصغر لبطاقات الشريط الأفقي في الصفحة الرئيسية.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (player.isFriend) return _chip(context, context.tr('صديق'));
    if (sent || player.isPending)
      return _chip(context, context.tr('تم الإرسال'));

    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSizes.sm : AppSizes.md,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_add_alt, size: 12, color: Colors.white),
              const SizedBox(width: AppSizes.xs),
              Text(
                context.tr('إضافة'),
                style: AppTextStyles.caption.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? AppSizes.sm : AppSizes.md,
      vertical: 6,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
    ),
    child: Text(
      label,
      maxLines: 1,
      style: AppTextStyles.caption.copyWith(color: const Color(0xFF4B5563)),
    ),
  );
}
