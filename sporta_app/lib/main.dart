import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/sporta_app.dart';
import 'core/di/service_locator.dart';
import 'core/push/push_service.dart';
import 'core/storage/local_prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // أندرويد 15+ يفرض الرسم من حافة إلى حافة ولا يسمح بالانسحاب منه؛ نُعلنه
  // صراحةً ونجعل شريطي الحالة والتنقّل شفافين كي ترسم الواجهة خلفهما بدل
  // شريط أسود. حشوات المناطق الآمنة تتكفّل بها SafeArea في الشريط السفلي
  // والصفحات. بدون هذا تُحذّر Google Play: «Edge-to-edge may not display
  // for all users».
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  await LocalPrefs.init();
  setupLocator();
  await PushService.init();
  runApp(const SportaApp());
}
