import 'package:flutter/material.dart';
import 'package:sporta_app/core/state/app_scope.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/money.dart';

/// Shows a beautiful "Insufficient balance" dialog.
/// Returns true if the user taps "Top Up", false/null if they cancel.
Future<bool?> showInsufficientBalanceDialog(
  BuildContext context, {
  required double currentBalance,
  required double requiredAmount,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => InsufficientBalanceDialog(
      currentBalance: currentBalance,
      requiredAmount: requiredAmount,
    ),
  );
}

class InsufficientBalanceDialog extends StatelessWidget {
  const InsufficientBalanceDialog({
    super.key,
    required this.currentBalance,
    required this.requiredAmount,
  });

  final double currentBalance;
  final double requiredAmount;

  @override
  Widget build(BuildContext context) {
    final missing = (requiredAmount - currentBalance).clamp(0.0, double.infinity);

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
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: Color(0xFFD97706),
                size: 36,
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Title ─────────────────────────────────────────────────────────
            Text(
              context.tr('رصيد غير كافٍ'),
              style: AppTextStyles.heading3
                  .copyWith(color: AppColors.secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              context.tr('رصيدك الحالي لا يكفي لإتمام العملية.\nيرجى شحن المحفظة والمحاولة مجدداً.'),
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.mutedForeground),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Balance info card ─────────────────────────────────────────────
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
                  _row(
                    context,
                    context.tr('رصيدك الحالي'),
                    '${money(currentBalance)} ${context.tr('ر.س')}',
                    AppColors.mutedForeground,
                  ),
                  const Divider(height: AppSizes.md),
                  _row(
                    context,
                    context.tr('المبلغ المطلوب'),
                    '${money(requiredAmount)} ${context.tr('ر.س')}',
                    AppColors.secondary,
                  ),
                  const Divider(height: AppSizes.md),
                  _row(
                    context,
                    context.tr('المبلغ الناقص'),
                    '${money(missing)} ${context.tr('ر.س')}',
                    AppColors.destructive,
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            // ── Buttons ───────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize:
                      const Size(double.infinity, AppSizes.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusLg),
                  ),
                ),
                icon: const Icon(Icons.add_card_outlined),
                label: Text(context.tr('شحن المحفظة')),
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
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusLg),
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

  Widget _row(BuildContext context, String label, String value, Color valueColor,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.mutedForeground)),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: valueColor,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
