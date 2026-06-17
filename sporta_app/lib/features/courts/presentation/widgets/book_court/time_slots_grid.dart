import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../domain/entities/court_entity.dart';
import '../../courts_helpers.dart';

/// Grid of bookable time slots for the selected date. Booked slots are shown
/// disabled; peak slots are marked with a dot.
class TimeSlotsGrid extends StatelessWidget {
  const TimeSlotsGrid({
    super.key,
    required this.court,
    required this.timeSlots,
    required this.bookedSlots,
    required this.selectedTime,
    required this.loading,
    required this.onSelect,
  });

  final CourtEntity court;
  final List<String> timeSlots;
  final Set<String> bookedSlots;
  final String? selectedTime;
  final bool loading;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'اختر الوقت',
              style:
                  AppTextStyles.heading2.copyWith(color: AppColors.secondary),
            ),
            const Spacer(),
            const _LegendItem(
              color: Color(0xFFF0FDF4),
              borderColor: Color(0xFF86EFAC),
              label: 'متاح',
            ),
            const SizedBox(width: AppSizes.sm),
            const _LegendItem(
              color: Color(0xFFE5E7EB),
              borderColor: Color(0xFFE5E7EB),
              label: 'محجوز',
            ),
          ],
        ),
        const SizedBox(height: AppSizes.xs),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFB923C),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSizes.xs),
            Text(
              'ساعة الذروة (16:00 - 23:00)',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.mutedForeground),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(AppSizes.xl),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          _buildGrid(),
      ],
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSizes.sm,
        mainAxisSpacing: AppSizes.sm,
        childAspectRatio: 1.8,
      ),
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final time = timeSlots[index];
        if (bookedSlots.contains(time)) return _BookedSlot(time: time);
        return _AvailableSlot(
          time: time,
          price: slotPrice(court, time),
          isPeak: isPeakHour(time),
          isSelected: selectedTime == time,
          onTap: () => onSelect(time),
        );
      },
    );
  }
}

class _AvailableSlot extends StatelessWidget {
  const _AvailableSlot({
    required this.time,
    required this.price,
    required this.isPeak,
    required this.isSelected,
    required this.onTap,
  });

  final String time;
  final int price;
  final bool isPeak;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFF86EFAC),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    time,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.secondary,
                    ),
                  ),
                  Text(
                    '$price ر.س',
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.85)
                          : const Color(0xFF16A34A),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isPeak && !isSelected)
              const Positioned(top: 4, left: 4, child: _PeakDot()),
          ],
        ),
      ),
    );
  }
}

class _BookedSlot extends StatelessWidget {
  const _BookedSlot({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              time,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.mutedForeground,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'محجوز',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedForeground,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeakDot extends StatelessWidget {
  const _PeakDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFFFB923C),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.borderColor,
    required this.label,
  });

  final Color color;
  final Color borderColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: borderColor),
          ),
        ),
        const SizedBox(width: 3),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11)),
      ],
    );
  }
}
