import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/booking_details.dart';

// ─── Local palette ────────────────────────────────────────────────────────────
const Color _green50 = Color(0xFFF0FDF4);
const Color _green100 = Color(0xFFDCFCE7);
const Color _green200 = Color(0xFFBBF7D0);
const Color _green500 = Color(0xFF22C55E);
const Color _green600 = Color(0xFF16A34A);
const Color _red50 = Color(0xFFFEF2F2);
const Color _red300 = Color(0xFFFCA5A5);
const Color _red500 = Color(0xFFEF4444);
const Color _red600 = Color(0xFFDC2626);
const Color _blue600 = Color(0xFF2563EB);
const Color _blue700 = Color(0xFF1D4ED8);
const Color _blue50 = Color(0xFFEFF6FF);
const Color _purple700 = Color(0xFF7E22CE);
const Color _purple600 = Color(0xFF9333EA);
const Color _amber500 = Color(0xFFF59E0B);
const Color _amber50 = Color(0xFFFFFBEB);
const Color _gray50 = Color(0xFFF9FAFB);
const Color _gray100 = Color(0xFFF3F4F6);
const Color _gray200 = Color(0xFFE5E7EB);
const Color _gray400 = Color(0xFF9CA3AF);

// ─── Payment method enum ──────────────────────────────────────────────────────
enum _PaymentMethod { wallet, visa, mada, applePay }

// ─── Default booking ─────────────────────────────────────────────────────────
const BookingDetails _defaultBooking = BookingDetails(
  courtName: 'نادي البادل الملكي',
  date: 'السبت، 6 يونيو',
  time: '04:00 مساءً',
  duration: '60 دقيقة',
  totalPrice: 280,
);

const int _walletBalance = 150;
const String _validPromoCode = 'SPORTA10';

// ─── Card number formatter ────────────────────────────────────────────────────
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 16 ? digits.substring(0, 16) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(limited[i]);
    }
    final result = buffer.toString();
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

// ─── Expiry formatter ────────────────────────────────────────────────────────
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 4 ? digits.substring(0, 4) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(limited[i]);
    }
    final result = buffer.toString();
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

// ─── PaymentPage ─────────────────────────────────────────────────────────────
class PaymentPage extends StatefulWidget {
  const PaymentPage({
    super.key,
    required this.onBack,
    this.onComplete,
    this.bookingDetails,
  });

  final VoidCallback onBack;
  final VoidCallback? onComplete;
  final BookingDetails? bookingDetails;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late final BookingDetails _booking;
  late final String _bookingRef;

  _PaymentMethod _selectedMethod = _PaymentMethod.wallet;
  bool _summaryExpanded = false;
  bool _promoApplied = false;
  String _promoError = '';
  bool _isProcessing = false;
  bool _showSuccess = false;

