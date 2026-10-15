import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/points_entity.dart';
import '../cubit/points_cubit.dart';
import '../../../../core/utils/system_insets.dart';

/// Bottom sheet that picks how many points to convert into wallet credit.
/// Resolves to true when a redemption succeeded.
Future<bool?> showRedeemPointsSheet(
  BuildContext context,
  PointsCubit cubit,
  PointsSummaryEntity summary,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
    ),
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _RedeemSheet(summary: summary),
    ),
  );
}

class _RedeemSheet extends StatefulWidget {
  const _RedeemSheet({required this.summary});

  final PointsSummaryEntity summary;

  @override
  State<_RedeemSheet> createState() => _RedeemSheetState();
}

class _RedeemSheetState extends State<_RedeemSheet> {
  late int _points = widget.summary.minRedeemPoints;

  double get _valueSar => widget.summary.redeemPointsPerRiyal <= 0
      ? 0
      : _points / widget.summary.redeemPointsPerRiyal;

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final min = s.minRedeemPoints.clamp(1, s.balance);
    final max = s.balance;

    return Directionality(
      textDirection: Directionality.of(context),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSizes.pagePadding,
          right: AppSizes.pagePadding,
          top: AppSizes.xl,
          bottom: MediaQuery.of(context).viewInsets.bottom +
              AppSizes.xl +
              context.bottomSystemInset,
        ),
        child: BlocBuilder<PointsCubit, PointsState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('استبدال النقاط'),
                    style: AppTextStyles.heading2),
                const SizedBox(height: AppSizes.sm),
                Text(
                  '${s.redeemPointsPerRiyal} ${context.tr('نقطة = 1 ر.س رصيد محفظة')}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.mutedForeground),
                ),
                const SizedBox(height: AppSizes.xl),
                Center(
                  child: Column(
                    children: [
                      Text('$_points ${context.tr('نقطة')}',
                          style: AppTextStyles.heading1
                              .copyWith(color: AppColors.primary)),
                      Text(
                        '= ${_valueSar.toStringAsFixed(2)} ${context.tr('ر.س')}',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                ),
                if (max > min)
                  Slider(
                    value: _points.toDouble().clamp(
                        min.toDouble(), max.toDouble()),
                    min: min.toDouble(),
                    max: max.toDouble(),
                    divisions: (max - min) < 100 ? (max - min) : 100,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _points = v.round()),
                  ),
                const SizedBox(height: AppSizes.md),
                Row(
                  children: [
                    for (final fraction in [0.25, 0.5, 1.0])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.xs),
                          child: OutlinedButton(
                            onPressed: () => setState(() => _points =
                                (max * fraction).round().clamp(min, max)),
                            child: Text(fraction == 1.0
                                ? context.tr('الكل')
                                : '${(fraction * 100).round()}%'),
                          ),
                        ),
                      ),
                  ],
                ),
                if (state.error != null) ...[
                  const SizedBox(height: AppSizes.md),
                  Text(state.error!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.destructive)),
                ],
                const SizedBox(height: AppSizes.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.redeeming
                        ? null
                        : () async {
                            final isArabic =
                                context.appSettings.language.isRtl;
                            final ok = await context
                                .read<PointsCubit>()
                                .redeem(_points, isArabic: isArabic);
                            if (ok && context.mounted) {
                              Navigator.of(context).pop(true);
                            }
                          },
                    child: state.redeeming
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.tr('تأكيد الاستبدال')),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
