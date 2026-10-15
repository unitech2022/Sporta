import '../../../../core/widgets/add_to_calendar_button.dart';
import 'package:flutter/material.dart';

import '../../../reviews/domain/review_models.dart';
import '../../../reviews/presentation/widgets/review_prompt_card.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../data/court_repository.dart';
import '../../domain/entities/booking_entity.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/utils/system_insets.dart';

/// Full details of a single court booking, with a cancel action when allowed.
class BookingDetailPage extends StatefulWidget {
  const BookingDetailPage({super.key, required this.booking});

  final BookingEntity booking;

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  late BookingEntity _b = widget.booking;
  bool _cancelling = false;
  bool _changed = false; // tell the list to refresh on pop

  bool get _canCancel => _b.canCancel;

  String _statusLabel(String s) => switch (s) {
    'Confirmed' => context.tr('مؤكدة'),
    'Pending' => context.tr('قيد الانتظار'),
    'Completed' => context.tr('منتهية'),
    'Cancelled' => context.tr('ملغاة'),
    _ => s,
  };

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: Directionality.of(context),
        child: AlertDialog(
          title: Text(context.tr('إلغاء الحجز')),
          content: Text(context.tr('هل أنت متأكد من إلغاء هذا الحجز؟')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.tr('تراجع')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.destructive,
              ),
              child: Text(context.tr('تأكيد الإلغاء')),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _cancelling = true);
    try {
      final updated = await getIt<CourtRepository>().cancelBooking(_b.id);
      if (!mounted) return;
      setState(() {
        _b = updated;
        _cancelling = false;
        _changed = true;
      });
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('تم إلغاء الحجز'))),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) Navigator.of(context).pop(_changed);
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              _header(),
              Expanded(
                child: ListView(
                  padding: context.safeBottom(
                    const EdgeInsets.all(AppSizes.pagePadding),
                  ),
                  children: [
                    // «كيف كان الملعب؟» بعد انتهاء الحجز — تختفي قبله.
                    ReviewPromptCard(
                      reviewContext: ReviewContext.booking,
                      contextId: _b.id,
                      padding: const EdgeInsets.only(bottom: AppSizes.xl),
                    ),
                    _statsRow(),
                    const SizedBox(height: AppSizes.xl),
                    _infoCard(),
                    // بعد تأكيد الملعب: إضافة الموعد لتقويم الهاتف بضغطة.
                    if (_b.isUpcomingConfirmed) ...[
                      const SizedBox(height: AppSizes.xl),
                      AddToCalendarButton(
                        calendarKey: 'booking-${_b.id}',
                        title: context.trArgs('حجز ملعب · {p0}', {
                          'p0': _b.courtName,
                        }),
                        startKsa: _b.startTime,
                        durationMinutes: _b.durationMinutes,
                        location: [
                          _b.venueName,
                          _b.city,
                        ].where((e) => e.isNotEmpty).join('، '),
                        description: context.tr('حجز عبر سبورتا'),
                      ),
                    ],
                    if (_canCancel) ...[
                      const SizedBox(height: AppSizes.xl),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _cancelling ? null : _cancel,
                          icon: _cancelling
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.close),
                          label: Text(context.tr('إلغاء الحجز')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.destructive,
                            side: const BorderSide(
                              color: AppColors.destructive,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusLg,
                              ),
                            ),
                          ),
                        ),
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

  Widget _header() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.md,
            AppSizes.pagePadding,
            AppSizes.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(_changed),
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(AppSizes.sm),
                        child: DirectionalIcon(
                          rtl: Icons.arrow_forward,
                          ltr: Icons.arrow_back,
                          color: Colors.white,
                          size: AppSizes.iconMd,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Text(
                    context.tr('تفاصيل الحجز'),
                    style: AppTextStyles.heading2.copyWith(color: Colors.white),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      _statusLabel(_b.status),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
                    child: const Icon(
                      Icons.sports_tennis,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _b.courtName,
                          style: AppTextStyles.heading3.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _b.venueName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(
          child: _stat(
            Icons.payments_outlined,
            AppColors.success,
            '${_b.totalPrice} ${context.tr('ر.س')}',
            context.tr('الإجمالي'),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: _stat(
            Icons.timelapse,
            const Color(0xFF2563EB),
            '${_b.durationMinutes} ${context.tr('دقيقة')}',
            context.tr('المدة'),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: _stat(
            _b.paidFullAmount ? Icons.check_circle_outline : Icons.schedule,
            _b.paidFullAmount ? AppColors.success : AppColors.warning,
            _b.paidFullAmount ? context.tr('مدفوع') : context.tr('جزئي'),
            context.tr('الدفع'),
          ),
        ),
      ],
    );
  }

  Widget _stat(IconData icon, Color color, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.lg,
        horizontal: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppSizes.iconMd),
          const SizedBox(height: AppSizes.sm),
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _infoCard() {
    final end = _b.startTime.add(Duration(minutes: _b.durationMinutes));
    final rows = <Widget>[
      _row(
        Icons.confirmation_number_outlined,
        context.tr('رقم الحجز'),
        '#${_b.id}',
      ),
      _row(
        Icons.event_outlined,
        context.tr('التاريخ'),
        _formatDate(_b.startTime),
      ),
      _row(
        Icons.access_time,
        context.tr('الوقت'),
        '${_time(_b.startTime)} — ${_time(end)}',
      ),
      _row(Icons.sports_tennis, context.tr('الملعب'), _b.courtName),
      _row(Icons.business_outlined, context.tr('النادي'), _b.venueName),
      if (_b.city.isNotEmpty)
        _row(Icons.location_on_outlined, context.tr('المدينة'), _b.city),
      _row(
        Icons.timelapse_outlined,
        context.tr('المدة'),
        '${_b.durationMinutes} ${context.tr('دقيقة')}',
      ),
      _row(
        Icons.payments_outlined,
        context.tr('الإجمالي'),
        '${_b.totalPrice} ${context.tr('ر.س')}',
      ),
      _row(
        _b.paidFullAmount ? Icons.check_circle_outline : Icons.schedule,
        context.tr('حالة الدفع'),
        _b.paidFullAmount
            ? context.tr('مدفوع بالكامل')
            : context.tr('دفع جزئي'),
      ),
      _row(
        Icons.info_outline,
        context.tr('حالة الحجز'),
        _statusLabel(_b.status),
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: AppSizes.xl),
            rows[i],
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${AppDates.weekday(d)} ${d.day} ${AppDates.monthName(d.month)} ${d.year}';

  String _time(DateTime d) {
    final period = AppDates.periodShort(d);
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$h12:${d.minute.toString().padLeft(2, '0')} $period';
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: AppSizes.iconSm, color: AppColors.mutedForeground),
        const SizedBox(width: AppSizes.md),
        Text(label, style: AppTextStyles.caption),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
