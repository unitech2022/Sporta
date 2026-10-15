import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/localization/tr_global.dart';

/// A small segmented control that lets the reader switch a policy page between
/// its Arabic and English versions, independent of the app language.
class PolicyLanguageToggle extends StatelessWidget {
  const PolicyLanguageToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AppLanguage value;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xs),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(trg('العربية'), AppLanguage.ar),
          _segment('English', AppLanguage.en),
        ],
      ),
    );
  }

  Widget _segment(String label, AppLanguage lang) {
    final selected = value == lang;
    return GestureDetector(
      onTap: selected ? null : () => onChanged(lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }
}
