import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/entities/match_entity.dart';
import '../cubit/matches_cubit.dart';
import 'mine_section_header.dart';
import 'open_match_card.dart';

/// المباريات المفتوحة — rendered from live data (`MatchesCubit`).
///
/// في الأعلى قسم «مبارياتي» (أحدث خمس مباريات حالية أنشأها المستخدم أو هو
/// فيها، من الخادم) مع «عرض الكل»، ثم «مباريات أخرى» من القائمة العامة بعد
/// استبعاد ما يخصّه كي لا تتكرر البطاقة.
class MatchesOpenMatchesTab extends StatelessWidget {
  const MatchesOpenMatchesTab({
    super.key,
    required this.status,
    required this.matches,
    required this.joiningId,
    required this.onJoin,
    required this.onEnterResult,
    required this.onInvite,
    required this.onRetry,
    required this.onOpenDetails,
    this.mine = const [],
    this.mineTotal = 0,
    this.onSeeAllMine,
    this.currentUserId = 0,
    this.hasMore = false,
    this.error,
  });

  final MatchesStatus status;
  final List<MatchEntity> matches;

  /// «مبارياتي» الحالية (أحدث خمس) وعددها الكلي.
  final List<MatchEntity> mine;
  final int mineTotal;
  final VoidCallback? onSeeAllMine;
  final int? joiningId;

  /// Whether the server has more pages (shows a bottom loader while the page
  /// scroll listener fetches them).
  final bool hasMore;

  /// The signed-in user's id, to surface and highlight their own matches.
  final int currentUserId;

  /// Passes the whole match (not just its id) so the caller can quote the
  /// share price in the payment confirmation.
  final void Function(MatchEntity match) onJoin;
  final void Function(MatchEntity match) onEnterResult;
  final void Function(MatchEntity match) onInvite;
  final VoidCallback onRetry;
  final void Function(MatchEntity match) onOpenDetails;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (status == MatchesStatus.loading || status == MatchesStatus.initial) {
      return const SkeletonList(
        itemCount: 4,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
      );
    }

    if (status == MatchesStatus.failure) {
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
              error ?? context.tr('تعذّر تحميل المباريات'),
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

    // ما يخصّني يُستبعد من القائمة العامة — له قسمه الخاص في الأعلى.
    final others = matches.where((m) => !_isMine(m)).toList();

    if (mine.isEmpty && others.isEmpty && !hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.xxxl),
        child: Column(
          children: [
            const Icon(
              Icons.sports_tennis,
              color: AppColors.mutedForeground,
              size: 56,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              context.tr('لا توجد مباريات مفتوحة حالياً'),
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
            title: context.tr('مبارياتي'),
            icon: Icons.sports_tennis,
            onSeeAll: onSeeAllMine,
          ),
          const SizedBox(height: AppSizes.md),
          for (final m in mine) ...[
            _card(m),
            const SizedBox(height: AppSizes.lg),
          ],
          if (others.isNotEmpty || hasMore) ...[
            const SizedBox(height: AppSizes.sm),
            MineSectionHeader(
              title: context.tr('مباريات أخرى'),
              icon: Icons.public,
            ),
            const SizedBox(height: AppSizes.md),
          ],
        ],
        if (others.isEmpty && !hasMore && mine.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
            child: Text(
              context.tr('لا توجد مباريات مفتوحة أخرى حالياً'),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ),
        for (final m in others) ...[
          _card(m),
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

  /// نفس معيار الخادم في «مبارياتي»: المنشئ أو أي صفّ لاعب (معتمد أو طلب
  /// معلّق أو دعوة).
  bool _isMine(MatchEntity m) =>
      m.hasJoined ||
      m.hasPendingRequest ||
      m.hasInvite ||
      (currentUserId != 0 && m.creatorId == currentUserId);

  Widget _card(MatchEntity m) => OpenMatchCard(
    match: m,
    isJoining: joiningId == m.id,
    currentUserId: currentUserId,
    onJoin: onJoin,
    onEnterResult: onEnterResult,
    onInvite: onInvite,
    onOpenDetails: onOpenDetails,
  );
}
