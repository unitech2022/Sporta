import '../di/service_locator.dart';
import '../state/app_settings.dart';
import 'app_translations.dart';

/// ترجمة خارج شجرة الواجهة (كيانات الدومين، الكيوبتات، دوال التنسيق):
/// نفس جدول `context.tr` لكن تُقرأ اللغة من [AppSettings] مباشرة.
String trg(String key) =>
    AppTranslations.of(getIt<AppSettings>().language, key);

/// نسخة القوالب من [trg] — `{n}` ونحوها تُستبدل بقيم [params] بعد الترجمة.
String trgArgs(String key, Map<String, Object?> params) =>
    AppTranslations.ofArgs(getIt<AppSettings>().language, key, params);

/// هل لغة التطبيق الحالية هي العربية؟ (لاختيار نصوص الخادم المزدوجة
/// مثل NameAr/NameEn ورسائل الأخطاء message/messageAr.)
bool get isAppArabic => getIt<AppSettings>().language == AppLanguage.ar;

/// اسم قادم من الخادم له نسختان (عربية + إنجليزية اختيارية): يعيد الإنجليزية
/// حين تكون لغة التطبيق إنجليزية وهي متوفرة، وإلا العربية.
String localizedServerName(Object? ar, Object? en) {
  final arName = ar?.toString() ?? '';
  final enName = en?.toString() ?? '';
  return (!isAppArabic && enName.isNotEmpty) ? enName : arName;
}
