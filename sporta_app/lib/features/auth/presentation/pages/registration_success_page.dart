import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/state/app_settings.dart';
import '../../domain/entities/registration_data.dart';

/// Shown after a successful registration with the chosen roles and
/// suggested next steps.
class RegistrationSuccessPage extends StatelessWidget {
  const RegistrationSuccessPage({
    super.key,
    required this.data,
    required this.onStart,
  });

  final RegistrationData data;
  final VoidCallback onStart;

  static const _nextSteps = {
    UserRole.player: 'أكمل معلومات اللاعب وحدد مستواك',
    UserRole.coach: 'أضف شهاداتك وتخصصاتك التدريبية',
    UserRole.venue: 'أضف تفاصيل ملعبك والمرافق المتوفرة',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
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
                'مرحباً بك في SPORTA!',
                style: AppTextStyles.heading1
                    .copyWith(fontSize: 30, color: AppColors.secondary),
              ),
              SizedBox(height: AppSizes.md),
              Text(
                'تم إنشاء حسابك بنجاح 🎉',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.mutedForeground),
              ),
              const SizedBox(height: AppSizes.xxl),
              if (data.roles.isNotEmpty) ...[
                _RolesCard(roles: data.roles),
                const SizedBox(height: AppSizes.xxl),
              ],
              _NextStepsCard(roles: data.roles),
              const SizedBox(height: AppSizes.xxl),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onStart,
                  child: const Text('ابدأ الآن'),
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
            'أدوارك في التطبيق',
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
              '💡 يمكنك التبديل بين الأدوار في أي وقت من القائمة الرئيسية',
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
      'استكشف الملاعب والمباريات القريبة منك',
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
            'الخطوات التالية',
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
