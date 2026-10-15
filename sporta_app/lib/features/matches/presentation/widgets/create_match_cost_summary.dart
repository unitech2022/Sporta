import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

const Color _green50 = Color(0xFFF0FDF4);
const Color _green100 = Color(0xFFDCFCE7);
const Color _green200 = Color(0xFFBBF7D0);
const Color _green600 = Color(0xFF16A34A);
const Color _green700 = Color(0xFF15803D);

/// بطاقة «ملخص التكلفة»: سعر الملعب، وحصة اللاعب الواحد. لا خيار لطريقة
/// الدفع — الدفع فرديّ دائماً (الحجز العادي وحده يدفعه صاحبه كاملاً).
class CreateMatchCostSummary extends StatelessWidget {
  const CreateMatchCostSummary({
    super.key,
    required this.totalCost,
    required this.playerShare,
    required this.totalPlayers,
    this.hostedByVenue = false,
  });

  /// استضافة صاحب الملعب: لا يدفع شيئاً — اللاعبون يدفعون حصصهم وتصل إليه.
  final double totalCost;
  final double playerShare;
  final int totalPlayers;

  final bool hostedByVenue;

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
              const Icon(
                Icons.attach_money,
                size: AppSizes.iconMd,
                color: _green600,
              ),
              SizedBox(width: AppSizes.sm),
              Text(
                context.tr('ملخص التكلفة'),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.md),
          _summaryRow(
            label: context.tr('تكلفة الملعب الإجمالية:'),
            value: Text(
              context.trArgs('{p0} ر.س', {'p0': money(totalCost)}),
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
          SizedBox(height: AppSizes.sm),
          _summaryRow(
            label: context.tr('عدد اللاعبين الكلي:'),
            value: Text(
              context.trArgs('{p0} لاعبين', {'p0': totalPlayers}),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.sm),
            child: Divider(height: 1),
          ),
          _summaryRow(
            label: context.tr('حصة اللاعب الواحد:'),
            value: Text(
              context.trArgs('{p0} ر.س', {'p0': money(playerShare)}),
              style: AppTextStyles.heading3.copyWith(color: _green600),
            ),
          ),
          SizedBox(height: AppSizes.lg),
          // الدفع فرديّ دائماً: لا خيار «أدفع عن الجميع» — لكلٍّ حصته.
          Row(
            children: [
              Icon(
                hostedByVenue ? Icons.info_outline : Icons.call_split,
                size: AppSizes.iconSm,
                color: _green600,
              ),
              SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  hostedByVenue
                      ? context.tr(
                          'لا يُخصم منك شيء — كل لاعب يدفع حصته وتصلك مباشرةً بعد خصم نسبة سبورتا.',
                        )
                      : context.tr(
                          'كل لاعب يدفع حصته وحده — تُخصم حصتك أنت عند الإنشاء.',
                        ),
                  style: AppTextStyles.bodySmall.copyWith(color: _green700),
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
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.mutedForeground,
          ),
        ),
        value,
      ],
    );
  }
}
