import '../../../../core/widgets/add_to_calendar_button.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../data/coach_repository.dart';
import '../../domain/entities/coach_session_entity.dart';
import '../../../reviews/domain/review_models.dart';
import '../../../reviews/presentation/widgets/rate_experience_sheet.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/utils/money.dart';

/// Coach-facing detail of a session booking, with accept / reject actions when
/// the booking is still pending and a rate-the-player action once the paid
/// session has ended. Pops `true` when the booking changed.
class CoachBookingDetailPage extends StatefulWidget {
  const CoachBookingDetailPage({super.key, required this.session});

  final CoachSessionEntity session;

  @override
  State<CoachBookingDetailPage> createState() => _CoachBookingDetailPageState();
}

class _CoachBookingDetailPageState extends State<CoachBookingDetailPage> {
  late CoachSessionEntity _s = widget.session;
  bool _changed = false;
  bool _busy = false;

  bool get _isPending => _s.status == 'pending';

  String _formatWhen(DateTime d) {
    final weekday = AppDates.weekday(d);
    final month = AppDates.monthName(d.month);
    final period = AppDates.period(d);
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    return '$weekday ${d.day} $month · $h12:$minute $period';
  }

  (Color, String) _statusChip() => switch (_s.status) {
    'pending' => (AppColors.warning, context.tr('قيد الانتظار')),
    'rejected' => (AppColors.destructive, context.tr('مرفوضة')),
    'Completed' => (AppColors.success, context.tr('منتهية')),
    _ => (AppColors.primary, context.tr('مؤكدة')),
  };

  /// نافذة التقييم الموحّدة: اللاعب والملعب (إن وُجد) دفعة واحدة.
  Future<void> _ratePlayer() async {
    final updated = await openReviewSheet(
      context,
      ReviewContext.session,
      _s.id,
    );
    if (updated == null || !mounted) return;
    final mine = updated.targets
        .where((t) => t.type == ReviewTargetType.player)
        .map((t) => t.myReview)
        .whereType<ReviewItem>()
        .firstOrNull;
    setState(() {
      _changed = true;
      if (mine != null) _s = _s.copyWithRating(mine.score, mine.comment);
    });
  }

  Future<void> _respond(bool approve) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await getIt<CoachRepository>().respondToSessionRequest(_s.id, approve);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _changed = true;
        _s = _s.copyWithStatus(approve ? 'Upcoming' : 'rejected');
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            approve ? context.tr('تم قبول الطلب') : context.tr('تم رفض الطلب'),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = _statusChip();
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
              _header(statusColor, statusLabel),
              Expanded(
                child: ListView(
                  padding: context.safeBottom(
                    const EdgeInsets.all(AppSizes.pagePadding),
                  ),
                  children: [
                    _statsRow(),
                    const SizedBox(height: AppSizes.xl),
                    _infoCard(),
                    if (_s.canAddToCalendar) ...[
                      const SizedBox(height: AppSizes.xl),
                      AddToCalendarButton(
                        calendarKey: 'session-${_s.id}',
                        title: context.trArgs('تدريب · {p0}', {
                          'p0': _s.playerName ?? _s.title,
                        }),
                        startKsa: _s.scheduledAt,
                        durationMinutes: _s.durationMinutes,
                        description: _s.title,
                      ),
                    ],
                    if (_s.isRated) ...[
                      const SizedBox(height: AppSizes.xl),
                      _ratingCard(),
                    ] else if (_s.canCoachRate) ...[
                      const SizedBox(height: AppSizes.xl),
                      if (_busy)
                        const Center(child: CircularProgressIndicator())
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _ratePlayer,
                            icon: const Icon(Icons.star_outline),
                            label: Text(context.tr('قيّم اللاعب')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusLg,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                    if (_isPending) ...[
                      const SizedBox(height: AppSizes.xl),
                      if (_busy)
                        const Center(child: CircularProgressIndicator())
                      else
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _respond(true),
                                icon: const Icon(Icons.check),
                                label: Text(context.tr('قبول')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSizes.md,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _respond(false),
                                icon: const Icon(Icons.close),
                                label: Text(context.tr('رفض')),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.destructive,
                                  side: const BorderSide(
                                    color: AppColors.destructive,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSizes.md,
                                  ),
                                ),
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

  Widget _header(Color statusColor, String statusLabel) {
    const color = Color(0xFF16A34A);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF22C55E), color],
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      statusLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
                    '${context.tr('اللاعب')}: ${_s.playerName ?? context.tr('لاعب')}',
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
            _s.isPaid ? Icons.check_circle_outline : Icons.schedule,
            _s.isPaid ? AppColors.success : AppColors.warning,
            _s.isPaid ? context.tr('مدفوع') : context.tr('غير مدفوع'),
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

  Widget _ratingCard() {
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
                '${context.tr('تقييمك للاعب')}: ',
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

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _row(
            Icons.person_outline,
            context.tr('اللاعب'),
            _s.playerName ?? context.tr('لاعب'),
          ),
          _row(
            Icons.access_time,
            context.tr('الوقت'),
            _formatWhen(_s.scheduledAt),
          ),
          if (_s.description != null && _s.description!.isNotEmpty)
            _row(Icons.notes, context.tr('الوصف'), _s.description!),
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
