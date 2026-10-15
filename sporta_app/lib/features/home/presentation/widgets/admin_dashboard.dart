import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../admin/presentation/pages/withdrawal_requests_page.dart';
import '../../../auth/presentation/state/auth_scope.dart';
import 'dashboard_blocks.dart';
import '../../../../core/localization/tr_global.dart';

const _navy = Color(0xFF0A2540);
const _navy2 = Color(0xFF12345B);

/// Platform-admin home dashboard. Assessment levels/questions are managed from
/// the web control panel (sporta-dashboard), not here.
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final userName = context.auth.user?.fullName ?? context.tr('الإدارة');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardHeader(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [_navy, _navy2],
          ),
          userName: '',
          roleLabel: trg('مشرف المنصة'),
          stats: [],
        ),
        Padding(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${context.tr('مرحبًا')} $userName',
                  style: AppTextStyles.heading2
                      .copyWith(color: AppColors.secondary)),
              const SizedBox(height: AppSizes.xs),
              Text(context.tr('أدوات إدارة المنصة'),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.mutedForeground)),
              const SizedBox(height: AppSizes.xxl),
              _navCard(
                context,
                icon: Icons.account_balance_wallet_outlined,
                label: context.tr('طلبات السحب'),
                subtitle: context.tr('راجع وأقر طلبات سحب رصيد المستخدمين'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const WithdrawalRequestsPage())),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _navCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppTextStyles.body.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              DirectionalIcon(rtl: Icons.chevron_left, ltr: Icons.chevron_right,
                  color: AppColors.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}
