import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sporta_app/core/di/service_locator.dart';
import 'package:sporta_app/core/network/paged.dart';
import 'package:sporta_app/core/state/app_scope.dart';
import 'package:sporta_app/core/state/app_settings.dart';
import 'package:sporta_app/core/widgets/filter_chip_group.dart';
import 'package:sporta_app/core/widgets/filter_header_button.dart';
import 'package:sporta_app/core/widgets/filter_sheet.dart';
import 'package:sporta_app/features/coaches/data/coach_repository.dart';
import 'package:sporta_app/features/coaches/domain/entities/coach_entity.dart';
import 'package:sporta_app/features/coaches/presentation/cubit/coaches_cubit.dart';
import 'package:sporta_app/features/courts/data/court_favorites_hub.dart';
import 'package:sporta_app/features/courts/data/court_repository.dart';
import 'package:sporta_app/features/courts/domain/entities/court_entity.dart';
import 'package:sporta_app/features/courts/presentation/cubit/courts_list/courts_cubit.dart';
import 'package:sporta_app/features/locations/data/location_models.dart';
import 'package:sporta_app/features/locations/data/location_repository.dart';

Widget _host(Widget child) => AppScope(
  settings: AppSettings(),
  child: MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: child),
    ),
  ),
);

/// Opens the shared sheet from a button and records what it resolved to.
Widget _sheetOpener(void Function(String?) onResult) {
  return Builder(
    builder: (context) => TextButton(
      onPressed: () async {
        final applied = await showFilterSheet<String>(
          context: context,
          initialValue: 'all',
          builder: (ctx, draft, onChanged) => FilterSection(
            title: 'تصفية حسب',
            child: FilterChipGroup(
              options: const [('all', 'الكل'), ('men', 'رجال')],
              selected: draft,
              onSelected: onChanged,
            ),
          ),
        );
        onResult(applied);
      },
      child: const Text('open'),
    ),
  );
}

CourtEntity _court({
  required String id,
  required String city,
  CourtType type = CourtType.indoor,
  CourtGender gender = CourtGender.men,
  int price = 100,
}) => CourtEntity(
  id: id,
  name: 'ملعب $id',
  rating: 4.6,
  reviews: 10,
  distance: '',
  distanceValue: 1,
  city: city,
  neighborhood: '',
  country: 'السعودية',
  type: type,
  gender: gender,
  basePrice: price,
  peakHourPrice: price,
  availableTimes: const [],
  availableDurations: const [60, 90],
  facilities: const [],
);

CoachEntity _coach({
  required String id,
  required String gender,
  required int levelMin,
  required int levelMax,
}) => CoachEntity(
  id: id,
  name: 'مدرب $id',
  avatarInitials: 'م',
  rating: 4.5,
  reviews: 3,
  students: 5,
  levelMin: levelMin,
  levelMax: levelMax,
  location: 'الرياض',
  price: 150,
  specialties: const [],
  badgeLabel: '',
  badgeType: '',
  avatarGradientColors: const [],
  gender: gender,
);

class _FakeCourtRepository extends CourtRepository {
  _FakeCourtRepository(this.courts) : super(Dio());

  final List<CourtEntity> courts;

  /// Mirrors the server-side filtering the real endpoint does.
  int calls = 0;

  @override
  Future<Paged<CourtEntity>> fetchCourts({
    String? city,
    String? type,
    String? gender,
    int page = 1,
    int pageSize = 20,
  }) async {
    calls++;
    final items = courts.where((c) {
      if (city != null && city.isNotEmpty && c.city != city) return false;
      if (type != null && c.type.name != type) return false;
      if (gender != null && c.gender.name != gender) return false;
      return true;
    }).toList();
    return Paged(
      items: items,
      page: page,
      pageSize: pageSize,
      total: items.length,
      hasMore: false,
    );
  }
}

class _FakeLocationRepository extends LocationRepository {
  _FakeLocationRepository() : super(Dio());

  @override
  Future<List<CityEntity>> fetchCities() async => const [
    CityEntity(id: 1, nameAr: 'الرياض', nameEn: 'Riyadh'),
  ];

  @override
  Future<List<DistrictEntity>> fetchDistricts(int cityId) async => const [
    DistrictEntity(id: 5, cityId: 1, nameAr: 'العليا', nameEn: 'Olaya'),
  ];
}

class _FakeCoachRepository extends CoachRepository {
  _FakeCoachRepository(this.coaches) : super(Dio());

  final List<CoachEntity> coaches;

  @override
  Future<Paged<CoachEntity>> fetchCoaches({
    String? city,
    String? gender,
    int page = 1,
    int pageSize = 20,
  }) async => Paged(
    items: coaches,
    page: page,
    pageSize: pageSize,
    total: coaches.length,
    hasMore: false,
  );
}

