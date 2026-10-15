import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/entities/notification_entity.dart';
import '../cubit/notifications_cubit.dart';
import '../notification_router.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/system_insets.dart';

/// Notifications list with mark-as-read.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationsCubit>(
      create: (_) => getIt<NotificationsCubit>()..load(),
      child: _NotificationsView(onBack: onBack),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView({required this.onBack});

  final VoidCallback onBack;

  String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return trg('الآن');
    if (diff.inMinutes < 60)
      return trgArgs('منذ {p0} دقيقة', {'p0': diff.inMinutes});
    if (diff.inHours < 24)
      return trgArgs('منذ {p0} ساعة', {'p0': diff.inHours});
    return trgArgs('منذ {p0} يوم', {'p0': diff.inDays});
  }

  IconData _icon(String? type) {
    switch (type) {
      case 'friend_request':
      case 'friend_accepted':
        return Icons.group_add_outlined;
      case 'follow':
        return Icons.person_add_alt_1_outlined;
      case 'match_invite':
      case 'americano_invite':
      case 'match_event_invite':
      case 'americano_event_invite':
      case 'tournament_event_invite':
        return Icons.mail_outline;
      case 'americano_invite_accepted':
      case 'americano_invite_rejected':
      case 'match_invite_accepted':
      case 'match_invite_rejected':
      case 'match_join':
      case 'match_join_request':
      case 'match_join_approved':
      case 'match_join_rejected':
        return Icons.sports_tennis;
      case 'coach_session':
        return Icons.school_outlined;
      case 'membership_new':
      case 'membership_renewed':
      case 'membership_renewal_soon':
      case 'membership_ended':
      case 'membership_ending_soon':
        return Icons.workspace_premium_outlined;
      default:
        return Icons.notifications_outlined;
    }
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
              child: BlocBuilder<NotificationsCubit, NotificationsState>(
                builder: (context, state) => _body(context, state),
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
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.xxxl,
            AppSizes.pagePadding,
            AppSizes.xxl,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const DirectionalIcon(
                  rtl: Icons.arrow_forward,
                  ltr: Icons.arrow_back,
                  color: Colors.white,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: AppSizes.md),
              Text(
                context.tr('الإشعارات'),
                style: AppTextStyles.heading2.copyWith(color: Colors.white),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    context.read<NotificationsCubit>().markAllRead(),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: Text(context.tr('تعليم الكل كمقروء')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, NotificationsState state) {
    switch (state.status) {
      case NotificationsStatus.initial:
      case NotificationsStatus.loading:
        return const SkeletonList(itemCount: 7);
      case NotificationsStatus.failure:
        return Center(
          child: Text(
            state.error ?? context.tr('تعذّر تحميل الإشعارات'),
            style: AppTextStyles.body.copyWith(color: AppColors.secondary),
          ),
        );
      case NotificationsStatus.success:
        if (state.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.notifications_none,
                    color: AppColors.mutedForeground,
                    size: 56,
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    context.tr('لا توجد إشعارات'),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
              context.read<NotificationsCubit>().loadMore();
            }
            return false;
          },
          child: ListView.separated(
            padding: context.safeBottom(
              const EdgeInsets.all(AppSizes.pagePadding),
            ),
            itemCount: state.items.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
            itemBuilder: (_, i) {
              if (i >= state.items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSizes.md),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _tile(context, state.items[i]);
            },
          ),
        );
    }
  }

  /// Marks the notification read and opens the screen it refers to (shared
  /// routing with push taps — see [openNotificationTarget]).
  void _onTap(BuildContext context, NotificationEntity n) {
    if (!n.isRead) context.read<NotificationsCubit>().markRead(n.id);
    openNotificationTarget(
      context,
      type: n.type ?? '',
      referenceId: n.referenceId,
    );
  }

  Widget _tile(BuildContext context, NotificationEntity n) {
    return Material(
      color: n.isRead
          ? Colors.white
          : AppColors.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: () => _onTap(context, n),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: n.isRead
                  ? AppColors.border
                  : AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Icon(_icon(n.type), color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(n.body, style: AppTextStyles.bodySmall),
                    const SizedBox(height: AppSizes.xs),
                    Text(_ago(n.createdAt), style: AppTextStyles.caption),
                  ],
                ),
              ),
              if (!n.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
