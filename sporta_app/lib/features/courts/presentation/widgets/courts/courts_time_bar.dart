import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/state/app_scope.dart';
import '../../../../../core/utils/server_time.dart';
import '../../../../../core/widgets/filter_chip_group.dart';
import '../../../../../core/widgets/filter_sheet.dart';
import '../../cubit/courts_list/courts_cubit.dart';
import '../book_court/booking_date_picker.dart';
import '../book_court/booking_date_utils.dart';

/// شريط البحث بالوقت تحت حقل البحث: اليوم، ونافذة الساعات، والمدة، و«المتاح
/// فقط». كل رقاقة تفتح ورقة صغيرة ولا يصل شيء للشاشة قبل «تطبيق».
class CourtsTimeBar extends StatelessWidget {
  const CourtsTimeBar({
    super.key,
    required this.filters,
    required this.onChanged,
  });

  final CourtsFilters filters;
  final ValueChanged<CourtsFilters> onChanged;

  /// أيام البحث: اليوم و14 بعده — كقائمة أيام صفحة الحجز.
  static const _days = 15;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _BarChip(
            icon: Icons.calendar_today_rounded,
            label: _dateLabel(context),
            onTap: () => _pickDate(context),
          ),
          const SizedBox(width: AppSizes.sm),
          _BarChip(
            icon: Icons.schedule_rounded,
            label: _windowLabel(context),
            onTap: () => _pickWindow(context),
          ),
          const SizedBox(width: AppSizes.sm),
          _BarChip(
            icon: Icons.timelapse_rounded,
            label: _durationLabel(context, filters.slotDuration),
            onTap: () => _pickDuration(context),
          ),
          const SizedBox(width: AppSizes.sm),
          _BarChip(
            icon: filters.onlyAvailable
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            label: context.tr('المتاح فقط'),
            showArrow: false,
            outlined: !filters.onlyAvailable,
            onTap: () => onChanged(
                filters.copyWith(onlyAvailable: !filters.onlyAvailable)),
          ),
        ],
      ),
    );
  }

  String _dateLabel(BuildContext context) {
    if (filters.isToday) return context.tr('اليوم');
    final d = filters.slotDate;
    final now = ksaNow();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    if (d == tomorrow) return context.tr('غداً');
    return '${BookingDateUtils.dayName(d)} ${BookingDateUtils.shortDate(d)}';
  }

  static String _hour(int h) => '${h.toString().padLeft(2, '0')}:00';

  String _windowLabel(BuildContext context) {
    final to = _hour(filters.toHour);
    if (filters.fromHour == null && filters.isToday) {
      return context.trArgs('الآن - {p0}', {'p0': to});
    }
    // عزل LTR حتى يُقرأ «18:00 - 22:00» بترتيبه داخل الواجهة العربية كما في
    // ورقة الاختيار، لا معكوساً.
    return '⁦${_hour(filters.slotFromHour)} - $to⁩';
  }

  static String _durationLabel(BuildContext context, int minutes) =>
      switch (minutes) {
        90 => context.tr('90 دقيقة'),
        120 => context.tr('120 دقيقة'),
        _ => context.tr('60 دقيقة'),
      };

  Future<void> _apply(
    BuildContext context, {
    required String title,
    required FilterSheetBuilder<CourtsFilters> builder,
  }) async {
    final applied = await showFilterSheet<CourtsFilters>(
      context: context,
      initialValue: filters,
      title: title,
      builder: builder,
    );
    if (applied != null) onChanged(applied);
  }

  void _pickDate(BuildContext context) {
    final today = ksaNow();
    final dates = List.generate(
      _days,
      (i) => DateTime(today.year, today.month, today.day + i),
    );
    _apply(
      context,
      title: 'متى تلعب؟',
      builder: (context, draft, onDraft) => BookingDatePicker(
        dates: dates,
        selectedDate: draft.slotDate,
        // اليوم يُحفظ فارغاً ليبقى «اليوم» حياً بعد منتصف الليل.
        onSelect: (d) => onDraft(d == dates.first
            ? draft.copyWith(clearDate: true)
            : draft.copyWith(date: d)),
      ),
    );
  }

  void _pickWindow(BuildContext context) {
    _apply(
      context,
      title: 'وقت اللعب',
      builder: (context, draft, onDraft) {
        final from = draft.slotFromHour;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${_hour(from)} - ${_hour(draft.toHour)}',
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: AppTextStyles.heading2.copyWith(color: AppColors.secondary),
            ),
            const SizedBox(height: AppSizes.sm),
            RangeSlider(
              values: RangeValues(from.toDouble(), draft.toHour.toDouble()),
              min: 0,
              max: 24,
              divisions: 24,
              activeColor: AppColors.primary,
              onChanged: (v) {
                var start = v.start.round();
                var end = v.end.round();
                // نافذة ساعة على الأقل.
                if (end <= start) {
                  if (start >= 23) {
                    start = 23;
                    end = 24;
                  } else {
                    end = start + 1;
                  }
                }
                onDraft(draft.copyWith(fromHour: start, toHour: end));
              },
            ),
            if (draft.isToday)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => onDraft(
                      draft.copyWith(clearFromHour: true, toHour: 24)),
                  icon: const Icon(Icons.bolt_rounded, size: AppSizes.iconMd),
                  label: Text(context.tr('من الآن إلى منتصف الليل')),
                ),
              ),
          ],
        );
      },
    );
  }

  void _pickDuration(BuildContext context) {
    _apply(
      context,
      title: 'مدة الحجز',
      builder: (context, draft, onDraft) => FilterChipGroup(
        options: [
          ('60', context.tr('60 دقيقة')),
          ('90', context.tr('90 دقيقة')),
          ('120', context.tr('120 دقيقة')),
        ],
        selected: '${draft.slotDuration}',
        onSelected: (v) =>
            onDraft(draft.copyWith(slotDuration: int.tryParse(v) ?? 60)),
      ),
    );
  }
}

/// رقاقة على خلفية الرأس المتدرّجة: بيضاء ممتلئة، أو بإطار أبيض للمفتاح المطفأ.
class _BarChip extends StatelessWidget {
  const _BarChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showArrow = true,
    this.outlined = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showArrow;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final fg = outlined ? Colors.white : AppColors.secondary;
    return Material(
      color: outlined ? Colors.white.withValues(alpha: 0.12) : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: outlined
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.transparent,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSizes.iconSm, color: fg),
              const SizedBox(width: AppSizes.xs),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showArrow) ...[
                const SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