void main() {
  // الكيوبتات تترجم عبر trg، وهي تقرأ اللغة من AppSettings في getIt.
  setUpAll(() {
    if (!getIt.isRegistered<AppSettings>()) {
      getIt.registerSingleton<AppSettings>(AppSettings());
    }
  });

  group('shared filter sheet', () {
    testWidgets('applies the draft only when تطبيق is pressed', (tester) async {
      String? result;
      var called = false;
      await tester.pumpWidget(
        _host(
          _sheetOpener((v) {
            result = v;
            called = true;
          }),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Picking a chip stays inside the sheet.
      expect(called, isFalse);
      await tester.tap(find.text('رجال'));
      await tester.pumpAndSettle();
      expect(called, isFalse);

      await tester.tap(find.text('تطبيق'));
      await tester.pumpAndSettle();
      expect(result, 'men');
    });

    testWidgets('the close icon discards the draft', (tester) async {
      String? result = 'untouched';
      await tester.pumpWidget(_host(_sheetOpener((v) => result = v)));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('رجال'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(result, isNull, reason: 'a dismissed sheet applies nothing');
    });
  });

  group('filter header button', () {
    testWidgets('opens the sheet while no filter is applied', (tester) async {
      var opened = 0, cleared = 0;
      await tester.pumpWidget(
        _host(
          FilterHeaderButton(
            activeCount: 0,
            onOpen: () => opened++,
            onClear: () => cleared++,
          ),
        ),
      );

      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.tune_rounded));
      expect((opened, cleared), (1, 0));
    });

    testWidgets('turns into a clear button once filters are applied', (
      tester,
    ) async {
      var opened = 0, cleared = 0;
      await tester.pumpWidget(
        _host(
          FilterHeaderButton(
            activeCount: 2,
            onOpen: () => opened++,
            onClear: () => cleared++,
          ),
        ),
      );

      expect(find.byIcon(Icons.filter_alt_off_rounded), findsOneWidget);
      expect(find.text('2'), findsOneWidget, reason: 'badge shows the count');
      await tester.tap(find.byIcon(Icons.filter_alt_off_rounded));
      expect((opened, cleared), (0, 1));
    });
  });

  group('courts filters', () {
    late _FakeCourtRepository repository;
    late CourtsCubit cubit;

    setUp(() {
      repository = _FakeCourtRepository([
        _court(id: '1', city: 'الرياض', type: CourtType.indoor),
        _court(id: '2', city: 'الرياض', type: CourtType.outdoor),
        _court(id: '3', city: 'جدة', type: CourtType.indoor),
      ]);
      cubit = CourtsCubit(
        repository,
        _FakeLocationRepository(),
        CourtFavoritesHub(),
      );
    });

    tearDown(() => cubit.close());

    test('type and city narrow the list, reset brings it back', () async {
      await cubit.loadCourts();
      expect(cubit.state.filtered.length, 3);

      cubit.updateFilters(cubit.state.filters.copyWith(type: CourtType.indoor));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.filtered.map((c) => c.id), ['1', '3']);

      cubit.updateFilters(cubit.state.filters.copyWith(city: 'جدة'));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.filtered.map((c) => c.id), ['3']);
      expect(cubit.state.filters.activeCount, 2);

      cubit.resetFilters();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.filtered.length, 3);
      expect(cubit.state.filters.activeCount, 0);
    });

    test('clearing the filters keeps the search text', () async {
      await cubit.loadCourts();
      cubit.updateFilters(cubit.state.filters.copyWith(query: 'ملعب 1'));
      cubit.updateFilters(
        cubit.state.filters.copyWith(gender: CourtGender.men),
      );
      await Future<void>.delayed(Duration.zero);

      cubit.resetFilters();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.filters.query, 'ملعب 1');
      expect(cubit.state.filtered.map((c) => c.id), ['1']);
    });

    test('selecting a city loads its districts for the sheet', () async {
      await cubit.loadCourts();
      cubit.updateFilters(cubit.state.filters.copyWith(city: 'الرياض'));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.districts.map((d) => d.nameAr), ['العليا']);
    });
  });

  group('coaches filters', () {
    test('level and gender apply together and clear together', () async {
      final cubit = CoachesCubit(
        _FakeCoachRepository([
          _coach(id: '1', gender: 'male', levelMin: 1, levelMax: 3),
          _coach(id: '2', gender: 'female', levelMin: 1, levelMax: 3),
          _coach(id: '3', gender: 'male', levelMin: 5, levelMax: 7),
        ]),
      );
      await cubit.loadCoaches();
      expect(cubit.state.filtered.length, 3);

      cubit.setFilters(levelFilter: 'مبتدئ', genderFilter: 'رجال');
      expect(cubit.state.filtered.map((c) => c.id), ['1']);

      cubit.resetFilters();
      expect(cubit.state.filtered.length, 3);
      expect(cubit.state.levelFilter, 'الكل');
      expect(cubit.state.genderFilter, 'الكل');

      await cubit.close();
    });
  });
}
