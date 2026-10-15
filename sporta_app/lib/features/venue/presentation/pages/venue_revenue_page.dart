import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../data/venue_repository.dart';
import '../../domain/entities/venue_dashboard.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/skeleton.dart';

const _emeraldGradient = LinearGradient(
  colors: [Color(0xFF047857), Color(0xFF059669)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
const _emerald = Color(0xFF059669);

/// Venue owner's financial reports: monthly/weekly revenue, chart, per-court
/// breakdown and transactions — all from `/venues/revenue`.
class VenueRevenuePage extends StatefulWidget {
  const VenueRevenuePage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<VenueRevenuePage> createState() => _VenueRevenuePageState();
}

class _VenueRevenuePageState extends State<VenueRevenuePage> {
  final _repository = getIt<VenueRepository>();

  String _periodType = 'month';
  int _offset = 0;
  bool _showPicker = false;
  VenueRevenueReport? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await _repository.fetchRevenueReport(
        periodType: _periodType,
        offset: _offset,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.display;
        _loading = false;
      });
    }
  }

  void _setPeriodType(String type) {
    if (type == _periodType) return;
    setState(() {
      _periodType = type;
      _offset = 0;
      _showPicker = false;
    });
    _load();
  }

  void _setOffset(int offset) {
    setState(() {
      _offset = offset;
      _showPicker = false;
    });
    _load();
  }

  List<(int offset, String label)> get _pickerOptions {
    if (_periodType == 'month') {
      return [
        (0, trg('الشهر الحالي')),
        (1, trg('الشهر الماضي')),
        (2, trg('قبل شهرين')),
        (3, trg('قبل 3 أشهر')),
        (4, trg('قبل 4 أشهر')),
        (5, trg('قبل 5 أشهر')),
      ];
    }
    return [
      (0, trg('هذا الأسبوع')),
      (1, trg('الأسبوع الماضي')),
      (2, trg('قبل أسبوعين')),
      (3, trg('قبل 3 أسابيع')),
      (4, trg('قبل 4 أسابيع')),
      (5, trg('قبل 5 أسابيع')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _header(context),
            Expanded(
              child: _loading
                  ? const _RevenueSkeleton()
                  : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    )
                  : _body(context, _report!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final report = _report;
    return Container(
      decoration: const BoxDecoration(gradient: _emeraldGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.lg,
            AppSizes.pagePadding,
            AppSizes.lg,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: widget.onBack,
                      child: const Padding(
                        padding: EdgeInsets.all(AppSizes.sm),
                        child: Icon(Icons.arrow_forward, color: Colors.white),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      context.tr('تفاصيل الإيرادات'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              // Period type tabs.
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Row(
                  children: [
                    for (final t in [
                      ('month', trg('شهري')),
                      ('week', trg('أسبوعي')),
                    ])
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _setPeriodType(t.$1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.sm,
                            ),
                            decoration: BoxDecoration(
                              color: _periodType == t.$1 ? Colors.white : null,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              context.tr(t.$2),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: _periodType == t.$1
                                    ? _emerald
                                    : Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.md),
              // Period picker button.
              Material(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  onTap: () => setState(() => _showPicker = !_showPicker),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.md,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          _showPicker
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: AppSizes.iconSm,
                        ),
                        Text(
                          report?.periodLabel ?? '...',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.white70,
                          size: AppSizes.iconSm,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_showPicker)
                Container(
                  margin: const EdgeInsets.only(top: AppSizes.sm),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final o in _pickerOptions)
                        InkWell(
                          onTap: () => _setOffset(o.$1),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.md,
                              vertical: AppSizes.md,
                            ),
                            decoration: BoxDecoration(
                              color: _offset == o.$1
                                  ? const Color(0xFFECFDF5)
                                  : Colors.white,
                              border: const Border(
                                bottom: BorderSide(color: Color(0xFFF3F4F6)),
                              ),
                            ),
                            child: Text(
                              context.tr(o.$2),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: _offset == o.$1
                                    ? _emerald
                                    : AppColors.secondary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSizes.md),
              // Total revenue hero.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                ),
                child: Column(
                  children: [
                    Text(
                      '${context.tr('إجمالي إيرادات')} ${_periodType == 'month' ? context.tr('الشهر') : context.tr('الأسبوع')}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report == null ? '—' : money(report.total),
                      style: AppTextStyles.heading1.copyWith(
                        color: Colors.white,
                        fontSize: 34,
                      ),
                    ),
                    Text(
                      context.tr('ريال سعودي'),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    if (report?.changePercent != null) ...[
                      const SizedBox(height: AppSizes.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            report!.changePercent! >= 0
                                ? Icons.arrow_outward
                                : Icons.south_east,
                            size: AppSizes.iconSm,
                            color: report.changePercent! >= 0
                                ? const Color(0xFF6EE7B7)
                                : const Color(0xFFFCA5A5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${report.changePercent! >= 0 ? '+' : ''}${money(report.changePercent!)}% ${context.tr('عن الفترة السابقة')}',
                            style: AppTextStyles.caption.copyWith(
                              color: report.changePercent! >= 0
                                  ? const Color(0xFF6EE7B7)
                                  : const Color(0xFFFCA5A5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, VenueRevenueReport report) {
    return SingleChildScrollView(
      padding: context.safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _barChartCard(context, report),
          const SizedBox(height: AppSizes.lg),
          _courtBreakdownCard(context, report),
          const SizedBox(height: AppSizes.lg),
          _transactionsCard(context, report),
        ],
      ),
    );
  }

  Widget _barChartCard(BuildContext context, VenueRevenueReport report) {
    final maxVal = report.bars.fold<double>(
      0,
      (m, b) => b.amount > m ? b.amount : m,
    );
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                color: _emerald,
                size: AppSizes.iconMd,
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  '${context.tr('الإيرادات التفصيلية')} · ${report.periodLabel}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          if (report.bars.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
              child: Text(
                context.tr('لا توجد بيانات لهذه الفترة'),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
            )
          else
            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final b in report.bars)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              b.amount >= 1000
                                  ? '${(b.amount / 1000).toStringAsFixed(1)}k'
                                  : money(b.amount),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.mutedForeground,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 80,
                              alignment: Alignment.bottomCenter,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: FractionallySizedBox(
                                heightFactor: maxVal > 0
                                    ? (b.amount / maxVal).clamp(0, 1)
                                    : 0,
                                widthFactor: 1,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: _emerald,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              b.label,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.mutedForeground,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _courtBreakdownCard(BuildContext context, VenueRevenueReport report) {
    const dotColors = [_emerald, Color(0xFF3B82F6), Color(0xFFF59E0B)];
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: _emerald,
                size: AppSizes.iconMd,
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                context.tr('الإيرادات حسب الملعب'),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          if (report.courtBreakdown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
              child: Text(
                context.tr('لا توجد بيانات لهذه الفترة'),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
            )
          else
            for (var i = 0; i < report.courtBreakdown.length; i++) ...[
              _courtRevenueRow(
                context,
                report.courtBreakdown[i],
                dotColors[i % dotColors.length],
              ),
              if (i < report.courtBreakdown.length - 1)
                const SizedBox(height: AppSizes.md),
            ],
        ],
      ),
    );
  }

  Widget _courtRevenueRow(BuildContext context, CourtRevenue c, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  c.courtName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            Text(
              context.trArgs('{p0} ر.س  ({p1} حجز)', {
                'p0': money(c.total),
                'p1': c.bookingsCount,
              }),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          child: LinearProgressIndicator(
            value: (c.percent / 100).clamp(0, 1),
            minHeight: 8,
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${money(c.percent)}% ${context.tr('من الإجمالي')}',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }

  Widget _transactionsCard(BuildContext context, VenueRevenueReport report) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.filter_alt_outlined,
                      color: _emerald,
                      size: AppSizes.iconMd,
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        '${context.tr('المعاملات')} · ${report.periodLabel}',
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${report.transactions.length} ${context.tr('معاملة')}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          if (report.transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
              child: Text(
                context.tr('لا توجد معاملات لهذه الفترة'),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
            )
          else
            for (var i = 0; i < report.transactions.length; i++) ...[
              _transactionTile(context, report.transactions[i]),
              if (i < report.transactions.length - 1)
                const SizedBox(height: AppSizes.sm),
            ],
        ],
      ),
    );
  }

  Widget _transactionTile(BuildContext context, RevenueTransaction tx) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.arrow_outward, color: _emerald, size: 20),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tx.courtName} · ${tx.timeRangeLabel}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  '${tx.playerName} · ${_dateLabel(tx.date)}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Text(
            context.trArgs('+{p0} ر.س', {'p0': money(tx.amount)}),
            style: AppTextStyles.bodySmall.copyWith(
              color: _emerald,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

/// هيكل التحميل تحت الترويسة: بطاقة الرسم البياني ثم التوزيع ثم المعاملات.
class _RevenueSkeleton extends StatelessWidget {
  const _RevenueSkeleton();

  static const _barHeights = [50.0, 80.0, 35.0, 95.0, 60.0, 75.0];

  Widget _card(List<Widget> children) => Container(
    padding: const EdgeInsets.all(AppSizes.lg),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            SkeletonBox.circle(size: 20),
            SizedBox(width: AppSizes.sm),
            SkeletonBox(height: 14, width: 150),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        ...children,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _card([
            SizedBox(
              height: 110,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final h in _barHeights)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: SkeletonBox(height: h, radius: 4),
                      ),
                    ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: AppSizes.lg),
          _card([
            for (var i = 0; i < 3; i++) ...[
              Row(
                children: [
                  SkeletonBox(height: 10, width: i.isEven ? 90 : 70),
                  const Spacer(),
                  const SkeletonBox(height: 10, width: 80),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              const SkeletonBox(height: 8, radius: AppSizes.radiusFull),
              if (i != 2) const SizedBox(height: AppSizes.md),
            ],
          ]),
          const SizedBox(height: AppSizes.lg),
          _card([
            for (var i = 0; i < 3; i++) ...[
              Row(
                children: [
                  const SkeletonBox.circle(size: 40),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 12, width: i.isEven ? 120 : 100),
                        const SizedBox(height: AppSizes.sm),
                        const SkeletonBox(height: 10, width: 80),
                      ],
                    ),
                  ),
                  const SkeletonBox(height: 12, width: 60),
                ],
              ),
              if (i != 2) const SizedBox(height: AppSizes.md),
            ],
          ]),
        ],
      ),
    );
  }
}
