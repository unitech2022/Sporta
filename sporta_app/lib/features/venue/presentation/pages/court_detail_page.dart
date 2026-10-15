import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/state/app_scope.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../../reviews/presentation/widgets/court_reviews_section.dart';
import '../../data/venue_repository.dart';
import '../../domain/entities/owner_court_slot.dart';
import '../../domain/entities/owner_venue.dart';
import 'court_schedule_page.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/widgets/skeleton.dart';
import 'package:sporta_app/core/utils/server_time.dart';

/// Owner view of a single court: details + the day's hourly slots. The owner
/// taps an available slot to block it (booked slots are disabled). Pops a
/// [CourtDetailAction] when the owner chooses to edit or delete.
class CourtDetailPage extends StatefulWidget {
  const CourtDetailPage({super.key, required this.court});

  final OwnerCourt court;

  @override
  State<CourtDetailPage> createState() => _CourtDetailPageState();
}

class _CourtDetailPageState extends State<CourtDetailPage> {
  final _repo = getIt<VenueRepository>();

  late final List<DateTime> _days = List.generate(
    14,
    (i) => ksaNow().add(Duration(days: i)),
  );
  late DateTime _selected = _days.first;

  /// يتحدّث بعد حفظ الجدول حتى يظهر الدوام الجديد فوراً.
  late OwnerCourt _court = widget.court;

  List<OwnerCourtSlot> _slots = [];
  bool _loading = true;
  int? _busyHour;

  /// وضع التحديد المتعدد: يجمع ساعات ثم يتيحها أو يوقفها دفعة واحدة.
  bool _selecting = false;
  final Set<int> _selectedHours = {};
  bool _bulkBusy = false;

