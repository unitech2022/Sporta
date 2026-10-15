import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';
import '../../../memberships/presentation/widgets/member_share.dart';
import '../../../../core/widgets/load_more_listener.dart';

import '../../../invites/domain/event_invite.dart';
import '../../../invites/presentation/invite_friends.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/filter_chip_group.dart';
import '../../../../core/widgets/filter_header_button.dart';
import '../../../../core/widgets/filter_sheet.dart';
import '../../../../core/widgets/gradient_page_header.dart';
import '../../../ads/presentation/widgets/ad_slider.dart';
import '../../../americano/presentation/cubit/americano_list_cubit.dart';
import '../../../americano/presentation/pages/americano_create_page.dart';
import '../../../cup/presentation/pages/cup_create_page.dart';
import '../../../americano/presentation/pages/americano_detail_page.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/state/auth_scope.dart';
import '../../../friends/presentation/pages/friends_page.dart';
import '../../domain/entities/match_entity.dart';
import '../../../payment/presentation/widgets/payment_confirm_dialog.dart';
import '../match_eligibility.dart';
import '../cubit/matches_cubit.dart';
import '../widgets/finished_events_button.dart';
import '../widgets/matches_americano_tab.dart';
import '../widgets/matches_open_matches_tab.dart';
import '../cubit/my_events_cubit.dart';
import '../../../americano/domain/entities/americano_entity.dart';
import 'create_match_page.dart';
import 'my_events_page.dart';
import 'match_detail_page.dart';
import 'match_result_entry_page.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../auth/presentation/widgets/login_required_sheet.dart';

/// المباريات — converted from MatchesPage.tsx.
class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key, this.onBack, this.onNavigate});

  final VoidCallback? onBack;

  /// Navigation callback. Page ids: 'create-match', 'join-match',
  /// 'create-americano', 'join-americano', 'match-result'.
  final void Function(String page, [String? matchType])? onNavigate;

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

enum _MatchesTab { matches, americano, tournaments }

enum _MatchFilter { all, level, date, location, men, women }

class _MatchesPageState extends State<MatchesPage> {
  _MatchesTab _activeTab = _MatchesTab.matches;
  _MatchFilter _filter = _MatchFilter.all;
  MatchesCubit? _cubit;
  AmericanoListCubit? _americanoCubit;
  AmericanoListCubit? _tournamentCubit;

  bool get _isMatchesTab => _activeTab == _MatchesTab.matches;
  bool get _isTournamentsTab => _activeTab == _MatchesTab.tournaments;

  /// The filter options offered by the sheet, as (enum name, Arabic label).
  static List<(String, String)> get _filterOptions => [
    ('all', trg('الكل')),
    ('level', trg('المستوى')),
    ('date', trg('التاريخ')),
    ('location', trg('الموقع')),
    ('men', trg('رجال')),
    ('women', trg('نساء')),
  ];

  /// Opens the shared filter sheet; the pick only lands on the list once
  /// "تطبيق" is pressed.
  Future<void> _openFilterSheet() async {
    final applied = await showFilterSheet<_MatchFilter>(
      context: context,
      initialValue: _filter,
      builder: (sheetContext, draft, onChanged) => FilterSection(
        title: sheetContext.tr('تصفية حسب'),
        child: FilterChipGroup(
          options: [
            for (final option in _filterOptions)
              (option.$1, sheetContext.tr(option.$2)),
          ],
          selected: draft.name,
          onSelected: (value) => onChanged(_MatchFilter.values.byName(value)),
        ),
      ),
    );
    if (applied == null || !mounted) return;
    setState(() => _filter = applied);
  }

