import 'package:sporta_app/core/state/app_scope.dart';
import 'package:sporta_app/features/reviews/presentation/widgets/review_prompt_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/state/data_signals.dart';
import '../../../venue/domain/entities/venue_dashboard.dart' as entity;
import '../../../venue/presentation/cubit/venue_dashboard_cubit.dart';
import '../../../americano/presentation/pages/americano_create_page.dart';
import '../../../cup/presentation/pages/cup_create_page.dart';
import '../../../matches/presentation/pages/create_match_page.dart';
import '../../../venue/presentation/pages/manage_bookings_page.dart';
import '../../../venue/presentation/pages/venue_revenue_page.dart';
import 'dashboard_blocks.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/utils/money.dart';

const _greenDark = Color(0xFF16A34A);
const _blueDark = Color(0xFF2563EB);
const _orangeDark = Color(0xFFEA580C);

/// Venue-owner home dashboard — real stats from the API.
///
/// تعيد التحميل كلما تغيّرت ملاعب المالك من تبويب «ملاعبي»: التبويبان حيّان معاً
/// في `IndexedStack`، فبلا هذا الاستماع تبقى اللوحة على أرقامها حتى إعادة تشغيل
/// التطبيق.
class VenueDashboard extends StatefulWidget {
  const VenueDashboard({super.key});

  @override
  State<VenueDashboard> createState() => _VenueDashboardState();
}

class _VenueDashboardState extends State<VenueDashboard> {
  late final VenueDashboardCubit _cubit = getIt<VenueDashboardCubit>()..load();

  @override
  void initState() {
    super.initState();
    DataSignals.venues.addListener(_reload);
  }

  @override
  void dispose() {
    DataSignals.venues.removeListener(_reload);
    // BlocProvider.value لا يُغلق الكيوبت، فإغلاقه علينا.
    _cubit.close();
    super.dispose();
  }

  void _reload() {
    if (mounted) _cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VenueDashboardCubit>.value(
      value: _cubit,
      child: const _VenueDashboardView(),
    );
  }
}

