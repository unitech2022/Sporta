import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../reviews/presentation/widgets/review_prompt_card.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/tinted_card.dart';
import '../../../ads/data/ad_repository.dart';
import '../../../ads/domain/ad_entity.dart';
import '../../../ads/presentation/widgets/ad_slider.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../../courts/data/court_repository.dart';
import '../../../courts/domain/entities/court_entity.dart';
import '../../../courts/presentation/pages/court_detail_page.dart';
import '../../../friends/data/friend_repository.dart';
import '../../../friends/domain/entities/feed_item.dart';
import '../../../friends/domain/entities/player_summary.dart';
import '../../../friends/presentation/cubit/feed_cubit.dart';
import '../../../friends/presentation/pages/feed_page.dart';
import '../../../friends/presentation/pages/players_page.dart';
import 'players_section.dart';
import '../../../matches/data/match_repository.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../../../matches/presentation/pages/match_detail_page.dart';
import '../../../americano/data/americano_repository.dart';
import '../../../americano/domain/entities/americano_entity.dart';
import '../../../americano/presentation/pages/americano_detail_page.dart';
import '../../data/pulse_repository.dart';
import '../../domain/pulse_item.dart';
import '../pages/pulse_page.dart';
import 'pulse_section.dart';
import 'tournaments_section.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../points/presentation/pages/leaderboard_page.dart';
import '../../../points/presentation/widgets/leaderboard_board.dart';
import '../../../../core/localization/app_dates.dart';
import 'package:sporta_app/core/utils/server_time.dart';

const _blue = Color(0xFF3B82F6);
const _green = Color(0xFF22C55E);
const _orange = Color(0xFFF97316);
const _purple = Color(0xFFA855F7);
const _yellow = Color(0xFFEAB308);

/// Player home dashboard: promo slider, nearby matches, courts map, nearest
/// courts, friend activity and friend suggestions.
class PlayerDashboard extends StatefulWidget {
  const PlayerDashboard({super.key, required this.onNavigate});

  /// Switches the bottom-nav tab ('matches' | 'courts' | ...).
  final void Function(String page) onNavigate;

  @override
  State<PlayerDashboard> createState() => _PlayerDashboardState();
}

class _PlayerDashboardState extends State<PlayerDashboard> {
  final _friendRepo = getIt<FriendRepository>();
  final _matchRepo = getIt<MatchRepository>();
  final _courtRepo = getIt<CourtRepository>();
  final _adRepo = getIt<AdRepository>();
  final _pulseRepo = getIt<PulseRepository>();
  final _americanoRepo = getIt<AmericanoRepository>();
  late final FeedCubit _feedCubit;

  /// Community pulse — only the first few are shown here; "عرض الكل" opens the
  /// full list.
  List<PulseItem> _pulse = [];
  bool _pulseLoading = true;

  /// Playable tournaments (americano with `isTournament`), upcoming only.
  List<AmericanoEntity> _tournaments = [];
  bool _tournamentsLoading = true;

  List<AdEntity> _ads = [];
  bool _adsLoading = true;

  final Set<int> _friendRequests = {};
  List<PlayerSummary> _suggestions = [];
  bool _suggestionsLoading = true;

  List<MatchEntity> _matches = [];
  bool _matchesLoading = true;

  /// The player's own match(es) starting within 30 minutes — shown as a
  /// prominent card at the very top of the home page.
  List<MatchEntity> _upcoming = [];
  Timer? _upcomingTicker;

  List<CourtEntity> _courts = [];
  bool _courtsLoading = true;

  static const _feedColors = [_blue, _orange, _yellow, _green, _purple];

