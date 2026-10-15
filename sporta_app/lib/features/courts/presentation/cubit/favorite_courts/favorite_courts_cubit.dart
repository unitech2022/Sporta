import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../auth/data/models/api_exception.dart';
import '../../../data/court_favorites_hub.dart';
import '../../../data/court_repository.dart';
import '../../../domain/entities/court_entity.dart';

part 'favorite_courts_state.dart';

/// شاشة «الملاعب المفضّلة»: قائمة مقسّمة لصفحات تُحمَّل تباعاً مع التمرير.
/// إزالة ملعب تُحذفه من القائمة فوراً وترتدّ إن فشل الطلب.
class FavoriteCourtsCubit extends Cubit<FavoriteCourtsState> {
  FavoriteCourtsCubit(this._repository, this._favoritesHub)
      : super(const FavoriteCourtsState());

  final CourtRepository _repository;
  final CourtFavoritesHub _favoritesHub;

  Future<void> load({bool isArabic = true}) async {
    emit(state.copyWith(status: FavoriteCourtsStatus.loading, error: null));
    try {
      final page = await _repository.fetchFavoriteCourts();
      if (isClosed) return;
      emit(state.copyWith(
        status: FavoriteCourtsStatus.success,
        courts: page.items,
        page: page.page,
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: FavoriteCourtsStatus.failure,
        error: e.display,
      ));
    }
  }

  /// يُلحق الصفحة التالية عند اقتراب القائمة من نهايتها.
  Future<void> loadMore() async {
    if (state.status != FavoriteCourtsStatus.success ||
        !state.hasMore ||
        state.loadingMore) {
      return;
    }
    emit(state.copyWith(loadingMore: true, error: state.error));
    try {
      final page = await _repository.fetchFavoriteCourts(page: state.page + 1);
      if (isClosed) return;
      emit(state.copyWith(
        courts: [...state.courts, ...page.items],
        page: page.page,
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } on ApiException {
      // نبقي المحمَّل؛ تمريرة أخرى تعيد المحاولة.
      if (isClosed) return;
      emit(state.copyWith(loadingMore: false, error: state.error));
    }
  }

  /// يزيل الملعب من المفضّلة. الحذف تفاؤلي ويُستعاد الصف في مكانه إن فشل الطلب.
  Future<void> remove(CourtEntity court) async {
    final id = int.tryParse(court.id);
    if (id == null) return;

    final index = state.courts.indexWhere((c) => c.id == court.id);
    if (index < 0) return;

    final without = [...state.courts]..removeAt(index);
    emit(state.copyWith(courts: without));

    try {
      await _repository.toggleCourtFavorite(id, false);
      // تصل قائمة الملاعب الحيّة في الـ shell فيفرغ قلبها هي أيضاً.
      _favoritesHub.publish(court.id, isFavorite: false);
    } on ApiException {
      if (isClosed) return;
      final restored = [...state.courts]..insert(index, court);
      emit(state.copyWith(courts: restored));
    }
  }
}