class _VenueDashboardView extends StatelessWidget {
  const _VenueDashboardView();

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
    return BlocBuilder<VenueDashboardCubit, VenueDashboardState>(
      builder: (context, state) {
        final d = state.dashboard;
        return _body(context, state, d);
      },
    );
  }

  Widget _body(
    BuildContext context,
    VenueDashboardState state,
    entity.VenueDashboard? d,
  ) {
    if (state.status == VenueDashboardStatus.loading ||
        state.status == VenueDashboardStatus.initial) {
      return _dashboardSkeleton();
    }
    if (state.status == VenueDashboardStatus.failure) {
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

    // لا نعرض أي قسم فارغ — كل قسم يظهر فقط حين يملك بيانات فعلية، ويبقى قسم
    // «إجراءات سريعة» دائماً لأنه أزرار لا بيانات.
    final sections = <Widget>[
      if (dash.weekRevenue > 0 || dash.todayBookings > 0)
        _overviewSection(context, dash),
      if (dash.liveCourtStatuses.isNotEmpty) _liveCourtsSection(context, dash),
      if (dash.upcomingBookings.isNotEmpty)
        _upcomingBookingsSection(context, dash),
      if (dash.weekBookingsCount > 0 ||
          dash.weekPlayHours > 0 ||
          dash.weekRevenue > 0)
        _weekStatsSection(context, dash),
      _quickActionsSection(context),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dash.courtsCount > 0) _statsHeader(context, dash),
        Padding(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // تقييم اللاعبين والمدربين بعد تجاربهم على ملاعبك — يخفي نفسه
              // إن لم يوجد شيء.
              const PendingReviewsCard(
                padding: EdgeInsets.only(bottom: AppSizes.xxl),
              ),
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSizes.xxl),
                sections[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _overviewSection(BuildContext context, entity.VenueDashboard dash) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                value: context.trArgs('{p0} ر.س', {
                  'p0': money(dash.weekRevenue),
                }),
                label: context.tr('إيرادات هذا الأسبوع'),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: OverviewStatCard(
                icon: Icons.event_available_outlined,
                color: _blueDark,
                value: '${dash.todayBookings}',
                label: context.tr('حجوزات اليوم'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('إجراءات سريعة'),
          style: AppTextStyles.heading2.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSizes.lg),
        // استضافة حدث على ملاعبه: مباراة أو أمريكانو أو بطولة يسجّل فيها
        // اللاعبون، وصاحب الملعب منظّم لا لاعب.
        SizedBox(
          width: double.infinity,
          child: _quickAction(
            context,
            icon: Icons.add_circle_outline,
            gradient: AppColors.primaryGradient,
            label: context.tr('استضافة على ملعبك'),
            onTap: () => _showHostSheet(context),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          children: [
            Expanded(
              child: _quickAction(
                context,
                icon: Icons.event_available_outlined,
                gradient: AppColors.primaryGradient,
                label: context.tr('إدارة الحجوزات'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ManageBookingsPage(
                      onBack: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: _quickAction(
                context,
                icon: Icons.bar_chart_rounded,
                color: AppColors.primary,
                label: context.tr('التقارير المالية'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => VenueRevenuePage(
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

  /// ماذا يستضيف المالك؟ نفس أنواع اللاعب الثلاثة، لكن بلا أن يكون لاعباً.
  Future<void> _showHostSheet(BuildContext context) async {
    final navigator = Navigator.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
        ),
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sheetContext.tr('استضافة على ملعبك'),
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              sheetContext.tr(
                'أنشئ مباراة أو أمريكانو أو بطولة على ملاعبك، ويسجّل فيها اللاعبون',
              ),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            _hostOption(
              sheetContext,
              icon: Icons.groups_outlined,
              title: sheetContext.tr('إنشاء مباراة'),
              subtitle: sheetContext.tr('مباراة مفتوحة ينضم إليها اللاعبون'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                navigator.push(
                  MaterialPageRoute<void>(
                    builder: (_) => CreateMatchPage(
                      hostedByVenue: true,
                      onBack: () => navigator.pop(),
                      onComplete: () => navigator.pop(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSizes.sm),
            _hostOption(
              sheetContext,
              icon: Icons.sync_alt,
              title: sheetContext.tr('إنشاء أمريكانو'),
              subtitle: sheetContext.tr('فردي بتبديل الشركاء أو فرق ثابتة'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                navigator.push(
                  MaterialPageRoute<void>(
                    builder: (_) => AmericanoCreatePage(
                      hostedByVenue: true,
                      onBack: () => navigator.pop(),
                      onCreated: (_) => navigator.pop(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSizes.sm),
            _hostOption(
              sheetContext,
              icon: Icons.emoji_events_outlined,
              title: sheetContext.tr('إنشاء بطولة'),
              subtitle: sheetContext.tr(
                'نظام كأس العالم — مجموعات وإقصائيات على ملاعبك',
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                navigator.push(
                  MaterialPageRoute<void>(
                    builder: (_) => CupCreatePage(
                      hostedByVenue: true,
                      onBack: () => navigator.pop(),
                      // تُغلق صفحة الإضافة؛ حوار النجاح يعرض «متابعة» إلى البطولة.
                      onCreated: (_) => navigator.pop(),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: MediaQuery.of(sheetContext).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _hostOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: AppSizes.iconMd,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: AppSizes.iconMd,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Quick stat chips (courts count, booking rate). No logo/owner name/bell
  /// here — those already live in the page's own app bar.
  Widget _statsHeader(BuildContext context, entity.VenueDashboard dash) {
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
            child: _statChip('${dash.courtsCount}', context.tr('ملاعب')),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: _statChip(
              '${dash.bookingRatePercent.toStringAsFixed(0)}%',
              context.tr('نسبة الحجز'),
            ),
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

  Widget _liveCourtsSection(BuildContext context, entity.VenueDashboard dash) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('حالة الملاعب الآن'),
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.secondary,
              ),
            ),
            Text(context.tr('تحديث مباشر'), style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSizes.md,
          mainAxisSpacing: AppSizes.md,
          childAspectRatio: 1.7,
          children: [
            for (final c in dash.liveCourtStatuses)
              _courtStatusCard(context, c),
          ],
        ),
      ],
    );
  }

  Widget _courtStatusCard(BuildContext context, entity.CourtLiveStatus c) {
    final (
      bg,
      border,
      badgeBg,
      badgeFg,
      badgeLabel,
      icon,
      subtitle,
    ) = switch (c.status) {
      'booked' => (
        const Color(0xFFF0FDF4),
        _greenDark.withValues(alpha: 0.4),
        _greenDark,
        Colors.white,
        trg('محجوز'),
        Icons.access_time,
        c.timeRangeLabel ?? '',
      ),
      'maintenance' => (
        const Color(0xFFFFF7ED),
        _orangeDark.withValues(alpha: 0.4),
        _orangeDark,
        Colors.white,
        trg('صيانة'),
        Icons.build_outlined,
        context.tr('قيد الصيانة'),
      ),
      _ => (
        Colors.white,
        AppColors.border,
        const Color(0xFFE5E7EB),
        const Color(0xFF6B7280),
        trg('متاح'),
        Icons.access_time,
        context.tr('متاح للحجز'),
      ),
    };
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  c.name,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  context.tr(badgeLabel),
                  style: AppTextStyles.caption.copyWith(color: badgeFg),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Icon(
                icon,
                size: AppSizes.iconSm,
                color: AppColors.mutedForeground,
              ),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _upcomingBookingsSection(
    BuildContext context,
    entity.VenueDashboard dash,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('الحجوزات القادمة'),
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.secondary,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ManageBookingsPage(
                    onBack: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              child: Text(
                context.tr('عرض الكل'),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        for (var i = 0; i < dash.upcomingBookings.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSizes.md),
          _upcomingBookingTile(context, dash.upcomingBookings[i]),
        ],
      ],
    );
  }

  Widget _upcomingBookingTile(BuildContext context, entity.VenueBooking b) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            b.courtName,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          ' • ${b.playerName}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 12,
                          color: AppColors.mutedForeground,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${context.tr('ملعب')} ${b.courtTypeLabel}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  context.tr('مؤكدة'),
                  style: AppTextStyles.caption.copyWith(color: _blueDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          const Divider(height: 1),
          const SizedBox(height: AppSizes.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: AppSizes.iconSm,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Text(_when(b.startTime), style: AppTextStyles.bodySmall),
                ],
              ),
              Text(
                context.trArgs('{p0} ر.س', {'p0': money(b.totalPrice)}),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weekStatsSection(BuildContext context, entity.VenueDashboard dash) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('إحصائيات هذا الأسبوع'),
          style: AppTextStyles.heading2.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSizes.lg),
        Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Column(
            children: [
              _weekStatRow(
                context,
                context.tr('إجمالي الحجوزات'),
                '${dash.weekBookingsCount} ${context.tr('حجز')}',
              ),
              const SizedBox(height: AppSizes.sm),
              _weekStatRow(
                context,
                context.tr('ساعات اللعب'),
                '${dash.weekPlayHours.toStringAsFixed(0)} ${context.tr('ساعة')}',
              ),
              const SizedBox(height: AppSizes.sm),
              _weekStatRow(
                context,
                context.tr('متوسط سعر الساعة'),
                trgArgs('{p0} ر.س', {'p0': money(dash.weekAvgHourlyPrice)}),
              ),
              const SizedBox(height: AppSizes.md),
              const Divider(height: 1),
              const SizedBox(height: AppSizes.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('الإيرادات الإجمالية'),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    context.trArgs('{p0} ر.س', {'p0': money(dash.weekRevenue)}),
                    style: AppTextStyles.heading3.copyWith(
                      color: _greenDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _weekStatRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.mutedForeground,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
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