  /// Applies the active filter chip to the open-matches list. Level filters to
  /// matches whose range includes the player's level; location filters to the
  /// player's city; date sorts soonest-first; men/women filters to the
  /// joiners' gender chosen when the match was created.
  List<MatchEntity> _applyFilter(List<MatchEntity> matches) {
    final user = context.auth.user;
    switch (_filter) {
      case _MatchFilter.all:
        return matches;
      case _MatchFilter.level:
        final lvl = user?.level?.toDouble();
        if (lvl == null) return matches;
        return matches
            .where((m) => lvl >= m.minLevel && lvl <= m.maxLevel)
            .toList();
      case _MatchFilter.location:
        final city = user?.city;
        if (city == null || city.isEmpty) return matches;
        return matches.where((m) => m.city == city).toList();
      case _MatchFilter.date:
        final sorted = [...matches]
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        return sorted;
      case _MatchFilter.men:
        return matches.where((m) => !m.isWomen).toList();
      case _MatchFilter.women:
        return matches.where((m) => m.isWomen).toList();
    }
  }

  /// One create entry point for the whole page: a sheet with the three
  /// options (مباراة / أمريكانو / بطولة).
  Future<void> _onCreatePressed() async {
    // إنشاء مباراة/أمريكانو/بطولة يخص حساباً.
    if (await guestBlocked(context)) return;
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CreateChooserSheet(
        onCreateMatch: () {
          Navigator.of(sheetContext).pop();
          _openCreateMatch();
        },
        onCreateAmericano: () {
          Navigator.of(sheetContext).pop();
          _openCreateAmericano();
        },
        onCreateTournament: () {
          Navigator.of(sheetContext).pop();
          _openCreateTournament();
        },
      ),
    );
  }

  /// زر الحالة الفارغة ينشئ مباشرةً حسب التبويب النشط — شيت الاختيار
  /// يخص زر «إنشاء» في الهيدر وحده.
  Future<void> _onEmptyStateCreatePressed() async {
    if (await guestBlocked(context)) return;
    if (!mounted) return;
    if (_isMatchesTab) {
      await _openCreateMatch();
    } else if (_isTournamentsTab) {
      await _openCreateTournament();
    } else {
      await _openCreateAmericano();
    }
  }

  Future<void> _openFriends() async {
    if (await guestBlocked(context)) return;
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FriendsPage(onBack: () => Navigator.of(context).pop()),
      ),
    );
  }

  Future<void> _openCreateAmericano() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AmericanoCreatePage(
          onBack: () => Navigator.of(context).pop(),
          // تُغلق صفحة الإضافة؛ حوار النجاح يعرض «متابعة» إلى التفاصيل.
          onCreated: (_) => Navigator.of(context).pop(),
        ),
      ),
    );
    _americanoCubit?.load(); // refresh after returning
  }

  /// البطولة الإقصائية (نظام كأس العالم): فرق من لاعبَين، مجموعات و/أو
  /// خروج المغلوب، والتطبيق يشكّل القرعة والمباريات.
  Future<void> _openCreateTournament() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CupCreatePage(
          onBack: () => Navigator.of(context).pop(),
          // تُغلق صفحة الإضافة؛ حوار النجاح يعرض «متابعة» إلى البطولة.
          onCreated: (_) => Navigator.of(context).pop(),
        ),
      ),
    );
    _tournamentCubit?.load(); // refresh after returning
  }

  Future<void> _openCreateMatch() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateMatchPage(
          onBack: () => Navigator.of(context).pop(),
          onComplete: () => Navigator.of(context).pop(),
        ),
      ),
    );
    // Refresh the list so a newly created match shows up.
    _cubit?.loadMatches();
  }

  Future<void> _openAmericano(BuildContext context, int id) async {
    final listCubit = context.read<AmericanoListCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AmericanoDetailPage(
          americanoId: id,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
    listCubit.load(); // refresh standings/progress after returning
  }

  Future<void> _openMatchResult(BuildContext context, MatchEntity match) async {
    if (await guestBlocked(context)) return;
    if (!context.mounted) return;
    final cubit = context.read<MatchesCubit>();
    final currentUserId = int.tryParse(getIt<AuthCubit>().user?.id ?? '') ?? 0;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchResultEntryPage(
          match: match,
          currentUserId: currentUserId,
          onBack: () => Navigator.of(context).pop(),
          onCompleted: () => Navigator.of(context).pop(),
        ),
      ),
    );
    cubit.loadMatches();
  }

  /// دعوة أصدقاء من بطاقة المباراة: نفس دعوة صفحة التفاصيل — حتى عدد
  /// المقاعد الشاغرة (أيّ عدد من 1 فأكثر، لا العدد كاملاً) مع مدة الصلاحية.
  Future<void> _invite(BuildContext context, MatchEntity match) async {
    final cubit = context.read<MatchesCubit>();
    await inviteFriendsToEvent(
      context,
      kind: InviteKind.match,
      targetId: match.id,
      startsAt: match.scheduledAt,
      maxCount: match.spotsLeft,
    );
    cubit.loadMatches();
  }

  Future<void> _openDetails(BuildContext context, MatchEntity match) async {
    final cubit = context.read<MatchesCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchDetailPage(matchId: match.id),
      ),
    );
    cubit
        .loadMatches(); // refresh after returning (join/approve may have changed)
  }

  static List<String> get _monthsAr => [
    trg('يناير'),
    trg('فبراير'),
    trg('مارس'),
    trg('أبريل'),
    trg('مايو'),
    trg('يونيو'),
    trg('يوليو'),
    trg('أغسطس'),
    trg('سبتمبر'),
    trg('أكتوبر'),
    trg('نوفمبر'),
    trg('ديسمبر'),
  ];

  /// Short "12 يوليو · 6:00 مساءً" label for the confirmation dialog.
  static String _whenLabel(DateTime d) {
    final period = AppDates.period(d);
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${_monthsAr[d.month - 1]} · $h12:$minute $period';
  }

  int get _currentUserId =>
      int.tryParse(getIt<AuthCubit>().user?.id ?? '') ?? 0;

  MyEventsKind get _currentEventsKind => _isMatchesTab
      ? MyEventsKind.match
      : _isTournamentsTab
      ? MyEventsKind.tournament
      : MyEventsKind.americano;

  /// «عرض الكل» في قسم ما يخصّ المستخدم: صفحة مقسّمة بمبارياته/أمريكانوه/
  /// بطولاته الحالية، و[finished] لصفحة «المنتهية». تُعاد القائمة عند الرجوع
  /// (قد تغيّر شيئاً هناك).
  Future<void> _openMyEvents(MyEventsKind kind, {bool finished = false}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MyEventsPage(kind: kind, finished: finished),
      ),
    );
    if (!mounted) return;
    switch (kind) {
      case MyEventsKind.match:
        _cubit?.loadMatches();
      case MyEventsKind.americano:
        _americanoCubit?.load();
      case MyEventsKind.tournament:
        _tournamentCubit?.load();
    }
  }

  /// «انضمام» من بطاقة أمريكانو/بطولة: يُنضمّ فعلاً من القائمة — فحص
  /// المستوى، ثم تأكيد الحصة إن كان على ملعب، ثم طلب ينتظر موافقة المنظّم.
  /// الخادم يضع اللاعب في أول مقعد شاغر (وفي الفرق: أول فريق ناقص).
  Future<void> _joinAmericano(BuildContext context, AmericanoEntity a) async {
    if (await guestBlocked(context)) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<AmericanoListCubit>();

    final level = getIt<AuthCubit>().user?.level;
    if (level != null && (level < a.minLevel || level > a.maxLevel)) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.trArgs('مستواك ({p0}) خارج نطاق هذا الحدث ({p1} - {p2})', {
              'p0': level,
              'p1': a.minLevel.toStringAsFixed(0),
              'p2': a.maxLevel.toStringAsFixed(0),
            }),
          ),
        ),
      );
      return;
    }

    if (a.pricePerPlayer > 0) {
      // عضو نادي الملعب يدفع حصته بعد خصم عضويته.
      final share = await eventShareQuote(
        americanoId: a.id,
        price: a.pricePerPlayer,
      );
      if (!context.mounted) return;
      final confirmed = await showPaymentConfirmDialog(
        context,
        title: a.isTournament || a.isKnockoutTournament
            ? context.tr('تأكيد الانضمام للبطولة')
            : context.tr('تأكيد الانضمام للأمريكانو'),
        amount: share.amount,
        details: [
          PaymentDetail(
            context.tr('الملعب'),
            a.venueName ?? context.tr('بدون ملعب محدد'),
          ),
          PaymentDetail(context.tr('النوع'), a.typeLabel),
          PaymentDetail(context.tr('الموعد'), _whenLabel(a.scheduledAt)),
          ...memberShareDetails(context, share),
        ],
        confirmLabel: context.tr('تأكيد الانضمام'),
        autoCancelNote: true,
      );
      if (confirmed != true || !context.mounted) return;
    }

    // النص قبل الانتظار: السياق قد لا يبقى صالحاً بعده.
    final sent = context.tr('أُرسل طلب انضمامك — بانتظار موافقة المنظّم');
    final error = await cubit.join(a.id);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(error ?? sent)));
  }

  Future<void> _join(BuildContext context, MatchEntity match) async {
    // الانضمام يحتاج حساباً؛ استعراض المباريات مفتوح للزائر.
    if (await guestBlocked(context)) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<MatchesCubit>();
    final joined = context.tr('تم الانضمام للمباراة بنجاح');

    // Check eligibility before the payment dialog — the server rejects an
    // out-of-range level anyway, and confirming a debit first would be cruel.
    final blocked = matchLevelBlockReason(
      match,
      getIt<AuthCubit>().user?.level,
    );
    if (blocked != null) {
      messenger.showSnackBar(SnackBar(content: Text(blocked)));
      return;
    }

    // The share is held as soon as the request is sent, and refunded if the
    // creator rejects it — so confirm the debit before calling.
    final share = await eventShareQuote(
      matchId: match.id,
      price: match.pricePerPlayer.toDouble(),
    );
    if (!context.mounted) return;
    final confirmed = await showPaymentConfirmDialog(
      context,
      title: context.tr('تأكيد الانضمام للمباراة'),
      amount: share.amount,
      details: [
        PaymentDetail(
          context.tr('الملعب'),
          match.venueName ?? context.tr('بدون ملعب محدد'),
        ),
        PaymentDetail(context.tr('الموعد'), _whenLabel(match.scheduledAt)),
        ...memberShareDetails(context, share),
      ],
      confirmLabel: context.tr('تأكيد الانضمام'),
      autoCancelNote: true,
    );
    if (confirmed != true) return;

    final error = await cubit.joinMatch(match.id);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(error ?? joined)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MatchesCubit>(
      create: (_) {
        _cubit = getIt<MatchesCubit>();
        // الزائر بلا «مبارياتي» (النقطة تتطلب حساباً).
        return _cubit!..loadMatches(includeMine: _currentUserId != 0);
      },
      child: ColoredBox(
        color: AppColors.background,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: LoadMoreListener(
                // يحمّل التالي قرب النهاية، أو فوراً إن لم تملأ القائمة الشاشة.
                onLoadMore: () {
                  // Load the next page of whichever tab is active.
                  if (_isMatchesTab) {
                    _cubit?.loadMore();
                  } else if (_isTournamentsTab) {
                    _tournamentCubit?.loadMore();
                  } else {
                    _americanoCubit?.loadMore();
                  }
                },
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.pagePadding,
                          vertical: AppSizes.lg,
                        ),
                        child: Column(
                          children: [
                            // بانر إعلانات صفحة المباريات — يخفي نفسه إن لم
                            // توجد إعلانات لها.
                            const AdBannerSection(
                              page: AdPlacements.matches,
                              padding: EdgeInsets.only(bottom: AppSizes.lg),
                            ),
                            // المنتهي لا يظهر في القوائم الحالية — يُفتح من هنا.
                            if (_currentUserId != 0) ...[
                              FinishedEventsButton(
                                kind: _currentEventsKind,
                                onTap: () => _openMyEvents(
                                  _currentEventsKind,
                                  finished: true,
                                ),
                              ),
                              const SizedBox(height: AppSizes.lg),
                            ],
                            if (_isMatchesTab)
                              BlocBuilder<MatchesCubit, MatchesState>(
                                builder: (context, state) =>
                                    MatchesOpenMatchesTab(
                                      status: state.status,
                                      currentUserId: _currentUserId,
                                      matches: _applyFilter(state.matches),
                                      mine: state.mine,
                                      mineTotal: state.mineTotal,
                                      onSeeAllMine: () =>
                                          _openMyEvents(MyEventsKind.match),
                                      joiningId: state.joiningId,
                                      hasMore: state.hasMore,
                                      error: state.error,
                                      onJoin: (m) => _join(context, m),
                                      onEnterResult: (m) =>
                                          _openMatchResult(context, m),
                                      onInvite: (m) => _invite(context, m),
                                      onOpenDetails: (m) =>
                                          _openDetails(context, m),
                                      onRetry: () => context
                                          .read<MatchesCubit>()
                                          .loadMatches(),
                                    ),
                              )
                            else if (_isTournamentsTab)
                              BlocProvider<AmericanoListCubit>(
                                // Keyed: this and the americano branch below are
                                // the same widget type in the same slot, so
                                // without distinct keys Flutter reuses the element
                                // when switching tabs, `create` never re-runs and
                                // the list keeps the other tab's `kind`.
                                key: const ValueKey('tab-tournaments'),
                                create: (_) {
                                  _tournamentCubit =
                                      getIt<AmericanoListCubit>();
                                  return _tournamentCubit!..load(
                                    kind: 'tournament',
                                    includeMine: _currentUserId != 0,
                                  );
                                },
                                child:
                                    BlocBuilder<
                                      AmericanoListCubit,
                                      AmericanoListState
                                    >(
                                      builder: (context, state) =>
                                          MatchesAmericanoTab(
                                            status: state.status,
                                            items: state.items,
                                            mine: state.mine,
                                            mineTotal: state.mineTotal,
                                            currentUserId: _currentUserId,
                                            joiningId: state.joiningId,
                                            onSeeAllMine: () => _openMyEvents(
                                              MyEventsKind.tournament,
                                            ),
                                            hasMore: state.hasMore,
                                            error: state.error,
                                            emptyLabel: 'لا توجد بطولات حالياً',
                                            mineLabel: 'بطولاتي',
                                            othersLabel: 'بطولات أخرى',
                                            onRetry: () => context
                                                .read<AmericanoListCubit>()
                                                .load(),
                                            onOpen: (id) =>
                                                _openAmericano(context, id),
                                            onJoin: (a) =>
                                                _joinAmericano(context, a),
                                          ),
                                    ),
                              )
                            else
                              BlocProvider<AmericanoListCubit>(
                                key: const ValueKey('tab-americano'),
                                create: (_) {
                                  _americanoCubit = getIt<AmericanoListCubit>();
                                  return _americanoCubit!..load(
                                    kind: 'americano',
                                    includeMine: _currentUserId != 0,
                                  );
                                },
                                child:
                                    BlocBuilder<
                                      AmericanoListCubit,
                                      AmericanoListState
                                    >(
                                      builder: (context, state) =>
                                          MatchesAmericanoTab(
                                            status: state.status,
                                            items: state.items,
                                            mine: state.mine,
                                            mineTotal: state.mineTotal,
                                            currentUserId: _currentUserId,
                                            joiningId: state.joiningId,
                                            onSeeAllMine: () => _openMyEvents(
                                              MyEventsKind.americano,
                                            ),
                                            hasMore: state.hasMore,
                                            error: state.error,
                                            onRetry: () => context
                                                .read<AmericanoListCubit>()
                                                .load(),
                                            onOpen: (id) =>
                                                _openAmericano(context, id),
                                            onJoin: (a) =>
                                                _joinAmericano(context, a),
                                          ),
                                    ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSizes.pagePadding,
                          0,
                          AppSizes.pagePadding,
                          AppSizes.pagePadding,
                        ),
                        child: _buildCreateButton(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GradientPageHeader(
      title: context.tr('المباريات'),
      onBack: widget.onBack,
      trailing: [
        // The filters only narrow the open-matches list, so the button follows
        // that tab.
        if (_isMatchesTab) ...[
          FilterHeaderButton(
            activeCount: _filter == _MatchFilter.all ? 0 : 1,
            onOpen: _openFilterSheet,
            onClear: () => setState(() => _filter = _MatchFilter.all),
          ),
          const SizedBox(width: AppSizes.xs),
        ],
        IconButton(
          onPressed: _openFriends,
          icon: const Icon(Icons.people_alt_outlined, color: Colors.white),
          tooltip: context.tr('الأصدقاء'),
        ),
        _HeaderCreateButton(
          label: context.tr('إنشاء'),
          onTap: _onCreatePressed,
        ),
      ],
      bottom: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _HeaderTabButton(
                  icon: Icons.track_changes,
                  label: context.tr('مباريات'),
                  selected: _isMatchesTab,
                  onTap: () => setState(() => _activeTab = _MatchesTab.matches),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _HeaderTabButton(
                  icon: Icons.sync_alt,
                  label: context.tr('أمريكانو'),
                  selected: _activeTab == _MatchesTab.americano,
                  onTap: () =>
                      setState(() => _activeTab = _MatchesTab.americano),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _HeaderTabButton(
                  icon: Icons.emoji_events,
                  label: context.tr('بطولات'),
                  selected: _isTournamentsTab,
                  onTap: () =>
                      setState(() => _activeTab = _MatchesTab.tournaments),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          AppSearchField(
            hint: _isMatchesTab
                ? context.tr('ابحث عن مباراة...')
                : _isTournamentsTab
                ? context.tr('ابحث عن بطولة...')
                : context.tr('ابحث عن أمريكانو...'),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: InkWell(
          onTap: _onEmptyStateCreatePressed,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isMatchesTab
                      ? Icons.group
                      : _isTournamentsTab
                      ? Icons.emoji_events
                      : Icons.sync_alt,
                  size: AppSizes.iconMd,
                  color: AppColors.onPrimary,
                ),
                SizedBox(width: AppSizes.sm),
                Text(
                  _isMatchesTab
                      ? context.tr('أنشئ مباراة جديدة')
                      : _isTournamentsTab
                      ? context.tr('أنشئ بطولة جديدة')
                      : context.tr('أنشئ أمريكانو جديد'),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet offering the three create options:
/// مباراة / أمريكانو / بطولة (نفس نظام الأمريكانو ليوم أو عدة أيام).
class _CreateChooserSheet extends StatelessWidget {
  const _CreateChooserSheet({
    required this.onCreateMatch,
    required this.onCreateAmericano,
    required this.onCreateTournament,
  });

  final VoidCallback onCreateMatch;
  final VoidCallback onCreateAmericano;
  final VoidCallback onCreateTournament;

  @override
  Widget build(BuildContext context) {
    Widget option({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.sm),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
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
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
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
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSizes.pagePadding,
        AppSizes.lg,
        AppSizes.pagePadding,
        AppSizes.lg + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Text(
            context.tr('ماذا تريد أن تنشئ؟'),
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSizes.lg),
          option(
            icon: Icons.group,
            title: context.tr('إنشاء مباراة'),
            subtitle: context.tr('مباراة مفتوحة ينضم إليها اللاعبون'),
            onTap: onCreateMatch,
          ),
          option(
            icon: Icons.sync_alt,
            title: context.tr('إنشاء أمريكانو'),
            subtitle: context.tr('فردي بتبديل الشركاء أو فرق ثابتة'),
            onTap: onCreateAmericano,
          ),
          option(
            icon: Icons.emoji_events,
            title: context.tr('إنشاء بطولة'),
            subtitle: context.tr('نفس نظام الأمريكانو — يوم واحد أو عدة أيام'),
            onTap: onCreateTournament,
          ),
        ],
      ),
    );
  }
}

/// Compact create button shown in the header next to the title.
class _HeaderCreateButton extends StatelessWidget {
  const _HeaderCreateButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add,
                size: AppSizes.iconMd,
                color: AppColors.onPrimary,
              ),
              SizedBox(width: AppSizes.sm),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header tab (مباريات مفتوحة / أمريكانو).
class _HeaderTabButton extends StatelessWidget {
  const _HeaderTabButton({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.primary : AppColors.onSecondary;

    return Material(
      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      elevation: selected ? 4 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppSizes.iconMd, color: foreground),
              SizedBox(width: AppSizes.sm),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w500,
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
