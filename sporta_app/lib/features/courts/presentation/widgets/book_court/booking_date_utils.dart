import '../../../../../core/localization/tr_global.dart';
/// Arabic date formatting helpers shared by the booking widgets.
class BookingDateUtils {
  const BookingDateUtils._();

  static List<String> get dayNames => [
    trg('الأحد'),
    trg('الاثنين'),
    trg('الثلاثاء'),
    trg('الأربعاء'),
    trg('الخميس'),
    trg('الجمعة'),
    trg('السبت'),
  ];

  static List<String> get monthNames => [
    trg('يناير'),
    trg('فبراير'),
    trg('مارس'),
    trg('أبريل'),
    trg('مايو'),
    trg('يونيو'),
    trg('يوليو'),
    trg('أغسطس'),
    trg('سبتمبر'),
    trg('أكتوبر'),
    trg('نوفمبر'),
    trg('ديسمبر'),
  ];

  /// e.g. "12 يونيو".
  static String shortDate(DateTime date) =>
      '${date.day} ${monthNames[date.month - 1]}';

  /// Weekday name for [date].
  static String dayName(DateTime date) => dayNames[date.weekday % 7];

  /// e.g. "الأحد، 12 يونيو 2026".
  static String fullDate(DateTime date) =>
      trgArgs('{p0}، {p1} {p2} {p3}', {'p0': dayNames[date.weekday % 7], 'p1': date.day, 'p2': monthNames[date.month - 1], 'p3': date.year});
}
