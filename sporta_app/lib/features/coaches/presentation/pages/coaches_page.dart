import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/load_more_listener.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../../core/widgets/filter_chip_group.dart';
import '../../../../core/widgets/filter_header_button.dart';
import '../../../../core/widgets/filter_sheet.dart';
import '../../../../core/widgets/step_progress_bar.dart';
import '../../../ads/presentation/widgets/ad_slider.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../../courts/data/court_repository.dart';
import '../../../courts/domain/entities/court_entity.dart';
import '../../data/coach_repository.dart';
import '../../../payment/presentation/widgets/payment_confirm_dialog.dart';
import '../../domain/entities/coach_entity.dart';
import '../../domain/entities/coach_offer_entity.dart';
import '../cubit/coaches_cubit.dart';
import 'coach_detail_page.dart';
import '../../../level/presentation/pages/advanced_assessment_page.dart';
import '../../../profile/presentation/pages/my_bookings_page.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../auth/presentation/widgets/login_required_sheet.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/skeleton.dart';
import 'package:sporta_app/core/utils/server_time.dart';
import '../../../../core/widgets/network_circle_avatar.dart';

/// Coaches listing screen. Provides a [CoachesCubit] and renders its state;
/// all data/filtering lives in the cubit and repository.
class CoachesPage extends StatelessWidget {
  const CoachesPage({super.key, this.onBack, this.onNavigate});

  final VoidCallback? onBack;
  final void Function(String page, [String? coachId])? onNavigate;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CoachesCubit>(
      create: (_) => getIt<CoachesCubit>()..loadCoaches(),
      child: _CoachesView(onBack: onBack, onNavigate: onNavigate),
    );
  }
}

class _CoachesView extends StatefulWidget {
  const _CoachesView({this.onBack, this.onNavigate});

  final VoidCallback? onBack;
  final void Function(String page, [String? coachId])? onNavigate;

  @override
  State<_CoachesView> createState() => _CoachesViewState();
}

class _CoachesViewState extends State<_CoachesView> {
  static const List<String> _levelFilters = ['الكل', 'مبتدئ', 'متوسط', 'متقدم'];
  static const List<String> _genderFilters = ['الكل', 'رجال', 'نساء'];

  /// Opens the shared filter sheet with the level/gender sections. The cubit
  /// only hears about the choice once "تطبيق" is pressed.
  Future<void> _openFilterSheet(CoachesCubit cubit) async {
    final applied = await showFilterSheet<({String level, String gender})>(
      context: context,
      initialValue: (
        level: cubit.state.levelFilter,
        gender: cubit.state.genderFilter,
      ),
      builder: (sheetContext, draft, onChanged) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterSection(
            title: sheetContext.tr('المستوى'),
            child: FilterChipGroup(
              options: [for (final f in _levelFilters) (f, sheetContext.tr(f))],
              selected: draft.level,
              onSelected: (v) => onChanged((level: v, gender: draft.gender)),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          FilterSection(
            title: sheetContext.tr('الجنس'),
            child: FilterChipGroup(
              options: [
                for (final f in _genderFilters) (f, sheetContext.tr(f)),
              ],
              selected: draft.gender,
              onSelected: (v) => onChanged((level: draft.level, gender: v)),
            ),
          ),
        ],
      ),
    );
    if (applied == null) return;
    cubit.setFilters(levelFilter: applied.level, genderFilter: applied.gender);
  }

  /// How many of the two filters are set to something other than "الكل".
  static int _activeFilterCount(CoachesState state) =>
      (state.levelFilter == 'الكل' ? 0 : 1) +
      (state.genderFilter == 'الكل' ? 0 : 1);

  Future<void> _openMySessions() async {
    if (await guestBlocked(context)) return;
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MyBookingsPage(
          initialTab: 1, // assessments tab
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _openAssessmentBooking() async {
    if (await guestBlocked(context)) return;
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AdvancedAssessmentPage(onBack: () => Navigator.of(context).pop()),
      ),
    );
  }

