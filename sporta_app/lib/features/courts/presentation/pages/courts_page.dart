import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/gradient_page_header.dart';
import '../cubit/courts_list/courts_cubit.dart';
import '../widgets/courts/court_card.dart';
import '../widgets/courts/courts_filter_panel.dart';
import '../widgets/courts/courts_map_view.dart';
import '../widgets/courts/courts_status_views.dart';
import '../widgets/courts/header_icon_button.dart';

/// Courts listing screen. Provides a [CourtsCubit] and renders its state; all
/// data/filtering logic lives in the cubit and repository.
class CourtsPage extends StatelessWidget {
  const CourtsPage({super.key, this.onBack, this.onNavigateToCourt});

  final VoidCallback? onBack;
  final void Function(String courtId)? onNavigateToCourt;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CourtsCubit>(
      create: (_) => getIt<CourtsCubit>()..loadCourts(),
      child: _CourtsView(onBack: onBack, onNavigateToCourt: onNavigateToCourt),
    );
  }
}

class _CourtsView extends StatefulWidget {
  const _CourtsView({this.onBack, this.onNavigateToCourt});

  final VoidCallback? onBack;
  final void Function(String courtId)? onNavigateToCourt;

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
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<CourtsCubit, CourtsState>(
          builder: (context, state) {
            final cubit = context.read<CourtsCubit>();
            return Column(
              children: [
                GradientPageHeader(
                  title: 'احجز ملعب',
                  onBack: widget.onBack,
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

  Widget _buildHeaderBottom(CourtsCubit cubit, CourtsState state) {
    final activeCount = state.filters.activeCount;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppSearchField(
                hint: 'ابحث عن ملعب...',
                controller: _searchController,
                onChanged: (value) =>
                    cubit.updateFilters(state.filters.copyWith(query: value)),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            HeaderIconButton(
              icon: state.showMap ? Icons.list_rounded : Icons.map_outlined,
              onTap: cubit.toggleMap,
              tooltip: state.showMap ? 'عرض قائمة' : 'عرض خريطة',
            ),
            const SizedBox(width: AppSizes.xs),
            Stack(
              clipBehavior: Clip.none,
              children: [
                HeaderIconButton(
                  icon: Icons.tune_rounded,
                  onTap: cubit.toggleFilters,
                  tooltip: 'الفلاتر',
                  isActive: state.showFilters,
                ),
                if (activeCount > 0) _FilterBadge(count: activeCount),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
      ],
    );
  }

  Widget _buildListBody(CourtsCubit cubit, CourtsState state) {
    return Column(
      children: [
        if (state.showFilters) _filterPanel(cubit, state),
        Expanded(child: _listContent(cubit, state)),
      ],
    );
  }

  Widget _listContent(CourtsCubit cubit, CourtsState state) {
    switch (state.status) {
      case CourtsStatus.loading:
      case CourtsStatus.initial:
        return const Center(child: CircularProgressIndicator());
      case CourtsStatus.failure:
        return CourtsErrorView(
          message: state.error ?? 'تعذّر تحميل الملاعب',
          onRetry: () => cubit.loadCourts(),
        );
      case CourtsStatus.success:
        if (state.filtered.isEmpty) return const CourtsEmptyView();
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          itemCount: state.filtered.length,
          itemBuilder: (context, index) {
            final court = state.filtered[index];
            return CourtCard(
              court: court,
              isFavorite: state.favoriteIds.contains(court.id),
              onFavoriteTap: () => cubit.toggleFavorite(court.id),
              onBookTap: () => widget.onNavigateToCourt?.call(court.id),
            );
          },
        );
    }
  }

  Widget _buildMapBody(CourtsCubit cubit, CourtsState state) {
    return Stack(
      children: [
        CourtsMapView(courts: state.filtered),
        if (state.showFilters)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _filterPanel(cubit, state),
          ),
      ],
    );
  }

  Widget _filterPanel(CourtsCubit cubit, CourtsState state) {
    return CourtsFilterPanel(
      filters: state.filters,
      onChanged: cubit.updateFilters,
      onReset: cubit.resetFilters,
    );
  }
}

/// Small count badge overlaid on the filters button.
class _FilterBadge extends StatelessWidget {
  const _FilterBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -4,
      left: -4,
      child: Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
