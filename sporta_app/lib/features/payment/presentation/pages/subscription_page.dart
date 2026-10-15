import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/entities/subscription_entity.dart';
import '../cubit/subscription_cubit.dart';
import '../widgets/payment_confirm_dialog.dart';
import '../widgets/package_card.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/system_insets.dart';

/// شاشة «الاشتراكات»: تعرض كل أنواع الاشتراك التي أضافها الأدمن (شهري/سنوي)
/// مع مزاياها وأسعارها،
/// وتتيح الاشتراك في أي منها أو إلغاء الاشتراك الحالي. متاحة لكل الأدوار
/// (لاعب / مدرب) من قسم «حسابي».
class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SubscriptionCubit>(
      create: (_) => getIt<SubscriptionCubit>()..load(),
      child: _View(onBack: onBack),
    );
  }
}

class _View extends StatelessWidget {
  const _View({required this.onBack});

  final VoidCallback onBack;

  Future<void> _run(
      BuildContext context, Future<String?> Function() act, String ok) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await act();
    messenger.showSnackBar(SnackBar(content: Text(error ?? ok)));
  }

  /// الاشتراك هو العملية الوحيدة هنا التي تخصم من المحفظة — الإلغاء مجاني.
  /// و«بالنسبة» لا يخصم شيئاً، فيؤكَّد بحوار عادي بلا مبلغ.
  Future<void> _subscribe(
    BuildContext context,
    SubscriptionCubit cubit,
    PackageEntity package,
  ) async {
    if (package.isCommission) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.tr('تأكيد الاشتراك')),
          content: Text(
            '${ctx.tr('اشتراك')} ${package.name}: '
            '${ctx.tr('بلا رسوم مقدَّمة، وتأخذ سبورتا')} '
            '${PackageEntity.fmt(package.commissionPercent)}% '
            '${ctx.tr('من كل عملية حتى تلغي الاشتراك.')}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.tr('تراجع')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.tr('تأكيد الاشتراك')),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
      await _run(
        context,
        () => cubit.subscribe(packageId: package.id),
        trgArgs('تم الاشتراك في {p0} 🎉', {'p0': package.name}),
      );
      return;
    }

    final confirmed = await showPaymentConfirmDialog(
      context,
      title: context.tr('تأكيد الاشتراك'),
      amount: package.priceAfterDiscount,
      details: [
        PaymentDetail(context.tr('الاشتراك'), package.name),
        PaymentDetail(context.tr('النوع'),
            trgArgs('{p0} ({p1} يوم)', {'p0': context.tr(package.periodLabel), 'p1': package.durationDays})),
        if (package.hasDiscount)
          PaymentDetail(context.tr('الخصم'),
              '${PackageEntity.fmt(package.discountPercent)}%'),
      ],
      confirmLabel: context.tr('تأكيد الاشتراك'),
    );
    if (confirmed != true || !context.mounted) return;
    await _run(
      context,
      () => cubit.subscribe(packageId: package.id),
      trgArgs('تم الاشتراك في {p0} 🎉', {'p0': package.name}),
    );
  }

  Future<void> _cancel(BuildContext context, SubscriptionCubit cubit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('إلغاء الاشتراك')),
        content: Text(ctx.tr('سيتم إيقاف مزايا الاشتراك فوراً. هل تريد المتابعة؟')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('تراجع')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr('إلغاء الاشتراك'),
                style: const TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _run(context, cubit.cancel, trg('تم إلغاء الاشتراك'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: BlocBuilder<SubscriptionCubit, SubscriptionState>(
              builder: (context, state) {
                if (state.status == SubscriptionStatus.loading ||
                    state.status == SubscriptionStatus.initial) {
                  return const SkeletonCardList(itemCount: 2, imageHeight: 72);
                }
                if (state.status == SubscriptionStatus.failure) {
                  return _error(context, state.error);
                }
                return RefreshIndicator(
                  onRefresh: () => context.read<SubscriptionCubit>().load(),
                  child: _body(context, state),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _error(BuildContext context, String? error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error ?? context.tr('تعذّر التحميل'),
                  textAlign: TextAlign.center,
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.secondary)),
              const SizedBox(height: AppSizes.md),
              TextButton(
                onPressed: () => context.read<SubscriptionCubit>().load(),
                child: Text(context.tr('إعادة المحاولة')),
              ),
            ],
          ),
        ),
      );

  Widget _header(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.pagePadding,
              AppSizes.xxxl, AppSizes.pagePadding, AppSizes.xxl),
          child: Row(
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
              Text(context.tr('الاشتراكات'),
                  style: AppTextStyles.heading2.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, SubscriptionState state) {
    final sub = state.subscription;
    final cubit = context.read<SubscriptionCubit>();
    final activeId = state.activePackageId;

    return ListView(
      padding: context.safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
      children: [
        if (sub != null && sub.isPlus) _activeBanner(context, sub, state, cubit),
        if (state.packages.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.xxxl),
            child: Center(
              child: Text(context.tr('لا توجد اشتراكات متاحة حالياً'),
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.mutedForeground)),
            ),
          )
        else ...[
          Text(context.tr('الاشتراكات المتاحة'),
              style:
                  AppTextStyles.heading3.copyWith(color: AppColors.secondary)),
          const SizedBox(height: AppSizes.md),
          for (final p in state.packages)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.lg),
              child: PackageCard(
                package: p,
                isCurrent: p.id == activeId,
                busy: state.busyPackageId == p.id,
                // لا اشتراك جديد أثناء تنفيذ عملية أخرى، ولا في اشتراك قائم.
                onSubscribe: state.busy || p.id == activeId
                    ? null
                    : () => _subscribe(context, cubit, p),
              ),
            ),
        ],
        const SizedBox(height: AppSizes.xl),
      ],
    );
  }

  Widget _activeBanner(BuildContext context, SubscriptionEntity sub,
      SubscriptionState state, SubscriptionCubit cubit) {
    final name = sub.packageName.isNotEmpty ? sub.packageName : 'Sporta Plus';
    final end = sub.endDate;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.xl),
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium,
                  color: AppColors.brandGold, size: 32),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  '${context.tr('أنت مشترك في')} $name',
                  style: AppTextStyles.heading3.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            end != null
                ? '${context.tr('ساري حتى')} ${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}'
                : context.tr('ساري بلا تاريخ انتهاء'),
            style: AppTextStyles.bodySmall
                .copyWith(color: Colors.white.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: AppSizes.md),
          TextButton(
            onPressed: state.busy ? null : () => _cancel(context, cubit),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg, vertical: AppSizes.sm),
            ),
            child: Text(context.tr('إلغاء الاشتراك')),
          ),
        ],
      ),
    );
  }
}
