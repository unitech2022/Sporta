part of 'courts_cubit.dart';

enum CourtsStatus { initial, loading, success, failure }

/// The set of filters/sorting the user can apply to the courts list. Kept as a
/// small immutable value object with [copyWith] so the cubit can update one
/// field at a time.
class CourtsFilters extends Equatable {
  const CourtsFilters({
    this.query = '',
    this.sortBy = 'rating',
    this.city = '',
    this.type,
    this.gender,
    this.priceRange = 'all',
    this.ratingFilter = 'all',
    this.duration = 'all',
  });

  final String query;
  final String sortBy;
  final String city;
  final CourtType? type;
  final CourtGender? gender;
  final String priceRange;
  final String ratingFilter;
  final String duration;

  /// Number of non-default filters currently applied (drives the badge count).
  int get activeCount {
    var count = 0;
    if (city.isNotEmpty) count++;
    if (type != null) count++;
    if (gender != null) count++;
    if (priceRange != 'all') count++;
    if (ratingFilter != 'all') count++;
    if (duration != 'all') count++;
    if (sortBy != 'rating') count++;
    return count;
  }

  CourtsFilters copyWith({
    String? query,
    String? sortBy,
    String? city,
    CourtType? type,
    CourtGender? gender,
    String? priceRange,
    String? ratingFilter,
    String? duration,
    bool clearType = false,
    bool clearGender = false,
  }) {
    return CourtsFilters(
      query: query ?? this.query,
      sortBy: sortBy ?? this.sortBy,
      city: city ?? this.city,
      type: clearType ? null : (type ?? this.type),
      gender: clearGender ? null : (gender ?? this.gender),
      priceRange: priceRange ?? this.priceRange,
      ratingFilter: ratingFilter ?? this.ratingFilter,
      duration: duration ?? this.duration,
    );
  }

  @override
  List<Object?> get props =>
      [query, sortBy, city, type, gender, priceRange, ratingFilter, duration];
}

class CourtsState extends Equatable {
  const CourtsState({
    this.status = CourtsStatus.initial,
    this.courts = const [],
    this.filtered = const [],
    this.favoriteIds = const {},
    this.filters = const CourtsFilters(),
    this.showMap = false,
    this.showFilters = false,
    this.error,
  });

  final CourtsStatus status;

  /// All courts returned by the API.
  final List<CourtEntity> courts;

  /// Courts after client-side filtering/sorting are applied.
  final List<CourtEntity> filtered;

  /// Ids of courts the user marked as favorite (UI-only for now).
  final Set<String> favoriteIds;

  final CourtsFilters filters;

  /// Whether the map view (vs. list) is shown.
  final bool showMap;

  /// Whether the filter panel is expanded.
  final bool showFilters;

  final String? error;

  CourtsState copyWith({
    CourtsStatus? status,
    List<CourtEntity>? courts,
    List<CourtEntity>? filtered,
    Set<String>? favoriteIds,
    CourtsFilters? filters,
    bool? showMap,
    bool? showFilters,
    String? error,
  }) {
    return CourtsState(
      status: status ?? this.status,
      courts: courts ?? this.courts,
      filtered: filtered ?? this.filtered,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      filters: filters ?? this.filters,
      showMap: showMap ?? this.showMap,
      showFilters: showFilters ?? this.showFilters,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [status, courts, filtered, favoriteIds, filters, showMap, showFilters, error];
}
