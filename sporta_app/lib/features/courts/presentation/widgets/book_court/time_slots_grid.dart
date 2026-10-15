import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../data/models/court_slot.dart';
import 'package:sporta_app/core/utils/server_time.dart';

/// Grid of bookable time slots for the selected date, stepped to match the
/// chosen duration (backend returns e.g. every 120 min for a 120-min
/// session). Booked slots are shown disabled; peak slots are marked with a dot.
class TimeSlotsGrid extends StatelessWidget {
  const TimeSlotsGrid({
    super.key,
    required this.slots,
    required this.selectedTime,
    required this.loading,
    required this.onSelect,
    this.dayClosed = false,
    this.dayRangeLabel = '',
    this.day,
  });

  final List<CourtSlot> slots;
  final String? selectedTime;
  final bool loading;
  final ValueChanged<String> onSelect;

  /// الملعب مغلق في اليوم المختار حسب دوام أسبوعه.
  final bool dayClosed;

  /// دوام اليوم المختار، مثل "08:00 - 14:00".
  final String dayRangeLabel;

  /// اليوم المختار. الخادم يُسقط مواعيد اليوم التي مضت، فالقائمة الفارغة في
  /// يومٍ حاضر تعني «انتهت مواعيد اليوم» لا «لا مواعيد بهذه المدة».
  final DateTime? day;

  /// هل في مواعيد اليوم موعد ذروة يستحق شرح النقطة البرتقالية؟
  bool get _hasPeak => slots.any((s) => s.isPeak);

  bool get _isToday {
    final d = day;
    if (d == null) return false;
    final now = ksaNow();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(context.tr('اختر الوقت'),
              style:
                  AppTextStyles.heading2.copyWith(color: AppColors.secondary),
            ),
            const Spacer(),
            _LegendItem(
              color: Color(0xFFF0FDF4),
              borderColor: Color(0xFF86EFAC),
              label: context.tr('متاح'),
            ),
            const SizedBox(width: AppSizes.sm),
            _LegendItem(
              color: Color(0xFFE5E7EB),
              borderColor: Color(0xFFE5E7EB),
              label: context.tr('محجوز'),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.xs),
        // ساعات الذروة صارت من تحديد صاحب الملعب، فلا نذكر نطاقاً ثابتاً —
        // نكتفي بشرح النقطة البرتقالية (وفقط حين يوجد موعد يحملها؛ ملعب
        // مسعَّر بالمدد بلا قواعد لا ذروة فيه)، ودوام اليوم يُعرض بجانبها.
        Row(
          children: [
            if (_hasPeak) ...[
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFB923C),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSizes.xs),
              Text(context.tr('سعر مرتفع'),
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedForeground),
              ),
            ],
            if (!dayClosed && dayRangeLabel.isNotEmpty) ...[
              const Spacer(),
              Text('${context.tr('الدوام')} $dayRangeLabel',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.mutedForeground),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSizes.md),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(AppSizes.xl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (slots.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.xl),
            child: Center(
              child: Text(
                  context.tr(dayClosed
                      ? context.tr('الملعب مغلق في هذا اليوم — اختر يوماً آخر')
                      : _isToday
                          ? context.tr('انتهت مواعيد اليوم — اختر يوماً آخر')
                          : context.tr('لا توجد أوقات متاحة لهذه المدة')),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.mutedForeground)),
            ),
          )
        else
          _buildGrid(),
      ],
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      // بلا هذين السطرين تعدّ الشبكة نفسها القائمة الرئيسية فتضيف حشوة
      // المنطقة الآمنة (أعلاها وأسفلها) — فراغ كبير قبل المواعيد وبعدها.
      primary: false,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSizes.sm,
        mainAxisSpacing: AppSizes.sm,
        childAspectRatio: 1.8,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final time = slot.time;
        if (slot.isBooked) return _BookedSlot(time: time);
        return _AvailableSlot(
          time: time,
          price: slot.price,
          isPeak: slot.isPeak,
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
  final double price;
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
                    context.trArgs('{p0} ر.س', {'p0': money(price)}),
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
            Text(context.tr('محجوز'),
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
