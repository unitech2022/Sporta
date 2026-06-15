import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

// ─── Local palette ────────────────────────────────────────────────────────────
const Color _green500 = Color(0xFF22C55E);
const Color _green600 = Color(0xFF16A34A);
const Color _blue600 = Color(0xFF2563EB);
const Color _blue700 = Color(0xFF1D4ED8);
const Color _purple600 = Color(0xFF9333EA);
const Color _purple700 = Color(0xFF7E22CE);
const Color _yellow50 = Color(0xFFFEFCE8);
const Color _yellow100 = Color(0xFFFEF9C3);
const Color _yellow600 = Color(0xFFCA8A04);
const Color _gray50 = Color(0xFFF9FAFB);
const Color _gray100 = Color(0xFFF3F4F6);
const Color _gray200 = Color(0xFFE5E7EB);
const Color _gray400 = Color(0xFF9CA3AF);

// ─── Payment method enum ──────────────────────────────────────────────────────
enum _TopUpMethod { creditCard, applePay, stcPay, mada }

// ─── TopUpWalletPage ──────────────────────────────────────────────────────────
class TopUpWalletPage extends StatefulWidget {
  const TopUpWalletPage({
    super.key,
    required this.onBack,
    this.onComplete,
    this.currentBalance = 250,
  });

  final VoidCallback onBack;
  final VoidCallback? onComplete;
  final int currentBalance;

  @override
  State<TopUpWalletPage> createState() => _TopUpWalletPageState();
}

class _TopUpWalletPageState extends State<TopUpWalletPage> {
  static const List<int> _quickAmounts = [50, 100, 200, 500, 1000, 2000];

  int? _selectedAmount;
  _TopUpMethod? _selectedMethod;
  final _customAmountCtrl = TextEditingController();
  String _amountError = '';
  bool _isProcessing = false;

  @override
  void dispose() {
    _customAmountCtrl.dispose();
    super.dispose();
  }

  // ── Effective amount ─────────────────────────────────────────────────────
  int? get _effectiveAmount {
    if (_selectedAmount != null) return _selectedAmount;
    final parsed = int.tryParse(_customAmountCtrl.text.trim());
    return parsed;
  }

  bool get _canProceed =>
      _effectiveAmount != null &&
      _effectiveAmount! >= 10 &&
      _selectedMethod != null;

  String _methodLabel(_TopUpMethod m) {
    switch (m) {
      case _TopUpMethod.creditCard:
        return 'بطاقة ائتمانية';
      case _TopUpMethod.applePay:
        return 'Apple Pay';
      case _TopUpMethod.stcPay:
        return 'STC Pay';
      case _TopUpMethod.mada:
        return 'مدى';
    }
  }

  // ── Validate custom amount ────────────────────────────────────────────────
  void _onCustomAmountChanged(String value) {
    setState(() {
      _selectedAmount = null;
      final parsed = int.tryParse(value.trim());
      if (value.trim().isEmpty) {
        _amountError = '';
      } else if (parsed == null) {
        _amountError = 'أدخل رقماً صحيحاً';
      } else if (parsed < 10) {
        _amountError = 'الحد الأدنى للشحن 10 ر.س';
      } else {
        _amountError = '';
      }
    });
  }

