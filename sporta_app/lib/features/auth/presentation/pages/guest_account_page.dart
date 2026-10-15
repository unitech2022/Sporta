import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../../core/widgets/gradient_page_header.dart';
import '../state/auth_scope.dart';
import '../../../../core/utils/system_insets.dart';

/// تبويب «حسابي» في وضع الزائر: دعوة لتسجيل الدخول أو إنشاء حساب، مع الروابط
/// التي لا تحتاج حساباً (اللغة، السياسات، اتصل بنا).
class GuestAccountPage extends StatelessWidget {
  const GuestAccountPage({super.key, required this.onNavigate});

  /// نفس معرّفات الصفحات المستخدمة في [MainShell]: 'language' و'terms'
  /// و'privacy' و'refund' و'contact'.
  final void Function(String page) onNavigate;

  void _goToAuth(BuildContext context) {
    context.auth.exitGuest();
    context.appSettings.restartApp();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          GradientPageHeader(title: context.tr('حسابي')),
          Expanded(
            child: ListView(
              padding: context
                  .safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
              children: [
                _joinCard(context),
                const SizedBox(height: AppSizes.lg),
                _linksCard(context),
                const SizedBox(height: AppSizes.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _joinCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      child: Column(
        children: [
          const Icon(Icons.sports_tennis, color: Colors.white, size: 40),
          const SizedBox(height: AppSizes.md),
          Text(
            context.tr('أنت تتصفّح كزائر'),
            style: AppTextStyles.heading3.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            context.tr(
                'أنشئ حساباً لتحجز الملاعب، تحجز مع المدربين، وتنضم إلى المباريات.'),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight,
            child: ElevatedButton(
              onPressed: () => _goToAuth(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.secondary,
              ),
              child: Text(context.tr('createNewAccount')),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight,
            child: OutlinedButton(
              onPressed: () => _goToAuth(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
              ),
              child: Text(context.tr('login')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linksCard(BuildContext context) {
    final items = <({IconData icon, Color color, String label, String page})>[
      (
        icon: Icons.language_rounded,
        color: const Color(0xFF2563EB),
        label: context.tr('اللغة'),
        page: 'language',
      ),
      (
        icon: Icons.message_outlined,
        color: const Color(0xFF16A34A),
        label: context.tr('اتصل بنا'),
        page: 'contact',
      ),
      (
        icon: Icons.description_outlined,
        color: const Color(0xFF9CA3AF),
        label: context.tr('الشروط والأحكام'),
        page: 'terms',
      ),
      (
        icon: Icons.shield_outlined,
        color: const Color(0xFF9CA3AF),
        label: context.tr('سياسة الخصوصية'),
        page: 'privacy',
      ),
      (
        icon: Icons.attach_money_rounded,
        color: const Color(0xFF9CA3AF),
        label: context.tr('سياسة الاسترجاع'),
        page: 'refund',
      ),
    ];

    // Material (لا Container ملوَّن) كي تظهر تموّجات ListTile ولا يطلق Flutter
    // تحذير «ink splashes may be invisible».
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg, vertical: AppSizes.xs),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: items[i].color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Icon(items[i].icon,
                    color: items[i].color, size: AppSizes.iconSm),
              ),
              title: Text(items[i].label,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.secondary)),
              trailing: const DirectionalIcon(
                rtl: Icons.chevron_left_rounded,
                ltr: Icons.chevron_right_rounded,
                color: AppColors.mutedForeground,
              ),
              onTap: () => onNavigate(items[i].page),
            ),
            if (i < items.length - 1)
              const Divider(
                  height: 1, indent: AppSizes.lg, endIndent: AppSizes.lg),
          ],
        ],
      ),
    );
  }
}