  static List<String> get _weekdays => [
    trg('الإثنين'),
    trg('الثلاثاء'),
    trg('الأربعاء'),
    trg('الخميس'),
    trg('الجمعة'),
    trg('السبت'),
    trg('الأحد'),
  ];
  static List<String> get _months => [
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

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _selectedHours.clear();
    });
    try {
      final slots = await _repo.fetchCourtSlots(_court.id, _key(_selected));
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _toggle(OwnerCourtSlot s) async {
    if (s.isBooked || _busyHour != null) return;
    setState(() => _busyHour = s.hour);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final slots = await _repo.toggleCourtSlot(
        _court.id,
        _key(_selected),
        s.hour,
      );
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _busyHour = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busyHour = null);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  /// يطبّق الإتاحة/الإيقاف على كل الساعات المحددة دفعة واحدة.
  Future<void> _applyBulk(bool available) async {
    if (_selectedHours.isEmpty || _bulkBusy) return;
    setState(() => _bulkBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final slots = await _repo.setCourtSlots(
        _court.id,
        _key(_selected),
        _selectedHours.toList(),
        available: available,
      );
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _bulkBusy = false;
        _selecting = false;
        _selectedHours.clear();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _bulkBusy = false);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  /// جدول الملعب — الدوام الأسبوعي وأسعار الأوقات.
  Future<void> _openSchedule() async {
    final updated = await Navigator.of(context).push<OwnerCourt>(
      MaterialPageRoute(builder: (_) => CourtSchedulePage(court: _court)),
    );
    if (updated == null || !mounted) return;
    setState(() => _court = updated);
    // الدوام الجديد يغيّر مواعيد اليوم المعروضة.
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = _court;
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          title: Text(c.name),
          actions: [
            IconButton(
              tooltip: context.tr('جدول الملعب'),
              onPressed: _openSchedule,
              icon: const Icon(Icons.calendar_month_outlined),
            ),
            IconButton(
              tooltip: context.tr('تعديل'),
              onPressed: () => Navigator.pop(context, CourtDetailAction.edit),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: context.tr('حذف'),
              onPressed: () => Navigator.pop(context, CourtDetailAction.delete),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: ListView(
          padding: context.safeBottom(
            const EdgeInsets.all(AppSizes.pagePadding),
          ),
          children: [
            _details(c),
            // تقييمات اللاعبين لهذا الملعب بعد مبارياتهم عليه.
            const SizedBox(height: AppSizes.lg),
            CourtReviewsSection(courtId: c.id),
            const SizedBox(height: AppSizes.xl),
            Text(
              context.tr('أوقات اليوم'),
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            _daySelector(),
            const SizedBox(height: AppSizes.md),
            _legend(),
            const SizedBox(height: AppSizes.md),
            if (_loading)
              // هيكل شبكة المواعيد بنفس أبعادها.
              Shimmer(
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: AppSizes.sm,
                  mainAxisSpacing: AppSizes.sm,
                  childAspectRatio: 1.35,
                  children: [
                    for (var i = 0; i < 12; i++)
                      const SkeletonBox(height: 48, radius: AppSizes.radiusMd),
                  ],
                ),
              )
            else if (_slots.isEmpty)
              _closedDayNotice()
            else ...[
              _bulkBar(),
              const SizedBox(height: AppSizes.sm),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSizes.sm,
                mainAxisSpacing: AppSizes.sm,
                childAspectRatio: 1.35,
                children: [for (final s in _slots) _slotChip(s)],
              ),
            ],
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  Widget _details(OwnerCourt c) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: (c.imageUrl != null && c.imageUrl!.isNotEmpty)
                ? Image.network(
                    ApiEndpoints.fileUrl(c.imageUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _imgPlaceholder(),
                  )
                : _imgPlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.xs,
                  children: [
                    _tag(c.typeLabel, AppColors.primary),
                    _tag(
                      c.isAvailable ? trg('مفعّل') : trg('موقوف'),
                      c.isAvailable
                          ? AppColors.success
                          : AppColors.mutedForeground,
                    ),
                    if (c.latitude != null && c.longitude != null)
                      _tag(trg('موقع محدد'), AppColors.primary),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  context.trArgs('حجز: {p0}', {'p0': _tiers(c.bookingTiers)}),
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSizes.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 14,
                      color: AppColors.mutedForeground,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        c.scheduleSummary,
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
                if (c.priceRules.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.xs),
                  Wrap(
                    spacing: AppSizes.sm,
                    runSpacing: AppSizes.xs,
                    children: [
                      for (final r in c.priceRules)
                        _tag(
                          '${r.dayLabel} ${r.rangeLabel} ${r.adjustmentLabel}',
                          r.adjustmentPercent >= 0
                              ? AppColors.primary
                              : AppColors.success,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _daySelector() {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSizes.sm),
        itemBuilder: (_, i) {
          final d = _days[i];
          final sel = _key(d) == _key(_selected);
          return GestureDetector(
            onTap: () {
              setState(() => _selected = d);
              _load();
            },
            child: Container(
              width: 58,
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(
                  color: sel ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekdays[d.weekday - 1],
                    style: AppTextStyles.caption.copyWith(
                      color: sel ? Colors.white : AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${d.day}',
                    style: AppTextStyles.body.copyWith(
                      color: sel ? Colors.white : AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _months[d.month - 1].substring(0, 3),
                    style: AppTextStyles.caption.copyWith(
                      color: sel ? Colors.white : AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _legend() {
    Widget item(Color c, String t) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(t, style: AppTextStyles.caption),
      ],
    );
    return Wrap(
      spacing: AppSizes.lg,
      runSpacing: AppSizes.xs,
      children: [
        item(AppColors.success, context.tr('متاح')),
        item(AppColors.mutedForeground, context.tr('موقوف')),
        item(AppColors.destructive, context.tr('محجوز')),
      ],
    );
  }

  /// شريط التحديد المتعدد: زر دخول للوضع، ثم "تحديد الكل" وأزرار
  /// الإتاحة/الإيقاف الجماعية. المحجوز لا يدخل في التحديد.
  Widget _bulkBar() {
    final selectable = {
      for (final s in _slots.where((s) => !s.isBooked)) s.hour,
    };
    if (!_selecting) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: selectable.isEmpty
              ? null
              : () => setState(() => _selecting = true),
          icon: const Icon(Icons.checklist_rtl, size: AppSizes.iconMd),
          label: Text(context.tr('تحديد متعدد')),
        ),
      );
    }

    final allSelected =
        selectable.isNotEmpty && _selectedHours.length == selectable.length;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() {
                    if (allSelected) {
                      _selectedHours.clear();
                    } else {
                      _selectedHours
                        ..clear()
                        ..addAll(selectable);
                    }
                  }),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        allSelected
                            ? Icons.check_box
                            : _selectedHours.isEmpty
                            ? Icons.check_box_outline_blank
                            : Icons.indeterminate_check_box,
                        color: AppColors.primary,
                        size: AppSizes.iconLg,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Text(
                        '${context.tr('تحديد الكل')} (${_selectedHours.length})',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: context.tr('إلغاء'),
                onPressed: _bulkBusy
                    ? null
                    : () => setState(() {
                        _selecting = false;
                        _selectedHours.clear();
                      }),
                icon: const Icon(Icons.close, size: AppSizes.iconMd),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _bulkBusy || _selectedHours.isEmpty
                      ? null
                      : () => _applyBulk(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(
                    Icons.check_circle_outline,
                    size: AppSizes.iconSm,
                  ),
                  label: Text(context.tr('متاح')),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _bulkBusy || _selectedHours.isEmpty
                      ? null
                      : () => _applyBulk(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mutedForeground,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.block, size: AppSizes.iconSm),
                  label: Text(context.tr('موقوف')),
                ),
              ),
              if (_bulkBusy) ...[
                const SizedBox(width: AppSizes.sm),
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _slotChip(OwnerCourtSlot s) {
    final busy = _busyHour == s.hour;
    final selected = _selecting && _selectedHours.contains(s.hour);
    final (bg, fg, border) = s.isBooked
        ? (
            const Color(0xFFFEF2F2),
            AppColors.destructive,
            AppColors.destructive,
          )
        : s.isAvailable
        ? (const Color(0xFFECFDF5), AppColors.success, AppColors.success)
        : (
            const Color(0xFFF3F4F6),
            AppColors.mutedForeground,
            AppColors.border,
          );
    return Opacity(
      opacity: s.isBooked ? 0.7 : 1,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: InkWell(
          onTap: s.isBooked
              ? null
              : _selecting
              ? () => setState(() {
                  if (!_selectedHours.remove(s.hour)) {
                    _selectedHours.add(s.hour);
                  }
                })
              : () => _toggle(s),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : border.withValues(alpha: 0.5),
                    width: selected ? 2 : 1,
                  ),
                ),
                // FittedBox يمنع تجاوز المحتوى ارتفاع خلية الشبكة الثابت مهما
                // كان عرض الشاشة أو حجم الخط في إعدادات الجهاز.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s.time,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (busy)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Text(
                          s.isBooked
                              ? context.tr('محجوز')
                              : s.isAvailable
                              ? context.tr('متاح')
                              : context.tr('موقوف'),
                          style: AppTextStyles.caption.copyWith(color: fg),
                        ),
                    ],
                  ),
                ),
              ),
              if (selected)
                const PositionedDirectional(
                  top: 3,
                  start: 3,
                  child: Icon(
                    Icons.check_circle,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// اليوم بلا مواعيد يعني أنه مغلق في دوام الأسبوع.
  Widget _closedDayNotice() => Container(
    padding: const EdgeInsets.all(AppSizes.lg),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        const Icon(Icons.event_busy_outlined, color: AppColors.mutedForeground),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(
            context.tr('الملعب مغلق في هذا اليوم حسب دوام الأسبوع.'),
            style: AppTextStyles.caption,
          ),
        ),
        TextButton(
          onPressed: _openSchedule,
          child: Text(context.tr('تعديل الدوام')),
        ),
      ],
    ),
  );

  Widget _imgPlaceholder() => Container(
    color: const Color(0xFFEFF6FF),
    child: const Center(
      child: Icon(Icons.stadium_outlined, size: 44, color: AppColors.primary),
    ),
  );

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
    ),
    child: Text(
      text,
      style: AppTextStyles.caption.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  String _tiers(List<CourtTier> tiers) {
    if (tiers.isEmpty) return '—';
    final sorted = [...tiers]
      ..sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
    return sorted
        .map(
          (t) => trgArgs('{p0}د:{p1}', {
            'p0': t.durationMinutes,
            'p1': t.price.toStringAsFixed(0),
          }),
        )
        .join(' / ');
  }
}
