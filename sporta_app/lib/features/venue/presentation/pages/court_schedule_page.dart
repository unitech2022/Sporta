import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../data/venue_repository.dart';
import '../../domain/entities/owner_venue.dart';
import '../widgets/court_schedule_widgets.dart';
import '../../../../core/utils/system_insets.dart';

/// جدول الملعب: دوام كل يوم من أيام الأسبوع + أسعار حسب اليوم والوقت.
/// يُرجع الملعب بعد الحفظ حتى تحدّث الشاشة السابقة بياناتها.
class CourtSchedulePage extends StatefulWidget {
  const CourtSchedulePage({super.key, required this.court});

  final OwnerCourt court;

  @override
  State<CourtSchedulePage> createState() => _CourtSchedulePageState();
}

class _CourtSchedulePageState extends State<CourtSchedulePage> {
  final _repo = getIt<VenueRepository>();

  late List<CourtOpeningHour> _hours = widget.court.openingHours.isEmpty
      ? CourtOpeningHour.defaultWeek()
      : [...widget.court.openingHours];
  late List<CourtPriceRule> _rules = [...widget.court.priceRules];

  /// مفتاح ثابت لكل بطاقة — حتى لا يُعاد بناء حقل السعر مع كل حرف ولا
  /// تنتقل حالة بطاقة إلى أخرى عند الحذف.
  late final List<int> _ids = [for (var i = 0; i < _rules.length; i++) i];
  late int _nextId = _rules.length;

  bool _saving = false;

  double get _basePrice {
    final hourly = widget.court.bookingTiers
        .where((t) => t.durationMinutes == 60)
        .map((t) => t.price)
        .firstOrNull;
    return hourly ?? widget.court.pricePerHour;
  }

  void _setDay(int index, CourtOpeningHour value) =>
      setState(() => _hours[index] = value);

  /// ينسخ دوام يوم إلى بقية الأيام المفتوحة — الأندية غالباً بدوام موحّد.
  void _copyToAll(CourtOpeningHour source) {
    setState(() {
      _hours = [
        for (final h in _hours)
          h.copyWith(
            isClosed: h.isClosed,
            openHour: source.openHour,
            closeHour: source.closeHour,
          ),
      ];
    });
  }

  void _addRule() {
    _ids.add(_nextId++);
    setState(
      () => _rules = [
        ..._rules,
        // نطاق جديد يبدأ بعد آخر نطاق وبسعر الملعب الأساسي — يعدّله المالك.
        CourtPriceRule(
          day: null,
          startHour: _nextFreeHour(),
          endHour: 24,
          hourlyPrice: _basePrice > 0 ? _basePrice : null,
        ),
      ],
    );
  }

  /// أول ساعة بعد نهاية آخر نطاق «كل الأيام» (حتى لا يتداخل الجديد).
  int _nextFreeHour() {
    final ends = _rules.where((r) => r.day == null).map((r) => r.endHour);
    final last = ends.isEmpty ? 6 : ends.reduce((a, b) => a > b ? a : b);
    return last >= 24 ? 23 : last;
  }

  bool _overlaps(int i) => [
    for (var j = 0; j < _rules.length; j++)
      if (j != i && _rules[i].overlaps(_rules[j])) j,
  ].isNotEmpty;

  Future<void> _save() async {
    if (_rules.indexed.any((e) => _overlaps(e.$1))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('عدّل النطاقات المتداخلة قبل الحفظ')),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final court = await _repo.updateCourtSchedule(
        courtId: widget.court.id,
        openingHours: _hours,
        priceRules: _rules,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('تم حفظ جدول الملعب'))),
      );
      navigator.pop(court);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final allClosed = _hours.every((h) => h.isClosed);
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          title: Text(context.tr('جدول الملعب')),
        ),
        body: ListView(
          padding: context.safeBottom(
            const EdgeInsets.all(AppSizes.pagePadding),
          ),
          children: [
            _sectionTitle(context.tr('دوام الأسبوع')),
            _hint(
              context.tr(
                'حدّد أوقات فتح الملعب في كل يوم. اللاعبون لا يرون أي موعد خارج هذه الأوقات، واليوم المغلق لا يقبل الحجز إطلاقاً.',
              ),
            ),
            const SizedBox(height: AppSizes.md),
            for (var i = 0; i < _hours.length; i++)
              OpeningDayRow(
                hours: _hours[i],
                onChanged: (v) => _setDay(i, v),
                onCopyToAll: () => _copyToAll(_hours[i]),
              ),
            if (allClosed)
              _warning(
                context.tr('كل الأيام مغلقة — لن يستطيع أحد حجز هذا الملعب.'),
              ),
            const SizedBox(height: AppSizes.xl),
            _sectionTitle(context.tr('أسعار حسب اليوم والوقت')),
            _hint(
              context.tr(
                'حدّد سعر الساعة لكل فترة — مثلاً من 6 صباحاً إلى 3 عصراً بسعر، ومن 3 عصراً إلى 12 ليلاً بسعر آخر. الحجز الذي يمتد بين فترتين يُحسب كل جزء منه بسعر فترته، ونطاق اليوم المحدد يسبق «كل الأيام».',
              ),
            ),
            const SizedBox(height: AppSizes.md),
            if (_rules.isEmpty)
              _emptyRules()
            else
              for (var i = 0; i < _rules.length; i++)
                PriceRuleCard(
                  key: ValueKey(_ids[i]),
                  rule: _rules[i],
                  basePrice: _basePrice,
                  hasOverlap: _overlaps(i),
                  onChanged: (v) => setState(() => _rules[i] = v),
                  onDelete: () => setState(() {
                    _rules.removeAt(i);
                    _ids.removeAt(i);
                  }),
                ),
            const SizedBox(height: AppSizes.sm),
            OutlinedButton.icon(
              onPressed: _addRule,
              icon: const Icon(Icons.add),
              label: Text(context.tr('إضافة فترة سعر')),
            ),
            const SizedBox(height: AppSizes.xxl),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(AppSizes.pagePadding),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(context.tr('حفظ الجدول')),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    context.tr(text),
    style: AppTextStyles.heading3.copyWith(color: AppColors.secondary),
  );

  Widget _hint(String text) => Padding(
    padding: const EdgeInsets.only(top: AppSizes.xs),
    child: Text(context.tr(text), style: AppTextStyles.caption),
  );

  Widget _warning(String text) => Container(
    padding: const EdgeInsets.all(AppSizes.md),
    decoration: BoxDecoration(
      color: AppColors.destructive.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.destructive,
          size: 20,
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(
            context.tr(text),
            style: AppTextStyles.caption.copyWith(color: AppColors.destructive),
          ),
        ),
      ],
    ),
  );

  Widget _emptyRules() => Container(
    padding: const EdgeInsets.all(AppSizes.lg),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        const Icon(Icons.schedule_outlined, color: AppColors.mutedForeground),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(
            context.tr('لا توجد قواعد — السعر موحّد طوال الأسبوع.'),
            style: AppTextStyles.caption,
          ),
        ),
      ],
    ),
  );
}
