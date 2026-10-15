import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_dates.dart';
import '../../../core/localization/tr_global.dart';

/// Formatting shared by the match-requests list and its details page, so a
/// status reads the same in both places.

/// "الأحد 12 أغسطس · 4:30 مساءً".
String formatMatchWhen(DateTime d) {
  final weekday = AppDates.weekday(d);
  final month = AppDates.monthName(d.month);
  final period = AppDates.period(d);
  final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  return '$weekday ${d.day} $month · $h12:$minute $period';
}

/// "12 أغسطس 2026" — used for the "أُنشئ في" line.
String formatMatchDate(DateTime d) =>
    '${d.day} ${AppDates.monthName(d.month)} ${d.year}';

/// Arabic label of a match status as the owner sees it.
String matchStatusLabelAr(String status) => switch (status) {
  'PendingApproval' => trg('قيد الموافقة'),
  'Open' => trg('مقبولة'),
  'Full' => trg('مكتملة'),
  'InProgress' => trg('جارية'),
  'Completed' => trg('منتهية'),
  'Cancelled' => trg('ملغاة'),
  _ => status,
};

Color matchStatusColor(String status) => switch (status) {
  'Open' || 'Full' || 'Completed' => AppColors.success,
  'PendingApproval' => AppColors.warning,
  'Cancelled' => AppColors.destructive,
  _ => AppColors.mutedForeground,
};
