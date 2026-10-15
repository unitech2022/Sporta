import 'package:flutter/material.dart';
import 'package:sporta_app/core/state/app_scope.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

const Color _green500 = Color(0xFF22C55E);
const Color _green600 = Color(0xFF16A34A);
const Color _green50 = Color(0xFFF0FDF4);

/// Shows a celebratory dialog after a wallet top-up completes successfully.
Future<void> showTopUpSuccessDialog(
  BuildContext context, {
  required double amount,
  required double newBalance,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => TopUpSuccessDialog(amount: amount, newBalance: newBalance),
  );
}

class TopUpSuccessDialog extends StatefulWidget {
  const TopUpSuccessDialog({
    super.key,
    required this.amount,
    required this.newBalance,
  });

  final double amount;
  final double newBalance;

  @override
  State<TopUpSuccessDialog> createState() => _TopUpSuccessDialogState();
}

class _TopUpSuccessDialogState extends State<TopUpSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _circleScale;
  late final Animation<double> _checkScale;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _circleScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
    );
    _checkScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.65, curve: Curves.easeOutBack),
    );
    _contentFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(_contentFade);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _money(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl + 4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Animated success badge ────────────────────────────────────────
            ScaleTransition(
              scale: _circleScale,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: [_green500, _green600],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _green500.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ScaleTransition(
                  scale: _checkScale,
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            FadeTransition(
              opacity: _contentFade,
              child: SlideTransition(
                position: _contentSlide,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Title ─────────────────────────────────────────────────
                    Text(
                      context.tr('تم الشحن بنجاح!'),
                      style: AppTextStyles.heading2
                          .copyWith(color: AppColors.secondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      context.tr('أُضيف المبلغ إلى محفظتك وهو جاهز للاستخدام فوراً'),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.mutedForeground),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // ── Amount card ───────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSizes.lg),
                      decoration: BoxDecoration(
                        color: _green50,
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        border: Border.all(
                          color: _green500.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '+${_money(widget.amount)} ${context.tr('ر.س')}',
                            style: AppTextStyles.heading1.copyWith(
                              color: _green600,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSizes.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: AppSizes.iconSm,
                                color: AppColors.mutedForeground,
                              ),
                              const SizedBox(width: AppSizes.xs),
                              Text(
                                '${context.tr('الرصيد الجديد')}: '
                                '${_money(widget.newBalance)} ${context.tr('ر.س')}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.xl),

                    // ── Done button ───────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
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
                        child: Text(context.tr('تم')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
