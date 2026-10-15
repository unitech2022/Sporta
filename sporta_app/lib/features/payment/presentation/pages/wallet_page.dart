import 'package:sporta_app/core/state/app_scope.dart';
import 'package:sporta_app/core/state/app_settings.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/load_more_listener.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/entities/wallet_entity.dart';
import '../cubit/wallet_cubit.dart';
import 'top_up_wallet_page.dart';
import 'withdraw_wallet_page.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/utils/money.dart';

/// Wallet screen: balance + quick actions + transactions.
class WalletPage extends StatelessWidget {
  const WalletPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    // .value: the cubit is shared via DI, so this page must not close it.
    return BlocProvider<WalletCubit>.value(
      value: getIt<WalletCubit>()..load(),
      child: _WalletView(onBack: onBack),
    );
  }
}

class _WalletView extends StatelessWidget {
  const _WalletView({required this.onBack});

  final VoidCallback onBack;

  static List<String> get _weekdaysAr => [
    trg('الاثنين'), trg('الثلاثاء'), trg('الأربعاء'), trg('الخميس'), trg('الجمعة'), trg('السبت'), trg('الأحد'),
  ];

  String _formatDate(DateTime d) =>
      '${_weekdaysAr[d.weekday - 1]} ${d.day}/${d.month}';

