import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../data/coach_repository.dart';
import '../../domain/entities/coach_session_entity.dart';
import '../pages/coach_booking_detail_page.dart';
import '../pages/coach_bookings_page.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/skeleton.dart';

/// Inline "bookings" section for the coach dashboard: a short preview of the
/// coach's bookings (pending first) with accept / reject, tap-through to the
/// details, and a "view all" link to the full bookings page.
class CoachBookingsSection extends StatefulWidget {
  CoachBookingsSection({
    super.key,
    this.previewCount = 4,
    this.title = 'الحجوزات',
    this.status,
    this.hideWhenEmpty = false,
    this.trailingGap = 0,
  });

  final int previewCount;

  /// Section heading — e.g. "طلبات جديدة" when [status] is "pending".
  final String title;

  /// Optional status filter ("pending" | "confirmed" | "completed" | "rejected").
  final String? status;

  /// يخفي القسم كلياً (بلا عنوان ولا رسالة) حين لا توجد حجوزات — تستخدمه
  /// الشاشة الرئيسية التي لا تعرض الأقسام الفارغة.
  final bool hideWhenEmpty;

  /// مسافة تُضاف أسفل القسم حين يظهر فقط، حتى لا تبقى فجوة عند إخفائه.
  final double trailingGap;

  @override
  State<CoachBookingsSection> createState() => _CoachBookingsSectionState();
}

class _CoachBookingsSectionState extends State<CoachBookingsSection> {
  final _repo = getIt<CoachRepository>();

  List<CoachSessionEntity> _items = [];
  int _total = 0;
  bool _loading = true;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _repo.fetchCoachBookings(
        page: 1,
        pageSize: widget.previewCount,
        status: widget.status,
      );
      if (!mounted) return;
      setState(() {
        _items = res.items;
        _total = res.total;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
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
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busyId = null);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  Future<void> _openDetail(CoachSessionEntity s) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CoachBookingDetailPage(session: s)),
    );
    if (changed == true) _load();
  }

  Future<void> _openAll() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CoachBookingsPage()));
    _load();
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
    if (widget.hideWhenEmpty && !_loading && _items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  context.tr(widget.title),
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                if (widget.status == 'pending' && _total > 0) ...[
                  const SizedBox(width: AppSizes.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.destructive,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      '$_total ${context.tr('طلبات')}',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            GestureDetector(
              onTap: _openAll,
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
        const SizedBox(height: AppSizes.lg),
        if (_loading)
          const SkeletonList(
            itemCount: 2,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
          )
        else if (_items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              context.tr(
                widget.status == 'pending'
                    ? context.tr('لا توجد طلبات جديدة')
                    : context.tr('لا توجد حجوزات'),
              ),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          )
        else
          for (var i = 0; i < _items.length; i++) ...[
            _tile(_items[i]),
            if (i != _items.length - 1) const SizedBox(height: AppSizes.md),
          ],
        if (widget.trailingGap > 0) SizedBox(height: widget.trailingGap),
      ],
    );
  }

  Widget _tile(CoachSessionEntity s) {
    final busy = _busyId == s.id;
    final isPending = s.status == 'pending';
    final (statusColor, statusLabel) = _statusChip(s);
    return GestureDetector(
      onTap: () => _openDetail(s),
      child: Container(
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
