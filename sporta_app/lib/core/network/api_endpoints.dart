import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

abstract class ApiEndpoints {
  /// Local backend port (see SportaApis appsettings.Development.json → urls).
  static const int _port = 7000;

  /// Base URL resolved per platform so the backend is reachable in development:
  /// - Android emulator reaches the host machine via 10.0.2.2 (not localhost).
  /// - iOS simulator / macOS / web reach it directly via localhost.
  /// - Physical devices need the machine's LAN IP — set [_lanIpOverride].
  static String get baseUrl {
    if (_lanIpOverride != null) return 'http://$_lanIpOverride:$_port/api';
    if (kIsWeb) return 'http://localhost:$_port/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:$_port/api';
    return 'http://localhost:$_port/api';
  }

  /// Set this to your computer's LAN IP (e.g. '192.168.1.10') when testing on a
  /// real phone over Wi-Fi. Leave null for emulator/simulator.
  static const String? _lanIpOverride = null;

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String updateLanguage = '/users/language';
  static const String levelAssessment = '/players/level-assessment';
  static const String playerProfile = '/players/me';
  static const String favoriteSport = '/players/favorite-sport';
}
