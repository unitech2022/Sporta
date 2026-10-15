import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/entities/feed_item.dart';
import '../cubit/feed_cubit.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/system_insets.dart';

/// Activity feed of the players the current user follows.
class FeedPage extends StatelessWidget {
  const FeedPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FeedCubit>(
      create: (_) => getIt<FeedCubit>()..load(),
      child: _FeedView(onBack: onBack),
    );
  }
}

class _FeedView extends StatelessWidget {
  const _FeedView({required this.onBack});

  final VoidCallback onBack;

  String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return trg('الآن');
    if (diff.inMinutes < 60) return trgArgs('منذ {p0} دقيقة', {'p0': diff.inMinutes});
    if (diff.inHours < 24) return trgArgs('منذ {p0} ساعة', {'p0': diff.inHours});
    return trgArgs('منذ {p0} يوم', {'p0': diff.inDays});
  }

  IconData _icon(String type) {
    switch (type) {
      case 'match_joined':
        return Icons.sports_tennis;
      case 'coach_session':
        return Icons.school_outlined;
      case 'level':
        return Icons.trending_up;
      default:
        return Icons.bolt;
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
              child: BlocBuilder<FeedCubit, FeedState>(
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
          padding: const EdgeInsets.fromLTRB(AppSizes.pagePadding,
              AppSizes.xxxl, AppSizes.pagePadding, AppSizes.xxl),
          child: Row(
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
              Text(context.tr('نشاط من أتابعهم'),
                  style: AppTextStyles.heading2.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, FeedState state) {
    switch (state.status) {
      case FeedStatus.initial:
      case FeedStatus.loading:
        return const SkeletonList();
      case FeedStatus.failure:
        return Center(
          child: Text(state.error ?? context.tr('تعذّر تحميل النشاط'),
              style: AppTextStyles.body.copyWith(color: AppColors.secondary)),
        );
      case FeedStatus.success:
        if (state.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.dynamic_feed_outlined,
                      color: AppColors.mutedForeground, size: 56),
                  const SizedBox(height: AppSizes.md),
                  Text(context.tr('لا يوجد نشاط بعد — تابع لاعبين لترى نشاطهم'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.mutedForeground)),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: context
              .safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
          itemCount: state.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
          itemBuilder: (_, i) => _tile(state.items[i]),
        );
    }
  }

  Widget _tile(FeedItem item) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Icon(_icon(item.type), color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: item.actorName,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: '  '),
                      TextSpan(
                        text: item.localizedText,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(_ago(item.createdAt), style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
