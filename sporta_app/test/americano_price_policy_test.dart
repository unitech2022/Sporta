import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sporta_app/core/di/service_locator.dart';
import 'package:sporta_app/core/network/paged.dart';
import 'package:sporta_app/core/state/app_scope.dart';
import 'package:sporta_app/core/state/app_settings.dart';
import 'package:sporta_app/features/americano/data/americano_repository.dart';
import 'package:sporta_app/features/americano/presentation/pages/americano_create_page.dart';
import 'package:sporta_app/features/courts/data/court_repository.dart';
import 'package:sporta_app/features/courts/domain/entities/court_entity.dart';

class _FakeCourtRepository extends CourtRepository {
  _FakeCourtRepository() : super(Dio());

  @override
  Future<Paged<CourtEntity>> fetchCourts({
    String? city,
    String? type,
    String? gender,
    int page = 1,
    int pageSize = 20,
  }) async =>
      const Paged(items: [], page: 1, pageSize: 20, total: 0, hasMore: false);
}

class _FakeAmericanoRepository extends AmericanoRepository {
  _FakeAmericanoRepository() : super(Dio());
}

Widget _page({bool isTournament = false}) => AppScope(
  settings: AppSettings(),
  child: MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: AmericanoCreatePage(
        onBack: () {},
        onCreated: (_) {},
        isTournament: isTournament,
      ),
    ),
  ),
);

void main() {
  /// The form is long; a tall viewport keeps every field (including the notice
  /// near the bottom) built so the finders can see it.
  Future<void> pumpPage(
    WidgetTester tester, {
    bool isTournament = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(420, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_page(isTournament: isTournament));
    await tester.pumpAndSettle();
  }

  setUp(() {
    // الصفحة تترجم عبر trg، وهي تقرأ اللغة من AppSettings في getIt.
    getIt.registerSingleton<AppSettings>(AppSettings());
    getIt.registerSingleton<CourtRepository>(_FakeCourtRepository());
    getIt.registerSingleton<AmericanoRepository>(_FakeAmericanoRepository());
  });

  tearDown(() => getIt.reset());

  group('americano price policy notice', () {
    testWidgets('shows the notice with an agreement checkbox', (tester) async {
      await pumpPage(tester);

      expect(find.text(kAmericanoPricePolicy), findsOneWidget);
      expect(find.text('تنبيه'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox)).value,
        isFalse,
        reason: 'the creator has to tick it themselves',
      );
    });

    testWidgets('ticking the checkbox records the agreement', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    });

    testWidgets('the create button stays disabled until it is agreed to', (
      tester,
    ) async {
      await pumpPage(tester);

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).last,
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('a teams americano shows the same notice', (tester) async {
      await pumpPage(tester);

      // The type selector's "فرق" option switches to the fixed-2v2 flow.
      await tester.tap(find.text('فرق').last);
      await tester.pumpAndSettle();

      expect(find.text(kAmericanoPricePolicy), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    // التنبيه خاص بالأمريكانو وحده: البطولة لا تعرضه ولا تشترط الموافقة عليه.
    testWidgets('a tournament does not show it', (tester) async {
      await pumpPage(tester, isTournament: true);

      expect(find.text(kAmericanoPricePolicy), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
    });
  });
}
