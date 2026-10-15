import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../data/coach_repository.dart';
import '../../domain/entities/coach_session_entity.dart';
import '../../../reviews/domain/review_models.dart';
import '../../../reviews/presentation/widgets/rate_experience_sheet.dart';
import 'coach_booking_detail_page.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/skeleton.dart';

/// Coach-facing bookings: a paginated, filterable list of all session bookings
/// with inline accept / reject for pending requests and a tap-through to the
/// booking details.
class CoachBookingsPage extends StatefulWidget {
  const CoachBookingsPage({super.key});

  @override
  State<CoachBookingsPage> createState() => _CoachBookingsPageState();
}

class _CoachBookingsPageState extends State<CoachBookingsPage> {
  final _repo = getIt<CoachRepository>();
  final _scroll = ScrollController();

  final List<CoachSessionEntity> _items = [];
  String? _status;
  int _page = 1;
  bool _hasMore = true;
  bool _loading = false;
  bool _initialLoading = true;
  int? _busyId;

  late final List<(String, String?)> _filters = [
    (context.tr('الكل'), null),
    (context.tr('قيد الانتظار'), 'pending'),
    (context.tr('مؤكدة'), 'confirmed'),
    (context.tr('منتهية'), 'completed'),
    (context.tr('مرفوضة'), 'rejected'),
  ];

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
      if (reset) {
        _page = 1;
        _hasMore = true;
        _items.clear();
        _initialLoading = true;
      }
    });
    try {
      final res = await _repo.fetchCoachBookings(page: _page, status: _status);
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

  Future<void> _respond(CoachSessionEntity s, bool approve) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busyId = s.id);
    try {
      await _repo.respondToSessionRequest(s.id, approve);
      if (!mounted) return;
      setState(() => _busyId = null);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            approve ? context.tr('تم قبول الطلب') : context.tr('تم رفض الطلب'),
          ),
        ),
      );
      _load(reset: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busyId = null);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  /// نافذة التقييم الموحّدة: اللاعب والملعب (إن وُجد) دفعة واحدة.
  Future<void> _ratePlayer(CoachSessionEntity s) async {
    final updated = await openReviewSheet(context, ReviewContext.session, s.id);
    if (updated != null && mounted) _load(reset: true);
  }

  Future<void> _openDetail(CoachSessionEntity s) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CoachBookingDetailPage(session: s)),
    );
    if (changed == true) _load(reset: true);
  }

  String _formatWhen(DateTime d) {
    final weekday = AppDates.weekday(d);
    final month = AppDates.monthName(d.month);
    final period = AppDates.period(d);
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    return '$weekday ${d.day} $month · $h12:$minute $period';
  }

  (Color, String) _statusChip(CoachSessionEntity s) => switch (s.status) {
    'pending' => (AppColors.warning, context.tr('قيد الانتظار')),
    'rejected' => (AppColors.destructive, context.tr('مرفوضة')),
    'Completed' => (AppColors.success, context.tr('منتهية')),
    _ => (AppColors.primary, context.tr('مؤكدة')),
  };

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          title: Text(context.tr('الحجوزات')),
        ),
        body: Column(
          children: [
            _filterBar(),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _filterBar() {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSizes.sm),
        itemBuilder: (_, i) {
          final f = _filters[i];
          final selected = f.$2 == _status;
          return Center(
            child: GestureDetector(
              onTap: () => _selectFilter(f.$2),
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
                  f.$1,
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
    if (_items.isEmpty) {
      return Center(
        child: Text(
          context.tr('لا توجد حجوزات'),
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
          return _tile(_items[i]);
        },
      ),
    );
  }

  Widget _tile(CoachSessionEntity s) {
    final busy = _busyId == s.id;
    final isPending = s.status == 'pending';
    final (statusColor, statusLabel) = _statusChip(s);
    return GestureDetector(
      onTap: () => _openDetail(s),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.md),
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.playerName ?? context.tr('لاعب'),
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(s.title, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTextStyles.caption.copyWith(color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppColors.mutedForeground,
                ),
                const SizedBox(width: AppSizes.xs),
                Text(_formatWhen(s.scheduledAt), style: AppTextStyles.caption),
                const Spacer(),
                Text(
                  '${money(s.price)} ${context.tr('ر.س')}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (s.isRated) ...[
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  Text(
                    '${context.tr('تقييمك للاعب')}: ',
                    style: AppTextStyles.caption,
                  ),
                  for (var i = 1; i <= 5; i++)
                    Icon(
                      i <= (s.coachRating ?? 0)
                          ? Icons.star
                          : Icons.star_border,
                      size: 16,
                      color: const Color(0xFFFACC15),
                    ),
                ],
              ),
            ] else if (s.canCoachRate) ...[
              const SizedBox(height: AppSizes.md),
              if (busy)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _ratePlayer(s),
                    icon: const Icon(Icons.star_outline, size: 18),
                    label: Text(context.tr('قيّم اللاعب')),
                  ),
                ),
            ],
            if (isPending) ...[
              const SizedBox(height: AppSizes.md),
              if (busy)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _respond(s, true),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(context.tr('قبول')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _respond(s, false),
                        icon: const Icon(Icons.close, size: 18),
                        label: Text(context.tr('رفض')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.destructive,
                          side: const BorderSide(color: AppColors.destructive),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}
