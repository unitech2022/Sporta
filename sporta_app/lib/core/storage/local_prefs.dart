import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalPrefs {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static const _kLanguage = 'language';
  static const _kUserJson = 'user_json';

  static String? getLanguage() => _prefs?.getString(_kLanguage);
  static Future<void> setLanguage(String lang) =>
      _prefs!.setString(_kLanguage, lang);

  static String? getUserJson() => _prefs?.getString(_kUserJson);
  static Future<void> setUserJson(String json) =>
      _prefs!.setString(_kUserJson, json);

  static Future<void> clearUser() async {
    await _prefs?.remove(_kUserJson);
  }
}
