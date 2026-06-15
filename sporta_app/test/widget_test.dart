import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sporta_app/app/sporta_app.dart';

void main() {
  testWidgets('app starts at the welcome page with auth actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SportaApp());

    expect(find.text('إنشاء حساب جديد'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('لديك حساب بالفعل؟'), findsOneWidget);
  });

  testWidgets('register goes to language selection then registration steps',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SportaApp());

    await tester.tap(find.text('إنشاء حساب جديد'));
    await tester.pumpAndSettle();
    expect(find.text('اختر اللغة'), findsOneWidget);

    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();
    expect(find.text('المعلومات الأساسية'), findsOneWidget);
    expect(find.text('خطوة 1 من 3'), findsOneWidget);
  });

  testWidgets('login flow reaches sports selection then the main shell',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SportaApp());

    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextField).first, '0501234567');
    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.pumpAndSettle();

    await tester.tap(find.text('تسجيل الدخول').last);
    await tester.pumpAndSettle();
    expect(find.text('مرحباً بك في SPORTA'), findsOneWidget);

    await tester.ensureVisible(find.text('ابدأ تجربة البادل'));
    await tester.tap(find.text('ابدأ تجربة البادل'));
    await tester.pumpAndSettle();
    expect(find.text('الرئيسية'), findsWidgets);
  });
}
