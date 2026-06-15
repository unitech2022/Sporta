import 'package:flutter/foundation.dart';

import '../localization/app_translations.dart';

/// Roles a user can act as inside the app.
enum UserRole {
  player,
  coach,
  venue;

  /// Translation key of the role's display name.
  String get trKey => this == UserRole.venue ? 'venueOwner' : name;

  /// Emoji used next to the role name in registration summaries.
  String get emoji => switch (this) {
        UserRole.player => '🎾',
        UserRole.coach => '🏆',
        UserRole.venue => '🏟️',
      };
}

/// App-wide settings: current language and active role.
class AppSettings extends ChangeNotifier {
  AppLanguage _language = AppLanguage.ar;
  UserRole _role = UserRole.player;

  AppLanguage get language => _language;
  UserRole get role => _role;

  void setLanguage(AppLanguage language) {
    if (language == _language) return;
    _language = language;
    notifyListeners();
  }

  void setRole(UserRole role) {
    if (role == _role) return;
    _role = role;
    notifyListeners();
  }
}
