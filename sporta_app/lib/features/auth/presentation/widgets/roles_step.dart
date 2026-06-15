import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_settings.dart';
import '../../domain/entities/registration_data.dart';
import 'role_card.dart';

/// Registration step 2: choose one or more roles.
class RolesStep extends StatelessWidget {
  const RolesStep({super.key, required this.data, required this.onChanged});

  final RegistrationData data;
  final VoidCallback onChanged;

  void _toggle(UserRole role) {
    if (!data.roles.remove(role)) data.roles.add(role);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر أدوارك في التطبيق',
          style: AppTextStyles.heading1.copyWith(color: AppColors.secondary),
        ),
        SizedBox(height: AppSizes.xxl),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            '💡 يمكنك اختيار أكثر من دور واحد. ستتمكن من التبديل بينهم في أي وقت',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.secondary),
          ),
        ),
        const SizedBox(height: AppSizes.xxl),
        RoleCard(
          title: 'لاعب',
          description: 'احجز ملاعب، انضم للمباريات، وتتبع تقدمك',
          icon: Icons.sports_tennis,
          selected: data.roles.contains(UserRole.player),
          onTap: () => _toggle(UserRole.player),
        ),
        const SizedBox(height: AppSizes.md),
        RoleCard(
          title: 'مدرب',
          description: 'قدم دروس تدريبية وطور مهارات اللاعبين',
          icon: Icons.emoji_events_outlined,
          selected: data.roles.contains(UserRole.coach),
          onTap: () => _toggle(UserRole.coach),
        ),
        const SizedBox(height: AppSizes.md),
        RoleCard(
          title: 'مالك ملعب',
          description: 'أدر ملعبك، استقبل الحجوزات، ونظم البطولات',
          icon: Icons.stadium_outlined,
          selected: data.roles.contains(UserRole.venue),
          onTap: () => _toggle(UserRole.venue),
        ),
        if (data.roles.isEmpty) ...[
          SizedBox(height: AppSizes.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: const Color(0xFFFEFCE8),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: const Color(0xFFFEF08A)),
            ),
            child: Text(
              '⚠️ يجب اختيار دور واحد على الأقل للمتابعة',
              style: AppTextStyles.bodySmall
                  .copyWith(color: const Color(0xFF854D0E)),
            ),
          ),
        ],
      ],
    );
  }
}
