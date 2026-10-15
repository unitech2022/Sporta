import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../courts/domain/entities/court_entity.dart';

/// عنوان حقل في صفحة الإنشاء.
class CupLabel extends StatelessWidget {
  const CupLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.sm),
    child: Text(
      text,
      style: AppTextStyles.body.copyWith(
        color: AppColors.secondary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// بطاقتا النظام (راديو): مجموعات + خروج المغلوب / خروج المغلوب مباشرة.
class CupFormatSelector extends StatelessWidget {
  const CupFormatSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _card(
          context,
          'groups',
          context.tr('مجموعات + خروج المغلوب'),
          context.tr(
            'تُقسَّم الفرق إلى مجموعات بنظام الدوري، ويتأهل الأول والثاني (وأفضل الثوالث عند الحاجة) إلى الأدوار الإقصائية.',
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        _card(
          context,
          'knockout',
          context.tr('خروج المغلوب مباشرة'),
          context.tr('كل مباراة إقصائية من البداية، والخاسر يغادر البطولة.'),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, String key, String title, String desc) {
    final on = value == key;
    return Material(
      color: on ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
          color: on ? AppColors.primary : AppColors.border,
          width: on ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => onChanged(key),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(top: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: on ? AppColors.primary : AppColors.mutedForeground,
                    width: 2,
                  ),
                ),
                child: on
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// عدد الفرق: إدخال يدوي واضح (− العدد +) — أي عدد من 4 فأكثر — ثم
/// اختيارات سريعة مرتّبة من الأصغر إلى الأكبر.
class CupTeamCountField extends StatefulWidget {
  const CupTeamCountField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  static const quick = [4, 8, 12, 16, 24, 32, 36];
  static const min = 4;
  static const max = 512;

  @override
  State<CupTeamCountField> createState() => _CupTeamCountFieldState();
}

class _CupTeamCountFieldState extends State<CupTeamCountField> {
  late final _ctrl = TextEditingController(text: '${widget.value}');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _set(int v) {
    final clamped = v.clamp(CupTeamCountField.min, CupTeamCountField.max);
    _ctrl.text = '$clamped';
    widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final typed = int.tryParse(_ctrl.text);
    final tooFew = typed != null && typed < CupTeamCountField.min;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: tooFew ? AppColors.destructive : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              _stepButton(
                Icons.remove,
                () => _set(widget.value - 1),
                enabled: widget.value > CupTeamCountField.min,
              ),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.secondary,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    suffixText: context.tr('فريق'),
                    hintText: context.tr('اكتب العدد'),
                  ),
                  onChanged: (s) {
                    setState(() {});
                    final v = int.tryParse(s);
                    if (v != null && v >= CupTeamCountField.min)
                      widget.onChanged(v);
                  },
                ),
              ),
              _stepButton(
                Icons.add,
                () => _set(widget.value + 1),
                enabled: widget.value < CupTeamCountField.max,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        // اختيارات سريعة من الأصغر إلى الأكبر.
        Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.sm,
          children: [
            for (final n in CupTeamCountField.quick)
              SizedBox(
                width: 56,
                child: CupPill(
                  label: '$n',
                  selected: widget.value == n,
                  onTap: () => _set(n),
                  height: 36,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          tooFew
              ? context.tr('أربعة فرق على الأقل.')
              : context.tr(
                  'كل فريق يتكوّن من لاعبَين، والمباراة 2 ضد 2. أربعة فرق على الأقل.',
                ),
          style: AppTextStyles.caption.copyWith(
            color: tooFew ? AppColors.destructive : AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }

  Widget _stepButton(
    IconData icon,
    VoidCallback onTap, {
    required bool enabled,
  }) => IconButton(
    onPressed: enabled ? onTap : null,
    icon: Icon(icon),
    color: AppColors.primary,
    disabledColor: AppColors.border,
  );
}

class CupPill extends StatelessWidget {
  const CupPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.height = 44,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.primary : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: SizedBox(
        height: height,
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: selected ? Colors.white : AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ),
  );
}

/// اختيار المنشأة ثم ملاعبها (واحد أو أكثر) — المباريات تُوزَّع عليها.
class CupCourtsPicker extends StatelessWidget {
  const CupCourtsPicker({
    super.key,
    required this.loading,
    required this.venues,
    required this.venue,
    required this.courts,
    required this.selected,
    required this.onVenueChanged,
    required this.onToggle,
  });

  final bool loading;
  final List<String> venues;
  final String? venue;
  final List<CourtEntity> courts;
  final Set<int> selected;
  final ValueChanged<String?> onVenueChanged;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    // هيكل بشكل قائمة المنشأة ثم رقائق الملاعب.
    if (loading) {
      return const Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 48, radius: AppSizes.radiusLg),
            SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: [
                SkeletonBox(width: 88, height: 32, radius: AppSizes.radiusFull),
                SkeletonBox(width: 72, height: 32, radius: AppSizes.radiusFull),
                SkeletonBox(width: 96, height: 32, radius: AppSizes.radiusFull),
              ],
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (venues.length > 1) ...[
          DropdownButtonFormField<String>(
            initialValue: venue,
            isExpanded: true,
            items: [
              for (final v in venues)
                DropdownMenuItem(value: v, child: Text(v)),
            ],
            onChanged: onVenueChanged,
          ),
          const SizedBox(height: AppSizes.sm),
        ] else if (venue != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.sm),
            child: Text(
              venue!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
        Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.sm,
          children: [
            for (final c in courts)
              FilterChip(
                label: Text(c.name),
                selected: selected.contains(c.numericId),
                onSelected: (_) => onToggle(c.numericId),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
              ),
          ],
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          context.tr(
            'اختر ملعباً أو أكثر من منشأة واحدة — كلما زادت الملاعب قصُر جدول البطولة.',
          ),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class CupPickerTile extends StatelessWidget {
  const CupPickerTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (label.isNotEmpty) ...[
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSizes.sm),
      ],
      Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                Icon(icon, size: AppSizes.iconSm, color: AppColors.primary),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    value,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

/// شبكة مدد مرتّبة من الأقصر إلى الأطول: النافذة اليومية (بالساعات) أو
/// مدة المباراة (دقائق حتى ساعتين). أعمدة متساوية: أربعة في السطر أو ثلاثة.
class CupMinutesSelector extends StatelessWidget {
  const CupMinutesSelector({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hours = false,
  });

  final List<int> options;
  final int value;
  final ValueChanged<int> onChanged;
  final bool hours;

  String _label(BuildContext context, int m) {
    if (hours) return context.trArgs('{p0} ساعات', {'p0': m ~/ 60});
    if (m == 60) return context.tr('ساعة');
    if (m == 120) return context.tr('ساعتان');
    return context.trArgs('{p0} دقيقة', {'p0': m});
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...options]..sort();
    final perRow = sorted.length == 4 ? 4 : 3;
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - AppSizes.sm * (perRow - 1)) / perRow;
        return Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.sm,
          children: [
            for (final m in sorted)
              SizedBox(
                width: w,
                child: CupPill(
                  label: _label(context, m),
                  selected: value == m,
                  onTap: () => onChanged(m),
                ),
              ),
          ],
        );
      },
    );
  }
}

class CupLevelRange extends StatelessWidget {
  const CupLevelRange({
    super.key,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int min;
  final int max;
  final void Function(int min, int max) onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _dropdown(
          context,
          context.tr('من'),
          min,
          (v) => onChanged(v, max < v ? v : max),
        ),
      ),
      const SizedBox(width: AppSizes.md),
      Expanded(
        child: _dropdown(
          context,
          context.tr('إلى'),
          max,
          (v) => onChanged(min > v ? v : min, v),
        ),
      ),
    ],
  );

  Widget _dropdown(
    BuildContext context,
    String label,
    int value,
    ValueChanged<int> onChanged,
  ) => DropdownButtonFormField<int>(
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: [
      for (var i = 1; i <= 7; i++)
        DropdownMenuItem(
          value: i,
          child: Text(context.trArgs('مستوى {p0}', {'p0': i})),
        ),
    ],
    onChanged: (v) => onChanged(v ?? value),
  );
}
