import 'package:flutter/material.dart';
import 'package:sporta_app/core/state/app_scope.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../settings/data/settings_repository.dart';
import '../../data/wallet_repository.dart';
import '../pages/top_up_wallet_page.dart';

/// One label/value line in the dialog's breakdown card (e.g. "الملعب" / "نادي X").
class PaymentDetail {
  const PaymentDetail(this.label, this.value);

  final String label;
  final String value;
}

/// Asks the user to confirm a wallet debit before it happens.
///
/// Returns `true` only when the user explicitly confirms; `false`/`null` when
/// they cancel or dismiss it — so callers must treat anything but `true` as a
/// cancel.
///
/// [amount] is what will leave the wallet, in SAR. Pass [deferred] for charges
/// that are not taken immediately (a coach session is only debited once the
/// coach approves), which swaps the wording from "سيتم خصم" to "سيُخصم عند...".
///
/// الرصيد يُجلب داخل الحوار نفسه، فكل نداء يربح عرضه بلا تغيير في مكان النداء:
/// اللاعب يرى ما سيُخصم وما سيبقى قبل أن يوافق، وإن كان رصيده أقل من المطلوب
/// فالزر يقوده إلى الشحن بدل محاولةٍ يعرف الخادم سلفاً أنها سترفض.
Future<bool?> showPaymentConfirmDialog(
  BuildContext context, {
  required String title,
  required double amount,
  List<PaymentDetail> details = const [],
  String? deferredNote,
  String? confirmLabel,
  bool autoCancelNote = false,
  String? footnote,
  String? headline,
  String? amountLabel,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => PaymentConfirmDialog(
      title: title,
      amount: amount,
      details: details,
      deferredNote: deferredNote,
      confirmLabel: confirmLabel,
      autoCancelNote: autoCancelNote,
      footnote: footnote,
      headline: headline,
      amountLabel: amountLabel,
    ),
  );
}

class PaymentConfirmDialog extends StatefulWidget {
  const PaymentConfirmDialog({
    super.key,
    required this.title,
    required this.amount,
    this.details = const [],
    this.deferredNote,
    this.confirmLabel,
    this.autoCancelNote = false,
    this.footnote,
    this.headline,
    this.amountLabel,
  });

  final String title;
  final double amount;
  final List<PaymentDetail> details;

  /// When set, the charge happens later — shown instead of the "سيتم خصم" line.
  final String? deferredNote;
  final String? confirmLabel;

  /// مباراة أو أمريكانو: يُطمئن اللاعب بأن ماله يعود إن لم يكتمل العدد.
  final bool autoCancelNote;

  /// سطر توضيحي أسفل التفاصيل (مثل «يُعاد المبلغ إن رُفض الطلب»).
  final String? footnote;

  /// يحلّ محلّ «سيتم خصم المبلغ من رصيد محفظتك عند التأكيد.».
  final String? headline;

  /// يحلّ محلّ «المبلغ المخصوم».
  final String? amountLabel;

  @override
  State<PaymentConfirmDialog> createState() => _PaymentConfirmDialogState();
}

class _PaymentConfirmDialogState extends State<PaymentConfirmDialog> {
  /// null = لم يصل بعد أو تعذّر جلبه؛ عندها يعمل الحوار كما كان بلا رصيد.
  double? _balance;
  bool _loadingBalance = true;

  /// مهلة الإلغاء التلقائي بالساعات، كما يضبطها الأدمن؛ null = لم تصل.
  double? _autoCancelHours;

  @override
  void initState() {
    super.initState();
    _loadBalance();
    if (widget.autoCancelNote) _loadAutoCancelHours();
  }

  Future<void> _loadAutoCancelHours() async {
    try {
      final settings = await getIt<SettingsRepository>().fetchPublicSettings();
      final raw = settings['match_autocancel_hours_before']?.valueAr;
      final hours = double.tryParse(raw ?? '');
      if (!mounted || hours == null || hours <= 0) return;
      setState(() => _autoCancelHours = hours);
    } catch (_) {
      // تعذّر جلب الإعداد: نُخفي الملاحظة بدل عرض رقم مخترع.
    }
  }

  Future<void> _loadBalance() async {
    try {
      final wallet = await getIt<WalletRepository>().fetchWallet();
      if (!mounted) return;
      setState(() {
        _balance = wallet.balance;
        _loadingBalance = false;
      });
    } catch (_) {
      // تعذّر جلب الرصيد (شبكة مثلاً): لا نمنع العملية — الخادم هو الحكم،
      // ويردّ برسالة «الرصيد غير كافٍ» إن لزم.
      if (!mounted) return;
      setState(() => _loadingBalance = false);
    }
  }

  /// الخصم فوري (لا مؤجّل) والرصيد معروف وأقل من المطلوب.
  bool get _insufficient =>
      widget.deferredNote == null &&
      _balance != null &&
      _balance! < widget.amount;

