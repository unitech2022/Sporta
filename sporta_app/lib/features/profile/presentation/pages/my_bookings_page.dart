import '../../../../core/widgets/add_to_calendar_button.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/paged.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../coaches/data/coach_repository.dart';
import '../../../coaches/domain/entities/coach_session_entity.dart';
import '../../../coaches/presentation/pages/coach_session_detail_page.dart';
import '../../../courts/data/court_repository.dart';
import '../../../courts/domain/entities/booking_entity.dart';
import '../../../courts/presentation/pages/booking_detail_page.dart';
import '../../../matches/data/match_repository.dart';
import '../../../matches/domain/entities/match_entity.dart';
import '../../../matches/presentation/pages/match_detail_page.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/utils/money.dart';

/// Unified "my bookings" screen: matches / assessments (coach sessions) /
/// courts, each a paginated, filterable tab.
class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key, required this.onBack, this.initialTab = 0});

  final VoidCallback onBack;

  /// Index of the tab shown first: 0 matches, 1 assessments, 2 courts.
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: DefaultTabController(
        length: 3,
        initialIndex: initialTab,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            title: Text(context.tr('حجوزاتي')),
            leading: IconButton(
              onPressed: onBack,
              icon: const DirectionalIcon(
                rtl: Icons.arrow_forward,
                ltr: Icons.arrow_back,
              ),
            ),
            bottom: TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: context.tr('المباريات')),
                Tab(text: context.tr('التقييمات')),
                Tab(text: context.tr('الملاعب')),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _matchesTab(context),
              _sessionsTab(context),
              _courtsTab(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Matches ─────────────────────────────────────────────────────────────────

  Widget _matchesTab(BuildContext context) {
    final repo = getIt<MatchRepository>();
    return _PaginatedTab<MatchEntity>(
      fetcher: (page, status) =>
          repo.fetchMyMatches(page: page, status: status),
      filters: [
        _Filter(context.tr('الكل'), null),
        _Filter(context.tr('مفتوحة'), 'Open'),
        _Filter(context.tr('مكتملة'), 'Full'),
        _Filter(context.tr('منتهية'), 'Completed'),
        _Filter(context.tr('ملغاة'), 'Cancelled'),
      ],
      emptyText: context.tr('لا توجد مباريات'),
      itemBuilder: (m, reload) => _card(
        icon: Icons.emoji_events_outlined,
        color: AppColors.primary,
        title: m.typeLabel,
        subtitle: m.venueName ?? context.tr('بدون ملعب محدد'),
        time: _formatWhen(m.scheduledAt),
        trailing: _statusChip(_matchStatusLabel(context, m.status)),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MatchDetailPage(matchId: m.id),
            ),
          );
          reload();
        },
      ),
    );
  }

  // ── Assessments (coach sessions) ─────────────────────────────────────────────

  Widget _sessionsTab(BuildContext context) {
    final repo = getIt<CoachRepository>();
    return _PaginatedTab<CoachSessionEntity>(
      fetcher: (page, status) =>
          repo.fetchMySessions(page: page, status: status),
      filters: [
        _Filter(context.tr('الكل'), null),
        _Filter(context.tr('قادمة'), 'upcoming'),
        _Filter(context.tr('منتهية'), 'completed'),
      ],
      emptyText: context.tr('لا توجد حجوزات بعد'),
      itemBuilder: (s, reload) => _card(
        icon: Icons.sports_outlined,
        color: const Color(0xFF7C3AED),
        title: s.title,
        subtitle: '${context.tr('المدرب')}: ${s.coachName}',
        time: _formatWhen(s.scheduledAt),
        trailing: _statusChip('${money(s.price)} ${context.tr('ر.س')}'),
        onTap: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => CoachSessionDetailPage(session: s),
            ),
          );
          if (changed == true) reload();
        },
      ),
    );
  }

  // ── Courts ────────────────────────────────────────────────────────────────

  Widget _courtsTab(BuildContext context) {
    final repo = getIt<CourtRepository>();
    return _PaginatedTab<BookingEntity>(
      fetcher: (page, status) =>
          repo.fetchMyBookings(page: page, status: status),
      filters: [
        _Filter(context.tr('الكل'), null),
        _Filter(context.tr('مؤكدة'), 'Confirmed'),
        _Filter(context.tr('قيد الانتظار'), 'Pending'),
        _Filter(context.tr('منتهية'), 'Completed'),
        _Filter(context.tr('ملغاة'), 'Cancelled'),
      ],
      emptyText: context.tr('لا توجد حجوزات بعد'),
      itemBuilder: (b, reload) => _card(
        icon: Icons.calendar_today_outlined,
        color: const Color(0xFF16A34A),
        title: '${b.courtName} • ${b.venueName}',
        subtitle: b.city,
        time: _formatWhen(b.startTime),
        trailing: _statusChip('${b.totalPrice} ${context.tr('ر.س')}'),
        // حجز مؤكَّد قادم: «أضف إلى التقويم» مباشرة من البطاقة.
        footer: b.isUpcomingConfirmed
            ? AddToCalendarButton(
                calendarKey: 'booking-${b.id}',
                compact: true,
                title: context.trArgs('حجز ملعب · {p0}', {'p0': b.courtName}),
                startKsa: b.startTime,
                durationMinutes: b.durationMinutes,
                location: [
                  b.venueName,
                  b.city,
                ].where((e) => e.isNotEmpty).join('، '),
                description: context.tr('حجز عبر سبورتا'),
              )
            : null,
        onTap: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => BookingDetailPage(booking: b),
            ),
          );
          if (changed == true) reload();
        },
      ),
    );
  }

  // ── shared bits ─────────────────────────────────────────────────────────────

  Widget _card({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String time,
    Widget? trailing,
    Widget? footer,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.mutedForeground,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            time,
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
              if (trailing != null) ...[
                const SizedBox(width: AppSizes.sm),
                trailing,
              ],
              if (onTap != null) ...[
                const SizedBox(width: AppSizes.xs),
                const DirectionalIcon(
                  rtl: Icons.chevron_left,
                  ltr: Icons.chevron_right,
                  color: AppColors.mutedForeground,
                ),
              ],
            ],
          ),
          if (footer != null) ...[
            const Divider(height: AppSizes.lg),
            Align(alignment: AlignmentDirectional.centerStart, child: footer),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: onTap == null
          ? card
          : Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                child: card,
              ),
            ),
    );
  }

  Widget _statusChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
    ),
    child: Text(
      label,
      style: AppTextStyles.caption.copyWith(color: AppColors.primary),
    ),
  );

  String _matchStatusLabel(BuildContext context, String s) => switch (s) {
    'Open' => context.tr('مفتوحة'),
    'Full' => context.tr('مكتملة'),
    'Completed' => context.tr('منتهية'),
    'Cancelled' => context.tr('ملغاة'),
    _ => s,
  };

  String _formatWhen(DateTime d) {
    final weekday = AppDates.weekday(d);
    final month = AppDates.monthName(d.month);
    final period = AppDates.periodShort(d);
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    return '$weekday ${d.day} $month · $h12:$minute $period';
  }
}

