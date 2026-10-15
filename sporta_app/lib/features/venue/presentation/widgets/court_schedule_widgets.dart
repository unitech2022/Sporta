import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../domain/entities/owner_venue.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/money.dart';

/// قائمة اختيار ساعة (00:00 … 24:00) بحدود قابلة للضبط.
class HourDropdown extends StatelessWidget {
  const HourDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 24,
    this.enabled = true,
    this.label,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final bool enabled;
  final String? label;

  static String format(int hour) => '${hour.toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    final items = [for (var h = min; h <= max; h++) h];
    // القيمة خارج المدى تُعرض كأقرب قيمة صالحة حتى لا ينهار الـ Dropdown.
    final safe = value.clamp(min, max);

    return DropdownButtonFormField<int>(
      initialValue: items.contains(safe) ? safe : items.first,
      isDense: true,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label == null ? null : context.tr(label!),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.sm,
        ),
      ),
      items: [
        for (final h in items)
          DropdownMenuItem(value: h, child: Text(format(h))),
      ],
      onChanged: enabled ? (v) => onChanged(v ?? min) : null,
    );
  }
}

/// صف يوم واحد في جدول الأسبوع: مفتوح/مغلق + ساعتا الفتح والإغلاق.
class OpeningDayRow extends StatelessWidget {
  const OpeningDayRow({
    super.key,
    required this.hours,
    required this.onChanged,
    required this.onCopyToAll,
  });

  final CourtOpeningHour hours;
  final ValueChanged<CourtOpeningHour> onChanged;
  final VoidCallback onCopyToAll;

