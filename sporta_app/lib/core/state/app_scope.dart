import 'package:flutter/widgets.dart';

import '../localization/app_translations.dart';
import 'app_settings.dart';

/// Exposes [AppSettings] to the widget tree and rebuilds dependents
/// when the language or role changes.
class AppScope extends InheritedNotifier<AppSettings> {
  const AppScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in the widget tree');
    return scope!.notifier!;
  }
}

extension AppScopeX on BuildContext {
  AppSettings get appSettings => AppScope.of(this);

  /// Translates [key] using the current app language.
  String tr(String key) => AppTranslations.of(appSettings.language, key);
}
