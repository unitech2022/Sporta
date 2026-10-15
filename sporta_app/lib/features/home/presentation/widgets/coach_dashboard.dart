import 'package:sporta_app/core/state/app_scope.dart';
import 'package:sporta_app/features/reviews/presentation/widgets/review_prompt_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/utils/server_time.dart';
import '../../../coaches/domain/entities/coach_dashboard.dart' as entity;
import '../../../coaches/domain/entities/coach_rating_entity.dart';
import '../../../coaches/domain/entities/coach_session_entity.dart';
import '../../../coaches/presentation/cubit/coach_dashboard_cubit.dart';
import '../../../coaches/presentation/pages/coach_booking_detail_page.dart';
import '../../../coaches/presentation/pages/coach_revenue_page.dart';
import '../../../coaches/presentation/pages/coach_students_page.dart';
import '../../../coaches/presentation/widgets/coach_bookings_section.dart';
import 'dashboard_blocks.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/utils/money.dart';

const _greenDark = Color(0xFF16A34A);
const _blueDark = Color(0xFF2563EB);

/// Coach home dashboard — real stats from the API.
class CoachDashboard extends StatelessWidget {
  const CoachDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CoachDashboardCubit>(
      create: (_) => getIt<CoachDashboardCubit>()..load(),
      child: const _CoachDashboardView(),
    );
  }
}

class _CoachDashboardView extends StatelessWidget {
  const _CoachDashboardView();

  static List<String> get _weekdaysAr => [
    trg('الاثنين'),
    trg('الثلاثاء'),
    trg('الأربعاء'),
    trg('الخميس'),
    trg('الجمعة'),
    trg('السبت'),
    trg('الأحد'),
  ];

  String _when(DateTime d) {
    final period = AppDates.period(d);
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '${_weekdaysAr[d.weekday - 1]} $h12 $period';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoachDashboardCubit, CoachDashboardState>(
      builder: (context, state) {
        final d = state.dashboard;
        return _shell(context, state, d);
      },
    );
  }

