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

  // ── الحساب النشط («تبديل الحساب») ──
  // يبقى بعد إعادة التشغيل وتغيير اللغة؛ يُستعاد فقط إن بقي الدور على الحساب.
  static const _kActiveRole = 'active_role';

  static String? getActiveRole() => _prefs?.getString(_kActiveRole);
  static Future<void> setActiveRole(String role) async {
    await _prefs?.setString(_kActiveRole, role);
  }

  // ── مواعيد أُضيفت لتقويم الهاتف ──
  // المفتاح يشمل وقت الموعد: لو تغيّر الموعد يعود الزر ليُضاف من جديد.
  static const _kCalendarAdded = 'calendar_added';

  static bool isCalendarAdded(String key) =>
      _prefs?.getStringList(_kCalendarAdded)?.contains(key) ?? false;

  static Future<void> markCalendarAdded(String key) async {
    final list = [...?_prefs?.getStringList(_kCalendarAdded)];
    if (list.contains(key)) return;
    list.add(key);
    // يكفي آخر 200 موعد.
    final trimmed = list.length > 200 ? list.sublist(list.length - 200) : list;
    await _prefs?.setStringList(_kCalendarAdded, trimmed);
  }

  // ── تجارب أخفى المستخدم بطاقة تقييمها («كيف كانت تجربتك؟») ──
  static const _kDismissedReviews = 'dismissed_reviews';

  static bool isReviewDismissed(String key) =>
      _prefs?.getStringList(_kDismissedReviews)?.contains(key) ?? false;

  static Future<void> dismissReview(String key) async {
    final list = [...?_prefs?.getStringList(_kDismissedReviews)];
    if (list.contains(key)) return;
    list.add(key);
    final trimmed = list.length > 200 ? list.sublist(list.length - 200) : list;
    await _prefs?.setStringList(_kDismissedReviews, trimmed);
  }

  static Future<void> clearUser() async {
    await _prefs?.remove(_kUserJson);
    await _prefs?.remove(_kActiveRole);
  }
}
