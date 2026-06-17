import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../auth/data/models/api_exception.dart';
import '../../../data/court_repository.dart';
import '../../../domain/entities/court_entity.dart';
import '../../courts_helpers.dart';

part 'courts_state.dart';

/// Drives the courts list screen: loading from the repository and applying the
/// user's filters/sorting. No networking lives here — it delegates to
/// [CourtRepository].
class CourtsCubit extends Cubit<CourtsState> {
  CourtsCubit(this._repository) : super(const CourtsState());

  final CourtRepository _repository;

  /// Fetches courts from the API and applies the current filters.
  Future<void> loadCourts({bool isArabic = true}) async {
    emit(state.copyWith(status: CourtsStatus.loading, error: null));
    try {
      final courts = await _repository.fetchCourts();
      emit(state.copyWith(
        status: CourtsStatus.success,
        courts: courts,
        filtered: _applyFilters(courts, state.filters),
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: CourtsStatus.failure,
        error: e.localized(isArabic),
      ));
    }
  }

  /// Replaces the active filters and recomputes the visible list.
  void updateFilters(CourtsFilters filters) {
    emit(state.copyWith(
      filters: filters,
      filtered: _applyFilters(state.courts, filters),
    ));
  }

  /// Clears all filters back to their defaults.
  void resetFilters() => updateFilters(const CourtsFilters());

  /// Toggles between the list and map views.
  void toggleMap() => emit(state.copyWith(showMap: !state.showMap));

  /// Expands or collapses the filter panel.
  void toggleFilters() => emit(state.copyWith(showFilters: !state.showFilters));

  /// Toggles a court's favorite flag (UI-only state).
  void toggleFavorite(String courtId) {
    final favorites = Set<String>.from(state.favoriteIds);
    if (!favorites.add(courtId)) favorites.remove(courtId);
    emit(state.copyWith(favoriteIds: favorites));
  }

  List<CourtEntity> _applyFilters(List<CourtEntity> courts, CourtsFilters f) {
    var result = filterCourts(
      courts: courts,
      query: f.query,
      sortBy: f.sortBy,
      selectedCity: f.city,
      selectedType: f.type,
      selectedGender: f.gender,
      priceRange: f.priceRange,
      ratingFilter: f.ratingFilter,
    );
    if (f.duration != 'all') {
      final dur = int.tryParse(f.duration);
      if (dur != null) {
        result = result.where((c) => c.availableDurations.contains(dur)).toList();
      }
    }
    return result;
  }
}
