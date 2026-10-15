import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pay/pay.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/payment/apple_pay_service.dart';
import '../../../../core/payment/payment_config.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../settings/data/settings_repository.dart';
import '../../data/wallet_repository.dart';
import '../../domain/entities/wallet_entity.dart';
import '../cubit/wallet_cubit.dart';
import '../widgets/top_up_success_dialog.dart';
import 'finy_checkout_page.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/system_insets.dart';

// ─── Local palette ────────────────────────────────────────────────────────────
const Color _green500 = Color(0xFF22C55E);
const Color _green600 = Color(0xFF16A34A);
const Color _yellow50 = Color(0xFFFEFCE8);
const Color _yellow100 = Color(0xFFFEF9C3);
const Color _yellow600 = Color(0xFFCA8A04);
const Color _gray50 = Color(0xFFF9FAFB);
const Color _gray100 = Color(0xFFF3F4F6);
const Color _gray200 = Color(0xFFE5E7EB);
const Color _gray400 = Color(0xFF9CA3AF);

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

  /// Fallbacks used until `/settings/public` answers (and if it never does).
  /// They mirror the server defaults in `SettingsService`.
  static const int _defaultMin = 10;
  static const int _defaultMax = 5000;

  int? _selectedAmount;
  final _customAmountCtrl = TextEditingController();
  String _amountError = '';
  bool _isProcessing = false;

  /// Top-up limits and notes, managed by the admin via the dashboard.
  int _minTopUp = _defaultMin;
  int _maxTopUp = _defaultMax;
  List<String> _extraNotes = const [];

  /// Server-computed fee/total for the currently chosen amount. Null while it
  /// is being fetched or if the amount changed since.
  TopUpQuote? _quote;
  int? _quotedFor;

  /// Non-null only when the server enables Apple Pay AND this iPhone has a
  /// card set up — otherwise the button never renders and the card flow is
  /// the only option, exactly as before.
  ApplePayService? _applePay;

  @override
  void initState() {
    super.initState();
    _loadLimits();
    _loadApplePay();
  }

  Future<void> _loadApplePay() async {
    if (!ApplePayService.isSupportedPlatform) return;
    try {
      final config = await getIt<WalletRepository>().fetchPaymentConfig();
      if (!config.applePayEnabled) return;
      final service = ApplePayService(config.applePay!);
      if (!await service.canPay()) return;
      if (!mounted) return;
      setState(() => _applePay = service);
    } catch (_) {
      // Silent: Apple Pay is a convenience on top of the card flow.
    }
  }

  Future<void> _loadLimits() async {
    try {
      final settings = await getIt<SettingsRepository>().fetchPublicSettings();
      if (!mounted) return;
      final isArabic = context.appSettings.language == AppLanguage.ar;

      int parse(String key, int fallback) {
        final raw = settings[key]?.valueAr.trim();
        return int.tryParse(raw ?? '') ?? fallback;
      }

      final notes = settings['wallet_topup_notes'];
      final rawNotes = isArabic
          ? notes?.valueAr
          : (notes?.valueEn.isNotEmpty == true ? notes!.valueEn : notes?.valueAr);

      setState(() {
        _minTopUp = parse('wallet_topup_min', _defaultMin);
        _maxTopUp = parse('wallet_topup_max', _defaultMax);
        _extraNotes = (rawNotes ?? '')
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();
      });
    } catch (_) {
      // Keep the defaults — the page stays usable if settings can't load.
    }
  }

  /// Refreshes the fee preview for the selected amount. The summary falls back
  /// to showing the amount alone until the quote lands.
  Future<void> _refreshQuote() async {
    final amount = _canProceed ? _effectiveAmount : null;
    if (amount == null) {
      if (_quote != null) setState(() { _quote = null; _quotedFor = null; });
      return;
    }
    if (_quotedFor == amount) return;

    try {
      final q = await getIt<WalletRepository>().fetchTopUpQuote(amount.toDouble());
      if (!mounted || _effectiveAmount != amount) return;
      setState(() { _quote = q; _quotedFor = amount; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _quote = null; _quotedFor = null; });
    }
  }

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
      _effectiveAmount! >= _minTopUp &&
      _effectiveAmount! <= _maxTopUp;

  // ── Validate custom amount ────────────────────────────────────────────────
  void _onCustomAmountChanged(String value) {
    setState(() {
      _selectedAmount = null;
      final parsed = int.tryParse(value.trim());
      if (value.trim().isEmpty) {
        _amountError = '';
      } else if (parsed == null) {
        _amountError = trg('أدخل رقماً صحيحاً');
      } else if (parsed < _minTopUp) {
        _amountError = trgArgs('الحد الأدنى للشحن {p0} ر.س', {'p0': _minTopUp});
      } else if (parsed > _maxTopUp) {
        _amountError = trgArgs('الحد الأقصى للشحن {p0} ر.س', {'p0': _maxTopUp});
      } else {
        _amountError = '';
      }
    });
    _refreshQuote();
  }

  // ── Confirm ──────────────────────────────────────────────────────────────
  void _showConfirmDialog() {
    final amount = _effectiveAmount!;
    final newBalance = widget.currentBalance + amount;
    final quote = _quotedFor == amount ? _quote : null;

    showDialog<void>(
      context: context,
      builder: (_) => Directionality(
        textDirection: Directionality.of(context),
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
              Text(context.tr('تأكيد شحن الرصيد'),
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.xl),
              _buildConfirmRow(trg('المبلغ المضاف للمحفظة'), trgArgs('{p0} ر.س', {'p0': amount})),
              const SizedBox(height: AppSizes.sm),
              if (quote != null && quote.hasFee) ...[
                _buildConfirmRow(
                    trg('رسوم الدفع (شاملة الضريبة)'), trgArgs('{p0} ر.س', {'p0': _money(quote.fee)})),
                const SizedBox(height: AppSizes.sm),
                _buildConfirmRow(trg('الإجمالي المخصوم من البطاقة'),
                    trgArgs('{p0} ر.س', {'p0': _money(quote.total)}),
                    bold: true),
              ] else
                _buildConfirmRow(trg('رسوم المعاملة'), trg('مجاناً'),
                    valueColor: _green600),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.sm),
                child: Divider(),
              ),
              _buildConfirmRow(trg('الرصيد الجديد'), trgArgs('{p0} ر.س', {'p0': newBalance}),
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
                          child: Text(context.tr('إلغاء'),
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
                          child: Text(context.tr('تأكيد'),
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
    // Guard against a double tap: the button is disabled while processing, but
    // the flag used to be set only after the first await, leaving a window in
    // which a second tap opened a second payment session.
    if (_isProcessing) return;
    final amount = _effectiveAmount;
    if (amount == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isProcessing = true);

    // The card form lives at the gateway, so the app opens a session and a URL
    // — nothing more. The total (amount + fee) is decided server-side; the app
    // never computes what is charged.
    final PaymentConfig paymentConfig;
    final TopUpSession session;
    try {
      final repo = getIt<WalletRepository>();
      paymentConfig = await repo.fetchPaymentConfig();
      if (!mounted) return;

      if (!paymentConfig.configured) {
        setState(() => _isProcessing = false);
        messenger.showSnackBar(SnackBar(
            content: Text(context.tr(
                'الدفع غير مُهيّأ بعد — يرجى ضبط بوابة الدفع في الخادم'))));
        return;
      }

      session = await repo.startTopUp(amount.toDouble());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
      return;
    }
    if (!mounted) return;
    setState(() => _isProcessing = false);

    // Open the hosted checkout and wait for the customer to be done with it.
    final reachedCallback = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FinyCheckoutPage(session: session),
      ),
    );
    if (!mounted || reachedCallback != true) return; // backed out

    setState(() => _isProcessing = true);
    try {
      // The backend re-reads the payment from the gateway before crediting —
      // reaching the callback URL is not itself proof of payment.
      final wallet = await getIt<WalletRepository>().confirmTopUp(session.paymentId);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (wallet == null) {
        // Confirmed by the bank but not yet by the gateway. The webhook lands
        // shortly; telling the user it failed would be a lie.
        messenger.showSnackBar(SnackBar(
            content: Text(context.tr(
                context.tr('العملية قيد التأكيد — سيظهر الرصيد خلال لحظات')))));
        await getIt<WalletCubit>().load();
        return;
      }

      // Refresh the shared wallet cubit here rather than in the caller, so
      // every screen showing the balance updates no matter which route opened
      // this page.
      await getIt<WalletCubit>().load();

      if (!mounted) return;
      await showTopUpSuccessDialog(
        context,
        amount: amount.toDouble(),
        newBalance: wallet.balance,
      );
      widget.onComplete?.call();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  /// Apple's sheet is the confirmation step, so there is no dialog first: the
  /// user sees the total on the sheet and authorizes with Face ID. The token
  /// that comes back is encrypted for the gateway; the server forwards it and
  /// answers with the settled wallet in one call.
  Future<void> _processApplePay() async {
    final amount = _effectiveAmount;
    final service = _applePay;
    if (amount == null || service == null || _isProcessing) return;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isProcessing = true);
    try {
      final repo = getIt<WalletRepository>();

      // What the sheet charges (amount + fee) is decided server-side — reuse
      // the quote already on screen, or fetch it if the amount just changed.
      final quote = _quotedFor == amount && _quote != null
          ? _quote!
          : await repo.fetchTopUpQuote(amount.toDouble());
      if (!mounted) return;

      final token = await service.requestToken(
        total: quote.total,
        label: trg('شحن محفظة سبورتا'),
      );
      if (!mounted) return;
      if (token == null) {
        // Sheet dismissed — not an error, nothing was charged.
        setState(() => _isProcessing = false);
        return;
      }

      final wallet = await repo.topUpWithApplePay(
        amount: amount.toDouble(),
        token: token,
      );
      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (wallet == null) {
        messenger.showSnackBar(SnackBar(
            content: Text(context.tr('العملية قيد التأكيد — سيظهر الرصيد خلال لحظات'))));
        await getIt<WalletCubit>().load();
        return;
      }

      await getIt<WalletCubit>().load();
      if (!mounted) return;
      await showTopUpSuccessDialog(
        context,
        amount: amount.toDouble(),
        newBalance: wallet.balance,
      );
      widget.onComplete?.call();
    } on ApplePayException {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      messenger.showSnackBar(
          SnackBar(content: Text(context.tr('تعذّر فتح Apple Pay'))));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: context
                    .safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBalanceCard(),
                    const SizedBox(height: AppSizes.xl),
                    _buildQuickAmountsSection(),
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
                  child: const DirectionalIcon(
                    rtl: Icons.arrow_forward,
                    ltr: Icons.arrow_back,
                    color: Colors.white,
                    size: AppSizes.iconMd,
                  ),
                ),
              ),
              SizedBox(width: AppSizes.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('شحن الرصيد'),
                    style: AppTextStyles.heading2
                        .copyWith(color: Colors.white),
                  ),
                  Text(context.tr('اختر المبلغ'),
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
              Text(context.tr('الرصيد الحالي'),
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              Text(
                context.trArgs('{p0} ر.س', {'p0': widget.currentBalance}),
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
        Text(context.tr('اختر المبلغ'),
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
                _refreshQuote();
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
                    context.trArgs('{p0} ر.س', {'p0': amount}),
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
            hintText: context.tr('أو أدخل مبلغاً مخصصاً'),
            hintStyle:
                AppTextStyles.bodySmall.copyWith(color: _gray400),
            filled: true,
            fillColor: _gray50,
            prefixIcon: const Icon(Icons.edit_outlined,
                size: AppSizes.iconSm, color: AppColors.mutedForeground),
            suffix: Text(context.tr('ر.س')),
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

  /// Drops the decimals on whole riyals, keeps them otherwise.
  static String _money(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  // ── Summary card ─────────────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    final amount = _effectiveAmount!;
    final newBalance = widget.currentBalance + amount;
    final quote = _quotedFor == amount ? _quote : null;
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
              Text(context.tr('ملخص العملية'),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.md),
          _buildSummaryRow(trg('المبلغ المضاف للمحفظة'), trgArgs('{p0} ر.س', {'p0': amount})),
          SizedBox(height: AppSizes.sm),
          // The fee comes from the server; until it lands, no number is claimed.
          if (quote == null)
            _buildSummaryRow(trg('رسوم المعاملة'), '…')
          else if (quote.hasFee)
            _buildSummaryRow(trg('رسوم الدفع (شاملة الضريبة)'), trgArgs('{p0} ر.س', {'p0': _money(quote.fee)}))
          else
            _buildSummaryRow(trg('رسوم المعاملة'), trg('مجاناً'), valueColor: _green600),
          if (quote != null && quote.hasFee) ...[
            SizedBox(height: AppSizes.sm),
            _buildSummaryRow(trg('الإجمالي المخصوم من البطاقة'),
                trgArgs('{p0} ر.س', {'p0': _money(quote.total)}),
                bold: true),
          ],
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.sm),
            child: Divider(),
          ),
          _buildSummaryRow(trg('الرصيد الجديد'), trgArgs('{p0} ر.س', {'p0': newBalance}),
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
  /// Limits are rendered from the admin-managed settings so the text can never
  /// drift from what the server actually enforces; the remaining bullets are
  /// free text the admin edits in the dashboard.
  Widget _buildInfoNote() {
    final bullets = [
      '${context.tr('الحد الأدنى للشحن')} $_minTopUp ${context.tr('ر.س')}',
      '${context.tr('الحد الأقصى للشحن في المرة الواحدة')} $_maxTopUp ${context.tr('ر.س')}',
      ..._extraNotes,
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
              Text(context.tr('معلومات هامة'),
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
    final applePay = _applePay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (applePay != null) ...[
          // Native PKPaymentButton (Apple's own artwork and wording) — required
          // by Apple's Pay guidelines; it also localizes itself.
          Opacity(
            opacity: enabled ? 1 : 0.4,
            child: IgnorePointer(
              ignoring: !enabled,
              child: SizedBox(
                height: AppSizes.buttonHeight,
                child: RawApplePayButton(
                  type: ApplePayButtonType.topUp,
                  style: ApplePayButtonStyle.black,
                  cornerRadius: AppSizes.radiusLg,
                  onPressed: _processApplePay,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: Text(context.tr('أو'),
                    style: AppTextStyles.bodySmall.copyWith(color: _gray400)),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: AppSizes.md),
        ],
        _buildCardRow(enabled),
      ],
    );
  }

  Widget _buildCardRow(bool enabled) {
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
            child: Text(context.tr('رجوع'),
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
                    : Text(context.tr('إتمام الشحن'),
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