class _Filter {
  const _Filter(this.label, this.value);
  final String label;
  final String? value;
}

/// Generic paginated + filterable list (infinite scroll "load more").
class _PaginatedTab<T> extends StatefulWidget {
  const _PaginatedTab({
    required this.fetcher,
    required this.filters,
    required this.itemBuilder,
    required this.emptyText,
  });

  final Future<Paged<T>> Function(int page, String? status) fetcher;
  final List<_Filter> filters;
  final Widget Function(T item, VoidCallback reload) itemBuilder;
  final String emptyText;

  @override
  State<_PaginatedTab<T>> createState() => _PaginatedTabState<T>();
}

class _PaginatedTabState<T> extends State<_PaginatedTab<T>> {
  final _scroll = ScrollController();
  final List<T> _items = [];
  late String? _status = widget.filters.first.value;
  int _page = 1;
  bool _hasMore = true;
  bool _loading = false;
  bool _initialLoading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_loading) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _items.clear();
        _initialLoading = true;
      }
    });
    try {
      final res = await widget.fetcher(_page, _status);
      if (!mounted) return;
      setState(() {
        _items.addAll(res.items);
        _hasMore = res.hasMore;
        _page += 1;
        _loading = false;
        _initialLoading = false;
      });
      _fillIfShort();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _initialLoading = false;
        _failed = true;
      });
    }
  }

  /// التحميل التالي يبدأ مع التمرير، فإن لم تملأ الدفعة الشاشة (شاشة طويلة
  /// أو تابلت) لا يمكن التمرير ولا تُحمَّل البقية — فنجلب التالية فوراً.
  void _fillIfShort() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_hasMore || _loading || !_scroll.hasClients) return;
      if (_scroll.position.maxScrollExtent <= 200) _load();
    });
  }

  void _selectFilter(String? value) {
    if (_status == value) return;
    setState(() => _status = value);
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _filterBar(),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _filterBar() {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
        itemCount: widget.filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSizes.sm),
        itemBuilder: (_, i) {
          final f = widget.filters[i];
          final selected = f.value == _status;
          return Center(
            child: GestureDetector(
              onTap: () => _selectFilter(f.value),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.sm,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  f.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: selected ? Colors.white : AppColors.secondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _body() {
    if (_initialLoading) {
      return const SkeletonList();
    }
    if (_failed && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr('تعذّر تحميل البيانات'),
              style: AppTextStyles.body.copyWith(color: AppColors.secondary),
            ),
            const SizedBox(height: AppSizes.md),
            OutlinedButton(
              onPressed: () => _load(reset: true),
              child: Text(context.tr('إعادة المحاولة')),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text(
          widget.emptyText,
          style: AppTextStyles.body.copyWith(color: AppColors.mutedForeground),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        controller: _scroll,
        padding: context.safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSizes.lg),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return widget.itemBuilder(_items[i], () => _load(reset: true));
        },
      ),
    );
  }
}