  Future<void> _goTopUp() async {
    final navigator = Navigator.of(context);
    final balance = _balance ?? 0;
    navigator.pop(false);
    await navigator.push(MaterialPageRoute<void>(
      builder: (_) => TopUpWalletPage(
        currentBalance: balance.round(),
        onBack: () => navigator.pop(),
        onComplete: () => navigator.pop(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sar = context.tr('ر.س');
    final insufficient = _insufficient;
    final remaining = _balance == null ? null : _balance! - widget.amount;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl + 4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon ──────────────────────────────────────────────────────────
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: insufficient
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: insufficient
                    ? const Color(0xFFD97706)
                    : const Color(0xFF16A34A),
                size: 36,
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Title + what happens ──────────────────────────────────────────
            Text(
              context.tr(widget.title),
              style:
                  AppTextStyles.heading3.copyWith(color: AppColors.secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              insufficient
                  ? context.tr('رصيد محفظتك لا يكفي لإتمام هذه العملية.')
                  : widget.deferredNote != null
                      ? context.tr(widget.deferredNote!)
                      : context.tr(widget.headline ??
                          'سيتم خصم المبلغ من رصيد محفظتك عند التأكيد.'),
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.mutedForeground),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Breakdown ─────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  for (final d in widget.details) ...[
                    _row(context, d.label, d.value, AppColors.secondary),
                    const Divider(height: AppSizes.md),
                  ],
                  _row(
                    context,
                    context.tr(widget.amountLabel ?? 'المبلغ المخصوم'),
                    '${_money(widget.amount)} $sar',
                    insufficient ? AppColors.warning : AppColors.primary,
                    bold: true,
                  ),
                  // رصيد المحفظة قبل الخصم وبعده — الرقم الذي يهم اللاعب فعلاً.
                  if (_loadingBalance) ...[
                    const Divider(height: AppSizes.md),
                    _balanceRow(
                      context,
                      context.tr('رصيد المحفظة'),
                      child: const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ] else if (_balance != null) ...[
                    const Divider(height: AppSizes.md),
                    _row(
                      context,
                      context.tr('رصيد المحفظة'),
                      '${_money(_balance!)} $sar',
                      AppColors.secondary,
                    ),
                    if (widget.deferredNote == null) ...[
                      const Divider(height: AppSizes.md),
                      _row(
                        context,
                        context.tr('الرصيد بعد الخصم'),
                        insufficient
                            ? '${context.trArgs('ناقص {p0}', {
                                'p0': _money(widget.amount - _balance!),
                              })} $sar'
                            : '${_money(remaining!)} $sar',
                        insufficient
                            ? AppColors.destructive
                            : AppColors.secondary,
                        bold: true,
                      ),
                    ],
                  ],
                ],
              ),
            ),
            if (widget.footnote != null) ...[
              const SizedBox(height: AppSizes.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: AppSizes.iconSm, color: AppColors.mutedForeground),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      context.tr(widget.footnote!),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.mutedForeground),
                    ),
                  ),
                ],
              ),
            ],
            // ── ملاحظة الإلغاء التلقائي ───────────────────────────────────────
            if (_autoCancelHours != null) ...[
              const SizedBox(height: AppSizes.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined,
                      size: AppSizes.iconSm, color: Color(0xFF16A34A)),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      context.trArgs(
                        'إن لم يكتمل عدد اللاعبين قبل {p0} من الموعد، يُلغى الحدث ويعود المبلغ إلى محفظتك.',
                        {'p0': _hoursLabel(context, _autoCancelHours!)},
                      ),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: const Color(0xFF15803D)),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSizes.xl),

            // ── Buttons ───────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // رصيد ناقص → الزر يشحن بدل أن يؤكد عمليةً سترفَض.
                onPressed: _loadingBalance
                    ? null
                    : insufficient
                        ? _goTopUp
                        : () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      insufficient ? AppColors.warning : AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.muted,
                  minimumSize:
                      const Size(double.infinity, AppSizes.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                ),
                child: Text(
                  insufficient
                      ? context.tr('شحن المحفظة')
                      : context.tr(widget.confirmLabel ?? context.tr('تأكيد الدفع')),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  minimumSize:
                      const Size(double.infinity, AppSizes.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Text(context.tr('إلغاء')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// «ساعة/ساعتين/٣ ساعات» — العربية تُفرّق بين المفرد والمثنى والجمع.
  static String _hoursLabel(BuildContext context, double hours) {
    final n = hours == hours.roundToDouble() ? hours.round() : null;
    if (n == 1) return context.tr('ساعة');
    if (n == 2) return context.tr('ساعتين');
    if (n != null && n <= 10) return context.trArgs('{p0} ساعات', {'p0': n});
    final value = n ?? hours;
    return context.trArgs('{p0} ساعة', {'p0': value});
  }

  /// Drops the decimals on whole riyals ("50" not "50.0"), keeps them otherwise.
  static String _money(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  Widget _row(BuildContext context, String label, String value, Color valueColor,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.mutedForeground)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodySmall.copyWith(
              color: valueColor,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _balanceRow(BuildContext context, String label,
      {required Widget child}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.mutedForeground)),
        child,
      ],
    );
  }
}
