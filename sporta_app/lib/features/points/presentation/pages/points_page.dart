import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/state/auth_scope.dart';
import '../../domain/entities/points_entity.dart';
import '../cubit/points_cubit.dart';
import '../widgets/levels_ladder.dart';
import '../widgets/points_ledger_tile.dart';
import '../widgets/points_rules_section.dart';
import '../widgets/points_summary_header.dart';
import '../widgets/redeem_points_sheet.dart';
import '../../../../core/utils/system_insets.dart';

/// صفحة النقاط: نقاط المكافآت ونقاط المستوى، قواعد كسبهما، سُلَّم المستويات،
/// ثم السجل بفلتر النوع.
class PointsPage extends StatelessWidget {
  const PointsPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PointsCubit>(
      create: (_) => getIt<PointsCubit>()..load(),
      child: _PointsView(onBack: onBack),
    );
  }
}

/// فلتر السجل: الكل / مكافآت / مستوى.
enum _LedgerFilter { all, reward, level }

class _PointsView extends StatefulWidget {
  const _PointsView({required this.onBack});

  final VoidCallback onBack;

  @override
  State<_PointsView> createState() => _PointsViewState();
}

class _PointsViewState extends State<_PointsView> {
  _LedgerFilter _filter = _LedgerFilter.all;

  Future<void> _redeem(PointsSummaryEntity summary) async {
    final cubit = context.read<PointsCubit>();
    final redeemed = await showRedeemPointsSheet(context, cubit, summary);
    if (redeemed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.tr('تم تحويل النقاط إلى رصيد المحفظة بنجاح')),
        backgroundColor: AppColors.success,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<PointsCubit, PointsState>(
          builder: (context, state) {
            return Column(
              children: [
                PointsSummaryHeader(
                  summary: state.summary,
                  onBack: widget.onBack,
                  onRedeem: () {
                    if (state.summary != null) _redeem(state.summary!);
                  },
                ),
                Expanded(child: _body(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context, PointsState state) {
    if (state.status == PointsStatus.loading && state.summary == null) {
      return const SkeletonList();
    }
    if (state.status == PointsStatus.failure && state.summary == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error ?? context.tr('حدث خطأ'),
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSizes.md),
            TextButton(
              onPressed: () => context.read<PointsCubit>().load(),
              child: Text(context.tr('إعادة المحاولة')),
            ),
          ],
        ),
      );
    }

    final summary = state.summary;
    final transactions = switch (_filter) {
      _LedgerFilter.all => state.transactions,
      _LedgerFilter.reward =>
        state.transactions.where((t) => !t.isLevel).toList(),
      _LedgerFilter.level => state.transactions.where((t) => t.isLevel).toList(),
    };

    return RefreshIndicator(
      onRefresh: () => context.read<PointsCubit>().load(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) {
            context.read<PointsCubit>().loadMore();
          }
          return false;
        },
        child: ListView(
          padding: context
              .safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
          children: [
            if (summary != null) ...[
              RewardRulesSection(summary: summary),
              const SizedBox(height: AppSizes.lg),
              LevelRulesSection(summary: summary),
              const SizedBox(height: AppSizes.lg),
            ],
            if (state.levels.isNotEmpty) ...[
              LevelsLadder(
                levels: state.levels,
                myLevel: context.auth.user?.level,
              ),
              const SizedBox(height: AppSizes.lg),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(context.tr('سجل النقاط'),
                      style: AppTextStyles.heading3),
                ),
                _filterChip(context, _LedgerFilter.all, context.tr('الكل')),
                const SizedBox(width: AppSizes.xs),
                _filterChip(context, _LedgerFilter.reward, context.tr('مكافآت')),
                const SizedBox(width: AppSizes.xs),
                _filterChip(context, _LedgerFilter.level, context.tr('مستوى')),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            if (transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.xxl),
                child: Center(
                  child: Text(
                    context.tr('لا توجد حركات نقاط بعد — احجز والعب لتكسب!'),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.mutedForeground),
                  ),
                ),
              )
            else
              ...transactions.map((t) => PointsLedgerTile(transaction: t)),
            if (state.loadingMore)
              const Padding(
                padding: EdgeInsets.all(AppSizes.md),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(BuildContext context, _LedgerFilter value, String label) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: AppSizes.xs),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: AppTextStyles.caption.copyWith(
                color: selected ? Colors.white : AppColors.secondary)),
      ),
    );
  }
}
