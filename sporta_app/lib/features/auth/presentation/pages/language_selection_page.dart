import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../../core/widgets/sporta_logo.dart';
import '../widgets/circle_back_button.dart';

/// Registration step 1: pick the app language. Selecting a card only updates
/// the highlighted choice; the "Next" button confirms it and advances.
class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({
    super.key,
    required this.onSelectLanguage,
    this.onBack,
  });

  final ValueChanged<AppLanguage> onSelectLanguage;
  final VoidCallback? onBack;

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  AppLanguage _selected = AppLanguage.ar;

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
              if (widget.onBack != null)
                CircleBackButton(onTap: widget.onBack!, dark: true),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: SportaLogo(width: 128)),
                    SizedBox(height: AppSizes.xxl),
                    Text(
                      context.tr('auth.language_selection_page.title'),
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
                      context.tr('auth.language_selection_page.subtitle'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.mutedForeground),
                    ),
                    const SizedBox(height: 48),
                    _LanguageOption(
                      badge: 'ع',
                      title: context.tr('العربية'),
                      subtitle: 'Arabic',
                      selected: _selected == AppLanguage.ar,
                      onTap: () => setState(() => _selected = AppLanguage.ar),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    _LanguageOption(
                      badge: 'EN',
                      title: 'English',
                      subtitle: context.tr('الإنجليزية'),
                      selected: _selected == AppLanguage.en,
                      onTap: () => setState(() => _selected = AppLanguage.en),
                    ),
                    const SizedBox(height: AppSizes.xxl),
                    ElevatedButton(
                      onPressed: () => widget.onSelectLanguage(_selected),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(context.tr('next')),
                          DirectionalIcon(
                            rtl: Icons.chevron_left,
                            ltr: Icons.chevron_right,
                            size: AppSizes.iconMd,
                          ),
                        ],
                      ),
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
                    Text(context.tr('auth.language_selection_page.stepIndicator'),
                        style: AppTextStyles.caption),
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
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  /// حرف اللغة داخل دائرة — بدل علم الإيموجي: خط التطبيق لا يحوي الإيموجي
  /// فكان العلم يظهر مربّعين بعلامة استفهام ويضغط العنوان إلى سطرين.
  final String badge;
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
              _LanguageBadge(label: badge, selected: selected),
              SizedBox(width: AppSizes.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

/// دائرة بحرف اللغة («ع» / «EN»)، تمتلئ بلون التطبيق حين تكون مختارة.
class _LanguageBadge extends StatelessWidget {
  const _LanguageBadge({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? AppColors.primary
            : AppColors.primary.withValues(alpha: 0.1),
      ),
      child: Text(
        label,
        style: AppTextStyles.heading3.copyWith(
          color: selected ? Colors.white : AppColors.primary,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
