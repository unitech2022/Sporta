import 'package:sporta_app/core/widgets/directional_icon.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/state/app_scope.dart';
import '../../../auth/presentation/state/auth_scope.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/system_insets.dart';

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  void _select(AppLanguage lang) {
    if (context.appSettings.language == lang) return;
    // Applies globally (locale + direction), persists locally and to the API.
    context.auth.updateLanguage(lang);
  }

  @override
  Widget build(BuildContext context) {
    final current = context.appSettings.language;
    return Directionality(
      textDirection: current.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: ColoredBox(
        color: AppColors.background,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: context.safeBottom(
                  const EdgeInsets.all(AppSizes.pagePadding),
                ),
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: AppSizes.lg),
                  _buildLanguageCard(current),
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
                    child: DirectionalIcon(
                      rtl: Icons.chevron_right,
                      ltr: Icons.chevron_left,
                      size: AppSizes.iconMd,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  context.tr('تغيير اللغة'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
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
            child: const Icon(
              Icons.language,
              size: AppSizes.iconSm,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('اختر اللغة المفضلة'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSizes.xs),
                Text(
                  context.tr('سيتم تطبيق اللغة الجديدة على جميع أجزاء التطبيق'),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(AppLanguage current) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          _languageRow(
            flag: 'ع',
            nameAr: trg('العربية'),
            nameNative: trg('العربية'),
            lang: AppLanguage.ar,
            current: current,
            isFirst: true,
          ),
          const Divider(height: 1, indent: AppSizes.lg),
          _languageRow(
            flag: 'EN',
            nameAr: trg('الإنجليزية'),
            nameNative: 'English',
            lang: AppLanguage.en,
            current: current,
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
    required AppLanguage lang,
    required AppLanguage current,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final selected = current == lang;
    return InkWell(
      onTap: () => _select(lang),
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
            top: isFirst
                ? const Radius.circular(AppSizes.radiusXl)
                : Radius.zero,
            bottom: isLast
                ? const Radius.circular(AppSizes.radiusXl)
                : Radius.zero,
          ),
        ),
        child: Row(
          children: [
            // حرف اللغة بدل علم الإيموجي: خط التطبيق لا يحوي الإيموجي.
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              child: Text(flag,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      height: 1)),
            ),
            SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nameAr,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
                child: const Icon(
                  Icons.check,
                  size: 14,
                  color: AppColors.onPrimary,
                ),
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
          const Icon(
            Icons.info_outline,
            size: AppSizes.iconMd,
            color: Color(0xFFD97706),
          ),
          SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              context.tr(
                'يُطبَّق تغيير اللغة فورًا على اتجاه التطبيق ولغته المحفوظة',
              ),
              style: AppTextStyles.bodySmall.copyWith(
                color: const Color(0xFF92400E),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
