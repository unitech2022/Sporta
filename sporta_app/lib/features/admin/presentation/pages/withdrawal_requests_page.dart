import 'package:flutter/material.dart';
import '../../../../core/widgets/load_more_listener.dart';
import 'package:sporta_app/core/state/app_scope.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../payment/data/wallet_repository.dart';
import '../../../payment/domain/entities/wallet_entity.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/skeleton.dart';

/// Admin page to view and process withdrawal requests.
class WithdrawalRequestsPage extends StatefulWidget {
  const WithdrawalRequestsPage({super.key});

  @override
  State<WithdrawalRequestsPage> createState() => _WithdrawalRequestsPageState();
}

class _WithdrawalRequestsPageState extends State<WithdrawalRequestsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final WalletRepository _repo;

  /// Bumped after processing a request so every status tab reloads (a
  /// processed request moves between tabs).
  int _refreshTick = 0;

  /// Server-side totals per status (drive the badge + header count).
  int _pendingTotal = 0;
  int _approvedTotal = 0;
  int _rejectedTotal = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _repo = getIt<WalletRepository>();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _load() => setState(() => _refreshTick++);

  Future<void> _process(WithdrawalRequestEntity req, bool approve) async {
    String? notes;
    if (!approve) {
      notes = await _showNotesDialog();
      if (notes == null) return; // cancelled
    }

    try {
      await _repo.processWithdrawal(req.id, approve, notes?.isEmpty == true ? null : notes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(approve
            ? context.tr('تمت الموافقة على طلب السحب')
            : context.tr('تم رفض طلب السحب')),
        backgroundColor: approve ? AppColors.success : AppColors.destructive,
      ));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception:', '').trim()),
        backgroundColor: AppColors.destructive,
      ));
    }
  }

  Future<String?> _showNotesDialog() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: Directionality.of(context),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusXl)),
          title: Text(context.tr('سبب الرفض')),
          content: TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: context.tr('أدخل سبب الرفض (اختياري)'),
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(context.tr('إلغاء')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.destructive,
                foregroundColor: Colors.white,
              ),
              child: Text(context.tr('رفض')),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(context),
            TabBar(
              controller: _tabs,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.mutedForeground,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(context.tr('قيد الانتظار')),
                    if (_pendingTotal > 0) ...[
                      const SizedBox(width: 6),
                      _badge(_pendingTotal),
                    ],
                  ]),
                ),
                Tab(text: context.tr('موافق عليها')),
                Tab(text: context.tr('مرفوضة')),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _StatusTab(
                    repo: _repo,
                    status: 'pending',
                    refreshTick: _refreshTick,
                    emptyLabel: context.tr('لا توجد طلبات معلقة'),
                    onApprove: (r) => _process(r, true),
                    onReject: (r) => _process(r, false),
                    showActions: true,
                    onTotal: (n) => setState(() => _pendingTotal = n),
                  ),
                  _StatusTab(
                    repo: _repo,
                    status: 'approved',
                    refreshTick: _refreshTick,
                    emptyLabel: context.tr('لا توجد طلبات موافق عليها'),
                    showActions: false,
                    onTotal: (n) => setState(() => _approvedTotal = n),
                  ),
                  _StatusTab(
                    repo: _repo,
                    status: 'rejected',
                    refreshTick: _refreshTick,
                    emptyLabel: context.tr('لا توجد طلبات مرفوضة'),
                    showActions: false,
                    onTotal: (n) => setState(() => _rejectedTotal = n),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFF0A2540), Color(0xFF12345B)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSizes.pagePadding, AppSizes.xxxl,
              AppSizes.pagePadding, AppSizes.lg),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const DirectionalIcon(
                    rtl: Icons.arrow_forward,
                    ltr: Icons.arrow_back,
                    color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: AppSizes.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('طلبات السحب'),
                      style:
                          AppTextStyles.heading2.copyWith(color: Colors.white)),
                  Text('${_pendingTotal + _approvedTotal + _rejectedTotal} ${context.tr('طلب إجمالاً')}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white.withValues(alpha: 0.7))),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(int count) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('$count',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      );
}

/// One status tab: fetches its own server-filtered, paginated list and loads
/// more as the admin scrolls.
class _StatusTab extends StatefulWidget {
  const _StatusTab({
    required this.repo,
    required this.status,
    required this.refreshTick,
    required this.emptyLabel,
    required this.showActions,
    this.onApprove,
    this.onReject,
    this.onTotal,
  });

