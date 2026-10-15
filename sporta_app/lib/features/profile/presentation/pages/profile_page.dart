import 'package:sporta_app/features/event_chat/presentation/pages/event_chat_page.dart';
import 'package:sporta_app/features/reviews/domain/review_models.dart';
import 'package:sporta_app/features/reviews/presentation/widgets/player_reputation_section.dart';
import 'package:sporta_app/features/reviews/presentation/pages/court_reviews_page.dart';
import 'package:sporta_app/features/reviews/presentation/widgets/rate_experience_sheet.dart';
import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sporta_app/core/widgets/directional_icon.dart';

import '../../../memberships/presentation/pages/venue_memberships_page.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_settings.dart';
import '../../../../core/widgets/gradient_page_header.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/pages/add_role_page.dart';
import '../../../auth/presentation/state/auth_scope.dart';
import '../../../coaches/data/coach_repository.dart';
import '../../../coaches/domain/entities/coach_dashboard.dart';
import '../../../coaches/presentation/pages/coach_booking_detail_page.dart';
import '../../../coaches/presentation/pages/coach_profile_edit_page.dart';
import '../../../coaches/presentation/pages/coach_revenue_page.dart';
import '../../../coaches/presentation/pages/coach_students_page.dart';
import '../../../coaches/presentation/pages/pending_assessments_page.dart';
import '../../../coaches/presentation/widgets/coach_offers_section.dart';
import '../../../courts/data/court_repository.dart';
import '../../../courts/domain/entities/booking_entity.dart';
import '../../../americano/presentation/pages/americano_detail_page.dart';
import '../../../friends/data/friend_repository.dart';
import '../../../friends/domain/entities/player_summary.dart';
import '../../../friends/presentation/pages/friends_page.dart';
import '../../../level/domain/level_question.dart';
import '../../../matches/data/match_repository.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../../../matches/presentation/pages/match_detail_page.dart';
import '../../../matches/presentation/widgets/match_scoreboard.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../venue/data/venue_repository.dart';
import '../../../venue/domain/entities/owner_venue.dart';
import '../../../venue/domain/entities/venue_dashboard.dart';
import '../../../venue/presentation/pages/manage_venues_page.dart';
import '../../../payment/presentation/cubit/wallet_cubit.dart';
import '../../../payment/presentation/pages/subscription_page.dart';
import '../../../payment/presentation/pages/top_up_wallet_page.dart';
import '../../../payment/presentation/pages/wallet_page.dart';
import '../../../payment/presentation/pages/withdraw_wallet_page.dart';
import '../../../notifications/domain/entities/notification_entity.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/utils/money.dart';
import 'package:sporta_app/core/utils/server_time.dart';
import '../../../../core/widgets/network_circle_avatar.dart';

