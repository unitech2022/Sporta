import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../data/venue_repository.dart';
import '../../domain/entities/owner_venue.dart';
import '../widgets/court_schedule_widgets.dart';

/// أسعار النادي حسب الوقت: يحدّد المالك فترات اليوم بسعر ساعة لكل فترة
/// («من 6 صباحاً إلى 3 عصراً بـ 100 ر.س، ومن 3 عصراً إلى 12 ليلاً بـ 150»)
/// ويطبّقها على كل ملاعب النادي دفعة واحدة أو على المختار منها. يمكن
/// تخصيص ملعب بعينه لاحقاً من «جدول الملعب».
class VenuePricingPage extends StatefulWidget {
  const VenuePricingPage({super.key, required this.venue});

  final OwnerVenue venue;

  @override
  State<VenuePricingPage> createState() => _VenuePricingPageState();
}

class _VenuePricingPageState extends State<VenuePricingPage> {
  final _repo = getIt<VenueRepository>();

  VenuePricing? _pricing;
  String? _error;
  bool _saving = false;

  /// الملاعب المستهدفة (افتراضياً كلها).
  final Set<int> _selected = {};
  List<CourtPriceRule> _rules = [];
  final List<int> _ids = [];
  int _nextId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _repo.fetchVenuePricing(widget.venue.id);
      if (!mounted) return;
      // نقطة البداية: أول ملعب له فترات (غالباً كلها متطابقة)، وإلا فترتان
      // مقترحتان صباحاً/مساءً بسعر الملعب.
      final source = p.courts.where((c) => c.priceRules.isNotEmpty).firstOrNull;
      setState(() {
        _pricing = p;
        _selected
          ..clear()
          ..addAll(p.courts.map((c) => c.id));
        _setRules(source?.priceRules ?? _suggested(p));
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.display);
    }
  }

  void _setRules(List<CourtPriceRule> rules) {
    _rules = [...rules];
    _ids
      ..clear()
      ..addAll([for (final _ in rules) _nextId++]);
  }

  /// فترتان مقترحتان: الصباح بالسعر الأساسي والمساء أعلى بقليل.
  List<CourtPriceRule> _suggested(VenuePricing p) {
    final base = _basePrice(p);
    if (base <= 0) return const [];
    return [
      CourtPriceRule(startHour: 6, endHour: 15, hourlyPrice: base),
      CourtPriceRule(
        startHour: 15,
        endHour: 24,
        hourlyPrice: (base * 1.25).roundToDouble(),
      ),
    ];
  }

  /// السعر الأساسي المرجعي: أول ملعب مختار.
  double _basePrice(VenuePricing p) =>
      p.courts
          .where((c) => _selected.isEmpty || _selected.contains(c.id))
          .map((c) => c.basePrice)
          .firstOrNull ??
      0;

  double get _commission =>
      _pricing?.courts.map((c) => c.commissionPercent).firstOrNull ?? 0;

  bool _overlaps(int i) => [
    for (var j = 0; j < _rules.length; j++)
      if (j != i && _rules[i].overlaps(_rules[j])) j,
  ].isNotEmpty;

  int _nextFreeHour() {
    final ends = _rules.where((r) => r.day == null).map((r) => r.endHour);
    final last = ends.isEmpty ? 6 : ends.reduce((a, b) => a > b ? a : b);
    return last >= 24 ? 23 : last;
  }

  void _addRule() {
    final base = _pricing == null ? 0.0 : _basePrice(_pricing!);
    setState(() {
      _rules.add(
        CourtPriceRule(
          startHour: _nextFreeHour(),
          endHour: 24,
          hourlyPrice: base > 0 ? base : null,
        ),
      );
      _ids.add(_nextId++);
    });
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_selected.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('اختر ملعباً واحداً على الأقل'))),
      );
      return;
    }
    if (_rules.indexed.any((e) => _overlaps(e.$1))) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.tr('عدّل النطاقات المتداخلة قبل الحفظ')),
        ),
      );
      return;
    }
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await _repo.updateVenuePricing(
        venueId: widget.venue.id,
        courtIds: _selected.toList(),
        priceRules: _rules,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.trArgs('حُفظت الأسعار على {p0} ملعب', {
              'p0': _selected.length,
            }),
          ),
        ),
      );
      navigator.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _pricing;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        title: Text(context.tr('أسعار النادي حسب الوقت')),
      ),
      body: p == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Text(_error!, style: AppTextStyles.body),
            )
          : ListView(
              padding: context.safeBottom(
                const EdgeInsets.all(AppSizes.pagePadding),
              ),
              children: [
                Text(
                  widget.venue.name,
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  context.tr(
                    'قسّم اليوم إلى فترات وحدّد سعر الساعة لكل فترة. الساعات خارج الفترات تبقى بسعر الملعب الأساسي، والحجز الممتد بين فترتين يُحسب كل جزء بسعره.',
                  ),
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSizes.lg),
                _sectionTitle(context.tr('الملاعب')),
                const SizedBox(height: AppSizes.sm),
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: [
                    for (final c in p.courts)
                      FilterChip(
                        selected: _selected.contains(c.id),
                        label: Text(
                          '${c.name} · ${context.trArgs('{p0} ر.س', {'p0': money(c.basePrice)})}',
                        ),
                        onSelected: (v) => setState(() {
                          if (v) {
                            _selected.add(c.id);
                          } else {
                            _selected.remove(c.id);
                          }
                        }),
                      ),
                  ],
                ),
                if (p.courts.length > 1 &&
                    p.courts.any((c) => c.priceRules.isNotEmpty) &&
                    p.courts.any((c) => c.priceRules.isEmpty))
                  Padding(
                    padding: const EdgeInsets.only(top: AppSizes.sm),
                    child: Text(
                      context.tr(
                        'بعض الملاعب لها أسعار خاصة — الحفظ يستبدلها بهذه الفترات للملاعب المختارة فقط.',
                      ),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSizes.xl),
                Row(
                  children: [
                    Expanded(child: _sectionTitle(context.tr('فترات اليوم'))),
                    if (_rules.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() => _setRules(const [])),
                        child: Text(context.tr('سعر موحّد')),
                      ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                if (_rules.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      context.tr(
                        'لا توجد فترات — كل ملعب بسعره الأساسي طوال اليوم.',
                      ),
                      style: AppTextStyles.caption,
                    ),
                  )
                else
                  for (var i = 0; i < _rules.length; i++)
                    PriceRuleCard(
                      key: ValueKey(_ids[i]),
                      rule: _rules[i],
                      basePrice: _basePrice(p),
                      commissionPercent: _commission,
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
                const SizedBox(height: AppSizes.md),
                Text(
                  context.tr(
                    'لتسعير مختلف ليوم معيّن (الجمعة مثلاً) أضف فترة واختر اليوم — فترة اليوم المحدد تسبق «كل الأيام».',
                  ),
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSizes.xxl),
              ],
            ),
      bottomNavigationBar: p == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(AppSizes.pagePadding),
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
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
                  label: Text(
                    context.trArgs('حفظ على {p0} ملعب', {
                      'p0': _selected.length,
                    }),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: AppTextStyles.bodyMedium.copyWith(
      color: AppColors.secondary,
      fontWeight: FontWeight.w700,
    ),
  );
}
