import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../../core/widgets/skeleton.dart';
import '../cubit/favorite_courts/favorite_courts_cubit.dart';
import '../widgets/courts/court_card.dart';
import '../widgets/courts/courts_status_views.dart';
import 'court_detail_page.dart';
import '../../../../core/utils/system_insets.dart';

/// «الملاعب المفضّلة» — الملاعب التي حفظها اللاعب من قائمة الملاعب. الضغط على
/// القلب هنا يزيل الملعب من القائمة مباشرة.
class FavoriteCourtsPage extends StatelessWidget {
  const FavoriteCourtsPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<FavoriteCourtsCubit>()
            ..load(isArabic: context.appSettings.language.isRtl),
      child: _FavoriteCourtsView(onBack: onBack),
    );
  }
}

class _FavoriteCourtsView extends StatelessWidget {
  const _FavoriteCourtsView({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FavoriteCourtsCubit>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        title: Text(context.tr('الملاعب المفضلة')),
        leading: IconButton(
          onPressed: onBack,
          icon: const DirectionalIcon(
            rtl: Icons.arrow_forward,
            ltr: Icons.arrow_back,
          ),
        ),
      ),
      body: BlocBuilder<FavoriteCourtsCubit, FavoriteCourtsState>(
        builder: (context, state) {
          switch (state.status) {
            case FavoriteCourtsStatus.initial:
            case FavoriteCourtsStatus.loading:
              return const SkeletonCardList(imageHeight: 160);

            case FavoriteCourtsStatus.failure:
              return CourtsErrorView(
                message: state.error ?? context.tr('حدث خطأ غير متوقع'),
                onRetry: () =>
                    cubit.load(isArabic: context.appSettings.language.isRtl),
              );

            case FavoriteCourtsStatus.success:
              if (state.courts.isEmpty) return const _EmptyFavorites();
              return RefreshIndicator(
                onRefresh: () =>
                    cubit.load(isArabic: context.appSettings.language.isRtl),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                      cubit.loadMore();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    // نفس هوامش قائمة الملاعب — البطاقة تتباعد رأسياً بنفسها فقط.
                    padding: context
                        .safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
                    itemCount: state.courts.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= state.courts.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSizes.md),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final court = state.courts[index];
                      return CourtCard(
                        court: court,
                        isFavorite: true,
                        onFavoriteTap: () => cubit.remove(court),
                        onBookTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CourtDetailPage(courtId: court.id),
                          ),
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CourtDetailPage(courtId: court.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 64,
              color: AppColors.mutedForeground.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              context.tr('لا توجد ملاعب مفضلة'),
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              context.tr('اضغط على القلب في أي ملعب لإضافته هنا'),
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
