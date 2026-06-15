/// Arabic date formatting helpers shared by the booking widgets.
class BookingDateUtils {
  const BookingDateUtils._();

  static const List<String> dayNames = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  static const List<String> monthNames = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  /// e.g. "12 يونيو".
  static String shortDate(DateTime date) =>
      '${date.day} ${monthNames[date.month - 1]}';

  /// Weekday name for [date].
  static String dayName(DateTime date) => dayNames[date.weekday % 7];

  /// e.g. "الأحد، 12 يونيو 2026".
  static String fullDate(DateTime date) =>
      '${dayNames[date.weekday % 7]}، ${date.day} ${monthNames[date.month - 1]} ${date.year}';
}
