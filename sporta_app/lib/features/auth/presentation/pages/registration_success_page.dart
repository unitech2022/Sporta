import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/state/app_settings.dart';
import '../widgets/account_review_notice.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/system_insets.dart';

/// Shown after a successful registration with the chosen roles and
/// suggested next steps.
///
/// حسابا المدرب وصاحب الملعب لا يُفعَّلان إلا بموافقة الأدمن، فتُعرض لهما رسالة
/// «قيد المراجعة» بدل خطوات البدء. من سجّل كلاعب أيضاً يدخل التطبيق كلاعب.
class RegistrationSuccessPage extends StatelessWidget {
  const RegistrationSuccessPage({
    super.key,
    required this.roles,
    required this.onStart,
    this.onBackToLogin,
  });

  /// الأدوار المختارة عند التسجيل — الفعّالة والمعلّقة معاً.
  final Set<UserRole> roles;
  final VoidCallback onStart;

  /// يُستدعى حين لا يملك الحساب أي دور فعّال (مدرب/ملعب فقط) — لا شيء يدخله
  /// التطبيق قبل الموافقة، فيعود لتسجيل الدخول.
  final VoidCallback? onBackToLogin;

  static Map<UserRole, String> get _nextSteps => {
    UserRole.player: trg('أكمل معلومات اللاعب وحدد مستواك'),
    UserRole.coach: trg('أضف شهاداتك وتخصصاتك التدريبية'),
    UserRole.venue: trg('أضف تفاصيل ملعبك والمرافق المتوفرة'),
  };

  /// أدوار تحتاج موافقة الأدمن قبل تفعيلها.
  bool get _needsReview =>
      roles.contains(UserRole.coach) || roles.contains(UserRole.venue);

  /// هل يملك دوراً يعمل فوراً (اللاعب) إلى جانب الدور المعلّق؟
  bool get _hasActiveRole => roles.contains(UserRole.player);

  @override
  Widget build(BuildContext context) {
    if (_needsReview) return _buildUnderReview(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: context.safeBottom(
              const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding)),
          child: Column(
            children: [
              SizedBox(height: 64),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline,
                    size: 48, color: Color(0xFF16A34A)),
              ),
              SizedBox(height: AppSizes.xxl),
              Text(
                context.tr('auth.registration_success_page.welcomeTitle'),
                style: AppTextStyles.heading1
                    .copyWith(fontSize: 30, color: AppColors.secondary),
              ),
              SizedBox(height: AppSizes.md),
              Text(
                context.tr('auth.registration_success_page.accountCreated'),
                style: AppTextStyles.body
                    .copyWith(color: AppColors.mutedForeground),
              ),
              const SizedBox(height: AppSizes.xxl),
              if (roles.isNotEmpty) ...[
                _RolesCard(roles: roles),
                const SizedBox(height: AppSizes.xxl),
              ],
              _NextStepsCard(roles: roles),
              const SizedBox(height: AppSizes.xxl),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onStart,
                  child: Text(context.tr('auth.registration_success_page.startNow')),
                ),
              ),
              const SizedBox(height: AppSizes.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  /// شاشة «طلبك قيد المراجعة» لحسابات المدرب/الملعب.
  Widget _buildUnderReview(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: context.safeBottom(
              const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding)),
          child: Column(
            children: [
              const SizedBox(height: 64),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.hourglass_top_rounded,
                    size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: AppSizes.xxl),
              Text(
                context.tr(accountReviewTitle),
                textAlign: TextAlign.center,
                style: AppTextStyles.heading1
                    .copyWith(fontSize: 26, color: AppColors.secondary),
              ),
              const SizedBox(height: AppSizes.xl),
              for (final paragraph in accountReviewParagraphs) ...[
                Text(
                  context.tr(paragraph),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.mutedForeground),
                ),
                const SizedBox(height: AppSizes.lg),
              ],
              const SizedBox(height: AppSizes.md),
              if (roles.isNotEmpty) ...[
                _RolesCard(roles: roles),
                const SizedBox(height: AppSizes.xxl),
              ],
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  // من سجّل كلاعب أيضاً يدخل الآن بدور اللاعب؛ ومن سجّل كمدرب
                  // أو ملعب فقط لا يملك ما يدخله قبل الموافقة.
                  onPressed:
                      _hasActiveRole ? onStart : (onBackToLogin ?? onStart),
                  child: Text(context.tr(_hasActiveRole
                      ? 'auth.registration_success_page.startNow'
                      : context.tr('العودة لتسجيل الدخول'))),
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

class _RolesCard extends StatelessWidget {
  const _RolesCard({required this.roles});

  final Set<UserRole> roles;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.xxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            context.tr('auth.registration_success_page.yourRoles'),
            style: AppTextStyles.heading3.copyWith(color: AppColors.secondary),
          ),
          SizedBox(height: AppSizes.lg),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            alignment: WrapAlignment.center,
            children: [
              for (final role in roles)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                    vertical: AppSizes.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    '${role.emoji} ${context.tr(role.trKey)}',
                    style:
                        AppTextStyles.bodySmall.copyWith(color: Colors.white),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSizes.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Text(
              context.tr('auth.registration_success_page.switchRolesHint'),
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextStepsCard extends StatelessWidget {
  const _NextStepsCard({required this.roles});

  final Set<UserRole> roles;

  @override
  Widget build(BuildContext context) {
    final steps = [
      for (final role in roles)
        RegistrationSuccessPage._nextSteps[role]!,
      context.tr('auth.registration_success_page.exploreNearby'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            context.tr('auth.registration_success_page.nextSteps'),
            style: AppTextStyles.heading3.copyWith(color: AppColors.secondary),
          ),
          SizedBox(height: AppSizes.md),
          for (final step in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✓', style: TextStyle(color: AppColors.primary)),
                  SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      step,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.mutedForeground),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
