import '../../../../core/widgets/add_to_calendar_button.dart';
import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/load_more_listener.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../domain/entities/coach_session_entity.dart';
import '../cubit/my_sessions_cubit.dart';
import '../../../reviews/domain/review_models.dart';
import '../../../reviews/presentation/widgets/rate_experience_sheet.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/skeleton.dart';

/// Lists the player's booked coach sessions (`coaches/sessions/me`).
class MyCoachSessionsPage extends StatelessWidget {
  const MyCoachSessionsPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MySessionsCubit>(
      create: (_) => getIt<MySessionsCubit>()..load(),
      child: _MySessionsView(onBack: onBack),
    );
  }
}

class _MySessionsView extends StatelessWidget {
  const _MySessionsView({required this.onBack});

  final VoidCallback onBack;

  /// نافذة التقييم الموحّدة: المدرب والملعب (إن وُجد) دفعة واحدة.
  Future<void> _rateCoach(
    BuildContext context,
    CoachSessionEntity session,
  ) async {
    final cubit = context.read<MySessionsCubit>();
    final updated = await openReviewSheet(
      context,
      ReviewContext.session,
      session.id,
    );
    if (updated != null) cubit.load();
  }

  String _formatWhen(DateTime d) {
    final weekday = AppDates.weekday(d);
    final month = AppDates.monthName(d.month);
    final hour = d.hour;
    final period = hour < 12 ? trg('صباحاً') : trg('مساءً');
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    return '$weekday ${d.day} $month · $h12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: BlocBuilder<MySessionsCubit, MySessionsState>(
                builder: (context, state) => _buildBody(context, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.xxxl,
            AppSizes.pagePadding,
            AppSizes.xxl,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const DirectionalIcon(
                  rtl: Icons.arrow_forward,
                  ltr: Icons.arrow_back,
                  color: Colors.white,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: AppSizes.md),
              Text(
                context.tr('حجوزاتي'),
                style: AppTextStyles.heading2.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MySessionsState state) {
    switch (state.status) {
      case MySessionsStatus.initial:
      case MySessionsStatus.loading:
        return const SkeletonList();
      case MySessionsStatus.failure:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.destructive,
                  size: 48,
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  state.error ?? context.tr('تعذّر تحميل الحجوزات'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                ElevatedButton(
                  onPressed: () => context.read<MySessionsCubit>().load(),
                  child: Text(context.tr('إعادة المحاولة')),
                ),
              ],
            ),
          ),
        );
      case MySessionsStatus.success:
        if (state.sessions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.event_busy_outlined,
                    color: AppColors.mutedForeground,
                    size: 56,
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    context.tr('لا توجد حجوزات بعد'),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return LoadMoreListener(
          // يحمّل التالي قرب النهاية، أو فوراً إن لم تملأ القائمة الشاشة.
          onLoadMore: () {
            context.read<MySessionsCubit>().loadMore();
          },
          child: ListView.separated(
            padding: context.safeBottom(
              const EdgeInsets.all(AppSizes.pagePadding),
            ),
            itemCount: state.sessions.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: AppSizes.md),
            itemBuilder: (_, i) {
              if (i >= state.sessions.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSizes.md),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _SessionCard(
                session: state.sessions[i],
                whenLabel: _formatWhen(state.sessions[i].scheduledAt),
                onRateCoach: () => _rateCoach(context, state.sessions[i]),
              );
            },
          ),
        );
    }
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.whenLabel,
    required this.onRateCoach,
  });

  final CoachSessionEntity session;
  final String whenLabel;
  final VoidCallback onRateCoach;

  @override
  Widget build(BuildContext context) {
    final completed = session.isCompleted;
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
                Icons.sports_tennis,
                color: AppColors.primary,
                size: AppSizes.iconMd,
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  session.coachName,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StatusChip(completed: completed),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          _row(Icons.schedule, whenLabel),
          const SizedBox(height: AppSizes.xs),
          _row(
            Icons.timelapse,
            trgArgs('{p0} دقيقة', {'p0': session.durationMinutes}),
          ),
          if (session.description != null &&
              session.description!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.xs),
            _row(Icons.fitness_center, session.description!),
          ],
          const Divider(height: AppSizes.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(context.tr('الإجمالي'), style: AppTextStyles.caption),
                  const SizedBox(width: AppSizes.sm),
                  _PaidChip(paid: session.isPaid),
                ],
              ),
              Text(
                context.trArgs('{p0} ر.س', {'p0': money(session.price)}),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (session.canAddToCalendar) ...[
            const SizedBox(height: AppSizes.xs),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AddToCalendarButton(
                compact: true,
                calendarKey: 'session-${session.id}',
                title: context.trArgs('تدريب مع {p0}', {
                  'p0': session.coachName,
                }),
                startKsa: session.scheduledAt,
                durationMinutes: session.durationMinutes,
                description: session.title,
              ),
            ),
          ],
          // تقييم المدرب للاعب — لا يظهر إلا بعد الدفع وانتهاء الجلسة.
          if (session.isPaid && session.isCompleted && session.isRated) ...[
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Text(
                  context.tr('تقييم المدرب: '),
                  style: AppTextStyles.caption,
                ),
                for (var i = 1; i <= 5; i++)
                  Icon(
                    i <= session.coachRating! ? Icons.star : Icons.star_border,
                    size: 16,
                    color: AppColors.brandGold,
                  ),
              ],
            ),
            if (session.coachReview != null &&
                session.coachReview!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.xs),
              Text(session.coachReview!, style: AppTextStyles.caption),
            ],
          ],
          // تقييم اللاعب للمدرب — يغذّي تقييم المدرب وشارة "معتمد".
          if (session.playerRating != null) ...[
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Text(
                  context.tr('تقييمك للمدرب: '),
                  style: AppTextStyles.caption,
                ),
                for (var i = 1; i <= 5; i++)
                  Icon(
                    i <= session.playerRating! ? Icons.star : Icons.star_border,
                    size: 16,
                    color: AppColors.brandGold,
                  ),
              ],
            ),
          ] else if (session.canPlayerRate) ...[
            const SizedBox(height: AppSizes.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRateCoach,
                icon: const Icon(Icons.star_border, size: 18),
                label: Text(context.tr('قيّم المدرب')),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.mutedForeground),
        const SizedBox(width: AppSizes.sm),
        Expanded(child: Text(text, style: AppTextStyles.caption)),
      ],
    );
  }
}

class _PaidChip extends StatelessWidget {
  const _PaidChip({required this.paid});

  final bool paid;

  @override
  Widget build(BuildContext context) {
    final color = paid ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        paid ? context.tr('مدفوعة') : context.tr('غير مدفوعة'),
        style: AppTextStyles.caption.copyWith(color: color),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final color = completed ? AppColors.success : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        completed ? context.tr('مكتملة') : context.tr('قادمة'),
        style: AppTextStyles.caption.copyWith(color: color),
      ),
    );
  }
}
