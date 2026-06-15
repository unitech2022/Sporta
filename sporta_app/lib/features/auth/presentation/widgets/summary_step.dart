import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/state/app_settings.dart';
import '../../domain/entities/registration_data.dart';

/// Registration step 3: review the selected roles before submitting.
class SummaryStep extends StatelessWidget {
  const SummaryStep({super.key, required this.data});

  final RegistrationData data;

  static const _roleDetails = {
    UserRole.player: 'تفضيلات اللعب وتحديد المستوى (لاعب)',
    UserRole.coach: 'الشهادات والتخصصات والتسعير (مدرب)',
    UserRole.venue: 'تفاصيل الملعب والمرافق والأسعار (ملعب)',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'معلومات إضافية',
          style: AppTextStyles.heading1.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSizes.xxl),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.xl),
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
            ),
          ),
          child: Column(
            children: [
              Text(
                'الأدوار المختارة:',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.secondary),
              ),
              const SizedBox(height: AppSizes.md),
              Wrap(
                spacing: AppSizes.sm,
                runSpacing: AppSizes.sm,
                alignment: WrapAlignment.center,
                children: [
                  for (final role in data.roles)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.lg,
                        vertical: AppSizes.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Text(
                        context.tr(role.trKey),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: AppSizes.xl),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.xl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ستتمكن من إكمال المعلومات التفصيلية لكل دور بعد إنشاء الحساب',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.secondary),
              ),
              SizedBox(height: AppSizes.md),
              for (final role in data.roles)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•',
                          style: TextStyle(color: AppColors.primary)),
                      SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          _roleDetails[role]!,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.mutedForeground),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: AppSizes.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            'ℹ️ يمكنك التبديل بين الأدوار في أي وقت من القائمة الرئيسية',
            style: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }
}
