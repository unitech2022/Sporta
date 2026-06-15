import 'package:flutter/material.dart';

import 'app/sporta_app.dart';
import 'core/storage/local_prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalPrefs.init();
  runApp(const SportaApp());
}
