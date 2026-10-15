import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../data/models/booking_quote.dart';
import '../../../domain/entities/court_entity.dart';
import '../../courts_helpers.dart';
import 'booking_date_utils.dart';
import '../../../../../core/localization/tr_global.dart';

/// Read-only summary of the chosen booking with the computed total price.
class BookingSummaryCard extends StatelessWidget {
  const BookingSummaryCard({
    super.key,
    required this.court,
    required this.date,
    required this.courtNumber,
    required this.time,
    required this.durationMinutes,
    this.quote,
    this.quoteLoading = false,
  });

  final CourtEntity court;
  final DateTime date;
  final int courtNumber;
  final String time;
  final int durationMinutes;

  /// تسعير الخادم — المرجع حين يصل، وإلا نعرض التقدير المحلي.
  final BookingQuote? quote;
  final bool quoteLoading;

  @override
  Widget build(BuildContext context) {
    final q = quote;
    final base = q?.basePrice ??
        sessionTotalPrice(court, time, durationMinutes).toDouble();
    final total = q?.total ?? base;
    final priceType = base > court.totalPrice
        ? trg('ساعة ذروة')
        : base < court.totalPrice
            ? trg('ساعة مخفّضة')
            : trg('سعر اعتيادي');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('ملخص الحجز'),
            style: AppTextStyles.heading2.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.md),
          _SummaryRow(
            icon: Icons.calendar_today_outlined,
            label: context.tr('التاريخ'),
            value: BookingDateUtils.fullDate(date),
          ),
          _SummaryRow(
            icon: Icons.grid_4x4_rounded,
            label: context.tr('رقم الملعب'),
            value: context.trArgs('ملعب {p0}', {'p0': courtNumber}),
          ),
          _SummaryRow(
            icon: Icons.access_time_rounded,
            label: context.tr('الوقت'),
            value: time,
          ),
          _SummaryRow(
            icon: Icons.timelapse_rounded,
            label: context.tr('المدة'),
            value: context.trArgs('{p0} دقيقة', {'p0': durationMinutes}),
          ),
          _SummaryRow(
            icon: Icons.info_outline_rounded,
            label: context.tr('نوع السعر'),
            value: priceType,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.sm),
            child: Divider(),
          ),
          if (q != null && q.hasDiscount) ...[
            _SummaryRow(
              icon: Icons.receipt_long_outlined,
              label: context.tr('سعر الملعب'),
              value: context.trArgs('{p0} ر.س', {'p0': _fmt(base)}),
            ),
            if (q.memberDiscountAmount > 0)
              _SummaryRow(
                icon: Icons.workspace_premium_outlined,
                label: context.tr('خصم عضوية النادي'),
                value: context.trArgs('- {p0} ر.س', {
                  'p0': _fmt(q.memberDiscountAmount),
                }),
              ),
            if (q.packageDiscountAmount >= 0.01)
              _SummaryRow(
                icon: Icons.local_offer_outlined,
                label: q.memberDiscountAmount > 0
                    ? context.tr('خصم باقتك')
                    : '${context.tr('خصم باقتك')} (${_fmt(q.discountPercent)}%)',
                value: context.trArgs('- {p0} ر.س', {
                  'p0': _fmt(q.packageDiscountAmount),
                }),
              ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('الإجمالي'),
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              if (quoteLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  context.trArgs('{p0} ر.س', {'p0': _fmt(total)}),
                  style: AppTextStyles.heading2.copyWith(
                    color: const Color(0xFF16A34A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// يعرض الرقم بلا كسور حين يكون صحيحاً (100 بدل 100.0).
String _fmt(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconSm, color: AppColors.mutedForeground),
          const SizedBox(width: AppSizes.sm),
          Text(
            label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.mutedForeground),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
