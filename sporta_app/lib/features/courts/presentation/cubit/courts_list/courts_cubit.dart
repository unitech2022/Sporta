import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../auth/data/models/api_exception.dart';
import '../../../../locations/data/location_models.dart';
import '../../../../locations/data/location_repository.dart';
import '../../../data/court_favorites_hub.dart';
import '../../../data/court_repository.dart';
import '../../../domain/entities/court_entity.dart';
import '../../courts_helpers.dart';
import '../../../../../core/network/paged.dart';
import '../../../../../core/utils/server_time.dart';

part 'courts_state.dart';

/// Drives the courts list screen: loading from the repository and applying the
/// user's filters/sorting. No networking lives here — it delegates to
/// [CourtRepository].
class CourtsCubit extends Cubit<CourtsState> {
  CourtsCubit(this._repository, this._locations, this._favoritesHub)
      : super(const CourtsState()) {
    // الصفحة تبقى حيّة داخل IndexedStack، فتصلها تغيّرات المفضّلة من صفحة
    // «الملاعب المفضلة» عبر الناقل بدل أن تبقى قلوبها قديمة.
    _favoritesSub = _favoritesHub.changes.listen(_onFavoriteChanged);
  }

  final CourtRepository _repository;
  final LocationRepository _locations;
  final CourtFavoritesHub _favoritesHub;
  late final StreamSubscription<CourtFavoriteChange> _favoritesSub;

  @override
  Future<void> close() {
    _favoritesSub.cancel();
    return super.close();
  }

  void _onFavoriteChanged(CourtFavoriteChange change) {
    if (isClosed) return;
    final ids = _withFavorite(change.courtId, change.isFavorite);
    if (ids.length == state.favoriteIds.length) return;   // لا جديد.
    // `error` يُمرَّر لأن copyWith يمسحه افتراضياً.
    emit(state.copyWith(favoriteIds: ids, error: state.error));
  }

  /// Fetches the first page of courts and applies the current filters.
  Future<void> loadCourts({bool isArabic = true}) async {
    loadCities();
    await _reload(state.filters, isArabic: isArabic);
  }

  /// (Re)loads the first page for [filters].
  ///
  /// المدينة/النوع/الجنس تُطبَّق على الخادم: الفلترة المحلية لا ترى إلا الصفحة
  /// المحمّلة، فمدينة ملاعبها خارج أول صفحة كانت تظهر فارغة.
  Future<void> _reload(CourtsFilters filters, {bool isArabic = true}) async {
    emit(state.copyWith(status: CourtsStatus.loading, error: null));
    try {
      final page = await _fetch(filters);
      if (isClosed) return;
      emit(state.copyWith(
        status: CourtsStatus.success,
        courts: page.items,
        filtered: _applyFilters(page.items, filters),
        favoriteIds: _favoriteIdsIn(page.items),
        cities: state.cities.isEmpty ? _citiesFrom(page.items) : state.cities,
        page: page.page,
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: CourtsStatus.failure,
        error: e.display,
      ));
    }
  }

  /// صفحة من الخادم بفلاتره (المدينة/النوع/الجنس) ونافذة البحث بالوقت.
  Future<Paged<CourtEntity>> _fetch(CourtsFilters filters, {int page = 1}) =>
      _repository.fetchCourts(
        city: filters.city,
        type: _typeParam(filters.type),
        gender: _genderParam(filters.gender),
        page: page,
        slotDate: filters.slotDate,
        fromHour: filters.slotFromHour,
        toHour: filters.toHour,
        durationMinutes: filters.slotDuration,
        onlyAvailable: filters.onlyAvailable,
      );

  /// يعيد تحميل الصفحة الأولى — للسحب للتحديث، فيُعاد حساب «الآن» والمواعيد.
  Future<void> refresh() => _reload(state.filters);

  /// Wire values for the filters the API applies itself; null means "no filter".
  static String? _typeParam(CourtType? type) => switch (type) {
        CourtType.indoor => 'indoor',
        CourtType.outdoor => 'outdoor',
        null => null,
      };

  static String? _genderParam(CourtGender? gender) => switch (gender) {
        CourtGender.men => 'men',
        CourtGender.women => 'women',
        CourtGender.family => 'family',
        CourtGender.all || null => null,
      };

