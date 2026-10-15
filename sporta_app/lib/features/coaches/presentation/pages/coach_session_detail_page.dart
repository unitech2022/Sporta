import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../domain/entities/coach_session_entity.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/utils/money.dart';

/// Full details of a booked coach (assessment/training) session. Shows the
/// coach's rating of the player once the paid session has ended and been rated.
class CoachSessionDetailPage extends StatefulWidget {
  const CoachSessionDetailPage({super.key, required this.session});

  final CoachSessionEntity session;

  @override
  State<CoachSessionDetailPage> createState() => _CoachSessionDetailPageState();
}

class _CoachSessionDetailPageState extends State<CoachSessionDetailPage> {
  late final CoachSessionEntity _s = widget.session;
  final bool _changed = false;

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
                    _statsRow(),
                    const SizedBox(height: AppSizes.xl),
                    _infoCard(),
                    // تقييم المدرب — يظهر فقط بعد الدفع وانتهاء الجلسة.
                    if (_s.isPaid && _s.isCompleted && _s.isRated) ...[
                      const SizedBox(height: AppSizes.xl),
                      _ratingDisplay(),
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
    final color = const Color(0xFF7C3AED);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.85)],
        ),
      ),
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
                    context.tr('تفاصيل الجلسة'),
                    style: AppTextStyles.heading2.copyWith(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                _s.title,
                style: AppTextStyles.heading3.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: AppSizes.iconSm,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    '${context.tr('المدرب')}: ${_s.coachName}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white70,
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
            '${money(_s.price)} ${context.tr('ر.س')}',
            context.tr('السعر'),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: _stat(
            Icons.timelapse,
            const Color(0xFF2563EB),
            '${_s.durationMinutes} ${context.tr('دقيقة')}',
            context.tr('المدة'),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: _stat(
            _s.isCompleted ? Icons.check_circle_outline : Icons.schedule,
            _s.isCompleted ? AppColors.success : AppColors.warning,
            _s.isCompleted ? context.tr('منتهية') : context.tr('قادمة'),
            context.tr('الحالة'),
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
    final end = _s.scheduledAt.add(Duration(minutes: _s.durationMinutes));
    final rows = <Widget>[
      _row(
        Icons.confirmation_number_outlined,
        context.tr('رقم الحجز'),
        '#${_s.id}',
      ),
      _row(Icons.sports_tennis, context.tr('الجلسة'), _s.title),
      _row(Icons.person_outline, context.tr('المدرب'), _s.coachName),
      _row(
        Icons.event_outlined,
        context.tr('التاريخ'),
        _formatDate(_s.scheduledAt),
      ),
      _row(
        Icons.access_time,
        context.tr('الوقت'),
        '${_time(_s.scheduledAt)} — ${_time(end)}',
      ),
      _row(
        Icons.timelapse_outlined,
        context.tr('المدة'),
        '${_s.durationMinutes} ${context.tr('دقيقة')}',
      ),
      _row(
        Icons.payments_outlined,
        context.tr('السعر'),
        '${money(_s.price)} ${context.tr('ر.س')}',
      ),
      _row(
        _s.isPaid ? Icons.check_circle_outline : Icons.schedule,
        context.tr('حالة الدفع'),
        _s.isPaid ? context.tr('مدفوع') : context.tr('غير مدفوع'),
      ),
      _row(Icons.info_outline, context.tr('الحالة'), _statusLabel(_s.status)),
      if (_s.description != null && _s.description!.isNotEmpty)
        _row(Icons.notes, context.tr('الوصف'), _s.description!),
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

  String _statusLabel(String s) => switch (s) {
    'pending' => context.tr('قيد الانتظار'),
    'confirmed' || 'Confirmed' => context.tr('مؤكدة'),
    'rejected' => context.tr('مرفوضة'),
    'Completed' || 'completed' => context.tr('منتهية'),
    'Cancelled' || 'cancelled' => context.tr('ملغاة'),
    _ => s,
  };

  Widget _ratingDisplay() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${context.tr('تقييم المدرب')}: ',
                style: AppTextStyles.bodySmall,
              ),
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= (_s.coachRating ?? 0) ? Icons.star : Icons.star_border,
                  color: const Color(0xFFFACC15),
                  size: 20,
                ),
            ],
          ),
          if (_s.coachReview != null && _s.coachReview!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.sm),
            Text(_s.coachReview!, style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
      ),
    );
  }
}
