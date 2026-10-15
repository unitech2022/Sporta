import 'dart:async';

import 'package:flutter/foundation.dart';

import '../localization/app_translations.dart';
import '../push/push_service.dart';
import '../storage/local_prefs.dart';

/// Roles a user can act as inside the app.
enum UserRole {
  player,
  coach,
  venue,
  admin;

  /// Translation key of the role's display name.
  String get trKey => this == UserRole.venue ? 'venueOwner' : name;

  /// Emoji used next to the role name in registration summaries.
  String get emoji => switch (this) {
        UserRole.player => '🎾',
        UserRole.coach => '🏆',
        UserRole.venue => '🏟️',
        UserRole.admin => '🛡️',
      };
}

/// App-wide settings: current language and active role.
class AppSettings extends ChangeNotifier {
  AppLanguage _language = AppLanguage.ar;
  UserRole _role = UserRole.player;

  /// Bumped by [restartApp]; used as the root widget key so the whole app
  /// (navigator stack included) is rebuilt from scratch.
  int _appGeneration = 0;

  AppLanguage get language => _language;
  UserRole get role => _role;
  int get appGeneration => _appGeneration;

  void setLanguage(AppLanguage language) {
    if (language == _language) return;
    _language = language;
    notifyListeners();
  }

  /// Relaunches the app UI from the splash screen (e.g. after a language
  /// change), dropping every open route and page state.
  void restartApp() {
    // The navigator hangs off a GlobalKey (push routing); without a fresh key
    // the rebuilt app would inherit the old route stack and stay on whatever
    // page was open.
    PushService.resetNavigatorKey();
    _appGeneration++;
    notifyListeners();
  }

  /// يبدّل الحساب النشط ويحفظه، فيعود التطبيق إليه بعد إعادة التشغيل أو
  /// تغيير اللغة بدل الرجوع إلى الدور الأول.
  void setRole(UserRole role) {
    unawaited(LocalPrefs.setActiveRole(role.name));
    if (role == _role) return;
    _role = role;
    notifyListeners();
  }
}