  /// Appends the next page when the list scrolls near its end.
  Future<void> loadMore({bool isArabic = true}) async {
    if (state.status != CourtsStatus.success ||
        !state.hasMore ||
        state.loadingMore) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _fetch(state.filters, page: state.page + 1);
      final courts = [...state.courts, ...page.items];
      emit(state.copyWith(
        courts: courts,
        filtered: _applyFilters(courts, state.filters),
        favoriteIds: {...state.favoriteIds, ..._favoriteIdsIn(page.items)},
        page: page.page,
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } on ApiException {
      // Keep what's loaded; the user can scroll again to retry.
      emit(state.copyWith(loadingMore: false));
    }
  }

  /// Loads the cities the admin added in the database; they drive the city
  /// chips in the filter panel. If the request fails we keep whatever cities
  /// the loaded courts mention, so the filter is never empty.
  Future<void> loadCities() async {
    try {
      final cities = await _locations.fetchCities();
      if (isClosed || cities.isEmpty) return;
      // `error` is passed through because copyWith clears it by default.
      emit(state.copyWith(cities: cities, error: state.error));
    } on ApiException {
      if (isClosed || state.cities.isNotEmpty) return;
      emit(state.copyWith(
        cities: _citiesFrom(state.courts),
        error: state.error,
      ));
    }
  }

  /// Distinct city names of the given courts, as a fallback city list.
  List<CityEntity> _citiesFrom(List<CourtEntity> courts) {
    final names = <String>{
      for (final c in courts)
        if (c.city.trim().isNotEmpty) c.city.trim(),
    }.toList()
      ..sort();
    return [
      for (var i = 0; i < names.length; i++)
        CityEntity(id: -(i + 1), nameAr: names[i], nameEn: names[i]),
    ];
  }

  /// Districts of the selected city. Loaded from the locations API, falling
  /// back to the districts the loaded courts mention so the dropdown still
  /// works for venues whose city isn't in the locations table.
  Future<void> loadDistricts(String cityName) async {
    if (cityName.isEmpty) {
      if (!isClosed) emit(state.copyWith(districts: const [], error: state.error));
      return;
    }
    var cityId = 0;
    for (final c in state.cities) {
      if (c.nameAr == cityName) {
        cityId = c.id;
        break;
      }
    }
    List<DistrictEntity> districts = const [];
    // Negative ids come from the court-derived fallback city list: those cities
    // don't exist in the locations table, so there's nothing to fetch.
    if (cityId > 0) {
      try {
        districts = await _locations.fetchDistricts(cityId);
      } on ApiException {
        districts = const [];
      }
    }
    if (isClosed) return;
    emit(state.copyWith(
      districts: districts.isEmpty ? _districtsFrom(state.courts, cityName) : districts,
      error: state.error,
    ));
  }

  /// Distinct district names of the courts in [cityName], as a fallback list.
  List<DistrictEntity> _districtsFrom(List<CourtEntity> courts, String cityName) {
    final names = <String>{
      for (final c in courts)
        if (c.city.trim() == cityName && c.district.trim().isNotEmpty)
          c.district.trim(),
    }.toList()
      ..sort();
    return [
      for (var i = 0; i < names.length; i++)
        DistrictEntity(
          id: -(i + 1),
          cityId: 0,
          nameAr: names[i],
          nameEn: names[i],
        ),
    ];
  }

  /// Replaces the active filters and recomputes the visible list.
  void updateFilters(CourtsFilters filters) {
    // Switching city invalidates the district: its list belongs to the old one.
    final cityChanged = filters.city != state.filters.city;
    final next = cityChanged ? filters.copyWith(district: '') : filters;
    // These are server-side, so changing one needs a fresh first page.
    final refetch = cityChanged ||
        next.type != state.filters.type ||
        next.gender != state.filters.gender ||
        !next.sameSlotWindow(state.filters);
    emit(state.copyWith(
      filters: next,
      filtered: _applyFilters(state.courts, next),
      districts: cityChanged ? const [] : null,
    ));
    if (cityChanged) loadDistricts(next.city);
    if (refetch) _reload(next);
  }

  /// Clears all filters back to their defaults. The search text and the time
  /// window aren't part of the filter sheet, so they stay.
  void resetFilters() => updateFilters(state.filters.resetKeepingWindow());

  /// Toggles between the list and map views.
  void toggleMap() => emit(state.copyWith(showMap: !state.showMap));

  static Set<String> _favoriteIdsIn(List<CourtEntity> courts) =>
      courts.where((c) => c.isFavorite).map((c) => c.id).toSet();

  /// يبدّل مفضّلة ملعب على الخادم. القلب يتحرّك فوراً (تفاؤلياً) ويرتدّ إن فشل
  /// الطلب، فلا تُظهر الواجهة حالة لم تُحفظ فعلاً.
  Future<void> toggleFavorite(String courtId) async {
    final id = int.tryParse(courtId);
    if (id == null) return;

    final wasFavorite = state.favoriteIds.contains(courtId);
    emit(state.copyWith(favoriteIds: _withFavorite(courtId, !wasFavorite)));

    try {
      final saved = await _repository.toggleCourtFavorite(id, !wasFavorite);
      if (isClosed) return;
      emit(state.copyWith(favoriteIds: _withFavorite(courtId, saved)));
      _favoritesHub.publish(courtId, isFavorite: saved);
    } on ApiException {
      if (isClosed) return;
      emit(state.copyWith(favoriteIds: _withFavorite(courtId, wasFavorite)));
    }
  }

  Set<String> _withFavorite(String courtId, bool favorite) {
    final ids = Set<String>.from(state.favoriteIds);
    if (favorite) {
      ids.add(courtId);
    } else {
      ids.remove(courtId);
    }
    return ids;
  }

  List<CourtEntity> _applyFilters(List<CourtEntity> courts, CourtsFilters f) {
    // f.city is intentionally absent: the API already filtered by it, and
    // re-checking the free-text venue city here would drop rows whose spelling
    // differs from the name in the cities list.
    var result = filterCourts(
      courts: courts,
      query: f.query,
      sortBy: f.sortBy,
      selectedType: f.type,
      selectedGender: f.gender,
      priceRange: f.priceRange,
      ratingFilter: f.ratingFilter,
    );
    if (f.district.isNotEmpty) {
      result =
          result.where((c) => c.district.trim() == f.district).toList();
    }
    // الخادم يرتّب من له مواعيد فارغة أولاً؛ الترتيب المحلي (التقييم/السعر)
    // يبقى داخل كل فئة ولا يدفع ملعباً بلا مواعيد فوق المتاح.
    return [
      ...result.where((c) => c.freeSlots?.isNotEmpty ?? false),
      ...result.where((c) => !(c.freeSlots?.isNotEmpty ?? false)),
    ];
  }
}