  final WalletRepository repo;
  final String status;

  /// Parent bumps this to force a reload (after a request is processed).
  final int refreshTick;
  final String emptyLabel;
  final bool showActions;
  final void Function(WithdrawalRequestEntity)? onApprove;
  final void Function(WithdrawalRequestEntity)? onReject;

  /// Reports the server-side total for this status (drives badges).
  final ValueChanged<int>? onTotal;

  @override
  State<_StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<_StatusTab>
    with AutomaticKeepAliveClientMixin {
  List<WithdrawalRequestEntity> _items = [];
  int _page = 1;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _StatusTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page =
          await widget.repo.fetchWithdrawalRequests(status: widget.status);
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _page = page.page;
        _hasMore = page.hasMore;
        _loading = false;
      });
      widget.onTotal?.call(page.total);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception:', '').trim();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore || _loading) return;
    _loadingMore = true;
    try {
      final page = await widget.repo
          .fetchWithdrawalRequests(status: widget.status, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...page.items];
        _page = page.page;
        _hasMore = page.hasMore;
      });
    } catch (_) {
      // Keep what's loaded; scrolling again retries.
    } finally {
      _loadingMore = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const SkeletonList();
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!,
                style:
                    AppTextStyles.body.copyWith(color: AppColors.destructive)),
            const SizedBox(height: AppSizes.md),
            ElevatedButton(
                onPressed: _load, child: Text(context.tr('إعادة المحاولة'))),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 48, color: AppColors.mutedForeground),
            const SizedBox(height: AppSizes.md),
            Text(widget.emptyLabel,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.mutedForeground)),
          ],
        ),
      );
    }

    return LoadMoreListener(
      // يحمّل التالي قرب النهاية، أو فوراً إن لم تملأ القائمة الشاشة.
      onLoadMore: () {
          _loadMore();
      },
      child: ListView.separated(
        padding: context.safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
        itemBuilder: (context, i) {
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _RequestCard(
              req: _items[i],
              showActions: widget.showActions,
              onApprove: widget.onApprove,
              onReject: widget.onReject);
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.req,
    required this.showActions,
    this.onApprove,
    this.onReject,
  });

  final WithdrawalRequestEntity req;
  final bool showActions;
  final void Function(WithdrawalRequestEntity)? onApprove;
  final void Function(WithdrawalRequestEntity)? onReject;

  Color get _statusColor {
    switch (req.status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.destructive;
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _statusLabel(BuildContext context) {
    switch (req.status) {
      case 'approved':
        return context.tr('موافق عليه');
      case 'rejected':
        return context.tr('مرفوض');
      default:
        return context.tr('قيد الانتظار');
    }
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: amount + status badge
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: Icon(Icons.north_east,
                          color: _statusColor, size: 20),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${money(req.amount)} ${context.tr('ر.س')}',
                          style: AppTextStyles.heading3
                              .copyWith(color: AppColors.secondary),
                        ),
                        Text(
                          _formatDate(req.createdAt),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Text(
                  _statusLabel(context),
                  style: AppTextStyles.caption.copyWith(
                      color: _statusColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          const Divider(height: 1),
          const SizedBox(height: AppSizes.md),

          // Bank info
          _infoRow(context, Icons.person_outline, context.tr('صاحب الحساب'),
              req.accountHolderName),
          const SizedBox(height: AppSizes.sm),
          _infoRow(context, Icons.business_outlined, context.tr('البنك'),
              req.bankName),
          const SizedBox(height: AppSizes.sm),
          _infoRow(context, Icons.account_balance_outlined,
              context.tr('الآيبان'), req.iban),

          if (req.adminNotes != null && req.adminNotes!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.sm),
            _infoRow(context, Icons.note_outlined, context.tr('ملاحظة الإدارة'),
                req.adminNotes!),
          ],

          if (showActions) ...[
            const SizedBox(height: AppSizes.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onReject?.call(req),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.destructive,
                      side: const BorderSide(color: AppColors.destructive),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusLg)),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text(context.tr('رفض')),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onApprove?.call(req),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusLg)),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(context.tr('موافقة')),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.mutedForeground),
        const SizedBox(width: AppSizes.sm),
        Text('$label: ',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.mutedForeground)),
        Expanded(
          child: Text(value,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.secondary),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
