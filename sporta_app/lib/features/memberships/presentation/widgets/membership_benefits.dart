import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/money.dart';

/// لون العضويات: ذهبي دافئ يميّزها عن أزرار التطبيق.
const Color membershipGold = Color(0xFFC88A04);

/// سطور مزايا خطة/عضوية: الخصم (وسقفه) وأيام الأولوية.
class MembershipBenefits extends StatelessWidget {
  const MembershipBenefits({
    super.key,
    required this.discountPercent,
    required this.monthlyDiscountHours,
    required this.priorityDays,
  });

  final double discountPercent;
  final int? monthlyDiscountHours;
  final int priorityDays;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (discountPercent > 0)
          _line(
            Icons.local_offer_outlined,
            monthlyDiscountHours == null
                ? context.trArgs('خصم {p0}% على كل حجوزاتك في النادي', {
                    'p0': money(discountPercent),
                  })
                : context.trArgs('خصم {p0}% على أول {p1} ساعات حجز شهرياً', {
                    'p0': money(discountPercent),
                    'p1': monthlyDiscountHours!,
                  }),
          ),
        if (priorityDays > 0)
          _line(
            Icons.bolt_outlined,
            context.trArgs('أولوية الحجز: احجز قبل غيرك بـ {p0} أيام', {
              'p0': priorityDays,
            }),
          ),
      ],
    );
  }

  Widget _line(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(top: AppSizes.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.success),
        const SizedBox(width: AppSizes.xs),
        Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
      ],
    ),
  );
}

/// شارة «عضو» صغيرة.
class MemberBadge extends StatelessWidget {
  const MemberBadge({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE8A3), Color(0xFFF2B705)],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium,
            size: 14,
            color: Color(0xFF7A4E00),
          ),
          const SizedBox(width: 3),
          Text(
            label ?? context.tr('عضو'),
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFF7A4E00),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