  // ── Confirm ──────────────────────────────────────────────────────────────
  void _showConfirmDialog() {
    final amount = _effectiveAmount!;
    final method = _methodLabel(_selectedMethod!);
    final newBalance = widget.currentBalance + amount;

    showDialog<void>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          ),
          contentPadding: const EdgeInsets.all(AppSizes.pagePadding),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: AppSizes.xl,
                ),
              ),
              SizedBox(height: AppSizes.lg),
              Text(
                'تأكيد شحن الرصيد',
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.xl),
              _buildConfirmRow('المبلغ', '$amount ر.س'),
              const SizedBox(height: AppSizes.sm),
              _buildConfirmRow('طريقة الدفع', method),
              const SizedBox(height: AppSizes.sm),
              _buildConfirmRow('رسوم المعاملة', 'مجاناً',
                  valueColor: _green600),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.sm),
                child: Divider(color: AppColors.border),
              ),
              _buildConfirmRow('الرصيد الجديد', '$newBalance ر.س',
                  valueColor: AppColors.primary, bold: true),
              SizedBox(height: AppSizes.xl),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: _gray100,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusLg),
                        ),
                        child: Center(
                          child: Text(
                            'إلغاء',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.secondary),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSizes.md),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _processTopUp();
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusLg),
                        ),
                        child: Center(
                          child: Text(
                            'تأكيد',
                            style: AppTextStyles.body
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmRow(String label, String value,
      {Color? valueColor, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: valueColor ?? AppColors.secondary,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Future<void> _processTopUp() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isProcessing = false);
    widget.onComplete?.call();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBalanceCard(),
                    const SizedBox(height: AppSizes.xl),
                    _buildQuickAmountsSection(),
                    const SizedBox(height: AppSizes.xl),
                    _buildPaymentMethodsSection(),
                    const SizedBox(height: AppSizes.xl),
                    if (_canProceed) ...[
                      _buildSummaryCard(),
                      const SizedBox(height: AppSizes.xl),
                    ],
                    _buildInfoNote(),
                    const SizedBox(height: AppSizes.xl),
                    _buildActionButtons(),
                    const SizedBox(height: AppSizes.xxxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.xxxl,
            AppSizes.pagePadding,
            AppSizes.xl,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: AppSizes.iconMd,
                  ),
                ),
              ),
              SizedBox(width: AppSizes.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'شحن الرصيد',
                    style: AppTextStyles.heading2
                        .copyWith(color: Colors.white),
                  ),
                  Text(
                    'اختر المبلغ وطريقة الدفع',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Balance card ─────────────────────────────────────────────────────────
  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [_green500, _green600],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: AppSizes.xl,
            ),
          ),
          SizedBox(width: AppSizes.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الرصيد الحالي',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              Text(
                '${widget.currentBalance} ر.س',
                style: AppTextStyles.heading2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Quick amounts ─────────────────────────────────────────────────────────
  Widget _buildQuickAmountsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر المبلغ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSizes.sm,
          mainAxisSpacing: AppSizes.sm,
          childAspectRatio: 2.2,
          children: _quickAmounts.map((amount) {
            final selected = _selectedAmount == amount;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAmount = amount;
                  _customAmountCtrl.clear();
                  _amountError = '';
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.card,
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$amount ر.س',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: selected
                          ? AppColors.primary
                          : AppColors.secondary,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: AppSizes.md),
        TextField(
          controller: _customAmountCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: _onCustomAmountChanged,
          decoration: InputDecoration(
            hintText: 'أو أدخل مبلغاً مخصصاً',
            hintStyle:
                AppTextStyles.bodySmall.copyWith(color: _gray400),
            filled: true,
            fillColor: _gray50,
            prefixIcon: const Icon(Icons.edit_outlined,
                size: AppSizes.iconSm, color: AppColors.mutedForeground),
            suffix: const Text('ر.س'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              borderSide: BorderSide(
                color: _amountError.isNotEmpty ? AppColors.destructive : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              borderSide: BorderSide(
                color: _amountError.isNotEmpty
                    ? AppColors.destructive
                    : AppColors.primary,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.md,
            ),
            isDense: true,
          ),
        ),
        if (_amountError.isNotEmpty) ...[
          SizedBox(height: AppSizes.xs),
          Text(
            _amountError,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.destructive),
          ),
        ],
      ],
    );
  }

  // ── Payment methods ──────────────────────────────────────────────────────
  Widget _buildPaymentMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'طريقة الدفع',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSizes.sm,
          mainAxisSpacing: AppSizes.sm,
          childAspectRatio: 2.5,
          children: [
            _buildMethodCard(
              method: _TopUpMethod.creditCard,
              label: 'بطاقة ائتمانية',
              icon: Icons.credit_card,
              gradient: const LinearGradient(
                colors: [_blue600, _blue700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            _buildMethodCard(
              method: _TopUpMethod.applePay,
              label: 'Apple Pay',
              icon: Icons.apple,
              gradient: const LinearGradient(
                colors: [Color(0xFF1C1C1E), Color(0xFF3A3A3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            _buildMethodCard(
              method: _TopUpMethod.stcPay,
              label: 'STC Pay',
              icon: Icons.phone_android,
              gradient: const LinearGradient(
                colors: [_purple600, _purple700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            _buildMethodCard(
              method: _TopUpMethod.mada,
              label: 'مدى',
              icon: Icons.payment,
              gradient: const LinearGradient(
                colors: [_green500, _green600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMethodCard({
    required _TopUpMethod method,
    required String label,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    final selected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: AppSizes.iconMd),
                  SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Positioned(
                top: AppSizes.sm,
                left: AppSizes.sm,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      size: 12, color: AppColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Summary card ─────────────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    final amount = _effectiveAmount!;
    final newBalance = widget.currentBalance + amount;
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: AppSizes.iconSm, color: AppColors.primary),
              SizedBox(width: AppSizes.sm),
              Text(
                'ملخص العملية',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.md),
          _buildSummaryRow('المبلغ', '$amount ر.س'),
          SizedBox(height: AppSizes.sm),
          _buildSummaryRow('رسوم المعاملة', 'مجاناً',
              valueColor: _green600),
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.sm),
            child: Divider(color: AppColors.border),
          ),
          _buildSummaryRow('الرصيد الجديد', '$newBalance ر.س',
              valueColor: AppColors.primary, bold: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {Color? valueColor, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: valueColor ?? AppColors.secondary,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ── Info note ────────────────────────────────────────────────────────────
  Widget _buildInfoNote() {
    const bullets = [
      'الحد الأدنى للشحن 10 ر.س',
      'الحد الأقصى للشحن في المرة الواحدة 5000 ر.س',
      'لا توجد رسوم على عمليات الشحن',
      'الرصيد صالح للاستخدام فور اكتمال عملية الدفع',
    ];
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: _yellow50,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: _yellow100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  size: AppSizes.iconSm, color: _yellow600),
              SizedBox(width: AppSizes.sm),
              Text(
                'معلومات هامة',
                style: AppTextStyles.bodySmall.copyWith(
                  color: _yellow600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.md),
          for (final bullet in bullets) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•',
                    style: AppTextStyles.caption
                        .copyWith(color: _yellow600)),
                SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    bullet,
                    style: AppTextStyles.caption
                        .copyWith(color: _yellow600),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.xs),
          ],
        ],
      ),
    );
  }

  // ── Action buttons ───────────────────────────────────────────────────────
  Widget _buildActionButtons() {
    final enabled = _canProceed && !_isProcessing;
    return Row(
      children: [
        GestureDetector(
          onTap: widget.onBack,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.xl,
              vertical: AppSizes.md,
            ),
            decoration: BoxDecoration(
              color: _gray100,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Text(
              'رجوع',
              style: AppTextStyles.body.copyWith(color: AppColors.secondary),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: GestureDetector(
            onTap: enabled ? _showConfirmDialog : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: AppSizes.buttonHeight,
              decoration: BoxDecoration(
                gradient: enabled ? AppColors.primaryGradient : null,
                color: enabled ? null : _gray200,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Center(
                child: _isProcessing
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'إتمام الشحن',
                        style: AppTextStyles.body.copyWith(
                          color: enabled ? Colors.white : _gray400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