  @override
  void initState() {
    super.initState();
    _feedCubit = getIt<FeedCubit>()..load();
    _loadAds();
    _loadSuggestions();
    _loadMatches();
    _loadUpcoming();
    _loadCourts();
    _loadPulse();
    _loadTournaments();
    // Refresh the countdown every minute so "starts in X min" stays accurate
    // and the card drops off once the window passes.
    _upcomingTicker = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _loadUpcoming(),
    );
  }

  Future<void> _loadUpcoming() async {
    try {
      final items = await _matchRepo.fetchUpcomingMatches();
      if (!mounted) return;
      setState(() => _upcoming = items);
    } catch (_) {
      // Silent: the card is optional and simply hides if it can't load.
    }
  }

  Future<void> _loadAds() async {
    try {
      final items = await _adRepo.fetchAds(page: AdPlacements.home);
      if (!mounted) return;
      setState(() {
        _ads = items;
        _adsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _adsLoading = false);
    }
  }

  @override
  void dispose() {
    _upcomingTicker?.cancel();
    _feedCubit.close();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    try {
      // كل اللاعبين مرتّبين بالأقرب (الترتيب من الخادم)، لا المقترحون وحدهم.
      final items = await _friendRepo.searchPlayers('');
      if (!mounted) return;
      setState(() {
        _suggestions = items;
        _suggestionsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _suggestionsLoading = false);
    }
  }

  Future<void> _loadMatches() async {
    try {
      // Dashboard preview: the first page is plenty (only 2 are shown).
      final items = (await _matchRepo.fetchMatches()).items;
      if (!mounted) return;
      setState(() {
        // Available = open with a free spot, not yet joined.
        _matches = items
            .where((m) => m.status == 'Open' && !m.isFull && !m.hasJoined)
            .toList();
        _matchesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _matchesLoading = false);
    }
  }

  Future<void> _loadCourts() async {
    try {
      // Dashboard preview: the first page is plenty (only 4 are shown).
      final items = (await _courtRepo.fetchCourts()).items;
      if (!mounted) return;
      setState(() {
        _courts = items;
        _courtsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _courtsLoading = false);
    }
  }

  Future<void> _loadPulse() async {
    try {
      final items = await _pulseRepo.fetchPulse();
      if (!mounted) return;
      setState(() {
        _pulse = items;
        _pulseLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _pulseLoading = false);
    }
  }

  Future<void> _loadTournaments() async {
    try {
      final page = await _americanoRepo.fetchAll(kind: 'tournament');
      if (!mounted) return;
      // The endpoint returns every tournament newest-created first; the home
      // preview only wants the ones still ahead, soonest first.
      final now = ksaNow();
      final today = DateTime(now.year, now.month, now.day);
      final upcoming = page.items.where((a) {
        if (a.isCompleted) return false;
        final last = a.endDate ?? a.scheduledAt;
        return !DateTime(last.year, last.month, last.day).isBefore(today);
      }).toList()..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      setState(() {
        _tournaments = upcoming;
        _tournamentsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _tournamentsLoading = false);
    }
  }

  Future<void> _sendFriendRequest(int userId) async {
    setState(() => _friendRequests.add(userId));
    try {
      await _friendRepo.sendRequest(userId);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _friendRequests.remove(userId));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  void _openMatch(int id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MatchDetailPage(matchId: id)),
    );
  }

  void _openTournament(int id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AmericanoDetailPage(
          americanoId: id,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _openCourt(String id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => CourtDetailPage(courtId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_upcoming.isNotEmpty) ...[
            for (final m in _upcoming) ...[
              _UpcomingMatchCard(match: m, onTap: () => _openMatch(m.id)),
              const SizedBox(height: AppSizes.lg),
            ],
            const SizedBox(height: AppSizes.md),
          ],
          // «كيف كانت تجربتك؟» لآخر تجربة انتهت وفيها أطراف لم تُقيَّم —
          // تخفي نفسها إن لم يوجد شيء (ومنه الزائر).
          const PendingReviewsCard(
            padding: EdgeInsets.only(bottom: AppSizes.xl),
          ),
          if (_ads.isNotEmpty) ...[
            AdSlider(ads: _ads, onNavigate: widget.onNavigate),
            const SizedBox(height: AppSizes.xxl),
          ] else if (_adsLoading) ...[
            const Shimmer(
              child: SkeletonBox(height: 180, radius: AppSizes.radiusXl),
            ),
            const SizedBox(height: AppSizes.xxl),
          ],
          // الأقسام الفارغة لا تُعرض أصلاً: كل قسم يخفي نفسه بعد التحميل حين
          // لا بيانات لديه، ويحمل مسافته السفلية معه فلا تبقى فجوة مكانه.
          _buildMatches(),
          _buildCourtsMap(),
          _buildNearestCourts(),
          _buildFeedSection(),
          _buildPulse(),
          _buildLeaderboard(),
          _buildTournaments(),
          _buildSuggestions(),
        ],
      ),
    );
  }

  // ── Nearby matches ──────────────────────────────────────────────────────
  Widget _buildMatches() {
    final shown = _matches.take(2).toList();
    if (!_matchesLoading && shown.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          trg('مباريات قريبة متاحة'),
          onViewAll: () => widget.onNavigate('matches'),
        ),
        if (_matchesLoading)
          const SkeletonList(
            itemCount: 2,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
          )
        else
          for (var i = 0; i < shown.length; i++) ...[
            _MatchCard(match: shown[i], onTap: () => _openMatch(shown[i].id)),
            if (i != shown.length - 1) const SizedBox(height: AppSizes.md),
          ],
        const SizedBox(height: AppSizes.xxl),
      ],
    );
  }

  // ── Courts map ──────────────────────────────────────────────────────────
  Widget _buildCourtsMap() {
    final located = _courts.where((c) => c.hasLocation).toList();
    if (!_courtsLoading && located.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(trg('خريطة الملاعب الرياضية')),
        _CourtsMapCard(
          courts: located,
          loading: _courtsLoading,
          onTap: () => widget.onNavigate('courts'),
        ),
        const SizedBox(height: AppSizes.xxl),
      ],
    );
  }

  // ── Nearest courts ──────────────────────────────────────────────────────
  Widget _buildNearestCourts() {
    final shown = _courts.take(4).toList();
    if (!_courtsLoading && shown.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          trg('أقرب الملاعب'),
          onViewAll: () => widget.onNavigate('courts'),
        ),
        if (_courtsLoading)
          const SkeletonList(
            itemCount: 3,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
          )
        else
          for (var i = 0; i < shown.length; i++) ...[
            _CourtCard(court: shown[i], onTap: () => _openCourt(shown[i].id)),
            if (i != shown.length - 1) const SizedBox(height: AppSizes.md),
          ],
        const SizedBox(height: AppSizes.xxl),
      ],
    );
  }

  // ── Friend activity (`/feed`) ───────────────────────────────────────────
  Widget _buildFeedSection() {
    return BlocBuilder<FeedCubit, FeedState>(
      bloc: _feedCubit,
      builder: (context, state) {
        final shown = state.items.take(5).toList();
        final loading =
            state.status == FeedStatus.loading && state.items.isEmpty;
        if (!loading && shown.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(
              trg('نشاط الأصدقاء'),
              onViewAll: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      FeedPage(onBack: () => Navigator.of(context).pop()),
                ),
              ),
            ),
            if (loading)
              const SkeletonList(
                itemCount: 3,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
              )
            else
              for (var i = 0; i < shown.length; i++) ...[
                _feedTile(shown[i], _feedColors[i % _feedColors.length]),
                if (i != shown.length - 1) const SizedBox(height: AppSizes.md),
              ],
            const SizedBox(height: AppSizes.xxl),
          ],
        );
      },
    );
  }

  Widget _feedTile(FeedItem item, Color color) {
    return _FriendActivityTile(
      color: color,
      initial: item.actorName.characters.firstOrNull ?? context.tr('؟'),
      name: item.actorName,
      details: item.localizedText,
      time: _relativeTime(item.createdAt),
    );
  }

  // ── Community pulse (`/pulse`) ──────────────────────────────────────────
  Widget _buildPulse() {
    final shown = _pulse.take(4).toList();
    if (!_pulseLoading && shown.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          trg('نبض المجتمع الرياضي'),
          onViewAll: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  PulsePage(onBack: () => Navigator.of(context).pop()),
            ),
          ),
        ),
        PulseSection(
          items: shown,
          loading: _pulseLoading,
          onOpenMatch: _openMatch,
        ),
        const SizedBox(height: AppSizes.xxl),
      ],
    );
  }

  // ── نقاط المستوى والمكافآت (`/points/leaderboard`) ──────────────────────
  Widget _buildLeaderboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          trg('نقاط المستوى والمكافآت'),
          onViewAll: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const LeaderboardPage()),
          ),
        ),
        const LeaderboardBoard(limit: 5),
        const SizedBox(height: AppSizes.xxl),
      ],
    );
  }

  // ── Padel tournaments (`/americano?kind=tournament`) ────────────────────
  Widget _buildTournaments() {
    final shown = _tournaments.take(3).toList();
    if (!_tournamentsLoading && shown.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // No "view all": onNavigate only switches the bottom-nav tab, so it
        // would land on the matches sub-tab rather than the tournaments one.
        _sectionTitle(trg('بطولات البادل')),
        TournamentsSection(
          tournaments: shown,
          loading: _tournamentsLoading,
          onOpen: _openTournament,
        ),
        const SizedBox(height: AppSizes.xxl),
      ],
    );
  }

  // ── Players (`/friends/search` — الأقرب أولاً) ──────────────────────────
  Widget _buildSuggestions() {
    final shown = _suggestions.take(10).toList();
    if (!_suggestionsLoading && shown.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          trg('اللاعبون'),
          onViewAll: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const PlayersPage())),
        ),
        PlayersSection(
          players: shown,
          loading: _suggestionsLoading,
          sentRequests: _friendRequests,
          onAdd: _sendFriendRequest,
          colors: _feedColors,
        ),
      ],
    );
  }

  static String _relativeTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return trg('الآن');
    if (d.inMinutes < 60) return trgArgs('منذ {p0} دقيقة', {'p0': d.inMinutes});
    if (d.inHours < 24) return trgArgs('منذ {p0} ساعة', {'p0': d.inHours});
    return trgArgs('منذ {p0} يوم', {'p0': d.inDays});
  }

  Widget _sectionTitle(String title, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('عرض الكل'),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  DirectionalIcon(
                    rtl: Icons.chevron_left,
                    ltr: Icons.chevron_right,
                    size: AppSizes.iconSm,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Upcoming match card ──────────────────────────────────────────────────────

/// Prominent hero card for a match the player is in that starts within the
/// next 30 minutes (or is already underway). Uses a live countdown and the
/// brand gradient so it stands out at the top of the home page.
class _UpcomingMatchCard extends StatelessWidget {
  const _UpcomingMatchCard({required this.match, required this.onTap});

  final MatchEntity match;
  final VoidCallback onTap;

  /// "تبدأ خلال 25 دقيقة" / "تبدأ خلال ساعة و10 دقيقة" / "جارية الآن".
  String _countdown() {
    final diff = match.scheduledAt.difference(ksaNow());
    if (diff.isNegative) return trg('جارية الآن');
    final mins = diff.inMinutes;
    if (mins < 1) return trg('تبدأ الآن');
    if (mins < 60) return trgArgs('تبدأ خلال {p0} دقيقة', {'p0': mins});
    final h = diff.inHours;
    final rem = mins - h * 60;
    return rem == 0
        ? trgArgs('تبدأ خلال {p0} ساعة', {'p0': h})
        : trgArgs('تبدأ خلال {p0} ساعة و{p1} دقيقة', {'p0': h, 'p1': rem});
  }

  @override
  Widget build(BuildContext context) {
    final live = !match.scheduledAt.isAfter(ksaNow());
    final place = [
      if (match.venueName != null && match.venueName!.isNotEmpty)
        match.venueName!,
      if (match.city != null && match.city!.isNotEmpty) match.city!,
    ].join(' • ');
    final time = TimeOfDay.fromDateTime(match.scheduledAt);
    final h12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? trg('صباحاً') : trg('مساءً');
    final clock = '$h12:${time.minute.toString().padLeft(2, '0')} $period';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.primary, _blue],
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        live ? Icons.sports_score : Icons.notifications_active,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: AppSizes.xs),
                      Text(
                        live
                            ? context.tr('جارية الآن')
                            : context.tr('مباراتك القادمة'),
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _countdown(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              match.typeLabel,
              style: AppTextStyles.heading3.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSizes.xs),
            Row(
              children: [
                const Icon(Icons.access_time, size: 13, color: Colors.white70),
                const SizedBox(width: AppSizes.xs),
                Text(
                  clock,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
                if (place.isNotEmpty) ...[
                  const SizedBox(width: AppSizes.md),
                  const Icon(
                    Icons.location_on_outlined,
                    size: 13,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Flexible(
                    child: Text(
                      place,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                const Icon(
                  Icons.groups_outlined,
                  size: 15,
                  color: Colors.white,
                ),
                const SizedBox(width: AppSizes.xs),
                Text(
                  '${match.currentPlayers}/${match.maxPlayers} ${context.tr('لاعبين')}',
                  style: AppTextStyles.caption.copyWith(color: Colors.white),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('التفاصيل'),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSizes.xs),
                    const DirectionalIcon(
                      rtl: Icons.chevron_left,
                      ltr: Icons.chevron_right,
                      size: AppSizes.iconSm,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Match card ────────────────────────────────────────────────────────────

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.onTap});

  final MatchEntity match;
  final VoidCallback onTap;

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
    final minute = d.minute.toString().padLeft(2, '0');
    return '${_weekdaysAr[d.weekday - 1]} · $h12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final place = [
      if (match.venueName != null && match.venueName!.isNotEmpty)
        match.venueName!,
      if (match.city != null && match.city!.isNotEmpty) match.city!,
    ].join(' • ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: const Icon(Icons.sports_tennis, color: AppColors.primary),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.typeLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: AppColors.mutedForeground,
                      ),
                      const SizedBox(width: AppSizes.xs),
                      Text(
                        _when(match.scheduledAt),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  if (place.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppColors.mutedForeground,
                        ),
                        const SizedBox(width: AppSizes.xs),
                        Flexible(
                          child: Text(
                            place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    '${match.spotsLeft} ${context.tr('مقعد')}',
                    style: AppTextStyles.caption.copyWith(color: _green),
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  '${money(match.pricePerPlayer)} ${context.tr('ر.س')}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Court card ──────────────────────────────────────────────────────────────

class _CourtCard extends StatelessWidget {
  const _CourtCard({required this.court, required this.onTap});

  final CourtEntity court;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final place = [
      if (court.areaLabel.isNotEmpty) court.areaLabel,
      if (court.city.isNotEmpty) court.city,
    ].join(' • ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: const Icon(Icons.stadium_outlined, color: _green),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    court.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (place.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppColors.mutedForeground,
                        ),
                        const SizedBox(width: AppSizes.xs),
                        Flexible(
                          child: Text(
                            place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 12, color: _yellow),
                    const SizedBox(width: 2),
                    Text(
                      court.rating.toStringAsFixed(1),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  '${court.totalPrice} ${context.tr('ر.س')}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Courts map preview ───────────────────────────────────────────────────────

/// Real OpenStreetMap preview of nearby courts. Markers sit on each court's
/// venue coordinates; tapping anywhere opens the full courts list. Interaction
/// is disabled so it behaves as a preview inside the scroll view.
class _CourtsMapCard extends StatelessWidget {
  const _CourtsMapCard({
    required this.courts,
    required this.loading,
    required this.onTap,
  });

  final List<CourtEntity> courts;
  final bool loading;
  final VoidCallback onTap;

  static const _fallbackCenter = LatLng(26.4207, 50.0888);

  LatLng get _center {
    if (courts.isEmpty) return _fallbackCenter;
    final lat =
        courts.map((c) => c.latitude!).reduce((a, b) => a + b) / courts.length;
    final lng =
        courts.map((c) => c.longitude!).reduce((a, b) => a + b) / courts.length;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 256,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (loading)
                const Shimmer(child: SkeletonBox(height: 256, radius: 0))
              else
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: courts.length > 1 ? 10.5 : 13,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.sportaapp.sporta_app',
                    ),
                    MarkerLayer(
                      markers: [
                        for (final c in courts)
                          Marker(
                            point: LatLng(c.latitude!, c.longitude!),
                            width: 44,
                            height: 44,
                            alignment: Alignment.topCenter,
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      CourtDetailPage(courtId: c.id),
                                ),
                              ),
                              child: const Icon(
                                Icons.location_on,
                                size: 40,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              PositionedDirectional(
                bottom: AppSizes.lg,
                start: AppSizes.lg,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                    vertical: AppSizes.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: AppSizes.iconSm,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Text(
                        courts.isEmpty
                            ? context.tr('استعرض الملاعب')
                            : context.trArgs('{p0} ملاعب على الخريطة', {
                                'p0': courts.length,
                              }),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PositionedDirectional(
                top: AppSizes.lg,
                start: AppSizes.lg,
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    size: AppSizes.iconMd,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Friend activity tile ──────────────────────────────────────────────────

class _FriendActivityTile extends StatelessWidget {
  const _FriendActivityTile({
    required this.color,
    required this.initial,
    required this.name,
    required this.details,
    required this.time,
  });

  final Color color;
  final String initial;
  final String name;
  final String details;
  final String time;

  @override
  Widget build(BuildContext context) {
    return TintedCard(
      tint: color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color,
            child: Text(
              initial,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(details, style: AppTextStyles.caption),
                const SizedBox(height: AppSizes.xs),
                Text(time, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
