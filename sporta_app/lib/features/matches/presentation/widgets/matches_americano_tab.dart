import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../americano/domain/entities/americano_entity.dart';
import '../../../americano/presentation/cubit/americano_list_cubit.dart';
import 'americano_event_card.dart';
import 'mine_section_header.dart';

/// أمريكانو / بطولات — rendered from live data (`AmericanoListCubit`).
///
/// في الأعلى قسم ما أنشأه المستخدم أو شارك فيه (أحدث خمسة حالية) مع «عرض
/// الكل»، ثم الباقي من القائمة العامة بعد استبعاد ما يخصّه.
class MatchesAmericanoTab extends StatelessWidget {
  const MatchesAmericanoTab({
    super.key,
    required this.status,
    required this.items,
    required this.onOpen,
    required this.onJoin,
    required this.onRetry,
    this.mine = const [],
    this.mineTotal = 0,
    this.onSeeAllMine,
    this.currentUserId = 0,
    this.joiningId,
    this.hasMore = false,
    this.error,
    this.emptyLabel = 'لا توجد بطولات أمريكانو حالياً',
    this.mineLabel = 'الأمريكانو الخاص بي',
    this.othersLabel = 'أمريكانو آخر',
  });

  final AmericanoListStatus status;
  final List<AmericanoEntity> items;

  /// ما يخصّ المستخدم من الحالية (أحدث خمسة) وعددها الكلي.
  final List<AmericanoEntity> mine;
  final int mineTotal;
  final VoidCallback? onSeeAllMine;
  final int currentUserId;

  /// الحدث الذي يُنضمّ إليه الآن من بطاقته.
  final int? joiningId;

  /// Empty-state text (the tournaments tab passes its own).
  final String emptyLabel;

  /// عنوانا القسمين (التبويبان يمرّران نصّيهما).
  final String mineLabel;
  final String othersLabel;

  /// Whether the server has more pages (shows a bottom loader while the page
  /// scroll listener fetches them).
  final bool hasMore;
  final void Function(int americanoId) onOpen;
  final void Function(AmericanoEntity event) onJoin;
  final VoidCallback onRetry;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (status == AmericanoListStatus.loading ||
        status == AmericanoListStatus.initial) {
      return const SkeletonList(
        itemCount: 4,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
      );
    }

    if (status == AmericanoListStatus.failure) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.xxxl),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.destructive,
              size: 48,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              error ?? context.tr('تعذّر تحميل الأمريكانو'),
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.secondary),
            ),
            const SizedBox(height: AppSizes.lg),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(context.tr('إعادة المحاولة')),
            ),
          ],
        ),
      );
    }

    final others = items.where((a) => !_isMine(a)).toList();

    if (mine.isEmpty && others.isEmpty && !hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.xxxl),
        child: Column(
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              color: AppColors.mutedForeground,
              size: 56,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              context.tr(emptyLabel),
              style: AppTextStyles.body.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mine.isNotEmpty) ...[
          MineSectionHeader(
            title: context.tr(mineLabel),
            icon: Icons.emoji_events,
            onSeeAll: onSeeAllMine,
          ),
          const SizedBox(height: AppSizes.md),
          for (final a in mine) ...[
            _card(a),
            const SizedBox(height: AppSizes.lg),
          ],
          if (others.isNotEmpty || hasMore) ...[
            const SizedBox(height: AppSizes.sm),
            MineSectionHeader(
              title: context.tr(othersLabel),
              icon: Icons.public,
            ),
            const SizedBox(height: AppSizes.md),
          ],
        ],
        if (others.isEmpty && !hasMore && mine.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
            child: Text(
              context.tr(emptyLabel),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ),
        for (final a in others) ...[
          _card(a),
          const SizedBox(height: AppSizes.lg),
        ],
        if (hasMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.md),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  /// نفس معيار الخادم: المنشئ أو أي صفّ لاعب (معتمد/طلب/دعوة).
  bool _isMine(AmericanoEntity a) =>
      currentUserId != 0 &&
      (a.creatorId == currentUserId ||
          a.players.any((p) => p.userId == currentUserId));

  Widget _card(AmericanoEntity a) => AmericanoEventCard(
    event: a,
    currentUserId: currentUserId,
    isJoining: joiningId == a.id,
    onOpen: (e) => onOpen(e.id),
    onJoin: onJoin,
  );
}
