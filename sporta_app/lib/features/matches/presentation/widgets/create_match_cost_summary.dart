import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'create_match_choice_button.dart';

const Color _green50 = Color(0xFFF0FDF4);
const Color _green100 = Color(0xFFDCFCE7);
const Color _green200 = Color(0xFFBBF7D0);
const Color _green500 = Color(0xFF22C55E);
const Color _green600 = Color(0xFF16A34A);
const Color _green700 = Color(0xFF15803D);

/// Green cost summary card: total court cost, per-player share and the
/// payment type selector ("ملخص التكلفة").
class CreateMatchCostSummary extends StatelessWidget {
  const CreateMatchCostSummary({
    super.key,
    required this.totalCost,
    required this.playerShare,
    required this.totalPlayers,
    required this.paymentType,
    required this.onPaymentTypeChanged,
  });

  final int totalCost;
  final int playerShare;
  final int totalPlayers;

  /// 'full' أو 'share'
  final String paymentType;
  final ValueChanged<String> onPaymentTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [_green50, _green100.withValues(alpha: 0.5)],
        ),
        border: Border.all(color: _green200),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.attach_money,
                  size: AppSizes.iconMd, color: _green600),
              SizedBox(width: AppSizes.sm),
              Text(
                'ملخص التكلفة',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.md),
          _summaryRow(
            label: 'تكلفة الملعب الإجمالية:',
            value: Text(
              '$totalCost ر.س',
              style: AppTextStyles.heading3
                  .copyWith(color: AppColors.secondary),
            ),
          ),
          SizedBox(height: AppSizes.sm),
          _summaryRow(
            label: 'عدد اللاعبين الكلي:',
            value: Text(
              '$totalPlayers لاعبين',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.secondary),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.sm),
            child: Divider(height: 1, thickness: 1, color: _green200),
          ),
          _summaryRow(
            label: 'حصة اللاعب الواحد:',
            value: Text(
              '$playerShare ر.س',
              style: AppTextStyles.heading3.copyWith(color: _green600),
            ),
          ),
          SizedBox(height: AppSizes.lg),
          Text(
            'طريقة الدفع *',
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Expanded(
                child: CreateMatchChoiceButton(
                  label: 'دفع المبلغ كاملاً',
                  subLabel: '$totalCost ر.س',
                  selected: paymentType == 'full',
                  onTap: () => onPaymentTypeChanged('full'),
                  selectedBorderColor: _green500,
                  selectedBackground: _green50,
                  selectedForeground: _green700,
                  padding: const EdgeInsets.all(AppSizes.lg),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: CreateMatchChoiceButton(
                  label: 'دفع حصتي فقط',
                  subLabel: '$playerShare ر.س',
                  selected: paymentType == 'share',
                  onTap: () => onPaymentTypeChanged('share'),
                  selectedBorderColor: _green500,
                  selectedBackground: _green50,
                  selectedForeground: _green700,
                  padding: const EdgeInsets.all(AppSizes.lg),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow({required String label, required Widget value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall
            .copyWith(color: AppColors.mutedForeground)),
        value,
      ],
    );
  }
}
