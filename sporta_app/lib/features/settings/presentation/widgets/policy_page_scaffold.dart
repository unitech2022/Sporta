import 'package:sporta_app/core/di/service_locator.dart';
import 'package:sporta_app/core/state/app_scope.dart';
import 'package:sporta_app/core/widgets/directional_icon.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../data/settings_repository.dart';
import '../../domain/setting_entity.dart';
import 'dynamic_policy_card.dart';
import 'policy_language_toggle.dart';
import '../../../../core/utils/system_insets.dart';

/// Shared chrome for the three legal pages (terms / privacy / refund). Fetches
/// the admin-managed content for [settingKey] from `/api/settings/public`,
/// renders it as organized Markdown, and lets the reader switch between the
/// Arabic and English versions with an in-page toggle.
class PolicyPageScaffold extends StatefulWidget {
  const PolicyPageScaffold({
    super.key,
    required this.onBack,
    required this.settingKey,
    required this.titleAr,
    required this.titleEn,
    required this.infoIcon,
  });

  final VoidCallback onBack;
  final String settingKey;
  final String titleAr;
  final String titleEn;
  final IconData infoIcon;

  @override
  State<PolicyPageScaffold> createState() => _PolicyPageScaffoldState();
}

class _PolicyPageScaffoldState extends State<PolicyPageScaffold> {
  SettingEntity? _setting;
  AppLanguage? _lang;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final settings = await getIt<SettingsRepository>().fetchPublicSettings();
      final s = settings[widget.settingKey];
      if (!mounted) return;
      setState(() {
        _setting = s;
        _loading = false;
        _failed = s == null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  bool get _hasBothLanguages =>
      (_setting?.valueAr.trim().isNotEmpty ?? false) &&
      (_setting?.valueEn.trim().isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final lang = _lang ??= context.appSettings.language;
    final isAr = lang == AppLanguage.ar;

    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          _header(isAr ? widget.titleAr : widget.titleEn),
          Expanded(child: _body(lang)),
        ],
      ),
    );
  }

  Widget _body(AppLanguage lang) {
    if (_loading) return _skeleton();
    if (_failed || _setting == null) {
      return _errorState(lang);
    }

    final isAr = lang == AppLanguage.ar;
    final text = isAr ? _setting!.valueAr : _setting!.valueEn;
    final resolved = text.trim().isNotEmpty ? text : _setting!.valueAr;

    return ListView(
      padding: context.safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
      children: [
        _infoCard(lang),
        if (_hasBothLanguages) ...[
          const SizedBox(height: AppSizes.lg),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: PolicyLanguageToggle(
              value: lang,
              onChanged: (l) => setState(() => _lang = l),
            ),
          ),
        ],
        const SizedBox(height: AppSizes.lg),
        Directionality(
          textDirection: lang.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: DynamicPolicyCard(text: resolved),
        ),
        const SizedBox(height: AppSizes.lg),
        _footer(lang),
        const SizedBox(height: AppSizes.xl),
      ],
    );
  }

  /// هيكل النص: بطاقة المعلومات ثم فقرات بعناوين.
  Widget _skeleton() {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const SkeletonBox(height: 72, radius: AppSizes.radiusXl),
          const SizedBox(height: AppSizes.xl),
          for (var p = 0; p < 3; p++) ...[
            const SkeletonBox(height: 16, width: 160),
            const SizedBox(height: AppSizes.md),
            for (var i = 0; i < 4; i++) ...[
              SkeletonBox(height: 10, width: i == 3 ? 180 : null),
              const SizedBox(height: AppSizes.sm),
            ],
            const SizedBox(height: AppSizes.lg),
          ],
        ],
      ),
    );
  }

  Widget _errorState(AppLanguage lang) {
    final isAr = lang == AppLanguage.ar;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              isAr
                  ? context.tr('تعذّر تحميل المحتوى. تحقق من اتصالك بالإنترنت.')
                  : 'Could not load the content. Check your connection.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            FilledButton.icon(
              onPressed: _load,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.refresh, size: AppSizes.iconMd),
              label: Text(isAr ? context.tr('إعادة المحاولة') : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(String title) {
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
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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

  Widget _infoCard(AppLanguage lang) {
    final isAr = lang == AppLanguage.ar;
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Icon(
              widget.infoIcon,
              size: AppSizes.iconMd,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? widget.titleAr : widget.titleEn,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  isAr
                      ? context.tr('يرجى قراءة هذه السياسة بعناية')
                      : 'Please read this policy carefully',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(AppLanguage lang) {
    final isAr = lang == AppLanguage.ar;
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(
          isAr
              ? context.tr('© 2026 SPORTA. جميع الحقوق محفوظة')
              : '© 2026 SPORTA. All rights reserved',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.mutedForeground,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
