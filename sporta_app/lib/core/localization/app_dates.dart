import 'tr_global.dart';

/// تنسيق تواريخ موحّد يتبع لغة التطبيق (أسماء الأيام والأشهر والفترة ص/م).
/// كل الصفحات التي كانت تحمل قوائم `_weekdaysAr`/`_monthsAr` الخاصة بها
/// تستخدم هذه الدوال حتى لا يظهر تاريخ عربي داخل واجهة إنجليزية.
abstract class AppDates {
  static const _weekdaysAr = [
    'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد',
  ];
  static const _weekdaysEn = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
    'Saturday', 'Sunday',
  ];
  static const _monthsAr = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];
  static const _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// اسم يوم الأسبوع للتاريخ (الاثنين=1..الأحد=7 كما في [DateTime.weekday]).
  static String weekday(DateTime d) =>
      (isAppArabic ? _weekdaysAr : _weekdaysEn)[d.weekday - 1];

  /// اسم الشهر (1..12).
  static String monthName(int month) =>
      (isAppArabic ? _monthsAr : _monthsEn)[month - 1];

  /// "مساءً"/"صباحاً" أو AM/PM حسب اللغة.
  static String period(DateTime d) =>
      d.hour < 12 ? (isAppArabic ? 'صباحاً' : 'AM') : (isAppArabic ? 'مساءً' : 'PM');

  /// "ص"/"م" أو AM/PM — الصيغة المختصرة.
  static String periodShort(DateTime d) =>
      d.hour < 12 ? (isAppArabic ? 'ص' : 'AM') : (isAppArabic ? 'م' : 'PM');

  /// ساعة 12-ساعية بلا أصفار بادئة (12، 1..11).
  static int hour12(DateTime d) => d.hour % 12 == 0 ? 12 : d.hour % 12;

  /// "الأحد 12 أغسطس · 4:30 مساءً" / "Sunday 12 August · 4:30 PM".
  static String fullWhen(DateTime d) {
    final minute = d.minute.toString().padLeft(2, '0');
    return '${weekday(d)} ${d.day} ${monthName(d.month)} · '
        '${hour12(d)}:$minute ${period(d)}';
  }

  /// "12 أغسطس" / "12 August".
  static String dayMonth(DateTime d) => '${d.day} ${monthName(d.month)}';

  /// "4:30 مساءً" / "4:30 PM".
  static String time12(DateTime d) {
    final minute = d.minute.toString().padLeft(2, '0');
    return '${hour12(d)}:$minute ${period(d)}';
  }
}