  Widget _shell(
    BuildContext context,
    CoachDashboardState state,
    entity.CoachDashboard? d,
  ) {
    if (state.status == CoachDashboardStatus.loading ||
        state.status == CoachDashboardStatus.initial) {
      return _dashboardSkeleton();
    }
    if (state.status == CoachDashboardStatus.failure) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.xxxl),
        child: Center(
          child: Text(
            state.error ?? context.tr('تعذّر تحميل اللوحة'),
            style: AppTextStyles.body.copyWith(color: AppColors.secondary),
          ),
        ),
      );
    }

    final dash = d!;
    final hasHeaderStats =
        dash.activeStudents > 0 || dash.totalSessions > 0 || dash.rating > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasHeaderStats) _statsHeader(context, dash),
        Padding(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: _body(context, dash),
        ),
      ],
    );
  }

  /// لا تُعرض الأقسام الفارغة إطلاقاً — كل قسم يحمل مسافته السفلية حين يظهر
  /// فقط، فلا تبقى فجوات مكان المخفي. «إجراءات سريعة» يبقى دائماً (أزرار).
  Widget _body(BuildContext context, entity.CoachDashboard dash) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // تقييم اللاعبين والملاعب بعد الجلسات — يخفي نفسه إن لم يوجد شيء.
        const PendingReviewsCard(
          padding: EdgeInsets.only(bottom: AppSizes.xxl),
        ),
        if (dash.monthRevenue > 0 || dash.weekSessions > 0) ...[
          Text(
            context.tr('نظرة عامة'),
            style: AppTextStyles.heading2.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.lg),
          Row(
            children: [
              Expanded(
                child: OverviewStatCard(
                  icon: Icons.attach_money,
                  color: _greenDark,
                  backgroundColor: Colors.white,
                  valueColor: AppColors.foreground,
                  value: context.trArgs('{p0} ر.س', {
                    'p0': money(dash.monthRevenue),
                  }),
                  label: context.tr('إيرادات هذا الشهر'),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: OverviewStatCard(
                  icon: Icons.menu_book_outlined,
                  color: _blueDark,
                  backgroundColor: Colors.white,
                  valueColor: AppColors.foreground,
                  value: '${dash.weekSessions}',
                  label: context.tr('حصص هذا الأسبوع'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xxl),
        ],
        CoachBookingsSection(
          title: context.tr('طلبات جديدة'),
          status: 'pending',
          hideWhenEmpty: true,
          trailingGap: AppSizes.xxl,
        ),
        if (dash.upcomingSessions.isNotEmpty) ...[
          Text(
            context.tr('الحصص القادمة'),
            style: AppTextStyles.heading2.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.lg),
          for (final s in dash.upcomingSessions) ...[
            _sessionTile(context, s),
            const SizedBox(height: AppSizes.md),
          ],
          const SizedBox(height: AppSizes.xxl),
        ],
        if (dash.recentRatings.isNotEmpty) ...[
          Text(
            context.tr('آخر التقييمات'),
            style: AppTextStyles.heading2.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.lg),
          for (final r in dash.recentRatings) ...[
            _ratingTile(context, r),
            const SizedBox(height: AppSizes.md),
          ],
          const SizedBox(height: AppSizes.xxl),
        ],
        Text(
          context.tr('إجراءات سريعة'),
          style: AppTextStyles.heading2.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSizes.lg),
        Row(
          children: [
            Expanded(
              child: _quickAction(
                context,
                icon: Icons.groups_outlined,
                gradient: AppColors.primaryGradient,
                label: context.tr('إدارة الطلاب'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CoachStudentsPage()),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: _quickAction(
                context,
                icon: Icons.bar_chart_rounded,
                color: AppColors.primary,
                label: context.tr('التقارير'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CoachRevenuePage(
                      onBack: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Quick stat chips (active students, rating, completed sessions). No
  /// logo/name/bell here — those already live in the page's own app bar.
  Widget _statsHeader(BuildContext context, entity.CoachDashboard dash) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pagePadding,
        AppSizes.lg,
        AppSizes.pagePadding,
        AppSizes.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: _statChip(
              '${dash.activeStudents}',
              context.tr('طلاب نشطين'),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: _statChip(
              dash.rating.toStringAsFixed(1),
              context.tr('التقييم'),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: _statChip('${dash.totalSessions}', context.tr('حصة مكتملة')),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.heading1.copyWith(color: Colors.white),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingTile(BuildContext context, CoachRatingEntity r) {
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
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Text(
                  r.playerName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    Icon(
                      Icons.star,
                      size: 14,
                      color: i <= r.rating ? Colors.amber : AppColors.border,
                    ),
                ],
              ),
            ],
          ),
          if (r.review != null && r.review!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSizes.sm),
            Text(
              '"${r.review}"',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ],
          const SizedBox(height: AppSizes.xs),
          Text(_ago(r.scheduledAt), style: AppTextStyles.caption),
        ],
      ),
    );
  }

  /// [d] is a session's scheduledAt — naive KSA time, so compare with KSA now.
  String _ago(DateTime d) {
    final diff = ksaNow().difference(d);
    if (diff.inMinutes < 1) return trg('الآن');
    if (diff.inMinutes < 60)
      return trgArgs('منذ {p0} دقيقة', {'p0': diff.inMinutes});
    if (diff.inHours < 24)
      return trgArgs('منذ {p0} ساعة', {'p0': diff.inHours});
    return trgArgs('منذ {p0} يوم', {'p0': diff.inDays});
  }

  Widget _quickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Gradient? gradient,
    Color? color,
  }) {
    final isFilled = gradient != null;
    return Material(
      color: isFilled ? null : Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.xl),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            border: isFilled
                ? null
                : Border.all(color: AppColors.border, width: 2),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: isFilled ? Colors.white : color),
              const SizedBox(height: AppSizes.sm),
              Text(
                context.tr(label),
                style: AppTextStyles.bodySmall.copyWith(
                  color: isFilled ? Colors.white : AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sessionTile(BuildContext context, CoachSessionEntity s) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      onTap: () async {
        final changed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => CoachBookingDetailPage(session: s)),
        );
        if (changed == true && context.mounted) {
          context.read<CoachDashboardCubit>().load();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_note_outlined, color: _greenDark),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.title,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(_when(s.scheduledAt), style: AppTextStyles.caption),
                ],
              ),
            ),
            Text(
              context.trArgs('{p0} ر.س', {'p0': money(s.price)}),
              style: AppTextStyles.body.copyWith(
                color: _greenDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// هيكل اللوحة أثناء التحميل: «نظرة عامة» (بطاقتا إحصاء) ثم قائمة بطاقات.
Widget _dashboardSkeleton() {
  return Padding(
    padding: const EdgeInsets.all(AppSizes.pagePadding),
    child: Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 120, height: 20),
          const SizedBox(height: AppSizes.lg),
          const Row(
            children: [
              Expanded(
                child: SkeletonBox(height: 116, radius: AppSizes.radiusXl),
              ),
              SizedBox(width: AppSizes.md),
              Expanded(
                child: SkeletonBox(height: 116, radius: AppSizes.radiusXl),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xxl),
          const SkeletonBox(width: 150, height: 20),
          const SizedBox(height: AppSizes.lg),
          for (var i = 0; i < 3; i++) ...[
            const SkeletonBox(height: 88, radius: AppSizes.radiusXl),
            if (i != 2) const SizedBox(height: AppSizes.md),
          ],
        ],
      ),
    ),
  );
}
