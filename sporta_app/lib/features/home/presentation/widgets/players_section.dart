import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../friends/domain/entities/player_summary.dart';
import '../../../friends/presentation/pages/players_page.dart';

/// شريط «اللاعبون» في الصفحة الرئيسية: صورة اللاعب واسمه وزرّ إضافة صديق.
/// أفقي لأن الغرض تصفّح سريع؛ القائمة الكاملة في [PlayersPage].
class PlayersSection extends StatelessWidget {
  const PlayersSection({
    super.key,
    required this.players,
    required this.loading,
    required this.sentRequests,
    required this.onAdd,
    required this.colors,
  });

  final List<PlayerSummary> players;
  final bool loading;

  /// معرّفات من أُرسلت لهم طلبات في هذه الجلسة.
  final Set<int> sentRequests;

  final void Function(int userId) onAdd;

  /// ألوان الصور البديلة (حرف الاسم) — نفس لوحة بقية الأقسام.
  final List<Color> colors;

  static const double _cardWidth = 132;

  @override
  Widget build(BuildContext context) {
    if (loading) return _skeleton();

    return SizedBox(
      height: 186,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: players.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSizes.md),
        itemBuilder: (_, i) {
          final player = players[i];
          return SizedBox(
            width: _cardWidth,
            child: Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PlayerAvatar(
                    player: player,
                    color: colors[i % colors.length],
                    radius: 30,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    player.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  AddFriendButton(
                    player: player,
                    sent: sentRequests.contains(player.userId),
                    onAdd: () => onAdd(player.userId),
                    compact: true,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// هيكل بشكل البطاقات نفسها: صورة ثم اسم ثم زرّ.
  Widget _skeleton() {
    return SizedBox(
      height: 186,
      child: Shimmer(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(width: AppSizes.md),
          itemBuilder: (_, _) => Container(
            width: _cardWidth,
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonBox.circle(size: 60),
                SizedBox(height: AppSizes.sm),
                SkeletonBox(width: 80, height: 12),
                SizedBox(height: AppSizes.sm),
                SkeletonBox(
                    width: 72, height: 26, radius: AppSizes.radiusFull),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
