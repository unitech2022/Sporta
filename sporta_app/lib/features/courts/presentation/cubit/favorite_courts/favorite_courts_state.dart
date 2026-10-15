part of 'favorite_courts_cubit.dart';

enum FavoriteCourtsStatus { initial, loading, success, failure }

class FavoriteCourtsState extends Equatable {
  const FavoriteCourtsState({
    this.status = FavoriteCourtsStatus.initial,
    this.courts = const [],
    this.page = 1,
    this.hasMore = false,
    this.loadingMore = false,
    this.error,
  });

  final FavoriteCourtsStatus status;

  /// المفضّلة بترتيب الخادم: الأحدث إضافةً أولاً.
  final List<CourtEntity> courts;

  /// آخر صفحة محمّلة وهل بقي بعدها المزيد.
  final int page;
  final bool hasMore;

  /// طلب صفحة تالية قيد التنفيذ.
  final bool loadingMore;

  final String? error;

  FavoriteCourtsState copyWith({
    FavoriteCourtsStatus? status,
    List<CourtEntity>? courts,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    String? error,
  }) {
    return FavoriteCourtsState(
      status: status ?? this.status,
      courts: courts ?? this.courts,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, courts, page, hasMore, loadingMore, error];
}
