import 'package:flutter/material.dart';

import 'app/sporta_app.dart';
import 'core/di/service_locator.dart';
import 'core/storage/local_prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalPrefs.init();
  setupLocator();
  runApp(const SportaApp());
}