  @override
  Widget build(BuildContext context) {
    final open = !hours.isClosed;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr(hours.dayLabel),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (open)
                IconButton(
                  tooltip: context.tr('تطبيق على كل الأيام'),
                  onPressed: onCopyToAll,
                  icon: const Icon(Icons.copy_all_outlined, size: 20),
                  color: AppColors.primary,
                ),
              Text(
                context.tr(open ? context.tr('مفتوح') : context.tr('مغلق')),
                style: AppTextStyles.caption.copyWith(
                  color: open ? AppColors.success : AppColors.mutedForeground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Switch(
                value: open,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => onChanged(hours.copyWith(isClosed: !v)),
              ),
            ],
          ),
          if (open) ...[
            const SizedBox(height: AppSizes.xs),
            Row(
              children: [
                Expanded(
                  child: HourDropdown(
                    label: context.tr('من'),
                    value: hours.openHour,
                    max: 23,
                    onChanged: (v) => onChanged(
                      hours.copyWith(
                        openHour: v,
                        // الإغلاق يبقى بعد الفتح دائماً.
                        closeHour: v >= hours.closeHour
                            ? v + 1
                            : hours.closeHour,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: HourDropdown(
                    label: context.tr('إلى'),
                    value: hours.closeHour,
                    min: hours.openHour + 1,
                    onChanged: (v) => onChanged(hours.copyWith(closeHour: v)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// بطاقة نطاق سعر واحد: اليوم + من/إلى + سعر الساعة — إما سعر ثابت
/// («من 6 صباحاً إلى 3 عصراً بـ 100 ر.س») أو نسبة زيادة/خصم على السعر الأساسي.
class PriceRuleCard extends StatefulWidget {
  const PriceRuleCard({
    super.key,
    required this.rule,
    required this.basePrice,
    required this.onChanged,
    required this.onDelete,
    this.commissionPercent = 0,
    this.hasOverlap = false,
  });

  final CourtPriceRule rule;

  /// سعر الساعة الأساسي (سعر المالك) — أساس النسبة والسعر الافتراضي.
  final double basePrice;
  final ValueChanged<CourtPriceRule> onChanged;
  final VoidCallback onDelete;

  /// نسبة سبورتا — لعرض ما يدفعه اللاعب فعلاً.
  final double commissionPercent;

  /// يتداخل مع نطاق آخر لنفس اليوم (يُبرز بالأحمر).
  final bool hasOverlap;

  @override
  State<PriceRuleCard> createState() => _PriceRuleCardState();
}

class _PriceRuleCardState extends State<PriceRuleCard> {
  late final TextEditingController _price = TextEditingController(
    text: widget.rule.hourlyPrice == null
        ? ''
        : money(widget.rule.hourlyPrice!),
  );

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  CourtPriceRule get rule => widget.rule;

  void _setMode(bool fixed) {
    if (fixed == rule.isFixedPrice) return;
    if (fixed) {
      // يبدأ السعر الثابت من سعر النطاق الحالي حتى لا يقفز السعر فجأة.
      final start = rule.rateFrom(widget.basePrice).roundToDouble();
      _price.text = money(start);
      widget.onChanged(rule.copyWith(hourlyPrice: start, adjustmentPercent: 0));
    } else {
      widget.onChanged(rule.copyWith(clearHourlyPrice: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rate = rule.rateFrom(widget.basePrice);
    final playerRate = rate * (100 + widget.commissionPercent) / 100;
    final cheaper = rate < widget.basePrice;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: widget.hasOverlap ? AppColors.destructive : AppColors.border,
          width: widget.hasOverlap ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: rule.day ?? -1,
                  isDense: true,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.tr('اليوم'),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm,
                      vertical: AppSizes.sm,
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: -1,
                      child: Text(context.tr('كل الأيام')),
                    ),
                    for (var d = 0; d < 7; d++)
                      DropdownMenuItem(
                        value: d,
                        child: Text(context.tr(CourtOpeningHour.dayNames[d])),
                      ),
                  ],
                  onChanged: (v) => widget.onChanged(
                    v == -1 || v == null
                        ? rule.copyWith(clearDay: true)
                        : rule.copyWith(day: v),
                  ),
                ),
              ),
              IconButton(
                tooltip: context.tr('حذف'),
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline),
                color: AppColors.destructive,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Row(
            children: [
              Expanded(
                child: HourDropdown(
                  label: context.tr('من'),
                  value: rule.startHour,
                  max: 23,
                  onChanged: (v) => widget.onChanged(
                    rule.copyWith(
                      startHour: v,
                      endHour: v >= rule.endHour ? v + 1 : rule.endHour,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: HourDropdown(
                  label: context.tr('إلى'),
                  value: rule.endHour,
                  min: rule.startHour + 1,
                  onChanged: (v) => widget.onChanged(rule.copyWith(endHour: v)),
                ),
              ),
            ],
          ),
          if (widget.hasOverlap)
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.xs),
              child: Text(
                context.tr('هذا النطاق يتداخل مع نطاق آخر لنفس اليوم'),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.destructive,
                ),
              ),
            ),
          const SizedBox(height: AppSizes.sm),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: Text(context.tr('سعر ثابت')),
              ),
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.percent, size: 18),
                label: Text(context.tr('نسبة من السعر')),
              ),
            ],
            selected: {rule.isFixedPrice},
            onSelectionChanged: (v) => _setMode(v.first),
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: rule.isFixedPrice
                    ? TextField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: context.tr('سعر الساعة (ر.س)'),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) {
                          final n = double.tryParse(
                            v.replaceAll(',', '.').trim(),
                          );
                          if (n != null && n > 0) {
                            widget.onChanged(rule.copyWith(hourlyPrice: n));
                          }
                        },
                      )
                    : DropdownButtonFormField<double>(
                        initialValue: _nearestPercent(rule.adjustmentPercent),
                        isDense: true,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.tr('تعديل السعر'),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm,
                            vertical: AppSizes.sm,
                          ),
                        ),
                        items: [
                          for (final p in _percentOptions)
                            DropdownMenuItem(
                              value: p,
                              child: Text(_percentLabel(p)),
                            ),
                        ],
                        onChanged: (v) => widget.onChanged(
                          rule.copyWith(adjustmentPercent: v ?? 0),
                        ),
                      ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('يستلم الملعب / ساعة'),
                      style: AppTextStyles.caption,
                    ),
                    Text(
                      context.trArgs('{p0} ر.س', {'p0': money(rate)}),
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cheaper ? AppColors.success : AppColors.primary,
                      ),
                    ),
                    if (widget.commissionPercent > 0)
                      Text(
                        context.trArgs('يدفع اللاعب {p0} ر.س', {
                          'p0': money(playerRate),
                        }),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _percentOptions = <double>[
    -50,
    -40,
    -30,
    -25,
    -20,
    -15,
    -10,
    -5,
    0,
    5,
    10,
    15,
    20,
    25,
    30,
    40,
    50,
    75,
    100,
  ];

  static double _nearestPercent(double value) => _percentOptions.reduce(
    (a, b) => (a - value).abs() <= (b - value).abs() ? a : b,
  );

  static String _percentLabel(double p) {
    if (p == 0) return trg('بدون تغيير');
    final sign = p > 0 ? '+' : '−';
    return '$sign${p.abs().toStringAsFixed(0)}%';
  }
}
