import 'package:flutter/material.dart';
import 'package:sporta_app/core/state/app_scope.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../data/wallet_repository.dart';
import '../../domain/entities/wallet_entity.dart';
import '../widgets/payment_confirm_dialog.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/utils/money.dart';

/// Page for requesting a wallet withdrawal.
class WithdrawWalletPage extends StatefulWidget {
  const WithdrawWalletPage({
    super.key,
    required this.wallet,
    required this.onBack,
    required this.onComplete,
  });

  final WalletEntity wallet;
  final VoidCallback onBack;
  final VoidCallback onComplete;

  @override
  State<WithdrawWalletPage> createState() => _WithdrawWalletPageState();
}

class _WithdrawWalletPageState extends State<WithdrawWalletPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();

  bool _submitting = false;
  String? _error;

  late final WalletRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = getIt<WalletRepository>();
    _amountCtrl.text =
        widget.wallet.balance.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _ibanCtrl.dispose();
    _bankCtrl.dispose();
    _holderCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;
    if (amount > widget.wallet.balance) {
      setState(() => _error = context.tr('المبلغ أكبر من رصيد محفظتك'));
      return;
    }

    // المبلغ يُخصم من المحفظة لحظة تقديم الطلب (ويُعاد إن رُفض)، فيُعرض على
    // العميل قبل التنفيذ مع رصيده قبل الخصم وبعده.
    final iban = _ibanCtrl.text.trim().replaceAll(' ', '');
    final confirmed = await showPaymentConfirmDialog(
      context,
      title: context.tr('تأكيد طلب السحب'),
      amount: amount,
      headline: 'سيتم خصم المبلغ التالي من محفظتك وتحويله إلى حسابك البنكي.',
      amountLabel: 'مبلغ السحب',
      details: [
        PaymentDetail(context.tr('البنك'), _bankCtrl.text.trim()),
        PaymentDetail(context.tr('صاحب الحساب'), _holderCtrl.text.trim()),
        PaymentDetail(
          context.tr('الآيبان'),
          iban.length > 8 ? '•••• ${iban.substring(iban.length - 4)}' : iban,
        ),
      ],
      footnote: 'يُراجع الطلب من الإدارة قبل التحويل، وإن رُفض يُعاد المبلغ إلى محفظتك.',
      confirmLabel: context.tr('تأكيد السحب'),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await _repo.requestWithdrawal(
        amount: amount,
        iban: _ibanCtrl.text.trim(),
        bankName: _bankCtrl.text.trim(),
        accountHolderName: _holderCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('تم تقديم طلب السحب بنجاح')),
          backgroundColor: AppColors.success,
        ),
      );
      widget.onComplete();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final threshold = widget.wallet.withdrawalThreshold;
    final balance = widget.wallet.balance;

    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: context
                    .safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance card
                      _BalanceCard(balance: balance, threshold: threshold),
                      const SizedBox(height: AppSizes.xl),

                      // Amount field
                      Text(context.tr('المبلغ'),
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.secondary)),
                      const SizedBox(height: AppSizes.sm),
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          suffix: Text(context.tr('ر.س')),
                          hintText: '0',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n <= 0)
                            return context.tr('fieldRequired');
                          if (n > balance)
                            return context.tr('رصيدك الحالي لا يكفي لإتمام العملية.\nيرجى شحن المحفظة والمحاولة مجدداً.');
                          if (n < threshold)
                            return context
                                .tr('الرصيد يجب أن يبلغ %s ر.س على الأقل للسحب')
                                .replaceAll('%s', money(threshold));
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizes.lg),

                      // IBAN
                      _label(context, context.tr('رقم الآيبان (IBAN)')),
                      const SizedBox(height: AppSizes.sm),
                      TextFormField(
                        controller: _ibanCtrl,
                        decoration: InputDecoration(
                          hintText: context.tr('أدخل رقم الآيبان'),
                          prefixIcon: const Icon(Icons.account_balance_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? context.tr('fieldRequired')
                            : null,
                      ),
                      const SizedBox(height: AppSizes.lg),

                      // Bank name
                      _label(context, context.tr('اسم البنك')),
                      const SizedBox(height: AppSizes.sm),
                      TextFormField(
                        controller: _bankCtrl,
                        decoration: InputDecoration(
                          hintText: context.tr('أدخل اسم البنك'),
                          prefixIcon: const Icon(Icons.business_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? context.tr('fieldRequired')
                            : null,
                      ),
                      const SizedBox(height: AppSizes.lg),

                      // Account holder
                      _label(context, context.tr('اسم صاحب الحساب')),
                      const SizedBox(height: AppSizes.sm),
                      TextFormField(
                        controller: _holderCtrl,
                        decoration: InputDecoration(
                          hintText: context.tr('أدخل اسم صاحب الحساب'),
                          prefixIcon: const Icon(Icons.person_outline),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? context.tr('fieldRequired')
                            : null,
                      ),
                      const SizedBox(height: AppSizes.xl),

                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSizes.md),
                          decoration: BoxDecoration(
                            color: AppColors.destructive.withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLg),
                            border: Border.all(
                                color: AppColors.destructive
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.destructive, size: 20),
                              const SizedBox(width: AppSizes.sm),
                              Expanded(
                                child: Text(_error!,
                                    style: AppTextStyles.bodySmall
                                        .copyWith(
                                            color: AppColors.destructive)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.lg),
                      ],

                      SizedBox(
                        width: double.infinity,
                        height: AppSizes.buttonHeight,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusLg),
                            ),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white))
                              : Text(context.tr('تأكيد طلب السحب')),
                        ),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.xxxl,
            AppSizes.pagePadding,
            AppSizes.xxl,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const DirectionalIcon(
                    rtl: Icons.arrow_forward,
                    ltr: Icons.arrow_back,
                    color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: AppSizes.md),
              Text(context.tr('سحب الرصيد'),
                  style:
                      AppTextStyles.heading2.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Text(text,
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary));
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.threshold});
  final double balance;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('رصيدك الحالي'),
              style: AppTextStyles.bodySmall
                  .copyWith(color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(height: AppSizes.xs),
          Text(
            '${money(balance)} ${context.tr('ر.س')}',
            style: AppTextStyles.heading1
                .copyWith(color: Colors.white, fontSize: 32),
          ),
          const SizedBox(height: AppSizes.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md, vertical: AppSizes.xs),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Text(
              '${context.tr('حد السحب الأدنى')}: ${money(threshold)} ${context.tr('ر.س')}',
              style: AppTextStyles.caption
                  .copyWith(color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}