  // card form
  final _cardNumberCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  bool _saveCard = false;
  bool _showCvv = false;
  final _promoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _booking = widget.bookingDetails ?? _defaultBooking;
    _bookingRef = 'SP${100000 + Random().nextInt(900000)}';
    _cardNameCtrl.addListener(() {
      final upper = _cardNameCtrl.text.toUpperCase();
      if (_cardNameCtrl.text != upper) {
        _cardNameCtrl.value = _cardNameCtrl.value.copyWith(
          text: upper,
          selection: TextSelection.collapsed(offset: upper.length),
        );
      }
      setState(() {});
    });
    _cardNumberCtrl.addListener(() => setState(() {}));
    _expiryCtrl.addListener(() => setState(() {}));
    _cvvCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _cardNameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _promoCtrl.dispose();
    super.dispose();
  }

  // ── Price logic ──────────────────────────────────────────────────────────
  int get _subtotal => _booking.totalPrice;
  int get _vat => (_subtotal * 0.15).round();
  int get _discount => _promoApplied ? (_subtotal * 0.1).round() : 0;
  int get _total => _subtotal + _vat - _discount;
  bool get _walletInsufficient => _walletBalance < _total;

  // ── Validation ───────────────────────────────────────────────────────────
  bool get _isFormValid {
    switch (_selectedMethod) {
      case _PaymentMethod.wallet:
        return !_walletInsufficient;
      case _PaymentMethod.applePay:
        return true;
      case _PaymentMethod.visa:
      case _PaymentMethod.mada:
        final digits =
            _cardNumberCtrl.text.replaceAll(RegExp(r'\D'), '');
        return digits.length == 16 &&
            _cardNameCtrl.text.trim().isNotEmpty &&
            _expiryCtrl.text.length == 5 &&
            _cvvCtrl.text.length == 3;
    }
  }

  // ── Promo ────────────────────────────────────────────────────────────────
  void _applyPromo() {
    final code = _promoCtrl.text.trim().toUpperCase();
    if (_promoApplied) {
      setState(() {
        _promoApplied = false;
        _promoCtrl.clear();
        _promoError = '';
      });
      return;
    }
    if (code == _validPromoCode) {
      setState(() {
        _promoApplied = true;
        _promoError = '';
      });
    } else {
      setState(() => _promoError = 'كود الخصم غير صحيح');
    }
  }

  // ── Payment ──────────────────────────────────────────────────────────────
  Future<void> _pay() async {
    if (!_isFormValid || _isProcessing) return;
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _showSuccess = true;
    });
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    _handleSuccessClose();
  }

  void _handleSuccessClose() {
    setState(() => _showSuccess = false);
    widget.onComplete?.call();
  }

  // ── Card masking ─────────────────────────────────────────────────────────
  String _maskedNumber() {
    final digits =
        _cardNumberCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '•••• •••• •••• ••••';
    final padded = digits.padRight(16, '•');
    final visible = padded.substring(12);
    final masked = '•••• •••• •••• $visible';
    return masked;
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizes.pagePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSummaryCard(),
                        const SizedBox(height: AppSizes.xl),
                        _buildPromoSection(),
                        const SizedBox(height: AppSizes.xl),
                        _buildPaymentMethodsSection(),
                        const SizedBox(height: AppSizes.xl),
                        if (_selectedMethod == _PaymentMethod.visa ||
                            _selectedMethod == _PaymentMethod.mada)
                          _buildCardForm(),
                        if (_selectedMethod == _PaymentMethod.applePay)
                          _buildApplePaySection(),
                        if (_selectedMethod == _PaymentMethod.wallet &&
                            _walletInsufficient)
                          _buildInsufficientWallet(),
                        const SizedBox(height: AppSizes.xl),
                        _buildSecurityNotice(),
                        const SizedBox(height: AppSizes.xl),
                        _buildPayButton(),
                        const SizedBox(height: AppSizes.xxxl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_showSuccess) _buildSuccessOverlay(),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
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
                    color: Colors.white.withValues(alpha: 0.15),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إتمام الدفع',
                      style: AppTextStyles.heading2
                          .copyWith(color: Colors.white),
                    ),
                    Text(
                      'آمن ومشفر بالكامل',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline,
                        size: 12, color: Colors.white),
                    SizedBox(width: AppSizes.xs),
                    Text(
                      'SSL',
                      style:
                          AppTextStyles.caption.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Summary card ─────────────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    return Container(
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
        children: [
          InkWell(
            onTap: () =>
                setState(() => _summaryExpanded = !_summaryExpanded),
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusLg),
                    ),
                    child: const Icon(Icons.sports_tennis,
                        color: Colors.white, size: AppSizes.iconMd),
                  ),
                  SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _booking.courtName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${_booking.date} • ${_booking.time}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$_total ر.س',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'التفاصيل',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.primary),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            _summaryExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_summaryExpanded) ...[
            Container(
              height: 1,
              color: AppColors.border,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                children: [
                  _buildPriceRow('سعر الجلسة', '$_subtotal ر.س'),
                  const SizedBox(height: AppSizes.sm),
                  _buildPriceRow('ضريبة القيمة المضافة 15%', '$_vat ر.س'),
                  if (_promoApplied) ...[
                    SizedBox(height: AppSizes.sm),
                    _buildPriceRow(
                      'خصم الكود (SPORTA10)',
                      '-$_discount ر.س',
                      valueColor: _green600,
                    ),
                  ],
                  SizedBox(height: AppSizes.sm),
                  Container(height: 1, color: AppColors.border),
                  SizedBox(height: AppSizes.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الإجمالي',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$_total ر.س',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: valueColor ?? AppColors.secondary,
          ),
        ),
      ],
    );
  }

  // ── Promo section ────────────────────────────────────────────────────────
  Widget _buildPromoSection() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_outlined,
                  size: AppSizes.iconSm, color: AppColors.primary),
              SizedBox(width: AppSizes.sm),
              Text(
                'كود الخصم',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoCtrl,
                  readOnly: _promoApplied,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: 'أدخل الكود',
                    hintStyle:
                        AppTextStyles.bodySmall.copyWith(color: _gray400),
                    filled: true,
                    fillColor: _promoApplied ? _green50 : _gray50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      borderSide: BorderSide(
                        color: _promoApplied ? _green200 : AppColors.border,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      borderSide: BorderSide(
                        color: _promoApplied ? _green200 : AppColors.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      borderSide: BorderSide(
                        color: _promoApplied
                            ? _green500
                            : AppColors.primary,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.sm,
                    ),
                    isDense: true,
                    suffixIcon: _promoApplied
                        ? const Icon(Icons.check_circle,
                            color: _green500, size: AppSizes.iconMd)
                        : null,
                  ),
                  onChanged: (_) => setState(() => _promoError = ''),
                ),
              ),
              SizedBox(width: AppSizes.sm),
              GestureDetector(
                onTap: _applyPromo,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                    vertical: AppSizes.sm,
                  ),
                  decoration: BoxDecoration(
                    color: _promoApplied
                        ? _red50
                        : AppColors.primary,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  child: Text(
                    _promoApplied ? 'إزالة' : 'تطبيق',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _promoApplied ? _red600 : Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_promoError.isNotEmpty) ...[
            SizedBox(height: AppSizes.xs),
            Text(
              _promoError,
              style: AppTextStyles.caption.copyWith(color: _red500),
            ),
          ],
          if (_promoApplied) ...[
            SizedBox(height: AppSizes.xs),
            Text(
              'تم تطبيق خصم 10% على السعر الأساسي',
              style: AppTextStyles.caption.copyWith(color: _green600),
            ),
          ],
          if (!_promoApplied) ...[
            SizedBox(height: AppSizes.xs),
            Text(
              'جرّب: SPORTA10',
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
          ],
        ],
      ),
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
        Column(
          children: [
            _buildMethodTile(
              method: _PaymentMethod.wallet,
              icon: Icons.account_balance_wallet_outlined,
              iconColor: _amber500,
              iconBg: _amber50,
              label: 'المحفظة الرقمية',
              sublabel: 'الرصيد: $_walletBalance ر.س',
              badge: _walletInsufficient
                  ? _buildBadge('رصيد غير كافٍ', _red500, _red50)
                  : null,
            ),
            const SizedBox(height: AppSizes.sm),
            _buildMethodTile(
              method: _PaymentMethod.visa,
              icon: Icons.credit_card,
              iconColor: _blue600,
              iconBg: _blue50,
              label: 'بطاقة فيزا',
              sublabel: 'Visa Credit / Debit',
            ),
            const SizedBox(height: AppSizes.sm),
            _buildMethodTile(
              method: _PaymentMethod.mada,
              icon: Icons.credit_card,
              iconColor: _purple700,
              iconBg: const Color(0xFFF5F3FF),
              label: 'بطاقة مدى',
              sublabel: 'مدى — البطاقة السعودية',
              labelSuffix: _buildMadaLabel(),
            ),
            SizedBox(height: AppSizes.sm),
            _buildMethodTile(
              method: _PaymentMethod.applePay,
              icon: Icons.apple,
              iconColor: Colors.black,
              iconBg: _gray100,
              label: 'Apple Pay',
              sublabel: 'ادفع بلمسة واحدة',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMadaLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: _purple600.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        'مدى',
        style: AppTextStyles.caption.copyWith(color: _purple700),
      ),
    );
  }

  Widget _buildBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: textColor),
      ),
    );
  }

  Widget _buildMethodTile({
    required _PaymentMethod method,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String sublabel,
    Widget? badge,
    Widget? labelSuffix,
  }) {
    final selected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(icon, color: iconColor, size: AppSizes.iconMd),
            ),
            SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (labelSuffix != null) ...[
                        SizedBox(width: AppSizes.xs),
                        labelSuffix,
                      ],
                      if (badge != null) ...[
                        SizedBox(width: AppSizes.sm),
                        badge,
                      ],
                    ],
                  ),
                  Text(sublabel, style: AppTextStyles.caption),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : _gray400,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Card form ────────────────────────────────────────────────────────────
  Widget _buildCardForm() {
    final isMada = _selectedMethod == _PaymentMethod.mada;
    final gradient = isMada
        ? const LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
          )
        : const LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [_blue700, Color(0xFF1E3A8A)],
          );

    final cardType = isMada ? 'مدى' : 'VISA';

    return Column(
      children: [
        // card preview
        Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          ),
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cardType,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.contactless,
                        color: Colors.white, size: 18),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _maskedNumber(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                    ),
                  ),
                  SizedBox(height: AppSizes.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _cardNameCtrl.text.isEmpty
                            ? 'اسم حامل البطاقة'
                            : _cardNameCtrl.text,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        _expiryCtrl.text.isEmpty
                            ? 'MM/YY'
                            : _expiryCtrl.text,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: AppSizes.lg),
        // form fields
        Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'بيانات البطاقة',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              _buildFieldLabel('رقم البطاقة'),
              const SizedBox(height: AppSizes.xs),
              _buildTextField(
                controller: _cardNumberCtrl,
                hint: 'XXXX XXXX XXXX XXXX',
                keyboardType: TextInputType.number,
                inputFormatters: [_CardNumberFormatter()],
                prefixIcon: Icons.credit_card,
              ),
              const SizedBox(height: AppSizes.md),
              _buildFieldLabel('اسم حامل البطاقة'),
              const SizedBox(height: AppSizes.xs),
              _buildTextField(
                controller: _cardNameCtrl,
                hint: 'الاسم كما يظهر على البطاقة',
                keyboardType: TextInputType.name,
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('تاريخ الانتهاء'),
                        const SizedBox(height: AppSizes.xs),
                        _buildTextField(
                          controller: _expiryCtrl,
                          hint: 'MM/YY',
                          keyboardType: TextInputType.number,
                          inputFormatters: [_ExpiryFormatter()],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('CVV'),
                        const SizedBox(height: AppSizes.xs),
                        _buildTextField(
                          controller: _cvvCtrl,
                          hint: '•••',
                          keyboardType: TextInputType.number,
                          obscure: !_showCvv,
                          maxLength: 3,
                          suffixIcon: GestureDetector(
                            onTap: () =>
                                setState(() => _showCvv = !_showCvv),
                            child: Icon(
                              _showCvv
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: AppSizes.iconSm,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              GestureDetector(
                onTap: () =>
                    setState(() => _saveCard = !_saveCard),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _saveCard
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppSizes.xs),
                        border: Border.all(
                          color: _saveCard
                              ? AppColors.primary
                              : _gray400,
                          width: 2,
                        ),
                      ),
                      child: _saveCard
                          ? const Icon(Icons.check,
                              size: 12, color: Colors.white)
                          : null,
                    ),
                    SizedBox(width: AppSizes.sm),
                    Text(
                      'حفظ البطاقة للمرات القادمة',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSizes.xl),
      ],
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.caption.copyWith(color: AppColors.secondary),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscure = false,
    int? maxLength,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscure,
      maxLength: maxLength,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            AppTextStyles.bodySmall.copyWith(color: _gray400),
        filled: true,
        fillColor: _gray50,
        counterText: '',
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon,
                size: AppSizes.iconSm, color: AppColors.mutedForeground)
            : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
        isDense: true,
      ),
    );
  }

  // ── Apple Pay section ────────────────────────────────────────────────────
  Widget _buildApplePaySection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.xl),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          ),
          child: Column(
            children: [
              const Icon(Icons.apple, color: Colors.white, size: 40),
              SizedBox(height: AppSizes.sm),
              Text(
                'Apple Pay',
                style: AppTextStyles.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSizes.xs),
              Text(
                'ادفع بأمان باستخدام Face ID أو Touch ID',
                style: AppTextStyles.caption
                    .copyWith(color: Colors.white60),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.xl),
      ],
    );
  }

  // ── Insufficient wallet ──────────────────────────────────────────────────
  Widget _buildInsufficientWallet() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: _red50,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            border: Border.all(color: _red300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: _red500, size: AppSizes.iconMd),
              SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رصيد المحفظة غير كافٍ',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _red600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: AppSizes.xs),
                    Text(
                      'رصيدك $_walletBalance ر.س والمبلغ المطلوب $_total ر.س',
                      style: AppTextStyles.caption.copyWith(color: _red600),
                    ),
                    SizedBox(height: AppSizes.md),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.lg,
                          vertical: AppSizes.sm,
                        ),
                        decoration: BoxDecoration(
                          color: _red600,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusLg),
                        ),
                        child: Text(
                          'شحن المحفظة',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.xl),
      ],
    );
  }

  // ── Security notice ──────────────────────────────────────────────────────
  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: _green50,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: _green200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _green100,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: const Icon(Icons.shield_outlined,
                color: _green600, size: AppSizes.iconMd),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دفع آمن ومشفر',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _green600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'مشفر بـ SSL 256-bit • لا نحتفظ ببيانات بطاقتك',
                  style: AppTextStyles.caption
                      .copyWith(color: _green600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Pay button ───────────────────────────────────────────────────────────
  Widget _buildPayButton() {
    final enabled = _isFormValid && !_isProcessing;
    return GestureDetector(
      onTap: enabled ? _pay : null,
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
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline,
                        color: Colors.white, size: AppSizes.iconSm),
                    SizedBox(width: AppSizes.sm),
                    Text(
                      'ادفع $_total ر.س',
                      style: AppTextStyles.body.copyWith(
                        color: enabled ? Colors.white : _gray400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Success overlay ──────────────────────────────────────────────────────
  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AppSizes.pagePadding),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_green500, _green600],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      color: Colors.white, size: 36),
                ),
                SizedBox(height: AppSizes.lg),
                Text(
                  'تم الدفع بنجاح!',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                SizedBox(height: AppSizes.sm),
                Text(
                  'تم تأكيد حجزك وإرسال تفاصيله إلى بريدك',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSizes.xl),
                // booking ref
                Container(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: _gray50,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('رقم الحجز',
                              style: AppTextStyles.caption),
                          SizedBox(height: AppSizes.xs),
                          Text(
                            _bookingRef,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Clipboard.setData(
                          ClipboardData(text: _bookingRef),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(AppSizes.sm),
                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                                AppSizes.radiusLg),
                          ),
                          child: const Icon(Icons.copy,
                              size: AppSizes.iconSm,
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                // booking details
                Container(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSuccessDetailRow(
                          Icons.location_on_outlined, _booking.courtName),
                      const SizedBox(height: AppSizes.sm),
                      _buildSuccessDetailRow(
                          Icons.calendar_today_outlined, _booking.date),
                      const SizedBox(height: AppSizes.sm),
                      _buildSuccessDetailRow(
                          Icons.access_time, _booking.time),
                      const SizedBox(height: AppSizes.sm),
                      _buildSuccessDetailRow(
                          Icons.timer_outlined, _booking.duration),
                      const SizedBox(height: AppSizes.sm),
                      _buildSuccessDetailRow(
                          Icons.attach_money, '$_total ر.س'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                // action shortcuts
                Row(
                  children: [
                    Expanded(
                        child: _buildShortcut(
                            Icons.calendar_today_outlined, 'أضف للتقويم')),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                        child: _buildShortcut(
                            Icons.directions_outlined, 'الاتجاهات')),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                        child: _buildShortcut(
                            Icons.share_outlined, 'شارك الحجز')),
                  ],
                ),
                SizedBox(height: AppSizes.lg),
                GestureDetector(
                  onTap: _handleSuccessClose,
                  child: Container(
                    width: double.infinity,
                    height: AppSizes.buttonHeight,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusLg),
                    ),
                    child: Center(
                      child: Text(
                        'العودة للرئيسية',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: AppSizes.iconSm, color: AppColors.primary),
        SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.secondary),
          ),
        ),
      ],
    );
  }

  Widget _buildShortcut(IconData icon, String label) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        decoration: BoxDecoration(
          color: _gray50,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: AppSizes.iconSm, color: AppColors.primary),
            SizedBox(height: AppSizes.xs),
            Text(label, style: AppTextStyles.caption,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
