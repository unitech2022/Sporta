import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sporta_app/app/main_shell.dart';
import 'package:sporta_app/core/state/app_scope.dart';
import 'package:sporta_app/core/state/app_settings.dart';

Widget _app() => AppScope(
      settings: AppSettings(),
      child: const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MainShell(),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MainShell builds all tabs without exception', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(_app());
    var e = tester.takeException();
    if (e != null) fail('MainShell (initial build) threw: $e');

    const tabIcons = [
      Icons.home_outlined,
      Icons.person_outline,
      Icons.emoji_events_outlined,
      Icons.calendar_today_outlined,
      Icons.menu_book_outlined,
    ];

    for (final icon in tabIcons) {
      await tester.tap(find.byIcon(icon).first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      e = tester.takeException();
      if (e != null) fail('Tab "$icon" threw: $e');
    }

    semantics.dispose();
  });
}
