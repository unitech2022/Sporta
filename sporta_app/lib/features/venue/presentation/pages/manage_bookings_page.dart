import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../data/venue_repository.dart';
import '../../domain/entities/venue_dashboard.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/skeleton.dart';

/// Venue-owner booking management: paginated, filterable list of bookings on the
/// owner's courts with confirm / reject (cancel + refund) actions.
class ManageBookingsPage extends StatefulWidget {
  const ManageBookingsPage({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<ManageBookingsPage> createState() => _ManageBookingsPageState();
}

class _ManageBookingsPageState extends State<ManageBookingsPage> {
  final _repo = getIt<VenueRepository>();
  final _scroll = ScrollController();

  final List<VenueBooking> _items = [];
  String? _status;
  int _page = 1;
  bool _hasMore = true;
  bool _loading = false;
  bool _initialLoading = true;
  int? _busyId;

  late final List<(String, String?)> _filters = [
    (context.tr('الكل'), null),
    (context.tr('قيد الانتظار'), 'Pending'),
    (context.tr('مؤكدة'), 'Confirmed'),
    (context.tr('منتهية'), 'Completed'),
    (context.tr('ملغاة'), 'Cancelled'),
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
      final res = await _repo.fetchVenueBookings(page: _page, status: _status);
      if (!mounted) return;
      setState(() {
        _items.addAll(res.items);
        _hasMore = res.hasMore;
        _page += 1;
        _loading = false;
        _initialLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _initialLoading = false;
      });
    }
  }

  void _selectFilter(String? value) {
    if (_status == value) return;
    setState(() => _status = value);
    _load(reset: true);
  }

  Future<void> _respond(VenueBooking b, bool approve) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busyId = b.id);
    try {
      await _repo.respondToBooking(b.id, approve);
      if (!mounted) return;
      setState(() => _busyId = null);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            approve ? context.tr('تم تأكيد الحجز') : context.tr('تم رفض الحجز'),
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

  String _formatWhen(DateTime d) {
    final weekday = AppDates.weekday(d);
    final month = AppDates.monthName(d.month);
    final period = AppDates.period(d);
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    return '$weekday ${d.day} $month · $h12:$minute $period';
  }

  String _statusLabel(String s) => switch (s) {
    'Pending' => context.tr('قيد الانتظار'),
    'Confirmed' => context.tr('مؤكدة'),
    'Completed' => context.tr('منتهية'),
    'Cancelled' => context.tr('ملغاة'),
    _ => s,
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
          title: Text(context.tr('إدارة الحجوزات')),
          leading: widget.onBack != null
              ? IconButton(
                  onPressed: widget.onBack,
                  icon: const DirectionalIcon(
                    rtl: Icons.arrow_forward,
                    ltr: Icons.arrow_back,
                  ),
                )
              : null,
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
      return const SkeletonList(showAvatar: false);
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

  Widget _tile(VenueBooking b) {
    final busy = _busyId == b.id;
    final isPending = b.status == 'Pending';
    final isConfirmed = b.status == 'Confirmed';
    final statusColor = switch (b.status) {
      'Confirmed' => AppColors.success,
      'Pending' => AppColors.warning,
      'Cancelled' => AppColors.destructive,
      _ => AppColors.mutedForeground,
    };
    return Container(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${b.courtName} • ${b.venueName}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${context.tr('اللاعب')}: ${b.playerName}',
                      style: AppTextStyles.caption,
                    ),
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
                  _statusLabel(b.status),
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
              Text(_formatWhen(b.startTime), style: AppTextStyles.caption),
              const Spacer(),
              Text(
                '${money(b.totalPrice)} ${context.tr('ر.س')}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (isPending || isConfirmed) ...[
            const SizedBox(height: AppSizes.md),
            if (busy)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  if (isPending)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _respond(b, true),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(context.tr('قبول')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  if (isPending) const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _respond(b, false),
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(
                        isConfirmed ? context.tr('إلغاء') : context.tr('رفض'),
                      ),
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
    );
  }
}
