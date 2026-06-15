import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  String _selectedLang = 'ar';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ColoredBox(
        color: AppColors.background,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: AppSizes.lg),
                  _buildLanguageCard(),
                  const SizedBox(height: AppSizes.lg),
                  _buildNote(),
                  const SizedBox(height: AppSizes.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF0EA5D4)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.xl,
            AppSizes.pagePadding,
            AppSizes.xl,
          ),
          child: Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.2),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: widget.onBack,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(AppSizes.sm),
                    child: Icon(Icons.chevron_right,
                        size: AppSizes.iconMd, color: Colors.white),
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'تغيير اللغة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: const Icon(Icons.language,
                size: AppSizes.iconSm, color: AppColors.primary),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اختر اللغة المفضلة',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: AppSizes.xs),
                Text(
                  'سيتم تطبيق اللغة الجديدة على جميع أجزاء التطبيق',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          _languageRow(
            flag: '🇸🇦',
            nameAr: 'العربية',
            nameNative: 'العربية',
            code: 'ar',
            isFirst: true,
          ),
          const Divider(height: 1, indent: AppSizes.lg),
          _languageRow(
            flag: '🇬🇧',
            nameAr: 'الإنجليزية',
            nameNative: 'English',
            code: 'en',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _languageRow({
    required String flag,
    required String nameAr,
    required String nameNative,
    required String code,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final selected = _selectedLang == code;
    return InkWell(
      onTap: () => setState(() => _selectedLang = code),
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(AppSizes.radiusXl) : Radius.zero,
        bottom: isLast ? const Radius.circular(AppSizes.radiusXl) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.vertical(
            top:
                isFirst ? const Radius.circular(AppSizes.radiusXl) : Radius.zero,
            bottom:
                isLast ? const Radius.circular(AppSizes.radiusXl) : Radius.zero,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nameAr,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500)),
                  Text(nameNative, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check,
                    size: 14, color: AppColors.onPrimary),
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
    );
  }

  Widget _buildNote() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              size: AppSizes.iconMd, color: Color(0xFFD97706)),
          SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              'بعد تغيير اللغة، سيتم إعادة تشغيل التطبيق لتطبيق التغييرات',
              style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF92400E), height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
