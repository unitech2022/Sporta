import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/entities/player_summary.dart';
import '../cubit/friends_cubit.dart';
import 'feed_page.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/widgets/network_circle_avatar.dart';

/// Friends hub: incoming requests, friends list, and search-to-add.
class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FriendsCubit>(
      create: (_) => getIt<FriendsCubit>()..load(),
      child: _FriendsView(onBack: onBack),
    );
  }
}

class _FriendsView extends StatelessWidget {
  const _FriendsView({required this.onBack});

  final VoidCallback onBack;

  Future<void> _add(BuildContext context, int userId) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<FriendsCubit>().sendRequest(userId);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? context.tr('تم إرسال طلب الصداقة'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _header(context),
            Expanded(
              child: BlocBuilder<FriendsCubit, FriendsState>(
                builder: (context, state) {
                  if (state.query.trim().isNotEmpty) {
                    return _searchResults(context, state);
                  }
                  return _main(context, state);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.pagePadding,
              AppSizes.xxxl, AppSizes.pagePadding, AppSizes.xxl),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const DirectionalIcon(
                        rtl: Icons.arrow_forward,
                        ltr: Icons.arrow_back,
                        color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Text(context.tr('الأصدقاء'),
                      style:
                          AppTextStyles.heading2.copyWith(color: Colors.white)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => FeedPage(
                          onBack: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.dynamic_feed_outlined,
                        color: Colors.white),
                    tooltip: context.tr('نشاط من أتابعهم'),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              AppSearchField(
                hint: context.tr('ابحث عن لاعب بالاسم أو الجوال...'),
                onChanged: (v) => context.read<FriendsCubit>().search(v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _main(BuildContext context, FriendsState state) {
    if (state.status == FriendsStatus.loading ||
        state.status == FriendsStatus.initial) {
      return const SkeletonList();
    }
    if (state.status == FriendsStatus.failure) {
      return Center(
        child: Text(state.error ?? context.tr('تعذّر تحميل الأصدقاء'),
            style: AppTextStyles.body.copyWith(color: AppColors.secondary)),
      );
    }

    return ListView(
      padding: context.safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
      children: [
        if (state.requests.isNotEmpty) ...[
          Text(context.tr('طلبات الصداقة'),
              style: AppTextStyles.heading3
                  .copyWith(color: AppColors.secondary)),
          const SizedBox(height: AppSizes.md),
          for (final r in state.requests) ...[
            _RequestTile(
              request: r,
              onAccept: () =>
                  context.read<FriendsCubit>().respond(r.id, true),
              onReject: () =>
                  context.read<FriendsCubit>().respond(r.id, false),
            ),
            const SizedBox(height: AppSizes.sm),
          ],
          const SizedBox(height: AppSizes.lg),
        ],
        Text(context.trArgs('أصدقائي ({p0})', {'p0': state.friends.length}),
            style: AppTextStyles.heading3.copyWith(color: AppColors.secondary)),
        const SizedBox(height: AppSizes.md),
        if (state.friends.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.xxl),
            child: Center(
              child: Text(context.tr('لا يوجد أصدقاء بعد — ابحث وأضف لاعبين'),
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.mutedForeground)),
            ),
          )
        else
          for (final f in state.friends) ...[
            _PlayerTile(player: f),
            const SizedBox(height: AppSizes.sm),
          ],
        if (state.following.isNotEmpty) ...[
          const SizedBox(height: AppSizes.lg),
          Text(context.trArgs('أتابعهم ({p0})', {'p0': state.following.length}),
              style: AppTextStyles.heading3
                  .copyWith(color: AppColors.secondary)),
          const SizedBox(height: AppSizes.md),
          for (final p in state.following) ...[
            _PlayerTile(
              player: p,
              trailing: _followToggle(context, p),
            ),
            const SizedBox(height: AppSizes.sm),
          ],
        ],
      ],
    );
  }

  Widget _searchResults(BuildContext context, FriendsState state) {
    if (state.searching) {
      return const SkeletonList(itemCount: 4);
    }
    if (state.searchResults.isEmpty) {
      return Center(
        child: Text(context.tr('لا توجد نتائج'),
            style: AppTextStyles.body.copyWith(color: AppColors.mutedForeground)),
      );
    }
    return ListView(
      padding: context.safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
      children: [
        for (final p in state.searchResults) ...[
          _PlayerTile(
            player: p,
            trailing: _relationAction(context, p),
          ),
          const SizedBox(height: AppSizes.sm),
        ],
      ],
    );
  }

  Widget _relationAction(BuildContext context, PlayerSummary p) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _followToggle(context, p),
        const SizedBox(width: AppSizes.xs),
        _friendAction(context, p),
      ],
    );
  }

  Widget _friendAction(BuildContext context, PlayerSummary p) {
    if (p.isFriend) {
      return const Icon(Icons.group, color: AppColors.success, size: 18);
    }
    if (p.isPending) {
      return const Icon(Icons.hourglass_top,
          color: AppColors.mutedForeground, size: 18);
    }
    return IconButton(
      onPressed: () => _add(context, p.userId),
      icon: const Icon(Icons.person_add_alt, color: AppColors.primary),
      tooltip: context.tr('إضافة صديق'),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _followToggle(BuildContext context, PlayerSummary p) {
    final following = p.isFollowing;
    return TextButton(
      onPressed: () =>
          context.read<FriendsCubit>().toggleFollow(p.userId, !following),
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: AppSizes.xs),
        foregroundColor: following ? AppColors.mutedForeground : AppColors.primary,
      ),
      child: Text(following ? context.tr('متابَع') : context.tr('متابعة')),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player, this.trailing});

  final PlayerSummary player;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          NetworkCircleAvatar(
            imageUrl: player.avatarUrl,
            radius: 20,
            backgroundColor: AppColors.primary,
            child: Text(player.initials,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name,
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600)),
                Text(
                  [
                    if (player.level != null) context.trArgs('مستوى {p0}', {'p0': player.level}),
                    if (player.city != null && player.city!.isNotEmpty)
                      player.city!,
                  ].join(' • '),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          NetworkCircleAvatar(
            imageUrl: request.avatarUrl,
            radius: 20,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(request.fromName,
                style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            onPressed: onAccept,
            icon: const Icon(Icons.check_circle, color: AppColors.success),
          ),
          IconButton(
            onPressed: onReject,
            icon: const Icon(Icons.cancel, color: AppColors.destructive),
          ),
        ],
      ),
    );
  }
}
