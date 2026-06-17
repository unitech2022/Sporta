import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_text_styles.dart';
import 'booking_date_utils.dart';

/// Horizontal strip of selectable dates (the first entry is "today").
class BookingDatePicker extends StatelessWidget {
  const BookingDatePicker({
    super.key,
    required this.dates,
    required this.selectedDate,
    required this.onSelect,
  });

  final List<DateTime> dates;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر التاريخ',
          style: AppTextStyles.heading2.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSizes.md),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
            itemBuilder: (context, index) => _DateCell(
              date: dates[index],
              isSelected: _isSameDay(selectedDate, dates[index]),
              isToday: index == 0,
              onTap: () => onSelect(dates[index]),
            ),
          ),
        ),
      ],
    );
  }

  static bool _isSameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              BookingDateUtils.dayName(date),
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? Colors.white : AppColors.mutedForeground,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${date.day}',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.secondary,
              ),
            ),
            if (isToday)
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
