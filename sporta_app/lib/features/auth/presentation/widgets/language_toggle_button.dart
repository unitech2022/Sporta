import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/state/app_scope.dart';

/// Pill button on auth screens that switches between Arabic and English.
class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key, this.compact = false});

  /// Compact shows "EN"/"ع" instead of the full language name.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final settings = context.appSettings;
    final isArabic = settings.language == AppLanguage.ar;
    final label = compact
        ? (isArabic ? 'EN' : 'ع')
        : (isArabic ? 'English' : 'العربية');

    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      shape: StadiumBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: () => settings
            .setLanguage(isArabic ? AppLanguage.en : AppLanguage.ar),
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.translate, size: AppSizes.iconSm,
                  color: Colors.white),
              SizedBox(width: AppSizes.sm),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
