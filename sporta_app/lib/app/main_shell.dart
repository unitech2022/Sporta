import 'package:sporta_app/core/widgets/directional_icon.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/constants/app_text_styles.dart';
import '../core/state/app_scope.dart';
import '../core/service_zone/service_zone_service.dart';
import '../core/state/app_settings.dart';
import '../core/widgets/app_bottom_nav_bar.dart';
import '../features/memberships/presentation/pages/my_memberships_page.dart';
import '../features/auth/presentation/state/auth_scope.dart';
import '../features/coaches/presentation/pages/coaches_page.dart';
import '../features/courts/presentation/pages/book_court_page.dart';
import '../features/courts/presentation/pages/courts_page.dart';
import '../features/courts/presentation/pages/favorite_courts_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/level/presentation/pages/level_assessment_page.dart';
import '../features/matches/presentation/pages/matches_page.dart';
import '../features/payment/presentation/pages/subscription_page.dart';
import '../features/payment/presentation/pages/top_up_wallet_page.dart';
import '../features/profile/presentation/pages/my_bookings_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/settings/presentation/pages/account_settings_page.dart';
import '../features/settings/presentation/pages/contact_us_page.dart';
import '../features/settings/presentation/pages/delete_account_page.dart';
import '../features/settings/presentation/pages/language_settings_page.dart';
import '../features/points/presentation/pages/points_page.dart';
import '../features/settings/presentation/pages/privacy_policy_page.dart';
import '../features/settings/presentation/pages/refund_policy_page.dart';
import '../features/settings/presentation/pages/terms_page.dart';
import '../features/venue/presentation/pages/manage_bookings_page.dart';
import '../features/venue/presentation/pages/manage_match_requests_page.dart';
import '../features/venue/presentation/pages/manage_venues_page.dart';

