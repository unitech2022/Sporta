import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/load_more_listener.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/filter_header_button.dart';
import '../../../../core/widgets/gradient_page_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../ads/presentation/widgets/ad_slider.dart';
import '../../../auth/presentation/widgets/login_required_sheet.dart';
import '../../../profile/presentation/pages/my_bookings_page.dart';
import '../cubit/courts_list/courts_cubit.dart';
import '../widgets/courts/court_card.dart';
import 'court_detail_page.dart';
import '../widgets/courts/courts_filter_sheet.dart';
import '../widgets/courts/courts_map_view.dart';
import '../widgets/courts/courts_status_views.dart';
import '../widgets/courts/courts_time_bar.dart';
import '../widgets/courts/header_icon_button.dart';
import '../../../../core/utils/system_insets.dart';

/// Courts listing screen. Provides a [CourtsCubit] and renders its state; all
/// data/filtering logic lives in the cubit and repository.
class CourtsPage extends StatelessWidget {
  const CourtsPage({
    super.key,
    this.onBack,
    this.onNavigateToCourt,
    this.onBookSlot,
  });

  final VoidCallback? onBack;
  final void Function(String courtId)? onNavigateToCourt;

  /// يفتح الحجز على موعد مختار من بطاقة البحث بالوقت. بدونه يُفتح الملعب
  /// عبر [onNavigateToCourt] بلا موعد مسبق.
  final BookSlotCallback? onBookSlot;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CourtsCubit>(
      create: (_) => getIt<CourtsCubit>()..loadCourts(),
      child: _CourtsView(
        onBack: onBack,
        onNavigateToCourt: onNavigateToCourt,
        onBookSlot: onBookSlot,
      ),
    );
  }
}

/// حجز موعد بعينه: الملعب واليوم والوقت (HH:mm) والمدة بالدقائق.
typedef BookSlotCallback = void Function(
    String courtId, DateTime date, String time, int durationMinutes);

class _CourtsView extends StatefulWidget {
  const _CourtsView({this.onBack, this.onNavigateToCourt, this.onBookSlot});

  final VoidCallback? onBack;
  final void Function(String courtId)? onNavigateToCourt;
  final BookSlotCallback? onBookSlot;

  @override
  State<_CourtsView> createState() => _CourtsViewState();
}

class _CourtsViewState extends State<_CourtsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<CourtsCubit, CourtsState>(
          builder: (context, state) {
            final cubit = context.read<CourtsCubit>();
            return Column(
              children: [
                GradientPageHeader(
                  title: context.tr('احجز ملعب'),
                  onBack: widget.onBack,
                  trailing: [
                    // اختصار إلى حجوزات اللاعب — يفتح على تبويب الملاعب.
                    TextButton.icon(
                      onPressed: _openMyBookings,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                      ),
                      icon: const Icon(Icons.event_available_outlined, size: 18),
                      label: Text(context.tr('حجوزاتي')),
                    ),
                  ],
                  bottom: _buildHeaderBottom(cubit, state),
                ),
                Expanded(
                  child: state.showMap
                      ? _buildMapBody(cubit, state)
                      : _buildListBody(cubit, state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openMyBookings() async {
    if (await guestBlocked(context)) return;
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MyBookingsPage(
          initialTab: 2, // تبويب حجوزات الملاعب
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Widget _buildHeaderBottom(CourtsCubit cubit, CourtsState state) {
    final activeCount = state.filters.activeCount;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppSearchField(
                hint: context.tr('ابحث عن ملعب...'),
                controller: _searchController,
                onChanged: (value) =>
                    cubit.updateFilters(state.filters.copyWith(query: value)),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            HeaderIconButton(
              icon: state.showMap ? Icons.list_rounded : Icons.map_outlined,
              onTap: cubit.toggleMap,
              tooltip: state.showMap ? context.tr('عرض قائمة') : context.tr('عرض خريطة'),
            ),
            const SizedBox(width: AppSizes.xs),
            FilterHeaderButton(
              activeCount: activeCount,
              onOpen: () => showCourtsFilterSheet(context, cubit),
              onClear: cubit.resetFilters,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        CourtsTimeBar(filters: state.filters, onChanged: cubit.updateFilters),
        const SizedBox(height: AppSizes.sm),
      ],
    );
  }

  Widget _buildListBody(CourtsCubit cubit, CourtsState state) {
    return _listContent(cubit, state);
  }

  Widget _listContent(CourtsCubit cubit, CourtsState state) {
    switch (state.status) {
      case CourtsStatus.loading:
      case CourtsStatus.initial:
        return const SkeletonCardList(imageHeight: 160);
      case CourtsStatus.failure:
        return CourtsErrorView(
          message: state.error ?? context.tr('تعذّر تحميل الملاعب'),
          onRetry: () => cubit.loadCourts(),
        );
      case CourtsStatus.success:
        if (state.filtered.isEmpty && !state.hasMore) {
          return const CourtsEmptyView();
        }
        return RefreshIndicator(
          // «الآن» والمواعيد الفارغة تُحسب وقت الطلب، والصفحة تبقى حية في
          // الشريط السفلي — السحب يعيد حسابها.
          onRefresh: cubit.refresh,
          child: LoadMoreListener(
            // يحمّل التالي قرب النهاية، أو فوراً إن لم تملأ القائمة الشاشة.
            onLoadMore: () {
                cubit.loadMore();
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: context
                  .safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
              itemCount: state.filtered.length + 1 + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                // بانر إعلانات صفحة الملاعب — يخفي نفسه إن لم توجد إعلانات لها.
                if (index == 0) {
                  return const AdBannerSection(
                    page: AdPlacements.courts,
                    padding: EdgeInsets.only(bottom: AppSizes.lg),
                  );
                }
                final itemIndex = index - 1;
                if (itemIndex >= state.filtered.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSizes.md),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final court = state.filtered[itemIndex];
                return CourtCard(
                  court: court,
                  isFavorite: state.favoriteIds.contains(court.id),
                  slotDuration: state.filters.slotDuration,
                  onSlotTap: (time) => _bookSlot(court.id, state.filters, time),
                  // المفضلة والحجز يخصّان حساباً؛ الزائر يُدعى لتسجيل الدخول.
                  onFavoriteTap: () async {
                    if (await guestBlocked(context)) return;
                    cubit.toggleFavorite(court.id);
                  },
                  onBookTap: () async {
                    if (await guestBlocked(context)) return;
                    if (!context.mounted) return;
                    widget.onNavigateToCourt?.call(court.id);
                  },
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
  }

  /// موعد من بطاقة البحث بالوقت: الزائر يُدعى للدخول، واللاعب يذهب للحجز
  /// والموعد مختار مسبقاً.
  Future<void> _bookSlot(
      String courtId, CourtsFilters filters, String time) async {
    if (await guestBlocked(context)) return;
    if (!mounted) return;
    final book = widget.onBookSlot;
    if (book != null) {
      book(courtId, filters.slotDate, time, filters.slotDuration);
    } else {
      widget.onNavigateToCourt?.call(courtId);
    }
  }

  Widget _buildMapBody(CourtsCubit cubit, CourtsState state) {
    return CourtsMapView(courts: state.filtered);
  }
}
