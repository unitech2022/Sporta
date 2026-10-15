import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sporta_app/app/sporta_app.dart';
import 'package:sporta_app/core/di/service_locator.dart';
import 'package:sporta_app/core/storage/local_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // نفس تهيئة main(): التطبيق يقرأ اللغة والمستودعات من getIt، ويقرأ الجلسة
  // المحفوظة من التخزين الآمن/المحلي — وكلاهما يحتاج قيماً وهمية في الاختبار،
  // وإلا بقي التطبيق على شاشة البداية إلى الأبد (قناة الإضافة لا تُجيب هنا).
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(const {});
    FlutterSecureStorage.setMockInitialValues(const {});
    await LocalPrefs.init();
    setupLocator();
  });

  /// يفتح التطبيق ويتخطّى شاشة البداية وبوابات الصيانة/التحديث/استعادة الجلسة.
  ///
  /// لا يصلح `pumpAndSettle` هنا: شاشة البداية تعرض مؤشر تحميل دائر لا يتوقف،
  /// فنُقدّم الزمن يدوياً حتى تظهر صفحة الترحيب (بلا جلسة محفوظة).
  Future<void> pumpAppPastSplash(WidgetTester tester) async {
    // مقاس واسع نسبياً: صفحات الترحيب/التسجيل تتجاوز عرض 390 بكسل.
    await tester.binding.setSurfaceSize(const Size(500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const SportaApp());
    for (var i = 0; i < 30; i++) {
      if (find.text('إنشاء حساب جديد').evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 100));
    }
    fail('التطبيق لم يصل إلى صفحة الترحيب بعد تخطّي شاشة البداية');
  }

  testWidgets('the app opens on the splash, then lands on the welcome page',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const SportaApp());
    await tester.pump();
    // شاشة البداية أولاً بينما تُفحص الجلسة المحفوظة.
    expect(find.text('إنشاء حساب جديد'), findsNothing);

    for (var i = 0; i < 30; i++) {
      if (find.text('إنشاء حساب جديد').evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('إنشاء حساب جديد'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('لديك حساب بالفعل؟'), findsOneWidget);
  });

  testWidgets('register goes to language selection then registration steps',
      (WidgetTester tester) async {
    await pumpAppPastSplash(tester);

    await tester.tap(find.text('إنشاء حساب جديد'));
    await tester.pumpAndSettle();
    expect(find.text('اختر اللغة'), findsOneWidget);
    expect(find.text('خطوة 1 من 4'), findsOneWidget);

    // اختيار اللغة يبرز الخيار فقط؛ الانتقال يتم بزر "التالي".
    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    expect(find.text('البيانات الشخصية'), findsOneWidget);
    expect(find.text('خطوة 1 من 3'), findsOneWidget);
  });

  // تسجيل دخول فعلي يحتاج خادماً، وهو غير متاح في اختبارات الوحدة — لذا نتحقق
  // من وصول الزر إلى نموذج الدخول كاملاً وجاهزاً للإدخال.
  testWidgets('login opens the sign-in form', (WidgetTester tester) async {
    await pumpAppPastSplash(tester);

    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pumpAndSettle();

    expect(find.text('أهلاً بعودتك!'), findsOneWidget);
    expect(find.text('رقم الجوال'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).first, '0501234567');
    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'تسجيل الدخول'), findsOneWidget);
  });
}
