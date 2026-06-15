import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/widgets/sporta_logo.dart';
import '../widgets/circle_back_button.dart';

/// Registration step 1: pick the app language.
class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({
    super.key,
    required this.onSelectLanguage,
    this.onBack,
  });

  final ValueChanged<AppLanguage> onSelectLanguage;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSizes.xxxl),
              if (onBack != null) CircleBackButton(onTap: onBack!, dark: true),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: SportaLogo(width: 128)),
                    SizedBox(height: AppSizes.xxl),
                    Text(
                      'اختر اللغة',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading1.copyWith(
                        fontSize: 30,
                        color: AppColors.secondary,
                      ),
                    ),
                    SizedBox(height: AppSizes.sm),
                    Text(
                      'Choose Language',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.secondary.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: AppSizes.sm),
                    Text(
                      'يمكنك تغيير اللغة في أي وقت من الإعدادات',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.mutedForeground),
                    ),
                    const SizedBox(height: 48),
                    _LanguageOption(
                      flag: '🇸🇦',
                      title: 'العربية',
                      subtitle: 'Arabic',
                      selected: true,
                      onTap: () => onSelectLanguage(AppLanguage.ar),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    _LanguageOption(
                      flag: '🇬🇧',
                      title: 'English',
                      subtitle: 'الإنجليزية',
                      selected: false,
                      onTap: () => onSelectLanguage(AppLanguage.en),
                    ),
                  ],
                ),
              ),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                    ),
                    SizedBox(height: AppSizes.sm),
                    Text('خطوة 1 من 4', style: AppTextStyles.caption),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String flag;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xxl),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 36)),
              SizedBox(width: AppSizes.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.heading2
                            .copyWith(color: AppColors.secondary)),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              if (selected)
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.check, size: 16, color: Colors.white),
                )
              else
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
