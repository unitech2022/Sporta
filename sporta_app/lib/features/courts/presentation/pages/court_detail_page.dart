import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../memberships/presentation/widgets/club_membership_section.dart';
import '../../../reviews/presentation/widgets/court_reviews_section.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../data/court_repository.dart';
import '../../domain/entities/court_entity.dart';
import '../widgets/court_detail/court_detail_hero.dart';
import '../widgets/court_detail/court_detail_location.dart';
import '../widgets/court_detail/court_detail_sections.dart';
import 'book_court_page.dart';
import '../../../auth/presentation/widgets/login_required_sheet.dart';
import '../../../../core/utils/system_insets.dart';

/// Full court profile: cover header, summary tiles, pricing, weekly schedule,
/// available times, facilities and location — with a sticky booking bar.
class CourtDetailPage extends StatefulWidget {
  const CourtDetailPage({super.key, required this.courtId});

  final String courtId;

  @override
  State<CourtDetailPage> createState() => _CourtDetailPageState();
}

class _CourtDetailPageState extends State<CourtDetailPage> {
  final _repo = getIt<CourtRepository>();

  CourtEntity? _court;
  bool _loading = true;
  bool _failed = false;
  int _membershipRefresh = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// [silent] keeps the loaded page on screen while pull-to-refresh runs —
  /// only the first load replaces the body with a spinner.
  Future<void> _load({bool silent = false}) async {
    setState(() {
      _loading = !silent;
      _failed = false;
    });
    try {
      final court = await _repo.fetchCourtById(
        int.tryParse(widget.courtId) ?? 0,
      );
      if (!mounted) return;
      setState(() {
        _court = court;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _openBooking() async {
    // الحجز يحتاج حساباً — الزائر يرى التفاصيل ثم يُدعى للتسجيل عند الحجز.
    if (await guestBlocked(context)) return;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookCourtPage(
          courtId: widget.courtId,
          onBack: () => Navigator.of(context).pop(),
          onComplete: () => Navigator.of(context).pop(),
        ),
      ),
    );
    // الحجز يستهلك من ساعات خصم العضوية — يُحدَّث قسمها عند العودة.
    if (mounted) setState(() => _membershipRefresh++);
  }

  Future<void> _openInMaps() async {
    final c = _court;
    if (c == null || !c.hasLocation) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${c.latitude},${c.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final court = _court;
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _loading
            ? _loadingState()
            : (_failed || court == null)
            ? _errorState()
            : _content(court),
        bottomNavigationBar: (_loading || court == null)
            ? null
            : _bottomBar(court),
      ),
    );
  }

  /// هيكل مكان الغلاف والتفاصيل، وزر الرجوع عائم فوقه كما في المحتوى.
  Widget _loadingState() {
    return Stack(
      children: [
        const Column(
          children: [
            Shimmer(
              child: SkeletonBox(height: CourtDetailHero.height, radius: 0),
            ),
            Expanded(child: SkeletonDetail(memberRows: 0)),
          ],
        ),
        PositionedDirectional(
          top: MediaQuery.paddingOf(context).top + AppSizes.sm,
          start: AppSizes.lg,
          child: _backButton(),
        ),
      ],
    );
  }

  Widget _errorState() {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.topStart,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const DirectionalIcon(
                rtl: Icons.arrow_forward,
                ltr: Icons.arrow_back,
              ),
            ),
          ),
          const Spacer(),
          Text(
            context.tr('تعذّر تحميل الملعب'),
            style: AppTextStyles.body.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.md),
          OutlinedButton(
            onPressed: _load,
            child: Text(context.tr('إعادة المحاولة')),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _content(CourtEntity c) {
    // The back button floats above the scroll view so it stays reachable
    // after the cover scrolls away.
    return Stack(
      children: [
        _scrollBody(c),
        PositionedDirectional(
          top: MediaQuery.paddingOf(context).top + AppSizes.sm,
          start: AppSizes.lg,
          child: _backButton(),
        ),
      ],
    );
  }

  Widget _backButton() {
    return Material(
      color: AppColors.secondary.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
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
    );
  }

  Widget _scrollBody(CourtEntity c) {
    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: CourtDetailHero(court: c)),
          SliverPadding(
            padding: context.safeBottom(
              const EdgeInsets.fromLTRB(
                AppSizes.lg,
                AppSizes.lg,
                AppSizes.lg,
                AppSizes.xxl,
              ),
            ),
            sliver: SliverList.list(
              children: [
                if (!c.isAvailable) ...[
                  _closedBanner(),
                  const SizedBox(height: AppSizes.md),
                ],
                CourtSummaryTiles(court: c),
                const SizedBox(height: AppSizes.md),
                CourtPricingSection(court: c),
                ClubMembershipSection(
                  key: ValueKey('membership-${c.venueId}'),
                  venueId: c.venueId,
                  onChanged: () => _load(silent: true),
                  refreshToken: _membershipRefresh,
                ),
                const SizedBox(height: AppSizes.md),
                CourtAboutSection(court: c),
                if (c.openingHours.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.md),
                  CourtScheduleSection(court: c),
                ],
                if (c.availableTimes.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.md),
                  CourtTimesSection(court: c),
                ],
                if (c.facilities.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.md),
                  CourtFacilitiesSection(court: c),
                ],
                const SizedBox(height: AppSizes.md),
                CourtLocationSection(court: c, onDirections: _openInMaps),
                const SizedBox(height: AppSizes.md),
                CourtReviewsSection(
                  key: ValueKey('reviews-${c.id}-${c.reviews}'),
                  courtId: c.numericId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _closedBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: AppColors.destructive.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.destructive,
            size: AppSizes.iconMd,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              context.tr('هذا الملعب غير متاح للحجز حالياً.'),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.destructive,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(CourtEntity c) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.trArgs('{p0} ر.س', {'p0': c.lowestPrice}),
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  context.tr('يبدأ من / ساعة'),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(width: AppSizes.lg),
            Expanded(
              child: SizedBox(
                height: AppSizes.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: c.isAvailable ? _openBooking : null,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(
                    c.isAvailable
                        ? context.tr('احجز الآن')
                        : context.tr('غير متاح'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
