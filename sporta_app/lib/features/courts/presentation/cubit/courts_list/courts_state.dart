part of 'courts_cubit.dart';

enum CourtsStatus { initial, loading, success, failure }

/// The set of filters/sorting the user can apply to the courts list. Kept as a
/// small immutable value object with [copyWith] so the cubit can update one
/// field at a time.
///
/// البحث بالوقت هو الوضع الافتراضي: بلا اختيار تفتح الصفحة على «اليوم، من
/// الآن إلى منتصف الليل». [date] و[fromHour] الفارغان يُحسبان وقت الطلب
/// ([slotDate]/[slotFromHour]) حتى لا يتجمّد «الآن» على لحظة فتح الصفحة.
class CourtsFilters extends Equatable {
  const CourtsFilters({
    this.query = '',
    this.sortBy = 'available',
    this.city = '',
    this.district = '',
    this.type,
    this.gender,
    this.priceRange = 'all',
    this.ratingFilter = 'all',
    this.date,
    this.fromHour,
    this.toHour = 24,
    this.slotDuration = 60,
    this.onlyAvailable = false,
  });

  final String query;
  final String sortBy;
  final String city;

  /// اسم الحي — only meaningful while a city is selected.
  final String district;

  final CourtType? type;
  final CourtGender? gender;
  final String priceRange;
  final String ratingFilter;

  /// يوم البحث بالوقت؛ null = اليوم (بساعة السعودية).
  final DateTime? date;

  /// بداية نافذة الوقت (0–23)؛ null = الساعة الحالية لليوم، وأول اليوم لغيره.
  final int? fromHour;

  /// نهاية نافذة الوقت (1–24)، غير شاملة: الموعد يبدأ قبلها.
  final int toHour;

  /// مدة الحجز المطلوبة بالدقائق — المواعيد تُحسب بها.
  final int slotDuration;

  /// إخفاء الملاعب التي لا مواعيد فارغة لها في النافذة.
  final bool onlyAvailable;

  /// اليوم الفعلي للطلب (بلا وقت).
  DateTime get slotDate {
    final d = date ?? ksaNow();
    return DateTime(d.year, d.month, d.day);
  }

  bool get isToday {
    final now = ksaNow();
    final d = slotDate;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  /// بداية النافذة الفعلية للطلب.
  int get slotFromHour => fromHour ?? (isToday ? ksaNow().hour : 0);

  /// Number of non-default filters currently applied (drives the badge count).
  /// حقول البحث بالوقت لا تُحسب: لها شريطها الظاهر، وزر الفلاتر النشط يمسح
  /// ما يعدّه.
  int get activeCount {
    var count = 0;
    if (city.isNotEmpty) count++;
    if (district.isNotEmpty) count++;
    if (type != null) count++;
    if (gender != null) count++;
    if (priceRange != 'all') count++;
    if (ratingFilter != 'all') count++;
    if (sortBy != 'available') count++;
    return count;
  }

  /// هل تغيّر ما يرسله البحث بالوقت إلى الخادم؟
  bool sameSlotWindow(CourtsFilters other) =>
      date == other.date &&
      fromHour == other.fromHour &&
      toHour == other.toHour &&
      slotDuration == other.slotDuration &&
      onlyAvailable == other.onlyAvailable;

  /// فلاتر افتراضية تحتفظ بالبحث والنافذة الحالية — «مسح الفلاتر» لا يمسّهما.
  CourtsFilters resetKeepingWindow() => CourtsFilters(
        query: query,
        date: date,
        fromHour: fromHour,
        toHour: toHour,
        slotDuration: slotDuration,
        onlyAvailable: onlyAvailable,
      );

  CourtsFilters copyWith({
    String? query,
    String? sortBy,
    String? city,
    String? district,
    CourtType? type,
    CourtGender? gender,
    String? priceRange,
    String? ratingFilter,
    DateTime? date,
    int? fromHour,
    int? toHour,
    int? slotDuration,
    bool? onlyAvailable,
    bool clearType = false,
    bool clearGender = false,
    bool clearDate = false,
    bool clearFromHour = false,
  }) {
    return CourtsFilters(
      query: query ?? this.query,
      sortBy: sortBy ?? this.sortBy,
      city: city ?? this.city,
      district: district ?? this.district,
      type: clearType ? null : (type ?? this.type),
      gender: clearGender ? null : (gender ?? this.gender),
      priceRange: priceRange ?? this.priceRange,
      ratingFilter: ratingFilter ?? this.ratingFilter,
      date: clearDate ? null : (date ?? this.date),
      fromHour: clearFromHour ? null : (fromHour ?? this.fromHour),
      toHour: toHour ?? this.toHour,
      slotDuration: slotDuration ?? this.slotDuration,
      onlyAvailable: onlyAvailable ?? this.onlyAvailable,
    );
  }

  @override
  List<Object?> get props => [
        query, sortBy, city, district, type, gender, priceRange, ratingFilter,
        date, fromHour, toHour, slotDuration, onlyAvailable,
      ];
}

class CourtsState extends Equatable {
  const CourtsState({
    this.status = CourtsStatus.initial,
    this.courts = const [],
    this.filtered = const [],
    this.favoriteIds = const {},
    this.cities = const [],
    this.districts = const [],
    this.filters = const CourtsFilters(),
    this.showMap = false,
    this.page = 1,
    this.hasMore = false,
    this.loadingMore = false,
    this.error,
  });

  final CourtsStatus status;

  /// All courts returned by the API.
  final List<CourtEntity> courts;

  /// Courts after client-side filtering/sorting are applied.
  final List<CourtEntity> filtered;

  /// Ids of courts the user marked as favorite (UI-only for now).
  final Set<String> favoriteIds;

  /// Cities available in the filter panel, loaded from the locations API.
  final List<CityEntity> cities;

  /// Districts of the currently selected city — empty when no city is picked.
  final List<DistrictEntity> districts;

  final CourtsFilters filters;

  /// Whether the map view (vs. list) is shown.
  final bool showMap;

  /// Last loaded page number.
  final int page;

  /// Whether the server has more pages to load.
  final bool hasMore;

  /// Whether a next-page request is in flight.
  final bool loadingMore;

  final String? error;

  CourtsState copyWith({
    CourtsStatus? status,
    List<CourtEntity>? courts,
    List<CourtEntity>? filtered,
    Set<String>? favoriteIds,
    List<CityEntity>? cities,
    List<DistrictEntity>? districts,
    CourtsFilters? filters,
    bool? showMap,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    String? error,
  }) {
    return CourtsState(
      status: status ?? this.status,
      courts: courts ?? this.courts,
      filtered: filtered ?? this.filtered,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      cities: cities ?? this.cities,
      districts: districts ?? this.districts,
      filters: filters ?? this.filters,
      showMap: showMap ?? this.showMap,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        status, courts, filtered, favoriteIds, cities, districts, filters,
        showMap, page, hasMore, loadingMore, error,
      ];
}
