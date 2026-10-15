import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sporta_app/core/di/service_locator.dart';
import 'package:sporta_app/core/state/app_scope.dart';
import 'package:sporta_app/core/state/app_settings.dart';
import 'package:sporta_app/features/venue/data/venue_repository.dart';
import 'package:sporta_app/features/venue/domain/entities/owner_venue.dart';
import 'package:sporta_app/features/venue/presentation/pages/court_schedule_page.dart';
import 'package:sporta_app/features/venue/presentation/widgets/court_schedule_widgets.dart';

/// ملعب بدوام مختلط: الجمعة مغلق، والسبت دوام قصير، مع قاعدتَي تسعير.
OwnerCourt _court() => OwnerCourt(
      id: 1,
      name: 'الملعب الأول',
      type: 'indoor',
      pricePerHour: 120,
      isAvailable: true,
      bookingTiers: const [CourtTier(durationMinutes: 60, price: 120)],
      openingHours: [
        for (var d = 0; d < 7; d++)
          if (d == 5)
            CourtOpeningHour(day: d, isClosed: true)
          else if (d == 6)
            CourtOpeningHour(day: d, openHour: 8, closeHour: 14)
          else
            CourtOpeningHour(day: d),
      ],
      priceRules: const [
        CourtPriceRule(
            day: null, startHour: 16, endHour: 24, adjustmentPercent: 30),
        CourtPriceRule(
            day: 4, startHour: 16, endHour: 24, adjustmentPercent: 50),
      ],
    );

Widget _app(OwnerCourt court) => AppScope(
      settings: AppSettings(),
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: CourtSchedulePage(court: court),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // الصفحة تترجم عبر trg، وهي تقرأ اللغة من AppSettings في getIt.
    if (!getIt.isRegistered<AppSettings>()) {
      getIt.registerSingleton<AppSettings>(AppSettings());
    }
    // الصفحة تحقن المستودع عبر getIt، ولا تستدعيه إلا عند الحفظ.
    if (!getIt.isRegistered<VenueRepository>()) {
      getIt.registerLazySingleton<VenueRepository>(
          () => VenueRepository(Dio()));
    }
  });

  testWidgets('جدول الملعب يعرض الأيام السبعة بدوامها', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_app(_court()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // القائمة كسولة، فنمرر حتى كل يوم بدل توقّع بنائها كلها دفعةً واحدة.
    for (final day in CourtOpeningHour.dayNames) {
      await tester.scrollUntilVisible(find.text(day), 120);
      expect(find.text(day), findsWidgets, reason: 'اليوم $day مفقود');
    }

    // الجمعة الوحيد المغلق.
    expect(find.text('مغلق'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('قواعد التسعير تظهر بنسبها', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_app(_court()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('+30%'), 200);
    expect(find.text('+30%'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('+50%'), 200);
    expect(find.text('+50%'), findsOneWidget);
    // السعر بعد التعديل معروض بجانب النسبة (120 × 1.3 و120 × 1.5).
    expect(find.text('180 ر.س'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('إغلاق يوم يخفي ساعاته، وإعادة فتحه تُظهرها', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_app(_court()));
    await tester.pumpAndSettle();

    // صف الأحد وحده — القائمة كسولة فلا يصح العدّ على مستوى الصفحة.
    Finder inSunday(Finder matching) => find.descendant(
        of: find.byType(OpeningDayRow).first, matching: matching);

    expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
    expect(inSunday(find.byType(HourDropdown)), findsNWidgets(2));
    expect(inSunday(find.text('مغلق')), findsNothing);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
    // اليوم المغلق يفقد قائمتَي الساعات ويظهر بحالة "مغلق".
    expect(inSunday(find.byType(HourDropdown)), findsNothing);
    expect(inSunday(find.text('مغلق')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('إضافة قاعدة سعر تضيف بطاقة جديدة', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_app(_court()));
    await tester.pumpAndSettle();

    final button = find.text('إضافة قاعدة سعر');
    await tester.scrollUntilVisible(button, 200);
    // شريط الحفظ السفلي يغطي آخر الصفحة، فنمرر قليلاً بعد ظهور الزر.
    await tester.drag(find.byType(ListView), const Offset(0, -150));
    await tester.pumpAndSettle();

    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // ‎+25%‎ هي نسبة القاعدة الجديدة الافتراضية.
    await tester.scrollUntilVisible(find.text('+25%'), 200);
    expect(find.text('+25%'), findsOneWidget);
  });
}
