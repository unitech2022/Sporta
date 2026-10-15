import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../data/coach_repository.dart';
import '../../domain/entities/coach_offer_entity.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/widgets/skeleton.dart';
import 'package:sporta_app/core/utils/server_time.dart';

/// العروض والخصومات — offers/discounts the coach adds to their profile,
/// shown to players before they book (embedded live in `CoachDto.offers`).
class CoachOffersSection extends StatefulWidget {
  const CoachOffersSection({super.key});

  @override
  State<CoachOffersSection> createState() => _CoachOffersSectionState();
}

class _CoachOffersSectionState extends State<CoachOffersSection> {
  final _repo = getIt<CoachRepository>();

  List<CoachOfferEntity> _offers = [];
  bool _loading = true;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final offers = await _repo.fetchMyOffers();
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleActive(CoachOfferEntity o) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busyId = o.id);
    try {
      await _repo.setOfferActive(o.id, !o.isActive);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _delete(CoachOfferEntity o) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('حذف العرض')),
        content: Text(ctx.tr('هل تريد حذف هذا العرض؟')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
            child: Text(ctx.tr('حذف')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busyId = o.id);
    try {
      await _repo.deleteOffer(o.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
      setState(() => _busyId = null);
    }
  }

  Future<void> _openAddSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddOfferSheet(),
    );
    if (created == true) _load();
  }

  String _targetLabel(BuildContext context, String target) => switch (target) {
    'individual' => context.tr('فردية'),
    'group' => context.tr('جماعية'),
    _ => context.tr('عام'),
  };

  String _dateLabel(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  @override
  Widget build(BuildContext context) {
    final activeCount = _offers.where((o) => o.isActive && !o.isExpired).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.tr('العروض والخصومات'),
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.secondary,
              ),
            ),
            if (activeCount > 0) ...[
              const SizedBox(width: AppSizes.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  '$activeCount ${context.tr('نشطة')}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        if (_loading)
          const SkeletonList(
            itemCount: 2,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            showAvatar: false,
          )
        else ...[
          for (final o in _offers) ...[
            _offerCard(context, o),
            const SizedBox(height: AppSizes.md),
          ],
          _addButton(context),
        ],
      ],
    );
  }

  Widget _offerCard(BuildContext context, CoachOfferEntity o) {
    final busy = _busyId == o.id;
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Text(
                  '${o.discountPercent}%',
                  style: AppTextStyles.body.copyWith(
                    color: const Color(0xFFEA580C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  _targetLabel(context, o.targetLabel),
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
              const Spacer(),
              if (busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                InkWell(
                  onTap: () => _delete(o),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.mutedForeground,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            o.title,
            style: AppTextStyles.body.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            '${context.tr('تنتهي')}: ${_dateLabel(o.expiresAt)}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          if (o.isExpired)
            Text(
              context.tr('منتهي'),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedForeground,
              ),
            )
          else
            InkWell(
              onTap: busy ? null : () => _toggleActive(o),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: o.isActive
                          ? AppColors.success
                          : AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    o.isActive ? context.tr('نشط') : context.tr('غير نشط'),
                    style: AppTextStyles.caption.copyWith(
                      color: o.isActive
                          ? AppColors.success
                          : AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _addButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        onTap: _openAddSheet,
        child: DottedBorderContainer(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: AppColors.primary, size: 18),
                const SizedBox(width: AppSizes.xs),
                Text(
                  context.tr('إضافة عرض أو خصم جديد'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A dashed-border container (Flutter has no built-in dashed border, so this
/// paints one directly via a CustomPainter).
class DottedBorderContainer extends StatelessWidget {
  const DottedBorderContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: AppColors.primary),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppSizes.radiusXl),
    );
    final path = Path()..addRRect(rrect);
    final dashed = _dashPath(path, dashLength: 6, gapLength: 4);
    canvas.drawPath(dashed, paint);
  }

  Path _dashPath(
    Path source, {
    required double dashLength,
    required double gapLength,
  }) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final length = draw ? dashLength : gapLength;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Bottom sheet form to create a new offer/discount.
class _AddOfferSheet extends StatefulWidget {
  const _AddOfferSheet();

  @override
  State<_AddOfferSheet> createState() => _AddOfferSheetState();
}

class _AddOfferSheetState extends State<_AddOfferSheet> {
  final _repo = getIt<CoachRepository>();
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _discount = TextEditingController();
  String _target = 'all';
  DateTime? _expiresAt;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _discount.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final now = ksaNow();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_expiresAt == null) {
      setState(() => _error = context.tr('يرجى اختيار تاريخ الانتهاء'));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repo.createOffer(
        title: _title.text.trim(),
        discountPercent: int.parse(_discount.text.trim()),
        targetLabel: _target,
        expiresAt: _expiresAt!,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.display;
      });
    }
  }

  String _dateLabel(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            context.bottomSystemInset,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
        ),
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSizes.lg),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
              ),
              Text(
                context.tr('إضافة عرض أو خصم جديد'),
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              TextFormField(
                controller: _title,
                decoration: InputDecoration(
                  labelText: context.tr('عنوان العرض'),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.tr('هذا الحقل مطلوب')
                    : null,
              ),
              const SizedBox(height: AppSizes.lg),
              TextFormField(
                controller: _discount,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.tr('نسبة الخصم %'),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                ),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 1 || n > 100) {
                    return context.tr('نسبة الخصم يجب أن تكون بين 1 و100');
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.lg),
              Wrap(
                spacing: AppSizes.sm,
                children: [
                  for (final (value, label) in [
                    ('all', trg('عام')),
                    ('individual', trg('فردية')),
                    ('group', trg('جماعية')),
                  ])
                    ChoiceChip(
                      label: Text(context.tr(label)),
                      selected: _target == value,
                      onSelected: (_) => setState(() => _target = value),
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              InkWell(
                onTap: _pickExpiry,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: context.tr('تاريخ الانتهاء'),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
                    suffixIcon: const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                    ),
                  ),
                  child: Text(
                    _expiresAt == null
                        ? context.tr('اختر التاريخ')
                        : _dateLabel(_expiresAt!),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSizes.md),
                Text(
                  _error!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.destructive,
                  ),
                ),
              ],
              const SizedBox(height: AppSizes.xl),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(context.tr('إضافة')),
                ),
              ),
              const SizedBox(height: AppSizes.md),
            ],
          ),
        ),
      ),
    );
  }
}
