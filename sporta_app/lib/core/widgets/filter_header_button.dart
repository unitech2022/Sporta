import 'package:flutter/material.dart';
import 'package:sporta_app/core/state/app_scope.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// The filter button that sits in a page's gradient header.
///
/// With no filter applied it opens the filter sheet. Once something is applied
/// it turns into a "clear the filters" button — the icon changes, a badge shows
/// how many are active, and a tap wipes them without opening the sheet.
class FilterHeaderButton extends StatelessWidget {
  const FilterHeaderButton({
    super.key,
    required this.activeCount,
    required this.onOpen,
    required this.onClear,
  });

  /// How many filters are currently applied; 0 means none.
  final int activeCount;

  final VoidCallback onOpen;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isActive = activeCount > 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Tooltip(
          message: context.tr(isActive ? context.tr('مسح الفلاتر') : context.tr('الفلاتر')),
          child: GestureDetector(
            onTap: isActive ? onClear : onOpen,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: isActive
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
              ),
              child: Icon(
                isActive ? Icons.filter_alt_off_rounded : Icons.tune_rounded,
                color: Colors.white,
                size: AppSizes.iconMd,
              ),
            ),
          ),
        ),
        if (isActive) _FilterBadge(count: activeCount),
      ],
    );
  }
}

/// Small count badge overlaid on the filter button.
class _FilterBadge extends StatelessWidget {
  const _FilterBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -4,
      left: -4,
      child: Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