  Future<void> _topUp(BuildContext context, double balance) async {
    final cubit = context.read<WalletCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TopUpWalletPage(
          currentBalance: balance.round(),
          onBack: () => Navigator.of(context).pop(),
          onComplete: () => Navigator.of(context).pop(),
        ),
      ),
    );
    cubit.load();
  }

  Future<void> _withdraw(BuildContext context, WalletEntity wallet) async {
    final cubit = context.read<WalletCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WithdrawWalletPage(
          wallet: wallet,
          onBack: () => Navigator.of(context).pop(),
          onComplete: () => Navigator.of(context).pop(),
        ),
      ),
    );
    cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<WalletCubit, WalletState>(
          builder: (context, state) {
            return Column(
              children: [
                _header(context, state),
                Expanded(child: _body(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context, WalletState state) {
    final balance = state.wallet?.balance ?? 0;
    final wallet = state.wallet;
    final canWithdraw = wallet?.canWithdraw ?? false;
    final pendingAmount = wallet?.pendingWithdrawalAmount ?? 0;
    // Withdrawals are for earners (coaches, venues, creators) — not players.
    final showWithdraw =
        wallet != null && context.appSettings.role != UserRole.player;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSizes.pagePadding, AppSizes.xxxl,
              AppSizes.pagePadding, AppSizes.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button + title
              Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const DirectionalIcon(
                        rtl: Icons.arrow_forward,
                        ltr: Icons.arrow_back,
                        color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Text(context.tr('المحفظة'),
                      style: AppTextStyles.heading2
                          .copyWith(color: Colors.white)),
                ],
              ),
              const SizedBox(height: AppSizes.xl),

              // Balance display
              Text(context.tr('الرصيد الحالي'),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.white.withValues(alpha: 0.8))),
              const SizedBox(height: AppSizes.xs),
              // لا نعرض «0» قبل وصول الرصيد الفعلي.
              if (wallet == null && state.status != WalletStatus.failure)
                const Opacity(
                  opacity: 0.35,
                  child: Shimmer(
                    child: SkeletonBox(
                        width: 180, height: 48, radius: AppSizes.radiusMd),
                  ),
                )
              else
                Text(
                  '${money(balance)} ${context.tr('ر.س')}',
                  style: AppTextStyles.heading1
                      .copyWith(color: Colors.white, fontSize: 40),
                ),

              // Pending withdrawal chip
              if (pendingAmount > 0) ...[
                const SizedBox(height: AppSizes.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md, vertical: AppSizes.xs),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7).withValues(alpha: 0.2),
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusSm),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.hourglass_top_rounded,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${context.tr('بانتظار المراجعة')}: ${money(pendingAmount)} ${context.tr('ر.س')}',
                        style: AppTextStyles.caption
                            .copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSizes.lg),

              // Action buttons row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _topUp(context, balance),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusLg),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(context.tr('شحن المحفظة'),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  if (showWithdraw) ...[
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: canWithdraw
                            ? () => _withdraw(context, wallet)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canWithdraw
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.1),
                          foregroundColor: Colors.white,
                          disabledForegroundColor:
                              Colors.white.withValues(alpha: 0.5),
                          disabledBackgroundColor:
                              Colors.white.withValues(alpha: 0.08),
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLg),
                            side: BorderSide(
                              color: Colors.white
                                  .withValues(alpha: canWithdraw ? 0.5 : 0.2),
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.north_east, size: 18),
                        label: Text(context.tr('سحب الرصيد'),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ],
              ),

              // Withdrawal threshold hint
              if (showWithdraw && !canWithdraw && pendingAmount == 0) ...[
                const SizedBox(height: AppSizes.sm),
                Text(
                  '${context.tr('حد السحب الأدنى')}: ${money(wallet.withdrawalThreshold)} ${context.tr('ر.س')}',
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WalletState state) {
    if (state.status == WalletStatus.loading ||
        state.status == WalletStatus.initial) {
      return const SkeletonList(itemCount: 7);
    }
    if (state.status == WalletStatus.failure) {
      return Center(
        child: Text(state.error ?? context.tr('تعذّر تحميل المحفظة'),
            style: AppTextStyles.body.copyWith(color: AppColors.secondary)),
      );
    }

    final txns = state.transactions;
    return LoadMoreListener(
      // يحمّل التالي قرب النهاية، أو فوراً إن لم تملأ القائمة الشاشة.
      onLoadMore: () {
          context.read<WalletCubit>().loadMore();
      },
      child: ListView(
        padding: context.safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
        children: [
          Text(context.tr('سجل المعاملات'),
              style:
                  AppTextStyles.heading3.copyWith(color: AppColors.secondary)),
          const SizedBox(height: AppSizes.md),
          if (txns.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.xxl),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        color: AppColors.mutedForeground, size: 48),
                    const SizedBox(height: AppSizes.md),
                    Text(context.tr('لا توجد معاملات بعد'),
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.mutedForeground)),
                  ],
                ),
              ),
            )
          else ...[
            for (final t in txns) ...[
              _txnTile(context, t),
              const SizedBox(height: AppSizes.sm),
            ],
            if (state.loadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.lg),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              )
            else if (!state.txHasMore && txns.length > 8)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
                child: Center(
                  child: Text(context.tr('لا مزيد من المعاملات'),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedForeground)),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _txnTile(BuildContext context, WalletTransactionEntity t) {
    final credit = t.isCredit;
    final failed = t.hasFailed;

    // A failed attempt is a log entry, not a movement — it must never read as
    // money that left the wallet, so it is greyed out and struck through.
    final color = failed
        ? AppColors.mutedForeground
        : (credit ? AppColors.success : AppColors.destructive);
    final icon = failed ? Icons.error_outline : _txnIcon(t.type, credit);

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.description ?? t.typeLabel,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  failed
                      ? '${t.typeLabel} · ${context.tr('لم تتم')} · ${_formatDate(t.createdAt)}'
                      : '${t.typeLabel} · ${_formatDate(t.createdAt)}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Text(
            '${credit && !failed ? '+' : ''}${money(t.amount)} ${context.tr('ر.س')}',
            style: AppTextStyles.body.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              decoration: failed ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }

  IconData _txnIcon(String type, bool credit) {
    switch (type) {
      case 'deposit':
        return Icons.add_card_outlined;
      case 'refund':
        return Icons.undo_rounded;
      case 'withdrawal':
        return Icons.north_east;
      case 'coachEarning':
        return Icons.sports_outlined;
      case 'venueEarning':
        return Icons.stadium_outlined;
      case 'reward':
        return Icons.star_outline_rounded;
      default:
        return credit ? Icons.south_west : Icons.north_east;
    }
  }
}
