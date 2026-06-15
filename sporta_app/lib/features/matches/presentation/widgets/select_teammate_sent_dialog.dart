import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/player.dart';

const Color _green100 = Color(0xFFDCFCE7);
const Color _green600 = Color(0xFF16A34A);
const Color _gray50 = Color(0xFFF9FAFB);
const Color _gray200 = Color(0xFFE5E7EB);

/// "تم إرسال الدعوة!" dialog shown after sending the teammate invitation
/// (converted from the confirmation overlay in SelectTeammatePage.tsx).
class SelectTeammateSentDialog extends StatelessWidget {
  const SelectTeammateSentDialog({
    super.key,
    required this.teammate,
    required this.requestDuration,
  });

  final Player teammate;
  final int requestDuration;

  String get _durationLabel =>
      '$requestDuration ${requestDuration == 1 ? 'ساعة' : 'ساعات'}';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(AppSizes.pagePadding),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 384),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: _green100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 48,
                  color: _green600,
                ),
              ),
              SizedBox(height: AppSizes.lg),
              Text(
                'تم إرسال الدعوة!',
                style: AppTextStyles.heading1
                    .copyWith(color: AppColors.secondary),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSizes.sm),
              Text.rich(
                TextSpan(
                  text: 'تم إرسال إشعار لـ ',
                  children: [
                    TextSpan(
                      text: teammate.name,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: ' للموافقة وإكمال الدفع'),
                  ],
                ),
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.mutedForeground),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSizes.xxl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: _gray50,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: 'زميلك:',
                      value: teammate.name,
                      valueStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: AppSizes.sm),
                    _SummaryRow(label: 'المستوى:', value: teammate.level),
                    SizedBox(height: AppSizes.sm),
                    _SummaryRow(
                      label: 'نسبة الفوز:',
                      value:
                          '${teammate.winRate?.toStringAsFixed(0) ?? '-'}%',
                      valueStyle: AppTextStyles.bodySmall.copyWith(
                        color: _green600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: AppSizes.sm),
                    _SummaryRow(
                      label: 'مدة العرض:',
                      value: _durationLabel,
                      valueStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      height: 1,
                      margin:
                          const EdgeInsets.symmetric(vertical: AppSizes.sm),
                      color: _gray200,
                    ),
                    Text(
                      'سيتم تأكيد الانضمام بعد موافقة زميلك خلال $_durationLabel',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
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
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.mutedForeground),
        ),
        Flexible(
          child: Text(
            value,
            style: valueStyle ??
                AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