  Future<void> _openBookingSheet(CoachEntity coach) async {
    // حجز جلسة يخص حساباً؛ تصفّح المدربين مفتوح للزائر.
    if (await guestBlocked(context)) return;
    if (!mounted) return;
    showCoachBookingSheet(context, coach);
  }

  /// يفتح صفحة تفاصيل المدرب؛ البطاقة المحمّلة تُمرَّر لترسم فوراً قبل وصول
  /// التفاصيل الكاملة.
  void _openCoachDetail(CoachEntity coach) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            CoachDetailPage(coachId: coach.numericId, initial: coach),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<CoachesCubit, CoachesState>(
          builder: (context, state) {
            return Column(
              children: [
                _buildHeader(state),
                Expanded(child: _buildBody(state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(CoachesState state) {
    if (state.status == CoachesStatus.loading ||
        state.status == CoachesStatus.initial) {
      return const _CoachesSkeleton();
    }

    if (state.status == CoachesStatus.failure) {
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
                state.error ?? context.tr('تعذّر تحميل المدربين'),
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.secondary),
              ),
              const SizedBox(height: AppSizes.lg),
              ElevatedButton(
                onPressed: () => context.read<CoachesCubit>().loadCoaches(),
                child: Text(context.tr('إعادة المحاولة')),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = state.filtered;
    return LoadMoreListener(
      // يحمّل التالي قرب النهاية، أو فوراً إن لم تملأ القائمة الشاشة.
      onLoadMore: () {
        context.read<CoachesCubit>().loadMore();
      },
      child: ListView(
        padding: context.safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
        children: [
          // بانر إعلانات صفحة المدربين — يخفي نفسه إن لم توجد إعلانات لها.
          const AdBannerSection(
            page: AdPlacements.coaches,
            padding: EdgeInsets.only(bottom: AppSizes.lg),
          ),
          if (kAdvancedAssessmentEnabled) ...[
            _buildAssessmentBanner(),
            const SizedBox(height: AppSizes.lg),
          ],
          if (filtered.isEmpty && !state.hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.xxxl),
              child: Center(
                child: Text(
                  context.tr('لا يوجد مدربون مطابقون'),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
            )
          else
            ...filtered.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.md),
                child: _CoachCard(
                  coach: c,
                  // الضغط على البطاقة يفتح التفاصيل، والزر يحجز مباشرة.
                  onTap: () => _openCoachDetail(c),
                  onBook: () {
                    if (c.isBooked) {
                      widget.onNavigate?.call('training-session', c.id);
                    } else {
                      _openBookingSheet(c);
                    }
                  },
                ),
              ),
            ),
          if (state.hasMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.md),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(CoachesState state) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.onBack != null) ...[
                    IconButton(
                      onPressed: widget.onBack,
                      icon: const DirectionalIcon(
                        rtl: Icons.arrow_forward,
                        ltr: Icons.arrow_back,
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(width: AppSizes.md),
                  ],
                  Text(
                    context.tr('طور مستواك'),
                    style: AppTextStyles.heading2.copyWith(color: Colors.white),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _openMySessions,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                      ),
                    ),
                    icon: const Icon(Icons.event_available_outlined, size: 18),
                    label: Text(context.tr('حجوزاتي')),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              Row(
                children: [
                  Expanded(
                    child: AppSearchField(
                      hint: context.tr('ابحث عن مدرب...'),
                      onChanged: (v) => context.read<CoachesCubit>().search(v),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  // المستوى والجنس صارا داخل bottom sheet الفلاتر.
                  FilterHeaderButton(
                    activeCount: _activeFilterCount(state),
                    onOpen: () =>
                        _openFilterSheet(context.read<CoachesCubit>()),
                    onClear: context.read<CoachesCubit>().resetFilters,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssessmentBanner() {
    const purple = Color(0xFF7C3AED);
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: purple.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              color: purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: const Icon(
              Icons.workspace_premium_outlined,
              color: purple,
              size: AppSizes.iconLg,
            ),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('تقييم مستوى عند مدرب معتمد'),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  context.tr('احصل على جلسة تقييم شاملة مع مدرب معتمد'),
                  style: AppTextStyles.caption,
                ),
                SizedBox(height: AppSizes.xs),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        context.tr('250 ر.س'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: purple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          ElevatedButton(
            onPressed: _openAssessmentBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
            ),
            child: Text(
              context.tr('احجز التقييم'),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({
    required this.coach,
    required this.onTap,
    required this.onBook,
  });

  final CoachEntity coach;

  /// فتح صفحة تفاصيل المدرب.
  final VoidCallback onTap;

  /// زر «احجز الآن» / «حجز مكتمل».
  final VoidCallback onBook;

  Color get _badgeBg {
    switch (coach.badgeType) {
      case 'women':
        return const Color(0xFFFFE4E6);
      case 'pro':
        return const Color(0xFFDCFCE7);
      default:
        return AppColors.primary.withValues(alpha: 0.1);
    }
  }

  Color get _badgeFg {
    switch (coach.badgeType) {
      case 'women':
        return const Color(0xFFDB2777);
      case 'pro':
        return const Color(0xFF16A34A);
      default:
        return AppColors.primary;
    }
  }

  List<Color> get _avatarColors {
    final colors = coach.avatarGradientColors;
    return [_hexColor(colors[0]), _hexColor(colors[1])];
  }

  Color _hexColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  NetworkDecorationImage(
                    imageUrl: coach.avatarUrl,
                    builder: (_, image) => Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _avatarColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                        image: image,
                      ),
                      child: image != null
                          ? null
                          : Center(
                              child: Text(
                                coach.avatarInitials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coach.name,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: AppSizes.xs),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFACC15),
                              size: 14,
                            ),
                            SizedBox(width: 2),
                            Text(
                              '${coach.rating}',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.foreground,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                context.trArgs(' ({p0} تقييم)', {
                                  'p0': coach.reviews,
                                }),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm,
                      vertical: AppSizes.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _badgeBg,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      coach.badgeLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: _badgeFg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  _infoChip(
                    Icons.people_outline,
                    trgArgs('{p0} طالب', {'p0': coach.students}),
                  ),
                  SizedBox(width: AppSizes.sm),
                  _infoChip(
                    Icons.bar_chart,
                    trgArgs('المستوى {p0}-{p1}', {
                      'p0': coach.levelMin,
                      'p1': coach.levelMax,
                    }),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: AppSizes.iconSm,
                    color: AppColors.mutedForeground,
                  ),
                  SizedBox(width: AppSizes.xs),
                  Flexible(
                    child: Text(
                      coach.distanceKm != null
                          ? context.trArgs('{p0} · {p1} كم', {
                              'p0': coach.location,
                              'p1': coach.distanceKm,
                            })
                          : coach.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.md),
              Wrap(
                spacing: AppSizes.xs,
                runSpacing: AppSizes.xs,
                children: coach.specialties
                    .map(
                      (s) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusFull,
                          ),
                        ),
                        child: Text(
                          s,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (coach.offers.isNotEmpty) ...[
                SizedBox(height: AppSizes.sm),
                _offerBadge(context, coach.offers),
              ],
              SizedBox(height: AppSizes.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${coach.price} ',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: context.tr('ر.س / جلسة'),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (coach.isBooked)
                    ElevatedButton.icon(
                      onPressed: onBook,
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: Text(context.tr('حجز مكتمل')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: AppSizes.sm,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusLg,
                          ),
                        ),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: onBook,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: AppSizes.sm,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusLg,
                          ),
                        ),
                      ),
                      child: Text(context.tr('احجز الآن')),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.mutedForeground),
          SizedBox(width: 3),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  /// Highlights the coach's best active offer (highest discount) — العروض
  /// والخصومات the coach added, shown to players before booking.
  Widget _offerBadge(BuildContext context, List<CoachOfferEntity> offers) {
    final best = offers.reduce(
      (a, b) => a.discountPercent >= b.discountPercent ? a : b,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_offer_outlined,
            size: 12,
            color: Color(0xFFEA580C),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${context.tr('خصم')} ${best.discountPercent}% · ${best.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFFEA580C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Booking Bottom Sheet ─────────────────────────────────────────────────────

/// يفتح ورقة حجز جلسة مع [coach]. عامة لأن صفحة تفاصيل المدرب تفتح نفس الورقة.
/// [onBooked] يُستدعى بعد نجاح الحجز (إضافةً إلى رسالة التأكيد).
Future<void> showCoachBookingSheet(
  BuildContext context,
  CoachEntity coach, {
  VoidCallback? onBooked,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final confirmation = context
      .tr('تم حجز جلسة مع %s بنجاح')
      .replaceAll('%s', coach.name);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BookingSheet(
      coach: coach,
      // The sheet creates the session, closes itself, then calls this.
      onBooked: () {
        messenger.showSnackBar(SnackBar(content: Text(confirmation)));
        onBooked?.call();
      },
    ),
  );
}

class _BookingSheet extends StatefulWidget {
  const _BookingSheet({required this.coach, required this.onBooked});

  final CoachEntity coach;

  /// Called after the session has been booked successfully.
  final VoidCallback onBooked;

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  int _step = 1;

  final Set<String> _selectedDomains = {};
  String? _selectedDate; // display label
  String? _selectedTime; // display label
  DateTime? _selectedDay; // real selected day
  int? _selectedHour; // real selected hour (24h)
  CourtEntity? _selectedCourt;

  bool _booking = false;

  // Real courts from the API, sorted nearest-first by the backend when the
  // player has a saved location.
  List<CourtEntity>? _courts;
  bool _courtsLoading = true;
  String? _courtsError;

  @override
  void initState() {
    super.initState();
    _loadCourts();
  }

  Future<void> _loadCourts() async {
    setState(() {
      _courtsLoading = true;
      _courtsError = null;
    });
    try {
      final page = await getIt<CourtRepository>().fetchCourts(pageSize: 50);
      if (!mounted) return;
      setState(() {
        _courts = page.items;
        _courtsLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _courtsError = e.display;
        _courtsLoading = false;
      });
    }
  }

  /// Upcoming days offered in the date picker (today + next 4 days).
  late final List<DateTime> _dateOptions = List.generate(5, (i) {
    final now = ksaNow();
    return DateTime(now.year, now.month, now.day).add(Duration(days: i));
  });

  static String _weekday(DateTime d) => AppDates.weekday(d);
  static String _dayMonth(DateTime d) =>
      '${d.day} ${AppDates.monthName(d.month)}';

  static List<Map<String, String>> get _domains => [
    {
      'id': 'attack',
      'icon': '⚔️',
      'label': trg('الهجوم'),
      'sublabel': 'Attack',
      'desc': trg('تحسين قوة وتوجيه الضربات الهجومية'),
    },
    {
      'id': 'defense',
      'icon': '🛡️',
      'label': trg('الدفاع'),
      'sublabel': 'Defense',
      'desc': trg('تقنيات التصدي واستعادة الكرة'),
    },
    {
      'id': 'control',
      'icon': '🎯',
      'label': trg('التحكم'),
      'sublabel': 'Control',
      'desc': trg('دقة التوجيه والتحكم في الكرة'),
    },
    {
      'id': 'movement',
      'icon': '🏃',
      'label': trg('الحركة'),
      'sublabel': 'Movement',
      'desc': trg('السرعة والرشاقة داخل الملعب'),
    },
    {
      'id': 'gameiq',
      'icon': '🧠',
      'label': trg('ذكاء اللعب'),
      'sublabel': 'Game IQ',
      'desc': trg('قراءة اللعبة واتخاذ القرار'),
    },
    {
      'id': 'teamplay',
      'icon': '🤝',
      'label': trg('اللعب الجماعي'),
      'sublabel': 'Team Play',
      'desc': trg('التنسيق والتواصل مع الشريك'),
    },
    {
      'id': 'serve',
      'icon': '🎾',
      'label': trg('الإرسال'),
      'sublabel': 'Serve',
      'desc': trg('تقنيات الإرسال وبدء النقطة'),
    },
  ];

  static List<Map<String, String>> get _times => [
    {'time': '08:00', 'period': trg('صباحاً'), 'h': '8'},
    {'time': '10:00', 'period': trg('صباحاً'), 'h': '10'},
    {'time': '12:00', 'period': trg('ظهراً'), 'h': '12'},
    {'time': '04:00', 'period': trg('مساءً'), 'h': '16'},
    {'time': '06:00', 'period': trg('مساءً'), 'h': '18'},
    {'time': '08:00', 'period': trg('مساءً'), 'h': '20'},
  ];

  static List<String> get _stepTitles => [
    trg('اختر مجالات التدريب'),
    trg('حدد الموعد'),
    trg('اختر الموقع'),
    trg('تأكيد الحجز'),
  ];

  bool get _canProceed {
    switch (_step) {
      case 1:
        return _selectedDomains.isNotEmpty;
      case 2:
        return _selectedDay != null && _selectedHour != null;
      case 3:
        return _selectedCourt != null;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (_step < 4) {
      setState(() => _step++);
    } else {
      _confirmBooking();
    }
  }

  /// Whether [hour] on the currently selected day is already in the past.
  /// Only "today" can have past slots; future days are always bookable.
  bool _isSlotPast(int hour) {
    final day = _selectedDay;
    if (day == null) return false;
    return DateTime(
      day.year,
      day.month,
      day.day,
      hour,
    ).isBefore(ksaNow());
  }

  static String _sessionWhenLabel(DateTime d) {
    final period = AppDates.period(d);
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '${d.day} ${AppDates.monthName(d.month)} · $h12:00 $period';
  }

  Future<void> _confirmBooking() async {
    if (_selectedDay == null || _selectedHour == null) return;
    final scheduledAt = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      _selectedHour!,
    );
    final messenger = ScaffoldMessenger.of(context);

    // Booking only creates a *request*; the wallet is charged later, when the
    // coach approves it — so the dialog promises a future debit, not one now.
    final confirmed = await showPaymentConfirmDialog(
      context,
      title: context.tr('تأكيد طلب الجلسة'),
      amount: widget.coach.price.toDouble(),
      details: [
        PaymentDetail(context.tr('المدرب'), widget.coach.name),
        PaymentDetail(context.tr('الموعد'), _sessionWhenLabel(scheduledAt)),
      ],
      deferredNote: context.tr(
        'سيُخصم المبلغ من محفظتك عند موافقة المدرب على الطلب، ولن يُخصم شيء إذا اعتذر.',
      ),
      confirmLabel: context.tr('إرسال الطلب'),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _booking = true);
    try {
      await getIt<CoachRepository>().bookSession(
        coachId: widget.coach.numericId,
        scheduledAt: scheduledAt,
        domains: _selectedDomains.toList(),
        courtId: _selectedCourt?.numericId,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onBooked();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _booking = false);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.xxxl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            _buildSheetHeader(),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                child: _buildStepBody(),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.md),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pagePadding,
        AppSizes.md,
        AppSizes.pagePadding,
        AppSizes.md,
      ),
      child: Column(
        children: [
          Row(
            children: [
              NetworkDecorationImage(
                imageUrl: widget.coach.avatarUrl,
                builder: (_, image) => Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    image: image,
                  ),
                  child: image != null
                      ? null
                      : Center(
                          child: Text(
                            widget.coach.avatarInitials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                ),
              ),
              SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.coach.name,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(_stepTitles[_step - 1], style: AppTextStyles.caption),
                  ],
                ),
              ),
              Text(
                context.trArgs('الخطوة {p0} من 4', {'p0': _step}),
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          StepProgressBar(
            currentStep: _step,
            totalSteps: 4,
            inactiveColor: const Color(0xFFE5E7EB),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_step) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Column(
      children: _domains.map((d) {
        final id = d['id']!;
        final selected = _selectedDomains.contains(id);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.sm),
          child: GestureDetector(
            onTap: () => setState(() {
              if (selected) {
                _selectedDomains.remove(id);
              } else {
                _selectedDomains.add(id);
              }
            }),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(d['icon']!, style: const TextStyle(fontSize: 22)),
                  SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              d['label']!,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: AppSizes.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.xs + 2,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusFull,
                                ),
                              ),
                              child: Text(
                                d['sublabel']!,
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(d['desc']!, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: AppSizes.iconMd,
                    )
                  else
                    Icon(
                      Icons.circle_outlined,
                      color: AppColors.border,
                      size: AppSizes.iconMd,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('اختر التاريخ'),
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _dateOptions.map((d) {
              final selected = _selectedDay == d;
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSizes.sm),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedDay = d;
                    _selectedDate = '${_weekday(d)} ${_dayMonth(d)}';
                    // Clear the time if it's now in the past for the new day.
                    if (_selectedHour != null && _isSlotPast(_selectedHour!)) {
                      _selectedHour = null;
                      _selectedTime = null;
                    }
                  }),
                  child: Container(
                    width: 72,
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _weekday(d),
                          style: AppTextStyles.caption.copyWith(
                            color: selected
                                ? Colors.white
                                : AppColors.mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: AppSizes.xs),
                        Text(
                          _dayMonth(d),
                          style: AppTextStyles.caption.copyWith(
                            color: selected
                                ? Colors.white
                                : AppColors.foreground,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: AppSizes.lg),
        Text(
          context.tr('اختر الوقت'),
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppSizes.sm,
            mainAxisSpacing: AppSizes.sm,
            childAspectRatio: 2.2,
          ),
          itemCount: _times.length,
          itemBuilder: (_, i) {
            final t = _times[i];
            final val = '${t['time']} ${t['period']}';
            final selected = _selectedTime == val;
            final disabled = _isSlotPast(int.parse(t['h']!));
            return GestureDetector(
              onTap: disabled
                  ? null
                  : () => setState(() {
                      _selectedTime = val;
                      _selectedHour = int.parse(t['h']!);
                    }),
              child: Opacity(
                opacity: disabled ? 0.4 : 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : disabled
                        ? AppColors.muted
                        : Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t['time']!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: selected ? Colors.white : AppColors.foreground,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          decoration: disabled
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      Text(
                        t['period']!,
                        style: AppTextStyles.caption.copyWith(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppColors.mutedForeground,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStep3() {
    if (_courtsLoading) {
      return const SkeletonList(
        itemCount: 3,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
      );
    }
    if (_courtsError != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          children: [
            Text(_courtsError!, style: AppTextStyles.bodySmall),
            const SizedBox(height: AppSizes.md),
            TextButton(
              onPressed: _loadCourts,
              child: Text(context.tr('إعادة المحاولة')),
            ),
          ],
        ),
      );
    }
    final courts = _courts ?? const [];
    if (courts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Center(
          child: Text(
            context.tr('لا توجد ملاعب متاحة حالياً'),
            style: AppTextStyles.bodySmall,
          ),
        ),
      );
    }
    return Column(
      children: courts.map((court) {
        final selected = _selectedCourt?.id == court.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.sm),
          child: GestureDetector(
            onTap: () => setState(() => _selectedCourt = court),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: AppSizes.iconMd,
                      color: selected
                          ? AppColors.primary
                          : AppColors.mutedForeground,
                    ),
                  ),
                  SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          court.name,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: AppSizes.xs),
                        Row(
                          children: [
                            if (court.distance.isNotEmpty) ...[
                              Text(
                                court.distance,
                                style: AppTextStyles.caption,
                              ),
                              Text(' · ', style: AppTextStyles.caption),
                            ] else if (court.city.isNotEmpty) ...[
                              Text(court.city, style: AppTextStyles.caption),
                              Text(' · ', style: AppTextStyles.caption),
                            ],
                            Text(
                              context.trArgs('{p0} ملاعب', {
                                'p0': court.courtCount,
                              }),
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: AppSizes.iconMd,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStep4() {
    final domainLabels = _selectedDomains
        .map((id) {
          final d = _domains.firstWhere(
            (x) => x['id'] == id,
            orElse: () => {'label': id},
          );
          return d['label']!;
        })
        .join(trg('، '));

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF16A34A),
                size: AppSizes.iconLg,
              ),
              SizedBox(width: AppSizes.sm),
              Text(
                context.tr('ملخص الحجز'),
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF15803D),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.md),
          _summaryRow(trg('المدرب'), widget.coach.name),
          _summaryRow(trg('المجالات'), domainLabels),
          _summaryRow(trg('التاريخ'), _selectedDate ?? ''),
          _summaryRow(trg('الوقت'), _selectedTime ?? ''),
          _summaryRow(trg('الموقع'), _selectedCourt?.name ?? ''),
          const Divider(height: AppSizes.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('الإجمالي'),
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF15803D),
                ),
              ),
              Text(
                context.trArgs('{p0} ر.س', {'p0': money(widget.coach.price)}),
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF15803D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFF16A34A),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFF15803D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.pagePadding,
          AppSizes.md,
          AppSizes.pagePadding,
          AppSizes.md,
        ),
        child: Row(
          children: [
            if (_step > 1) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _booking ? null : () => setState(() => _step--),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      AppSizes.buttonHeight,
                    ),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
                  ),
                  child: Text(context.tr('back')),
                ),
              ),
              const SizedBox(width: AppSizes.md),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (_canProceed && !_booking) ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(
                    alpha: 0.4,
                  ),
                  minimumSize: const Size(
                    double.infinity,
                    AppSizes.buttonHeight,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                ),
                child: _booking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _step < 4
                            ? context.tr('next')
                            : context.tr('تأكيد الحجز'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// هيكل تحميل قائمة المدربين بشكل [_CoachCard]: صورة ثم الاسم والشارة،
/// معلومات، تخصصات، ثم السعر وزر الحجز.
class _CoachesSkeleton extends StatelessWidget {
  const _CoachesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: AppSizes.md),
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SkeletonBox.circle(size: 52),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 14, width: i.isEven ? 140 : 110),
                        const SizedBox(height: AppSizes.sm),
                        const SkeletonBox(height: 10, width: 90),
                      ],
                    ),
                  ),
                  const SkeletonBox(
                    width: 60,
                    height: 22,
                    radius: AppSizes.radiusFull,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              const Row(
                children: [
                  SkeletonBox(
                    width: 80,
                    height: 24,
                    radius: AppSizes.radiusFull,
                  ),
                  SizedBox(width: AppSizes.sm),
                  SkeletonBox(
                    width: 96,
                    height: 24,
                    radius: AppSizes.radiusFull,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              const SkeletonBox(height: 10, width: 160),
              const SizedBox(height: AppSizes.md),
              const Row(
                children: [
                  SkeletonBox(
                    width: 56,
                    height: 18,
                    radius: AppSizes.radiusFull,
                  ),
                  SizedBox(width: AppSizes.xs),
                  SkeletonBox(
                    width: 72,
                    height: 18,
                    radius: AppSizes.radiusFull,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              const Row(
                children: [
                  SkeletonBox(width: 90, height: 16),
                  Spacer(),
                  SkeletonBox(width: 88, height: 34, radius: AppSizes.radiusLg),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
