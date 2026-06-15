import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../domain/entities/court_entity.dart';
import '../../courts_helpers.dart';
import 'booking_date_utils.dart';

/// Read-only summary of the chosen booking with the computed total price.
class BookingSummaryCard extends StatelessWidget {
  const BookingSummaryCard({
    super.key,
    required this.court,
    required this.date,
    required this.courtNumber,
    required this.time,
    required this.durationMinutes,
  });

  final CourtEntity court;
  final DateTime date;
  final int courtNumber;
  final String time;
  final int durationMinutes;

  @override
  Widget build(BuildContext context) {
    final total = sessionTotalPrice(court, time, durationMinutes);
    final priceType = isPeakHour(time) ? 'ساعة الذروة' : 'سعر اعتيادي';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ملخص الحجز',
            style: AppTextStyles.heading2.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.md),
          _SummaryRow(
            icon: Icons.calendar_today_outlined,
            label: 'التاريخ',
            value: BookingDateUtils.fullDate(date),
          ),
          _SummaryRow(
            icon: Icons.grid_4x4_rounded,
            label: 'رقم الملعب',
            value: 'ملعب $courtNumber',
          ),
          _SummaryRow(
            icon: Icons.access_time_rounded,
            label: 'الوقت',
            value: time,
          ),
          _SummaryRow(
            icon: Icons.timelapse_rounded,
            label: 'المدة',
            value: '$durationMinutes دقيقة',
          ),
          _SummaryRow(
            icon: Icons.info_outline_rounded,
            label: 'نوع السعر',
            value: priceType,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.sm),
            child: Divider(color: AppColors.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإجمالي',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              Text(
                '$total ر.س',
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
