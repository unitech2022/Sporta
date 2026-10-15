import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/widgets/gradient_page_header.dart';
import '../../../../core/widgets/load_more_listener.dart';
import '../../domain/review_models.dart';
import '../cubit/court_reviews_cubit.dart';
import '../widgets/review_widgets.dart';

/// كل تقييمات ملعب: الملخّص وأبرز الجوانب ثم المراجعات مقسّمة صفحات.
/// تُفتح من صفحة الملعب للاعب، ومن إشعار «تقييم جديد لملعبك» للمالك.
class CourtReviewsPage extends StatelessWidget {
  const CourtReviewsPage({super.key, required this.courtId, this.courtName});

  final int courtId;
  final String? courtName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CourtReviewsCubit>(
      create: (_) => getIt<CourtReviewsCubit>(param1: courtId)..load(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            GradientPageHeader(
              title: context.tr('تقييمات الملعب'),
              subtitle: courtName,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: BlocBuilder<CourtReviewsCubit, CourtReviewsState>(
                builder: (context, state) => switch (state.status) {
                  CourtReviewsStatus.loading => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  CourtReviewsStatus.failure => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.error ?? context.tr('تعذّر التحميل'),
                          style: AppTextStyles.body,
                        ),
                        const SizedBox(height: AppSizes.md),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<CourtReviewsCubit>().load(),
                          child: Text(context.tr('إعادة المحاولة')),
                        ),
                      ],
                    ),
                  ),
                  CourtReviewsStatus.success => _list(context, state),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, CourtReviewsState state) {
    final s = state.summary!;
    final cubit = context.read<CourtReviewsCubit>();
    if (s.count == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xxl),
          child: Text(
            context.tr(
              'لا توجد تقييمات بعد — يقيّمه اللاعبون بعد مبارياتهم عليه',
            ),
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ),
      );
    }
    return LoadMoreListener(
      onLoadMore: cubit.loadMore,
      child: RefreshIndicator(
        onRefresh: cubit.load,
        child: ListView(
          padding: context.safeBottom(
            const EdgeInsets.all(AppSizes.pagePadding),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RatingOverview(
                    average: s.average,
                    count: s.count,
                    distribution: s.distribution,
                  ),
                  if (s.topPraised.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.md),
                    Text(
                      context.tr('أكثر ما يمدحه اللاعبون'),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedForeground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final t in s.topPraised)
                          if (ReviewTag.find(ReviewTargetType.court, t.tag)
                              case final tag?)
                            ReviewTagChip(tag: tag, score: 5, count: t.count),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            for (final r in state.reviews) ...[
              Container(
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                child: ReviewItemTile(
                  review: r,
                  targetType: ReviewTargetType.court,
                ),
              ),
              const SizedBox(height: AppSizes.md),
            ],
            if (state.hasMore)
              const Padding(
                padding: EdgeInsets.all(AppSizes.md),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
