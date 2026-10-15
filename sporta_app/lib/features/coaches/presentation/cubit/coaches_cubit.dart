import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/models/api_exception.dart';
import '../../data/coach_repository.dart';
import '../../domain/entities/coach_entity.dart';

part 'coaches_state.dart';

/// Drives the coaches list screen: loads coaches from the repository and applies
/// the search query + level/gender filters. Networking lives in [CoachRepository].
class CoachesCubit extends Cubit<CoachesState> {
  CoachesCubit(this._repository) : super(const CoachesState());

  final CoachRepository _repository;

  Future<void> loadCoaches({bool isArabic = true}) async {
    emit(state.copyWith(status: CoachesStatus.loading, error: null));
    try {
      final page = await _repository.fetchCoaches();
      emit(
        state.copyWith(
          status: CoachesStatus.success,
          coaches: page.items,
          filtered: _applyFilters(
            page.items,
            state.query,
            state.levelFilter,
            state.genderFilter,
          ),
          page: page.page,
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(status: CoachesStatus.failure, error: e.display));
    }
  }

  /// Appends the next page when the list scrolls near its end.
  Future<void> loadMore() async {
    if (state.status != CoachesStatus.success ||
        !state.hasMore ||
        state.loadingMore) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _repository.fetchCoaches(page: state.page + 1);
      final coaches = [...state.coaches, ...page.items];
      emit(
        state.copyWith(
          coaches: coaches,
          filtered: _applyFilters(
            coaches,
            state.query,
            state.levelFilter,
            state.genderFilter,
          ),
          page: page.page,
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      );
    } on ApiException {
      // Keep what's loaded; the user can scroll again to retry.
      emit(state.copyWith(loadingMore: false));
    }
  }

  void search(String query) {
    emit(
      state.copyWith(
        query: query,
        filtered: _applyFilters(
          state.coaches,
          query,
          state.levelFilter,
          state.genderFilter,
        ),
      ),
    );
  }

  /// Applies the level ('الكل' | 'مبتدئ' | 'متوسط' | 'متقدم') and gender
  /// ('الكل' | 'رجال' | 'نساء') filters the filter sheet returns.
  void setFilters({required String levelFilter, required String genderFilter}) {
    emit(
      state.copyWith(
        levelFilter: levelFilter,
        genderFilter: genderFilter,
        filtered: _applyFilters(
          state.coaches,
          state.query,
          levelFilter,
          genderFilter,
        ),
      ),
    );
  }

  /// Clears both filters back to the raw 'الكل' sentinel. Filters are stored
  /// untranslated (the page translates them for display), so a translated
  /// value here would read as an active filter in English.
  void resetFilters() =>
      setFilters(levelFilter: 'الكل', genderFilter: 'الكل');

  List<CoachEntity> _applyFilters(
    List<CoachEntity> coaches,
    String query,
    String levelFilter,
    String genderFilter,
  ) {
    return coaches.where((c) {
      final matchesQuery =
          query.isEmpty || c.name.contains(query) || c.location.contains(query);
      if (!matchesQuery) return false;
      switch (genderFilter) {
        case 'رجال':
          if (c.gender != 'male') return false;
        case 'نساء':
          if (c.gender != 'female') return false;
      }
      switch (levelFilter) {
        case 'مبتدئ':
          return c.levelMax <= 3;
        case 'متوسط':
          return c.levelMin <= 4 && c.levelMax >= 4;
        case 'متقدم':
          return c.levelMax >= 5;
        default:
          return true;
      }
    }).toList();
  }
}
