part of 'coaches_cubit.dart';

enum CoachesStatus { initial, loading, success, failure }

class CoachesState extends Equatable {
  const CoachesState({
    this.status = CoachesStatus.initial,
    this.coaches = const [],
    this.filtered = const [],
    this.query = '',
    this.levelFilter = 'الكل',
    this.genderFilter = 'الكل',
    this.page = 1,
    this.hasMore = false,
    this.loadingMore = false,
    this.error,
  });

  final CoachesStatus status;

  /// All coaches returned by the API.
  final List<CoachEntity> coaches;

  /// Coaches after the search/level filters are applied.
  final List<CoachEntity> filtered;

  final String query;
  final String levelFilter;

  /// Coach gender filter: 'الكل' | 'رجال' | 'نساء'.
  final String genderFilter;

  /// Last loaded page number.
  final int page;

  /// Whether the server has more pages to load.
  final bool hasMore;

  /// Whether a next-page request is in flight.
  final bool loadingMore;

  final String? error;

  CoachesState copyWith({
    CoachesStatus? status,
    List<CoachEntity>? coaches,
    List<CoachEntity>? filtered,
    String? query,
    String? levelFilter,
    String? genderFilter,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    String? error,
  }) {
    return CoachesState(
      status: status ?? this.status,
      coaches: coaches ?? this.coaches,
      filtered: filtered ?? this.filtered,
      query: query ?? this.query,
      levelFilter: levelFilter ?? this.levelFilter,
      genderFilter: genderFilter ?? this.genderFilter,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    coaches,
    filtered,
    query,
    levelFilter,
    genderFilter,
    page,
    hasMore,
    loadingMore,
    error,
  ];
}
