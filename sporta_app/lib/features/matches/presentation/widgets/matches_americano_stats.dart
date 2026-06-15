import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Two-column "المسجلين / الملاعب" stats box used on americano cards.
class MatchesAmericanoStats extends StatelessWidget {
  const MatchesAmericanoStats({
    super.key,
    required this.background,
    required this.registered,
    required this.registeredColor,
    required this.courts,
    required this.courtsColor,
  });

  final Color background;
  final String registered;
  final Color registeredColor;
  final String courts;
  final Color courtsColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
              label: 'المسجلين',
              value: registered,
              valueColor: registeredColor,
            ),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: _StatColumn(
              label: 'الملاعب',
              value: courts,
              valueColor: courtsColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption),
        SizedBox(height: AppSizes.xs),
        Text(
          value,
          style: AppTextStyles.heading3.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
