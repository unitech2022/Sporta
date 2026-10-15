import '../../../../core/widgets/level_avatar.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../data/venue_repository.dart';
import '../../domain/entities/venue_match_request.dart';
import '../../domain/entities/venue_match_request_detail.dart';
import '../match_request_format.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/skeleton.dart';

/// Details of one match-hosting request on the owner's court: schedule, the
/// creator and how to reach them, who joined, the money involved, and the
/// approve/reject actions while it is still pending.
///
/// Pops `true` when the request was approved or rejected here, so the list can
/// refresh itself.
class MatchRequestDetailPage extends StatefulWidget {
  const MatchRequestDetailPage({
    super.key,
    required this.requestId,
    this.initial,
  });

  final int requestId;

  /// The list card that was tapped — drawn immediately while the full details
  /// load, so the page never opens blank.
  final VenueMatchRequest? initial;

  @override
  State<MatchRequestDetailPage> createState() => _MatchRequestDetailPageState();
}

class _MatchRequestDetailPageState extends State<MatchRequestDetailPage> {
  final _repo = getIt<VenueRepository>();

  VenueMatchRequestDetail? _detail;
  String? _error;
  bool _loading = true;
  bool _busy = false;

  /// Whether an approve/reject went through, so the list reloads on pop.
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _repo.fetchMatchRequest(widget.requestId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.display;
        _loading = false;
      });
    }
  }

  Future<void> _respond(bool approve) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await _repo.respondToMatchRequest(widget.requestId, approve);
      if (!mounted) return;
      _changed = true;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? context.tr('تم قبول المباراة')
                : context.tr('تم رفض المباراة'),
          ),
        ),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  Future<void> _callCreator(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('تعذّر فتح التطبيق'))));
    }
  }

  /// The card data if the details haven't arrived yet — the two share every
  /// field the summary section needs.
  VenueMatchRequest? get _summary => _detail ?? widget.initial;

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    return PopScope(
      // The list refreshes only when something actually changed here, so the
      // system back gesture has to carry the same result as the app bar button.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Directionality(
        textDirection: Directionality.of(context),
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            title: Text(context.tr('تفاصيل الطلب')),
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(_changed),
              icon: const DirectionalIcon(
                rtl: Icons.arrow_forward,
                ltr: Icons.arrow_back,
              ),
            ),
          ),
          body: _error != null && summary == null
              ? _errorView()
              : summary == null
              ? const SkeletonDetail(showStats: false)
              : _content(summary),
          bottomNavigationBar: summary?.status == 'PendingApproval'
              ? _actions()
              : null,
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.destructive,
              size: 48,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.secondary),
            ),
            const SizedBox(height: AppSizes.lg),
            ElevatedButton(
              onPressed: _load,
              child: Text(context.tr('إعادة المحاولة')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(VenueMatchRequest summary) {
    final detail = _detail;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: context.safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
        children: [
          _summaryCard(summary, detail),
          const SizedBox(height: AppSizes.md),
          if (detail != null) ...[
            _creatorCard(detail),
            const SizedBox(height: AppSizes.md),
            _playersCard(detail),
            const SizedBox(height: AppSizes.md),
            _moneyCard(detail),
            if (detail.notes != null && detail.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSizes.md),
              _notesCard(detail.notes!),
            ],
          ] else if (_loading)
            const SkeletonList(
              itemCount: 3,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
            )
          else if (_error != null)
            _inlineError(),
          const SizedBox(height: AppSizes.xxl),
        ],
      ),
    );
  }

  /// The details request failed but the tapped card is still on screen.
  Widget _inlineError() {
    return AppCard(
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.destructive,
            size: AppSizes.iconMd,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              _error!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
          TextButton(
            onPressed: _load,
            child: Text(context.tr('إعادة المحاولة')),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(VenueMatchRequest s, VenueMatchRequestDetail? detail) {
    final color = matchStatusColor(s.status);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${s.courtName} • ${s.venueName}',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  context.tr(matchStatusLabelAr(s.status)),
                  style: AppTextStyles.caption.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          _row(
            Icons.access_time,
            '${formatMatchWhen(s.scheduledAt)} · ${s.durationMinutes} ${context.tr('د')}',
          ),
          _row(
            Icons.people_outline,
            detail == null
                ? '${s.maxPlayers} ${context.tr('لاعبين')}'
                : '${detail.currentPlayers}/${s.maxPlayers} ${context.tr('لاعبين')}',
          ),
          if (detail != null) ...[
            _row(
              detail.isWomen ? Icons.female : Icons.male,
              detail.isWomen ? context.tr('نساء') : context.tr('رجال'),
            ),
            _row(
              Icons.bar_chart,
              '${context.tr('المستوى')} ${_trim(detail.minLevel)} - ${_trim(detail.maxLevel)}',
            ),
            if (detail.createdAt != null)
              _row(
                Icons.event_note_outlined,
                '${context.tr('أُنشئ في')} ${formatMatchDate(detail.createdAt!)}',
              ),
          ],
        ],
      ),
    );
  }

  Widget _creatorCard(VenueMatchRequestDetail d) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context.tr('منشئ المباراة')),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              AppAvatar(
                name: d.creatorName,
                imageUrl: d.creatorAvatarUrl,
                radius: 22,
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.creatorName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (d.creatorPhone.isNotEmpty)
                      Text(
                        d.creatorPhone,
                        textDirection: TextDirection.ltr,
                        style: AppTextStyles.caption,
                      ),
                  ],
                ),
              ),
              if (d.creatorPhone.isNotEmpty)
                IconButton(
                  onPressed: () => _callCreator(d.creatorPhone),
                  icon: const Icon(Icons.phone, color: AppColors.primary),
                  tooltip: context.tr('اتصال'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _playersCard(VenueMatchRequestDetail d) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _sectionTitle(context.tr('اللاعبون'))),
              Text(
                '${d.currentPlayers}/${d.maxPlayers}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          if (d.players.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
              child: Text(
                context.tr('لم ينضم أي لاعب بعد'),
                style: AppTextStyles.caption,
              ),
            )
          else
            for (final p in d.players) _playerTile(p),
        ],
      ),
    );
  }

  Widget _playerTile(VenueMatchPlayer p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      child: Row(
        children: [
          LevelAvatar(
            name: p.name,
            imageUrl: p.avatarUrl,
            level: p.level,
            radius: 18,
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        p.name,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    if (p.isCreator) ...[
                      const SizedBox(width: AppSizes.xs),
                      _tag(context.tr('المنشئ'), AppColors.primary),
                    ],
                    if (!p.isApproved) ...[
                      const SizedBox(width: AppSizes.xs),
                      _tag(
                        p.status == 'invited'
                            ? context.tr('مدعو')
                            : context.tr('بانتظار الموافقة'),
                        AppColors.warning,
                      ),
                    ],
                  ],
                ),
                // الرقم في دائرة أسفل الصورة؛ هنا اسم المستوى بلونه.
                if (p.level != null)
                  Text(
                    PlayerLevelStyle.name(p.level!),
                    style: AppTextStyles.caption.copyWith(
                      color: PlayerLevelStyle.color(p.level!),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          _tag(
            p.hasPaid ? context.tr('دفع') : context.tr('لم يدفع'),
            p.hasPaid ? AppColors.success : AppColors.mutedForeground,
          ),
        ],
      ),
    );
  }

  Widget _moneyCard(VenueMatchRequestDetail d) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context.tr('التفاصيل المالية')),
          const SizedBox(height: AppSizes.md),
          _moneyRow(context.tr('حصة اللاعب'), d.pricePerPlayer),
          _moneyRow(context.tr('إجمالي المباراة'), d.totalPrice),
          _moneyRow(context.tr('المبلغ المحجوز'), d.amountHeld),
          const Divider(color: AppColors.divider, height: AppSizes.xl),
          Row(
            children: [
              Icon(
                d.isFullPayment ? Icons.payments_outlined : Icons.call_split,
                size: AppSizes.iconSm,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: Text(
                  context.tr(d.paymentLabel),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${context.tr('صافي ما ستستلمه')}'
                  '${d.sportaCommissionPercent > 0 ? ' (${context.tr('بعد نسبة سبورتا')} ${_trim(d.sportaCommissionPercent)}%)' : ''}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
              Text(
                '${money(d.ownerEarning)} ${context.tr('ر.س')}',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _notesCard(String notes) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context.tr('ملاحظات')),
          const SizedBox(height: AppSizes.sm),
          Text(notes, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _actions() {
    return SafeArea(
      minimum: const EdgeInsets.all(AppSizes.pagePadding),
      child: _busy
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSizes.sm),
                child: CircularProgressIndicator(),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _respond(true),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(context.tr('قبول')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _respond(false),
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(context.tr('رفض')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.destructive,
                      side: const BorderSide(color: AppColors.destructive),
                      minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: AppTextStyles.bodySmall.copyWith(
      color: AppColors.secondary,
      fontWeight: FontWeight.bold,
    ),
  );

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.xs),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.mutedForeground),
          const SizedBox(width: AppSizes.xs),
          Expanded(child: Text(text, style: AppTextStyles.caption)),
        ],
      ),
    );
  }

  Widget _moneyRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.caption)),
          Text(
            '${money(amount)} ${context.tr('ر.س')}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: color)),
    );
  }

  /// 4.0 → "4", 4.5 → "4.5".
  static String _trim(double v) =>
      v == v.roundToDouble() ? money(v) : v.toString();
}
