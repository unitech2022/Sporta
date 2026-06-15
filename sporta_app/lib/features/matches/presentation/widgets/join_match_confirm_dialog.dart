import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

const Color _green100 = Color(0xFFDCFCE7);
const Color _green600 = Color(0xFF16A34A);
const Color _gray50 = Color(0xFFF9FAFB);
const Color _gray100 = Color(0xFFF3F4F6);
const Color _gray200 = Color(0xFFE5E7EB);

/// Join confirmation dialog (converted from the confirmation overlay
/// in JoinMatchPage.tsx).
class JoinMatchConfirmDialog extends StatelessWidget {
  const JoinMatchConfirmDialog({
    super.key,
    required this.message,
    required this.courtName,
    required this.dateLabel,
    required this.timeLabel,
    required this.costPerPlayer,
    required this.onConfirm,
    this.invitedFriendFirstNames = const [],
    this.teammateName,
    this.teammateNote,
  });

  final String message;
  final String courtName;
  final String dateLabel;
  final String timeLabel;
  final double costPerPlayer;
  final VoidCallback onConfirm;
  final List<String> invitedFriendFirstNames;
  final String? teammateName;
  final String? teammateNote;

  String get _cost =>
      costPerPlayer == costPerPlayer.roundToDouble()
          ? costPerPlayer.toStringAsFixed(0)
          : costPerPlayer.toString();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(AppSizes.pagePadding),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 384),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: _green100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: AppSizes.iconXl,
                  color: _green600,
                ),
              ),
              SizedBox(height: AppSizes.lg),
              Text(
                'تأكيد الانضمام',
                style: AppTextStyles.heading2
                    .copyWith(color: AppColors.secondary),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSizes.sm),
              Text(
                message,
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
                      label: 'المباراة:',
                      value: courtName,
                      valueStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: AppSizes.sm),
                    _SummaryRow(label: 'التاريخ:', value: dateLabel),
                    SizedBox(height: AppSizes.sm),
                    _SummaryRow(label: 'الوقت:', value: timeLabel),
                    if (invitedFriendFirstNames.isNotEmpty) ...[
                      const _SummaryDivider(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الأصدقاء المدعوون:',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.mutedForeground),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              spacing: AppSizes.xs,
                              runSpacing: AppSizes.xs,
                              children: [
                                for (final name in invitedFriendFirstNames)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSizes.sm,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                          AppSizes.radiusFull),
                                    ),
                                    child: Text(
                                      name,
                                      style: AppTextStyles.caption
                                          .copyWith(color: AppColors.primary),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (teammateName != null) ...[
                      const _SummaryDivider(),
                      _SummaryRow(
                        label: 'زميلك:',
                        value: teammateName!,
                        valueStyle: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const _SummaryDivider(),
                    _SummaryRow(
                      label: 'التكلفة:',
                      value: '$_cost ر.س',
                      valueStyle: AppTextStyles.bodySmall.copyWith(
                        color: _green600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (teammateNote != null) ...[
                      SizedBox(height: AppSizes.sm),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(teammateNote!, style: AppTextStyles.caption),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: AppSizes.xxl),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: _gray100,
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLg),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.md,
                          ),
                          child: Text(
                            'إلغاء',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.secondary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Material(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusLg),
                        ),
                        child: InkWell(
                          onTap: onConfirm,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusLg),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.md,
                            ),
                            child: Text(
                              'تأكيد الانضمام',
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.onPrimary),
                              textAlign: TextAlign.center,
                            ),
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
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.mutedForeground),
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

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      color: _gray200,
    );
  }
}