enum _ProfileView { roles, playerDashboard, coachDashboard, venueDashboard }

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.onBack, this.onLogout, this.onNavigate});
  final VoidCallback? onBack;
  final VoidCallback? onLogout;
  final void Function(String page)? onNavigate;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  _ProfileView _view = _ProfileView.roles;
  late final String _userName;
  late final Map<String, bool> _roles;

  // Real data for the role cards and role dashboards, loaded per owned role.
  int? _playerMatchesTotal;
  int? _playerBookingsTotal;
  List<BookingEntity>? _recentBookings;
  List<MatchEntity>? _upcomingMatches;
  List<MatchEntity>? _recentResults;
  List<PlayerSummary>? _friends;
  CoachDashboard? _coachDash;
  VenueDashboard? _venueDash;
  List<OwnerVenue>? _venues;

  final Set<int> _expandedCourts = {};

  /// Guards the one-time init below: [didChangeDependencies] runs again on any
  /// dependency change, but the user/roles snapshot is taken only once.
  bool _initialized = false;

  // اسم المستخدم يُترجم عبر `context.tr` (يقرأ AppScope)، وهذا ممنوع في
  // initState — لذا تُقرأ البيانات هنا بعد أن تصبح الاعتماديات متاحة.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final user = context.auth.user;
    _userName = user?.fullName ?? context.tr('لاعب');
    final roles = user?.roles ?? const [UserRole.player];
    _roles = {
      'player': roles.contains(UserRole.player),
      'coach': roles.contains(UserRole.coach),
      'venue': roles.contains(UserRole.venue),
    };
    _loadRoleData();
  }

  /// Loads the live stats shown on the role cards and sub-dashboards. Each
  /// section fails independently (a failed call just keeps its placeholder).
  Future<void> _loadRoleData() async {
    if (_roles['player'] == true) {
      getIt<MatchRepository>()
          .fetchMyMatches(pageSize: 1)
          .then(
            (p) =>
                mounted ? setState(() => _playerMatchesTotal = p.total) : null,
          )
          .catchError((_) {});
      getIt<CourtRepository>()
          .fetchMyBookings(pageSize: 3)
          .then(
            (p) => mounted
                ? setState(() {
                    _playerBookingsTotal = p.total;
                    _recentBookings = p.items;
                  })
                : null,
          )
          // On failure, fall back to an empty list so the card shows its empty
          // state instead of spinning forever.
          .catchError((_) {
            if (mounted) setState(() => _recentBookings = const []);
          });
      getIt<MatchRepository>()
          .fetchMyMatches(pageSize: 50)
          .then((p) {
            if (!mounted) return;
            final now = ksaNow();
            final upcoming =
                p.items
                    .where(
                      (m) =>
                          const {
                            'Open',
                            'Full',
                            'InProgress',
                          }.contains(m.status) &&
                          m.scheduledAt.isAfter(now),
                    )
                    .toList()
                  ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
            setState(() => _upcomingMatches = upcoming.take(5).toList());
          })
          .catchError((_) {
            if (mounted) setState(() => _upcomingMatches = const []);
          });
      getIt<MatchRepository>()
          .fetchMyMatches(pageSize: 20, status: 'Completed')
          .then(
            // المباريات ذات النتيجة المعتمدة فقط — الأمريكانو المكتمل نتيجته
            // في جولاته لا على المباراة فكان يظهر «لم تُسجَّل النتيجة».
            (p) => mounted
                ? setState(() => _recentResults = p.items
                    .where((m) => m.team1Score != null && m.team2Score != null)
                    .take(5)
                    .toList())
                : null,
          )
          .catchError((_) {
            if (mounted) setState(() => _recentResults = const []);
          });
      getIt<FriendRepository>()
          .fetchFriends()
          .then((f) => mounted ? setState(() => _friends = f) : null)
          .catchError((_) {
            if (mounted) setState(() => _friends = const []);
          });
    }
    if (_roles['coach'] == true) _loadCoachDashboard();
    if (_roles['venue'] == true) {
      getIt<VenueRepository>()
          .fetchDashboard()
          .then((d) => mounted ? setState(() => _venueDash = d) : null)
          .catchError((_) {});
      getIt<VenueRepository>()
          .fetchMyVenues()
          .then((v) => mounted ? setState(() => _venues = v) : null)
          .catchError((_) {});
    }
  }

  void _loadCoachDashboard() {
    getIt<CoachRepository>()
        .fetchDashboard()
        .then((d) => mounted ? setState(() => _coachDash = d) : null)
        .catchError((_) {});
  }

  Future<void> _addRole(String role) async {
    final userRole = switch (role) {
      'player' => UserRole.player,
      'coach' => UserRole.coach,
      _ => UserRole.venue,
    };
    // Open the account-details registration page (same as "add new account").
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => AddRolePage(role: userRole)),
    );
    if (added == true && mounted) {
      setState(() => _roles[role] = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // .value: the cubit is shared via DI, so this page must not close it.
    return BlocProvider<WalletCubit>.value(
      value: getIt<WalletCubit>()..load(),
      child: Directionality(
        textDirection: Directionality.of(context),
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: _buildCurrentView(),
        ),
      ),
    );
  }

  /// يرصّ الأقسام الظاهرة فقط: أي بانٍ يعيد null (قسم بلا بيانات) يُسقط تماماً
  /// ولا تبقى مسافته، فلا نعرض عناوين فارغة ولا رسائل «لا توجد…».
  /// [leadingGap] مسافة تسبق أول قسم ظاهر — تختفي هي أيضاً إن كانت كل الأقسام
  /// فارغة.
  List<Widget> _stack(
    List<Widget?> sections, {
    double gap = AppSizes.lg,
    double leadingGap = 0,
  }) {
    final visible = sections.whereType<Widget>().toList();
    if (visible.isEmpty) return const [];
    return [
      if (leadingGap > 0) SizedBox(height: leadingGap),
      for (var i = 0; i < visible.length; i++) ...[
        if (i > 0) SizedBox(height: gap),
        visible[i],
      ],
    ];
  }

  Widget _buildCurrentView() {
    switch (_view) {
      case _ProfileView.roles:
        return _buildRolesView();
      case _ProfileView.playerDashboard:
        return _buildPlayerDashboard();
      case _ProfileView.coachDashboard:
        return _buildCoachDashboard();
      case _ProfileView.venueDashboard:
        return _buildVenueDashboard();
    }
  }

  Widget _buildRolesView() {
    final addedRoles = _roles.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    final missingRoles = _roles.entries
        .where((e) => !e.value)
        .map((e) => e.key)
        .toList();

    return Column(
      children: [
        GradientPageHeader(title: context.tr('profile'), onBack: widget.onBack),
        Expanded(
          child: SingleChildScrollView(
            padding: context
                .safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserCard(),
                SizedBox(height: AppSizes.md),
                _buildWalletBalanceCard(),
                SizedBox(height: AppSizes.xl),
                if (addedRoles.isNotEmpty) ...[
                  Text(
                    context.tr('أدواري'),
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  ...addedRoles.map((role) => _buildRoleCard(role)),
                ],
                if (missingRoles.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.md),
                  _buildAddRoleButton(missingRoles),
                ],
                if (_roles['player'] == true) ...[
                  // سمعة اللاعب من تقييمات اللاعبين والمدربين وأصحاب الملاعب.
                  PlayerReputationSection(
                    userId: int.tryParse(getIt<AuthCubit>().user?.id ?? '') ?? 0,
                    padding: const EdgeInsets.only(top: AppSizes.xl),
                  ),
                  ..._stack([
                    _buildUpcomingMatchesCard(),
                    _buildRecentResultsCard(),
                    _buildFriendsCard(),
                    _buildFavoritesCard(),
                  ], leadingGap: AppSizes.xl),
                ],
                SizedBox(height: AppSizes.xl),
                _buildSettingsSection(),
                SizedBox(height: AppSizes.pagePadding),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    final url = context.auth.user?.avatarUrl;
    final initials = _userName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p.substring(0, 1))
        .join('.');
    // The gradient + initials double as the fallback when the photo fails.
    return NetworkDecorationImage(
      imageUrl: url,
      builder: (context, image) => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          image: image,
        ),
        child: image != null
            ? null
            : Center(
                child: Text(
                  initials.isEmpty ? context.tr('؟') : initials,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildWalletBalanceCard() {
    return BlocBuilder<WalletCubit, WalletState>(
      builder: (context, state) {
        final balance = state.wallet?.balance ?? 0;
        return AppCard(
          radius: AppSizes.radiusXl,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  WalletPage(onBack: () => Navigator.of(context).pop()),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: AppSizes.md),
              Expanded(
                child: Text(
                  context.tr('رصيد المحفظة'),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                state.status == WalletStatus.loading
                    ? '...'
                    : context.trArgs('{p0} ر.س', {'p0': money(balance)}),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.foreground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserCard() {
    return AppCard(
      radius: AppSizes.radiusXl,
      child: Row(
        children: [
          _buildAvatar(),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                Text(context.tr('عضو في سبورتا'), style: AppTextStyles.caption),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => widget.onNavigate?.call('account-settings'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.xs,
              ),
            ),
            child: Text(
              context.tr('تعديل'),
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(String role) {
    final user = context.auth.user;
    final data = switch (role) {
      'player' => (
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.sports_tennis_rounded,
        title: context.tr('لاعب'),
        stat1: _playerMatchesTotal == null
            ? '${context.tr('المباريات')}: —'
            : '$_playerMatchesTotal ${context.tr('مباراة')}',
        stat2: user?.levelAssessed == true && user?.level != null
            ? playerLevelName(user!.level!, context.appSettings.language)
            : context.tr('بدون تقييم مستوى'),
        view: _ProfileView.playerDashboard,
      ),
      'coach' => (
        gradient: const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF15803D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.fitness_center_rounded,
        title: context.tr('مدرب'),
        stat1: _coachDash == null
            ? '${context.tr('الطلاب')}: —'
            : '${_coachDash!.activeStudents} ${context.tr('طالب')}',
        stat2: _coachDash == null
            ? '${context.tr('الجلسات')}: —'
            : '${_coachDash!.totalSessions} ${context.tr('جلسة')}',
        view: _ProfileView.coachDashboard,
      ),
      _ => (
        gradient: const LinearGradient(
          colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.stadium_rounded,
        title: context.tr('ملعب'),
        stat1: _venueDash == null
            ? '${context.tr('الملاعب')}: —'
            : '${_venueDash!.courtsCount} ${context.tr('ملاعب')}',
        stat2: _venueDash == null
            ? '${context.tr('حجوزات اليوم')}: —'
            : '${_venueDash!.todayBookings} ${context.tr('حجوزات اليوم')}',
        view: _ProfileView.venueDashboard,
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: AppCard(
        radius: AppSizes.radiusXl,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: data.gradient,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Icon(
                data.icon,
                color: Colors.white,
                size: AppSizes.iconMd,
              ),
            ),
            SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  SizedBox(height: AppSizes.xs),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          data.stat1,
                          style: AppTextStyles.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: AppSizes.sm),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: AppColors.mutedForeground,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: AppSizes.sm),
                      Flexible(
                        child: Text(
                          data.stat2,
                          style: AppTextStyles.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => setState(() => _view = data.view),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.xs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                context.tr('عرض الملف'),
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRoleButton(List<String> missingRoles) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: AppColors.card,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusXl),
            ),
          ),
          builder: (context) {
            return Directionality(
              textDirection: Directionality.of(context),
              child: Padding(
                padding: context
                    .safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('إضافة دور جديد'),
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    ...missingRoles.map((role) {
                      final label = switch (role) {
                        'player' => trg('لاعب'),
                        'coach' => trg('مدرب'),
                        _ => trg('ملعب'),
                      };
                      final icon = switch (role) {
                        'player' => Icons.sports_tennis_rounded,
                        'coach' => Icons.fitness_center_rounded,
                        _ => Icons.stadium_rounded,
                      };
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusLg,
                            ),
                            border: const Border.fromBorderSide(
                              BorderSide(color: AppColors.border),
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: AppColors.primary,
                            size: AppSizes.iconMd,
                          ),
                        ),
                        title: Text(label, style: AppTextStyles.body),
                        trailing: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppColors.primary,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _addRole(role);
                        },
                      );
                    }),
                    const SizedBox(height: AppSizes.sm),
                  ],
                ),
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primary,
              size: AppSizes.iconMd,
            ),
            SizedBox(width: AppSizes.sm),
            Text(
              context.tr('إضافة دور جديد'),
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    final items = [
      (
        icon: Icons.event_available_outlined,
        color: AppColors.primary,
        label: context.tr('حجوزاتي'),
        page: 'my-bookings',
        isLogout: false,
      ),
      (
        icon: Icons.favorite_border_rounded,
        color: const Color(0xFFE11D48),
        label: context.tr('الملاعب المفضلة'),
        page: 'favorite-courts',
        isLogout: false,
      ),
      (
        icon: Icons.card_membership_outlined,
        color: const Color(0xFFC88A04),
        label: context.tr('عضويات الأندية'),
        page: 'my-memberships',
        isLogout: false,
      ),
      (
        icon: Icons.workspace_premium_outlined,
        color: AppColors.brandGold,
        label: context.tr('الباقات'),
        page: 'packages',
        isLogout: false,
      ),
      (
        icon: Icons.language_rounded,
        color: const Color(0xFF2563EB),
        label: context.tr('اللغة'),
        page: 'language',
        isLogout: false,
      ),
      (
        icon: Icons.settings_outlined,
        color: const Color(0xFFEA580C),
        label: context.tr('إعدادات الحساب'),
        page: 'account-settings',
        isLogout: false,
      ),
      (
        icon: Icons.message_outlined,
        color: const Color(0xFF16A34A),
        label: context.tr('اتصل بنا'),
        page: 'contact',
        isLogout: false,
      ),
      (
        icon: Icons.star_outline_rounded,
        color: AppColors.primary,
        label: context.tr('نظام النقاط'),
        page: 'points-system',
        isLogout: false,
      ),
      (
        icon: Icons.description_outlined,
        color: const Color(0xFF9CA3AF),
        label: context.tr('الشروط والأحكام'),
        page: 'terms',
        isLogout: false,
      ),
      (
        icon: Icons.shield_outlined,
        color: const Color(0xFF9CA3AF),
        label: context.tr('سياسة الخصوصية'),
        page: 'privacy',
        isLogout: false,
      ),
      (
        icon: Icons.attach_money_rounded,
        color: const Color(0xFF9CA3AF),
        label: context.tr('سياسة الاسترجاع'),
        page: 'refund',
        isLogout: false,
      ),
      (
        icon: Icons.logout_rounded,
        color: const Color(0xFFDC2626),
        label: context.tr('تسجيل الخروج'),
        page: '',
        isLogout: true,
      ),
      // حذف الحساب — مطلوب أن يكون في متناول المستخدم مباشرة (App Store 5.1.1(v)).
      (
        icon: Icons.delete_forever_outlined,
        color: const Color(0xFFDC2626),
        label: context.tr('حذف الحساب'),
        page: 'delete-account',
        isLogout: false,
      ),
    ];

    return AppCard(
      padding: EdgeInsets.zero,
      radius: AppSizes.radiusXl,
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.xs,
                ),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.color,
                    size: AppSizes.iconSm,
                  ),
                ),
                title: Text(
                  item.label,
                  style: AppTextStyles.body.copyWith(
                    color: item.isLogout || item.page == 'delete-account'
                        ? const Color(0xFFDC2626)
                        : AppColors.secondary,
                  ),
                ),
                trailing: item.isLogout
                    ? null
                    : const DirectionalIcon(
                        rtl: Icons.chevron_left_rounded,
                        ltr: Icons.chevron_right_rounded,
                        color: AppColors.mutedForeground,
                      ),
                onTap: () async {
                  if (item.isLogout) {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(ctx.tr('logout')),
                        content: Text(ctx.tr('هل أنت متأكد من تسجيل الخروج؟')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(ctx.tr('cancel')),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.destructive,
                            ),
                            child: Text(ctx.tr('logout')),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) widget.onLogout?.call();
                  } else {
                    widget.onNavigate?.call(item.page);
                  }
                },
              ),
              if (i < items.length - 1)
                const Divider(
                  height: 1,
                  indent: AppSizes.lg,
                  endIndent: AppSizes.lg,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPlayerDashboard() {
    return Column(
      children: [
        GradientPageHeader(
          title: context.tr('profile'),
          subtitle: _userName,
          onBack: () => setState(() => _view = _ProfileView.roles),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: context
                .safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._stack([
                  _buildPlayerProfileCard(),
                  _buildLevelCard(),
                  _buildPlayerStatsCard(),
                  _buildPlayerBookingsCard(),
                  _buildWalletCard(),
                  _buildPlusCard(),
                ]),
                _buildNotificationsSection(leadingGap: AppSizes.lg),
                SizedBox(height: AppSizes.pagePadding),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerProfileCard() {
    final user = context.auth.user;
    final levelLabel = user?.levelAssessed == true && user?.level != null
        ? playerLevelName(user!.level!, context.appSettings.language)
        : context.tr('بدون تقييم مستوى');
    return AppCard(
      radius: AppSizes.radiusXl,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Center(
              child: Text(
                _userName.isNotEmpty ? _userName.substring(0, 1) : context.tr('؟'),
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.bold,
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
                  _userName,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
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
                    levelLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(context.tr('المباريات'), style: AppTextStyles.caption),
              Text(
                _playerMatchesTotal?.toString() ?? '—',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// null حين لا يوجد أي رقم بعد (لا مباريات ولا حجوزات ولا مستوى مُقيَّم).
  Widget? _buildPlayerStatsCard() {
    final user = context.auth.user;
    final hasLevel = user?.levelAssessed == true && user?.level != null;
    final loaded = _playerMatchesTotal != null && _playerBookingsTotal != null;
    if (loaded &&
        !hasLevel &&
        _playerMatchesTotal == 0 &&
        _playerBookingsTotal == 0) {
      return null;
    }
    return AppCard(
      radius: AppSizes.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('إحصائياتي'),
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          _StatRow(
            label: context.tr('المباريات'),
            value: _playerMatchesTotal?.toString() ?? '—',
          ),
          _StatRow(
            label: context.tr('حجوزات الملاعب'),
            value: _playerBookingsTotal?.toString() ?? '—',
            valueColor: AppColors.primary,
          ),
          _StatRow(
            label: context.tr('المستوى'),
            value: user?.levelAssessed == true && user?.level != null
                ? playerLevelName(user!.level!, context.appSettings.language)
                : context.tr('بدون تقييم'),
            valueColor: const Color(0xFF16A34A),
            isLast: true,
          ),
        ],
      ),
    );
  }

  /// The player's latest court bookings from `/bookings/me` (top 3), with a
  /// "view all" shortcut to the full bookings page.
  Widget? _buildPlayerBookingsCard() {
    final bookings = _recentBookings;
    if (bookings != null && bookings.isEmpty) return null;
    return AppCard(
      radius: AppSizes.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.tr('حجوزاتي الحالية'),
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => widget.onNavigate?.call('my-bookings'),
                child: Text(
                  context.tr('عرض الكل'),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          if (bookings == null)
            _skeletonBlocks()
          else
            ...List.generate(bookings.length, (i) {
              final b = bookings[i];
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                b.venueName,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                            _bookingStatusBadge(b.status),
                          ],
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Wrap(
                          spacing: AppSizes.md,
                          runSpacing: AppSizes.xs,
                          children: [
                            _BookingChip(
                              icon: Icons.sports_tennis_rounded,
                              label: b.courtName,
                            ),
                            _BookingChip(
                              icon: Icons.calendar_today_outlined,
                              label: _bookingWhen(b.startTime),
                            ),
                            _BookingChip(
                              icon: Icons.timer_outlined,
                              label:
                                  '${b.durationMinutes} ${context.tr('دقيقة')}',
                            ),
                            _BookingChip(
                              icon: Icons.attach_money_rounded,
                              label: '${b.totalPrice} ${context.tr('ر.س')}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (i < bookings.length - 1)
                    const SizedBox(height: AppSizes.sm),
                ],
              );
            }),
        ],
      ),
    );
  }

  String _bookingWhen(DateTime d) =>
      '${d.year}/${d.month}/${d.day} · '
      '${d.hour % 12 == 0 ? 12 : d.hour % 12}:'
      '${d.minute.toString().padLeft(2, '0')} ${AppDates.period(d)}';

  Widget _bookingStatusBadge(String status) {
    final (label, color, bg) = switch (status) {
      'Confirmed' => (
        trg('مؤكدة'),
        const Color(0xFF16A34A),
        const Color(0xFFF0FDF4),
      ),
      'Pending' => (
        trg('في الانتظار'),
        const Color(0xFFD97706),
        const Color(0xFFFFFBEB),
      ),
      'Cancelled' => (
        trg('ملغاة'),
        const Color(0xFFDC2626),
        const Color(0xFFFEF2F2),
      ),
      'Completed' => (
        trg('مكتملة'),
        const Color(0xFF2563EB),
        const Color(0xFFEFF6FF),
      ),
      _ => (status, AppColors.mutedForeground, AppColors.background),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        context.tr(label),
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// The player's own upcoming matches (joined/created, not yet completed),
  /// nearest first.
  Widget? _buildUpcomingMatchesCard() {
    final matches = _upcomingMatches;
    if (matches != null && matches.isEmpty) return null;
    return AppCard(
      radius: AppSizes.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Expanded (not Spacer): عنوان طويل — بالإنجليزية مثلاً — يجب أن
              // يُقصَّ لا أن يدفع زر "عرض الكل" خارج البطاقة.
              Expanded(
                child: Text(
                  context.tr('مبارياتي القادمة'),
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => widget.onNavigate?.call('matches'),
                child: Text(
                  context.tr('عرض الكل'),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          if (matches == null)
            _skeletonBlocks()
          else
            ...List.generate(matches.length, (i) {
              final m = matches[i];
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusFull,
                                ),
                              ),
                              child: Text(
                                m.typeLabel,
                                style: AppTextStyles.caption.copyWith(
                                  color: const Color(0xFF2563EB),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          m.venueName ?? context.tr('بدون ملعب محدد'),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Wrap(
                          spacing: AppSizes.md,
                          runSpacing: AppSizes.xs,
                          children: [
                            _BookingChip(
                              icon: Icons.calendar_today_outlined,
                              label: _bookingWhen(m.scheduledAt),
                            ),
                            _BookingChip(
                              icon: Icons.people_outline,
                              label:
                                  '${m.currentPlayers}/${m.maxPlayers} ${context.tr('لاعب')}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (i < matches.length - 1)
                    const SizedBox(height: AppSizes.sm),
                ],
              );
            }),
        ],
      ),
    );
  }

  /// The player's most recent completed matches with their recorded score.
  Widget? _buildRecentResultsCard() {
    final results = _recentResults;
    if (results != null && results.isEmpty) return null;
    return AppCard(
      radius: AppSizes.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('آخر النتائج'),
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          if (results == null)
            _skeletonBlocks()
          else
            ...List.generate(results.length, (i) {
              final m = results[i];
              final hasScore = m.team1Score != null && m.team2Score != null;
              final me = int.tryParse(getIt<AuthCubit>().user?.id ?? '') ?? 0;
              final outcome = outcomeFor(m, me);
              // النتيجة من طرفي: فريقي أولاً (6 - 3 فوزاً لا 3 - 6).
              final myTeam = m.players.where((p) => p.userId == me).firstOrNull?.team;
              final score = myTeam == 2
                  ? '${m.team2Score} - ${m.team1Score}'
                  : '${m.team1Score} - ${m.team2Score}';
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i < results.length - 1 ? AppSizes.sm : 0,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => MatchDetailPage(matchId: m.id))),
                  child: Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasScore
                                  ? score
                                  : context.tr('لم تُسجَّل النتيجة'),
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_bookingWhen(m.scheduledAt)} · ${m.venueName ?? context.tr('بدون ملعب محدد')}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (outcome != null) OutcomePill(outcome: outcome),
                      const SizedBox(width: AppSizes.xs),
                      const DirectionalIcon(
                          rtl: Icons.chevron_left,
                          ltr: Icons.chevron_right,
                          color: AppColors.mutedForeground),
                    ],
                  ),
                ),
                ),
              );
            }),
        ],
      ),
    );
  }

  /// The player's accepted friends, with a heart toggle for favoriting a
  /// partner (drives [_buildFavoritesCard]).
  Widget? _buildFriendsCard() {
    final friends = _friends;
    if (friends != null && friends.isEmpty) return null;
    return AppCard(
      radius: AppSizes.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.tr('قائمة الأصدقاء'),
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const Spacer(),
              if (friends != null)
                Text(
                  '${friends.length} ${context.tr('صديق')}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          if (friends == null)
            _skeletonRows()
          else
            ...List.generate(friends.take(5).length, (i) {
              final f = friends[i];
              return Padding(
                padding: EdgeInsets.only(bottom: i < 4 ? AppSizes.sm : 0),
                child: _friendTile(f),
              );
            }),
          if (friends != null && friends.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.sm),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FriendsPage(
                        onBack: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  child: Text(
                    context.tr('عرض جميع الأصدقاء'),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Friends the player marked as a favorite partner (heart-toggled above).
  Widget? _buildFavoritesCard() {
    final friends = _friends;
    final favorites = friends?.where((f) => f.isFavorite).toList();
    if (favorites != null && favorites.isEmpty) return null;
    return AppCard(
      radius: AppSizes.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.tr('القائمة المفضلة'),
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const Spacer(),
              if (favorites != null)
                Text(
                  '${favorites.length} ${context.tr('مفضلين')}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          if (favorites == null)
            _skeletonRows()
          else
            ...List.generate(favorites.length, (i) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i < favorites.length - 1 ? AppSizes.sm : 0,
                ),
                child: _friendTile(favorites[i]),
              );
            }),
        ],
      ),
    );
  }

  Widget _friendTile(PlayerSummary f) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              f.initials,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                if (f.level != null)
                  Text(
                    '${context.tr('مستوى')} ${f.level}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _toggleFavoriteFriend(f),
            icon: Icon(
              f.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: f.isFavorite
                  ? Colors.pinkAccent
                  : AppColors.mutedForeground,
              size: AppSizes.iconMd,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavoriteFriend(PlayerSummary f) async {
    final next = !f.isFavorite;
    setState(() {
      _friends = _friends
          ?.map((p) => p.userId == f.userId ? p.copyWith(isFavorite: next) : p)
          .toList();
    });
    try {
      await getIt<FriendRepository>().toggleFavorite(f.userId, next);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _friends = _friends
            ?.map(
              (p) => p.userId == f.userId ? p.copyWith(isFavorite: !next) : p,
            )
            .toList();
      });
    }
  }

  /// Shows the player's level (from the authenticated user). Mirrors the card
  /// that used to live on the home dashboard.
  Widget _buildLevelCard() {
    final user = context.auth.user;
    if (user?.levelAssessed != true || user?.level == null) {
      return const SizedBox.shrink();
    }
    final level = user!.level!;
    final name = playerLevelName(level, context.appSettings.language);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$level',
              style: AppTextStyles.heading1.copyWith(
                color: Colors.white,
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('yourLevel'),
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                name,
                style: AppTextStyles.heading2.copyWith(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    return AppCard(
      radius: AppSizes.radiusXl,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WalletPage(onBack: () => Navigator.of(context).pop()),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: AppSizes.iconMd,
            ),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('محفظتي'), style: AppTextStyles.caption),
                Text(
                  context.tr('عرض الرصيد والمعاملات'),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => widget.onNavigate?.call('top-up-wallet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
            ),
            child: Text(context.tr('شحن الرصيد')),
          ),
        ],
      ),
    );
  }

  /// مدخل شاشة «الاشتراكات» (الأنواع الشهرية/السنوية التي يديرها الأدمن).
  Widget _buildPlusCard() {
    return AppCard(
      radius: AppSizes.radiusXl,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              SubscriptionPage(onBack: () => Navigator.of(context).pop()),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.brandGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: AppColors.brandGold,
              size: AppSizes.iconMd,
            ),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('الاشتراكات'),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  context.tr('اشتراك شهري أو سنوي بمزايا وخصومات'),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          DirectionalIcon(
            rtl: Icons.chevron_left,
            ltr: Icons.chevron_right,
            color: AppColors.mutedForeground,
          ),
        ],
      ),
    );
  }

  /// Recent notifications pulled from the real API. Tapping "عرض الكل" opens
  /// the full [NotificationsPage]; tapping an item marks it read.
  /// إشعارات الحساب — تُخفى بالكامل حين لا توجد إشعارات. حالتها تُجلب داخلياً،
  /// فتحمل [leadingGap] معها حتى لا تبقى فجوة مكانها عند الإخفاء.
  Widget _buildNotificationsSection({double leadingGap = 0}) {
    return BlocProvider<NotificationsCubit>(
      create: (_) => getIt<NotificationsCubit>()..load(),
      child: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          final items = state.items;
          final preview = items.take(4).toList();
          final loading =
              state.status == NotificationsStatus.loading && items.isEmpty;
          if (!loading && preview.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leadingGap > 0) SizedBox(height: leadingGap),
              Row(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.secondary,
                    size: AppSizes.iconMd,
                  ),
                  SizedBox(width: AppSizes.sm),
                  Text(
                    context.tr('الإشعارات'),
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  SizedBox(width: AppSizes.sm),
                  if (state.unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusFull,
                        ),
                      ),
                      child: Text(
                        '${state.unread}',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (items.isNotEmpty)
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => NotificationsPage(
                            onBack: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                      child: Text(
                        context.tr('عرض الكل'),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: AppSizes.md),
              if (loading)
                const SkeletonList(
                    itemCount: 3, shrinkWrap: true, padding: EdgeInsets.zero)
              else
                ...preview.map(
                  (n) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.sm),
                    child: _buildNotificationCard(
                      n,
                      () => _onNotificationTap(context, n),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Marks a notification read and opens the screen it refers to, based on its
  /// type (friend requests → friends, match/americano → their detail pages,
  /// bookings → my bookings).
  void _onNotificationTap(BuildContext context, NotificationEntity n) {
    if (!n.isRead) context.read<NotificationsCubit>().markRead(n.id);
    final type = n.type ?? '';
    final ref = n.referenceId;

    if (type.startsWith('friend_') || type == 'follow') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              FriendsPage(onBack: () => Navigator.of(context).pop()),
        ),
      );
    } else if ((type == 'review_match' || type == 'court_rating') && ref != null) {
      openReviewSheet(context, ReviewContext.match, ref);
    } else if (type == 'review_booking' && ref != null) {
      openReviewSheet(context, ReviewContext.booking, ref);
    } else if (type == 'review_session' && ref != null) {
      openReviewSheet(context, ReviewContext.session, ref);
    } else if (type == 'court_rated' && ref != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => CourtReviewsPage(courtId: ref)),
      );
    } else if (type.startsWith('venue_') || type.startsWith('court_')) {
      // Admin moderation of a venue/court — open the owner's venues management.
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ManageVenuesPage(onBack: () => Navigator.of(context).pop()),
        ),
      );
    } else if (type == 'membership_new' && ref != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VenueMembershipsPage(venueId: ref),
        ),
      );
    } else if (type.startsWith('membership_')) {
      widget.onNavigate?.call('my-memberships');
    } else if (type.startsWith('booking_')) {
      widget.onNavigate?.call('my-bookings');
    } else if (type == 'event_chat' && ref != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => EventChatPage(matchId: ref)),
      );
    } else if ((type.startsWith('americano_') || type.startsWith('tournament_')) && ref != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AmericanoDetailPage(
            americanoId: ref,
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } else if (type.startsWith('match_') && ref != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => MatchDetailPage(matchId: ref)),
      );
    }
  }

  Widget _buildNotificationCard(NotificationEntity n, VoidCallback onTap) {
    final isUnread = !n.isRead;
    final (icon, iconColor, iconBg) = switch (n.type) {
      'friend_request' || 'friend_accept' => (
        Icons.person_add_outlined,
        const Color(0xFF2563EB),
        const Color(0xFFEFF6FF),
      ),
      'match_invite' || 'match_join' => (
        Icons.sports_tennis_rounded,
        const Color(0xFF16A34A),
        const Color(0xFFF0FDF4),
      ),
      'follow' => (
        Icons.group_add_outlined,
        const Color(0xFFEA580C),
        const Color(0xFFFFF7ED),
      ),
      _ => (
        Icons.notifications_outlined,
        AppColors.primary,
        AppColors.primary.withValues(alpha: 0.1),
      ),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      child: AppCard(
        radius: AppSizes.radiusXl,
        color: isUnread
            ? AppColors.primary.withValues(alpha: 0.04)
            : AppColors.card,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Icon(icon, color: iconColor, size: AppSizes.iconMd),
            ),
            SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (n.body.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(n.body, style: AppTextStyles.caption),
                  ],
                  SizedBox(height: AppSizes.xs),
                  Text(
                    _relativeTime(n.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Short Arabic relative-time label (e.g. "منذ 5 دقائق").
  String _relativeTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return trg('الآن');
    if (d.inMinutes < 60) return trgArgs('منذ {p0} دقيقة', {'p0': d.inMinutes});
    if (d.inHours < 24) return trgArgs('منذ {p0} ساعة', {'p0': d.inHours});
    return trgArgs('منذ {p0} يوم', {'p0': d.inDays});
  }

  Widget _buildCoachDashboard() {
    return Column(
      children: [
        GradientPageHeader(
          title: context.tr('لوحة المدرب'),
          onBack: () => setState(() => _view = _ProfileView.roles),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: context
                .safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._stack([
                  _buildCoachProfileCard(),
                  _buildCoachStatsRow(),
                  _buildManageTraineesReportsBanner(),
                  _buildCoachTraineesSection(),
                  const CoachOffersSection(),
                  _buildCoachRevenueCard(),
                ], gap: AppSizes.xl),
                _buildNotificationsSection(leadingGap: AppSizes.xl),
                const SizedBox(height: AppSizes.xl),
                _buildCoachWalletSection(),
                const SizedBox(height: AppSizes.xl),
                Text(
                  context.tr('الإعدادات العامة'),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                _buildCoachSettingsSection(),
                SizedBox(height: AppSizes.pagePadding),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Coach-only settings: profile editing and level-assessment requests.
  Widget _buildCoachSettingsSection() {
    final items = [
      (
        icon: Icons.manage_accounts_outlined,
        color: const Color(0xFF16A34A),
        label: context.tr('تعديل الملف الشخصي'),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CoachProfileEditPage())),
      ),
      (
        icon: Icons.grading_outlined,
        color: const Color(0xFF2563EB),
        label: context.tr('طلبات تقييم المستوى'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PendingAssessmentsPage()),
        ),
      ),
      // نفس شاشة اشتراكات اللاعب — الاشتراك متاح لكل الأدوار.
      (
        icon: Icons.workspace_premium_outlined,
        color: AppColors.brandGold,
        label: context.tr('الاشتراكات'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                SubscriptionPage(onBack: () => Navigator.of(context).pop()),
          ),
        ),
      ),
    ];

    return AppCard(
      padding: EdgeInsets.zero,
      radius: AppSizes.radiusXl,
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.xs,
                ),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.color,
                    size: AppSizes.iconSm,
                  ),
                ),
                title: Text(
                  item.label,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                trailing: const DirectionalIcon(
                  rtl: Icons.chevron_left_rounded,
                  ltr: Icons.chevron_right_rounded,
                  color: AppColors.mutedForeground,
                ),
                onTap: item.onTap,
              ),
              if (i < items.length - 1)
                const Divider(
                  height: 1,
                  indent: AppSizes.lg,
                  endIndent: AppSizes.lg,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCoachProfileCard() {
    final d = _coachDash;
    return AppCard(
      radius: AppSizes.radiusXl,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Center(
              child: Text(
                _userName.isNotEmpty ? _userName.substring(0, 1) : context.tr('؟'),
                style: AppTextStyles.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
                  _userName,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                SizedBox(height: AppSizes.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Color(0xFFD97706),
                    ),
                    SizedBox(width: 2),
                    Text(
                      d == null ? '—' : d.rating.toStringAsFixed(1),
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(context.tr('طالب مسجل'), style: AppTextStyles.caption),
              Text(
                d?.activeStudents.toString() ?? '—',
                style: AppTextStyles.heading2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _buildCoachStatsRow() {
    final d = _coachDash;
    if (d != null &&
        d.totalSessions == 0 &&
        d.activeStudents == 0 &&
        d.rating == 0) {
      return null;
    }
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            value: d?.totalSessions.toString() ?? '—',
            label: context.tr('حصة تدريبية'),
            color: const Color(0xFF2563EB),
            bg: const Color(0xFFEFF6FF),
          ),
        ),
        SizedBox(width: AppSizes.sm),
        Expanded(
          child: _StatChip(
            value: d == null ? '—' : d.rating.toStringAsFixed(1),
            label: context.tr('التقييم'),
            color: const Color(0xFFD97706),
            bg: const Color(0xFFFFFBEB),
          ),
        ),
        SizedBox(width: AppSizes.sm),
        Expanded(
          child: _StatChip(
            value: d?.activeStudents.toString() ?? '—',
            label: context.tr('متدرب'),
            color: const Color(0xFF16A34A),
            bg: const Color(0xFFF0FDF4),
          ),
        ),
      ],
    );
  }

  /// Combined nav card to student management (إدارة الطلاب) — the "تقارير"
  /// half is reachable from the الإيرادات card's "تفاصيل الإيرادات" link below.
  Widget _buildManageTraineesReportsBanner() {
    final d = _coachDash;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CoachStudentsPage())),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.groups_outlined, color: Colors.white),
              ),
              SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('إدارة المتدربين والتقارير'),
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${d?.activeStudents ?? 0} ${context.tr('متدرب نشط')}',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const DirectionalIcon(
                rtl: Icons.chevron_left_rounded,
                ltr: Icons.chevron_right_rounded,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildCoachRevenueCard() {
    final d = _coachDash;
    if (d != null && d.totalRevenue == 0 && d.monthRevenue == 0) return null;
    return AppCard(
      radius: AppSizes.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('الإيرادات'),
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CoachRevenuePage(
                      onBack: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                child: Text(
                  context.tr('تفاصيل الإيرادات'),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d == null
                            ? '—'
                            : '${money(d.totalRevenue)} ${context.tr('ر.س')}',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                      Text(
                        context.tr('الإجمالي'),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: AppSizes.sm),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d == null
                            ? '—'
                            : '${money(d.monthRevenue)} ${context.tr('ر.س')}',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                      Text(
                        context.tr('هذا الشهر'),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// المحفظة — available balance plus quick top-up/withdraw actions, sharing
  /// the [WalletCubit] provided at the page root.
  Widget _buildCoachWalletSection() {
    return BlocBuilder<WalletCubit, WalletState>(
      builder: (context, state) {
        final wallet = state.wallet;
        final balance = wallet?.balance ?? 0;
        final canWithdraw = wallet?.canWithdraw ?? false;
        return AppCard(
          radius: AppSizes.radiusXl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('المحفظة'),
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              SizedBox(height: AppSizes.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Column(
                  children: [
                    Text(
                      context.tr('الرصيد المتاح'),
                      style: AppTextStyles.caption,
                    ),
                    SizedBox(height: AppSizes.xs),
                    Text(
                      state.status == WalletStatus.loading
                          ? '...'
                          : '${money(balance)} ${context.tr('ر.س')}',
                      style: AppTextStyles.heading1.copyWith(
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSizes.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: !canWithdraw
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => WithdrawWalletPage(
                                  wallet: wallet!,
                                  onBack: () => Navigator.of(context).pop(),
                                  onComplete: () => Navigator.of(context).pop(),
                                ),
                              ),
                            ),
                      child: Text(context.tr('سحب الرصيد')),
                    ),
                  ),
                  SizedBox(width: AppSizes.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TopUpWalletPage(
                            currentBalance: balance.round(),
                            onBack: () => Navigator.of(context).pop(),
                            onComplete: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(context.tr('شحن الرصيد')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Upcoming coach sessions from the live dashboard feed.
  Widget? _buildCoachTraineesSection() {
    final sessions = _coachDash?.upcomingSessions ?? const [];
    if (_coachDash != null && sessions.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('الجلسات القادمة'),
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        if (_coachDash == null)
          const SkeletonList(
              itemCount: 2, shrinkWrap: true, padding: EdgeInsets.zero)
        else
          AppCard(
            padding: EdgeInsets.zero,
            radius: AppSizes.radiusXl,
            child: Column(
              children: List.generate(sessions.length, (i) {
                final s = sessions[i];
                final name = s.playerName ?? s.title;
                return Column(
                  children: [
                    InkWell(
                      onTap: () async {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => CoachBookingDetailPage(session: s),
                          ),
                        );
                        if (changed == true) _loadCoachDashboard();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.lg),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF16A34A),
                                    Color(0xFF15803D),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusFull,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  name.isNotEmpty ? name.substring(0, 1) : context.tr('؟'),
                                  style: AppTextStyles.body.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
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
                                    name,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                  SizedBox(height: AppSizes.xs),
                                  Text(
                                    '${_bookingWhen(s.scheduledAt)} · '
                                    '${s.durationMinutes} ${context.tr('دقيقة')}',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${money(s.price)} ${context.tr('ر.س')}',
                              style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFF16A34A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (i < sessions.length - 1)
                      const Divider(
                        height: 1,
                        indent: AppSizes.lg,
                        endIndent: AppSizes.lg,
                      ),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildVenueDashboard() {
    return Column(
      children: [
        GradientPageHeader(
          title: context.tr('لوحة المنشأة'),
          onBack: () => setState(() => _view = _ProfileView.roles),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: context
                .safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._stack([
                  _buildVenueProfileCard(),
                  _buildVenueStatsRow(),
                  _buildCourtsSection(),
                ]),
                const SizedBox(height: AppSizes.pagePadding),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVenueProfileCard() {
    final venue = (_venues?.isNotEmpty ?? false) ? _venues!.first : null;
    return AppCard(
      radius: AppSizes.radiusXl,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: const Icon(
              Icons.stadium_rounded,
              color: Colors.white,
              size: AppSizes.iconMd,
            ),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venue?.name ?? _userName,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                SizedBox(height: AppSizes.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.mutedForeground,
                    ),
                    SizedBox(width: 2),
                    Text(venue?.city ?? '—', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildVenueStatsRow() {
    final d = _venueDash;
    if (d != null &&
        d.courtsCount == 0 &&
        d.todayBookings == 0 &&
        d.monthRevenue == 0) {
      return null;
    }
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            value: d?.courtsCount.toString() ?? '—',
            label: context.tr('الملاعب النشطة'),
            color: const Color(0xFF2563EB),
            bg: const Color(0xFFEFF6FF),
          ),
        ),
        SizedBox(width: AppSizes.sm),
        Expanded(
          child: _StatChip(
            value: d?.todayBookings.toString() ?? '—',
            label: context.tr('الحجوزات اليوم'),
            color: const Color(0xFF16A34A),
            bg: const Color(0xFFF0FDF4),
          ),
        ),
        SizedBox(width: AppSizes.sm),
        Expanded(
          child: _StatChip(
            value: d == null ? '—' : money(d.monthRevenue),
            label: context.tr('الإيراد الشهري ر.س'),
            color: const Color(0xFFEA580C),
            bg: const Color(0xFFFFF7ED),
          ),
        ),
      ],
    );
  }

  /// The owner's real courts (from `/venues/mine`), expandable to show the
  /// configured booking duration→price tiers.
  Widget? _buildCourtsSection() {
    final venues = _venues;
    final courts = venues == null
        ? null
        : [
            for (final v in venues)
              for (final c in v.courts) (venue: v, court: c),
          ];
    if (courts != null && courts.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('الملاعب'),
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        if (courts == null)
          const SkeletonList(
              itemCount: 2, shrinkWrap: true, padding: EdgeInsets.zero)
        else
          ...List.generate(courts.length, (i) {
            final entry = courts[i];
            return Padding(
              padding: EdgeInsets.only(
                bottom: i < courts.length - 1 ? AppSizes.md : 0,
              ),
              child: _buildCourtItem(index: i, entry: entry),
            );
          }),
      ],
    );
  }

  Widget _buildCourtItem({
    required int index,
    required ({OwnerVenue venue, OwnerCourt court}) entry,
  }) {
    final court = entry.court;
    final isExpanded = _expandedCourts.contains(index);
    final typeLabel = court.type == 'indoor'
        ? context.tr('داخلي')
        : context.tr('خارجي');
    return AppCard(
      padding: EdgeInsets.zero,
      radius: AppSizes.radiusXl,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(
              () => isExpanded
                  ? _expandedCourts.remove(index)
                  : _expandedCourts.add(index),
            ),
            borderRadius: isExpanded
                ? const BorderRadius.vertical(
                    top: Radius.circular(AppSizes.radiusXl),
                  )
                : BorderRadius.circular(AppSizes.radiusXl),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
                    child: const Icon(
                      Icons.sports_tennis_rounded,
                      color: Color(0xFFEA580C),
                      size: AppSizes.iconMd,
                    ),
                  ),
                  SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${court.name} · ${entry.venue.name}',
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        SizedBox(height: AppSizes.xs),
                        Row(
                          children: [
                            _CourtBadge(label: typeLabel),
                            SizedBox(width: AppSizes.xs),
                            _CourtBadge(
                              label: court.isAvailable
                                  ? context.tr('نشط')
                                  : context.tr('موقوف'),
                              isActive: court.isAvailable,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('الأوقات والأسعار'),
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  SizedBox(height: AppSizes.sm),
                  if (court.bookingTiers.isEmpty)
                    Text(
                      '${context.tr('السعر بالساعة')}: '
                      '${money(court.pricePerHour)} ${context.tr('ر.س')}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondary,
                      ),
                    )
                  else
                    ...court.bookingTiers.map(
                      (tier) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.xs),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEA580C),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: AppSizes.sm),
                            Text(
                              '${tier.durationMinutes} ${context.tr('دقيقة')}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.secondary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${money(tier.price)} ${context.tr('ر.س')}',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.bodySmall),
              Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
  });

  final String value;
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.md,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BookingChip extends StatelessWidget {
  const _BookingChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.mutedForeground),
        SizedBox(width: 3),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 12)),
      ],
    );
  }
}

class _CourtBadge extends StatelessWidget {
  const _CourtBadge({required this.label, this.isActive = false});
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xs, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF0FDF4) : AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(
          color: isActive ? const Color(0xFF22C55E) : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: isActive ? const Color(0xFF16A34A) : AppColors.mutedForeground,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// هيكل صفوف داخل بطاقة (حجوزات، مباريات، نتائج): كتل بخلفية الصف نفسه.
Widget _skeletonBlocks({int count = 2}) {
  return Shimmer(
    child: Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          const SkeletonBox(height: 64, radius: AppSizes.radiusLg),
          if (i != count - 1) const SizedBox(height: AppSizes.sm),
        ],
      ],
    ),
  );
}

/// هيكل صفوف أشخاص داخل بطاقة (الأصدقاء، المفضلة): صورة + سطران.
Widget _skeletonRows({int count = 3}) {
  return Shimmer(
    child: Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          Row(
            children: [
              const SkeletonBox.circle(size: 40),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 12, width: i.isEven ? 130 : 100),
                    const SizedBox(height: AppSizes.sm),
                    const SkeletonBox(height: 10, width: 70),
                  ],
                ),
              ),
            ],
          ),
          if (i != count - 1) const SizedBox(height: AppSizes.md),
        ],
      ],
    ),
  );
}