/// Root shell with the bottom navigation bar (tab order:
/// home, matches, courts, coaches, profile).
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Pages and the tab-name → index map are rebuilt when the active role changes
  // (each role has its own bottom-nav set).
  UserRole? _builtRole;
  List<Widget> _pages = const [];
  Map<String, int> _tabMap = const {};

  void _rebuildForRole(UserRole role) {
    _builtRole = role;
    if (role == UserRole.venue) {
      _pages = [
        HomePage(onNavigate: _navigate),
        const ManageVenuesPage(),
        const ManageBookingsPage(),
        const ManageMatchRequestsPage(),
        ProfilePage(onLogout: widget.onLogout, onNavigate: _navigate),
      ];
      _tabMap = const {
        'home': 0, 'courts': 1, 'bookings': 2, 'matches': 3, 'profile': 4,
      };
    } else {
      _pages = [
        HomePage(onNavigate: _navigate),
        const MatchesPage(),
        CourtsPage(
          onNavigateToCourt: _openBookCourt,
          onBookSlot: (id, date, time, duration) => _openBookCourt(
            id,
            date: date,
            time: time,
            duration: duration,
          ),
        ),
        const CoachesPage(),
        ProfilePage(onLogout: widget.onLogout, onNavigate: _navigate),
      ];
      _tabMap = const {
        'home': 0, 'matches': 1, 'courts': 2, 'coaches': 3, 'profile': 4,
      };
    }
    if (_currentIndex >= _pages.length) _currentIndex = 0;
  }

  List<AppBottomNavItem> _navItemsFor(BuildContext context, UserRole role) {
    if (role == UserRole.venue) {
      return [
        AppBottomNavItem(icon: Icons.home_outlined, label: context.tr('home')),
        AppBottomNavItem(
            icon: Icons.stadium_outlined, label: context.tr('ملاعبي')),
        AppBottomNavItem(
            icon: Icons.calendar_today_outlined, label: context.tr('الحجوزات')),
        AppBottomNavItem(
            icon: Icons.emoji_events_outlined, label: context.tr('المباريات')),
        AppBottomNavItem(
            icon: Icons.person_outline, label: context.tr('profile')),
      ];
    }
    return [
      AppBottomNavItem(icon: Icons.home_outlined, label: context.tr('home')),
      AppBottomNavItem(
          icon: Icons.emoji_events_outlined, label: context.tr('matches')),
      AppBottomNavItem(
          icon: Icons.calendar_today_outlined, label: context.tr('courts')),
      AppBottomNavItem(
          icon: Icons.menu_book_outlined, label: context.tr('coaches')),
      AppBottomNavItem(icon: Icons.person_outline, label: context.tr('profile')),
    ];
  }

  /// Central route handler for [HomePage]/[ProfilePage] `onNavigate` callbacks.
  /// Tab names switch the bottom-nav index; everything else pushes a page.
  void _navigate(String page) {
    final tabIndex = _tabMap[page];
    if (tabIndex != null) {
      setState(() => _currentIndex = tabIndex);
      return;
    }
    void pop() => Navigator.of(context).pop();
    final builder = switch (page) {
      'my-bookings' => (_) => MyBookingsPage(onBack: pop),
      'favorite-courts' => (_) => FavoriteCourtsPage(onBack: pop),
      'my-memberships' => (_) => const MyMembershipsPage(),
      'account-settings' => (_) => AccountSettingsPage(onBack: pop),
      'delete-account' => (_) => DeleteAccountPage(onBack: pop),
      'language' => (_) => LanguageSettingsPage(onBack: pop),
      'contact' => (_) => ContactUsPage(onBack: pop),
      'points-system' => (_) => PointsPage(onBack: pop),
      'packages' => (_) => SubscriptionPage(onBack: pop),
      'terms' => (_) => TermsPage(onBack: pop),
      'privacy' => (_) => PrivacyPolicyPage(onBack: pop),
      'refund' => (_) => RefundPolicyPage(onBack: pop),
      'top-up-wallet' => (_) => TopUpWalletPage(onBack: pop, onComplete: pop),
      _ => null,
    } as WidgetBuilder?;
    if (builder == null) return;
    // These settings pages render their own header/body without a Scaffold, so
    // provide a Material ancestor for their InkWells/ListTiles. Transparent so
    // each page's own background still shows (and harmless for pages that do
    // include their own Scaffold).
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (ctx) => Material(
        type: MaterialType.transparency,
        child: builder(ctx),
      ),
    ));
  }

  void _openBookCourt(
    String courtId, {
    DateTime? date,
    String? time,
    int? duration,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookCourtPage(
          courtId: courtId,
          initialDate: date,
          initialTime: time,
          initialDuration: duration,
          onBack: () => Navigator.of(context).pop(),
          onComplete: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _openLevelAssessment() {
    final sport = context.auth.user?.favoriteSport ?? 'padel';
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LevelAssessmentPage(
          sport: sport,
          onComplete: () => Navigator.of(context).pop(),
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  // آخر إحداثيات فُحص بها نطاق الخدمة — يُعاد الفحص حين يغيّر المستخدم موقعه
  // المحفوظ (من الإعدادات) لا مع كل إعادة بناء.
  (double?, double?)? _zoneCheckedFor;

  void _refreshServiceZoneIfMoved(double? lat, double? lng) {
    if (_zoneCheckedFor == (lat, lng)) return;
    _zoneCheckedFor = (lat, lng);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ServiceZoneService.instance.refresh(lat: lat, lng: lng),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.appSettings.role;
    if (_builtRole != role) _rebuildForRole(role);
    final navItems = _navItemsFor(context, role);

    final user = context.auth.user;
    final showLevelReminder =
        user != null && user.isPlayer && !user.levelAssessed;
    _refreshServiceZoneIfMoved(user?.latitude, user?.longitude);

    return Scaffold(
      body: Column(
        children: [
          const _OutsideServiceZoneBanner(),
          if (showLevelReminder)
            _LevelReminderBanner(onTap: _openLevelAssessment),
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        items: navItems,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

/// Persistent top banner shown across all tabs while a player hasn't completed
/// their level self-assessment. Tapping it opens the assessment.
class _LevelReminderBanner extends StatelessWidget {
  const _LevelReminderBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warning,
      child: InkWell(
        onTap: onTap,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.lg,
              vertical: AppSizes.md,
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: AppSizes.iconMd),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Text(
                    context.tr('completeLevelBanner'),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                DirectionalIcon(rtl: Icons.chevron_left, ltr: Icons.chevron_right,
                    color: Colors.white, size: AppSizes.iconMd),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// شريط «أنت حالياً خارج نطاق خدمة التطبيق» — يظهر أعلى كل التبويبات متى وقع
/// موقع المستخدم خارج مناطق الخدمة المفعّلة، ويختفي تماماً حين لا توجد مناطق.
class _OutsideServiceZoneBanner extends StatelessWidget {
  const _OutsideServiceZoneBanner();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ServiceZoneCheck>(
      valueListenable: ServiceZoneService.instance.listenable,
      builder: (context, check, _) {
        if (!check.isOutside) return const SizedBox.shrink();
        return Material(
          color: AppColors.destructive,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg,
                vertical: AppSizes.md,
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_off_rounded,
                      color: Colors.white, size: AppSizes.iconMd),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Text(
                      check.message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
