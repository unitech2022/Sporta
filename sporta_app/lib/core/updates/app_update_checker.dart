import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../features/settings/domain/setting_entity.dart';

/// App-update logic driven by the admin dashboard + Google Play.
///
/// Two independent layers:
///   * [isUpdateRequired] — the admin-controlled gate: when the installed
///     version is older than the `version_android` / `version_ios` setting,
///     the app is blocked behind `UpdateRequiredPage` until updated
///     (sohageMarket-style forced update; `"0"` or empty disables the gate).
///   * [check] — a courtesy background check with Google Play (Android only):
///     when Play has a newer build, it downloads *flexibly* while the user
///     keeps using the app and installs once done. Needs no admin action.
///
/// Both no-op silently on errors (web, debug/sideloaded installs, emulators
/// without Play) — update logic must never block or crash app startup.
class AppUpdateChecker {
  AppUpdateChecker._();

  static bool _ranThisLaunch = false;

  /// True when the admin-set minimum version for this platform is newer than
  /// the installed version — the caller should block the app behind the
  /// forced-update screen.
  static Future<bool> isUpdateRequired(
      Map<String, SettingEntity> settings) async {
    if (kIsWeb) return false;
    try {
      final key = Platform.isIOS ? 'version_ios' : 'version_android';
      final required = settings[key]?.valueAr.trim() ?? '';
      if (required.isEmpty || required == '0') return false;
      final current = (await PackageInfo.fromPlatform()).version;
      return _isBelow(current, required);
    } catch (_) {
      return false; // fail open — never lock users out on an error
    }
  }

  static Future<void> check(Map<String, SettingEntity> settings) async {
    if (_ranThisLaunch) return;
    _ranThisLaunch = true;
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }
      if (info.flexibleUpdateAllowed) {
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (_) {
      // Play unavailable or the user dismissed the dialog — carry on.
    }
  }

  /// True when [current] is older than [min]; both are dotted version strings
  /// ("1.2.3"). Missing segments count as 0, non-numeric segments as 0.
  @visibleForTesting
  static bool isBelow(String current, String min) => _isBelow(current, min);

  static bool _isBelow(String current, String min) {
    List<int> parse(String v) => v
        .split('.')
        .map((p) => int.tryParse(p.trim()) ?? 0)
        .toList(growable: false);

    final c = parse(current);
    final m = parse(min);
    final len = c.length > m.length ? c.length : m.length;
    for (var i = 0; i < len; i++) {
      final cv = i < c.length ? c[i] : 0;
      final mv = i < m.length ? m[i] : 0;
      if (cv != mv) return cv < mv;
    }
    return false;
  }
}
