import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_settings.dart';
import '../../domain/entities/role_account.dart';

/// "حساباتي في التطبيق" box: the user's role accounts with switch,
/// add and delete actions.
class HomeRolesBox extends StatelessWidget {
  const HomeRolesBox({
    super.key,
    required this.accounts,
    required this.activeRole,
    required this.onSelectRole,
    required this.onAddRole,
    required this.onDeleteRole,
  });

  final List<RoleAccount> accounts;
  final UserRole activeRole;
  final ValueChanged<RoleAccount> onSelectRole;
  final ValueChanged<UserRole> onAddRole;
  final ValueChanged<RoleAccount> onDeleteRole;

  static const _roleNames = {
    UserRole.player: 'لاعب',
    UserRole.coach: 'مدرب',
    UserRole.venue: 'مالك ملعب',
  };

  static const _roleColors = {
    UserRole.player: AppColors.primary,
    UserRole.coach: Color(0xFF7C3AED),
    UserRole.venue: AppColors.secondary,
  };

  List<UserRole> get _rolesToAdd => UserRole.values
      .where((role) => !accounts.any((a) => a.type == role))
      .toList();

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final role in _rolesToAdd)
              ListTile(
                title: Text('إضافة ${_roleNames[role]}',
                    style: AppTextStyles.body),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onAddRole(role);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, RoleAccount account) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        ),
        title: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.destructive, size: 28),
            ),
            SizedBox(height: AppSizes.lg),
            Text(
              'حذف حساب ${_roleNames[account.type]}',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف هذا الحساب؟ سيتم فقدان جميع بياناتك المرتبطة به ولا يمكن التراجع عن هذا الإجراء.',
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.mutedForeground),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onDeleteRole(account);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.destructive),
            child: const Text('حذف الحساب'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('حساباتي في التطبيق',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.secondary)),
              ),
              Material(
                color: _rolesToAdd.isEmpty
                    ? const Color(0xFFE5E7EB)
                    : AppColors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap:
                      _rolesToAdd.isEmpty ? null : () => _showAddMenu(context),
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.add,
                      size: AppSizes.iconSm,
                      color: _rolesToAdd.isEmpty
                          ? const Color(0xFF9CA3AF)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              for (final account in accounts) ...[
                if (account != accounts.first)
                  const SizedBox(width: AppSizes.md),
                Expanded(child: _accountCard(context, account)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _accountCard(BuildContext context, RoleAccount account) {
    final isActive = activeRole == account.type && account.completed;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            side: BorderSide(
              color: isActive ? AppColors.primary : AppColors.border,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: () => onSelectRole(account),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: _roleColors[account.type],
                        child: const Text('أ',
                            style: TextStyle(color: Colors.white)),
                      ),
                      if (!account.completed)
                        const PositionedDirectional(
                          top: -2,
                          end: -2,
                          child: CircleAvatar(
                            radius: 8,
                            backgroundColor: Color(0xFFF97316),
                            child: Text('!',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.white)),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: AppSizes.sm),
                  Text(
                    'أحمد',
                    style: AppTextStyles.caption.copyWith(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.secondary,
                    ),
                  ),
                  Text(
                    _roleNames[account.type]!,
                    style: AppTextStyles.caption.copyWith(
                      color: isActive
                          ? AppColors.primary.withValues(alpha: 0.7)
                          : AppColors.mutedForeground,
                    ),
                  ),
                  if (!account.completed)
                    Text(
                      'إكمال التسجيل',
                      style: AppTextStyles.caption
                          .copyWith(color: const Color(0xFFF97316)),
                    )
                  else if (isActive)
                    Container(
                      margin: const EdgeInsets.only(top: AppSizes.xs),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        PositionedDirectional(
          bottom: -8,
          end: -8,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(
              side: BorderSide(color: Color(0xFFFECACA)),
            ),
            elevation: 2,
            child: InkWell(
              onTap: () => _confirmDelete(context, account),
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.delete_outline,
                    size: 12, color: AppColors.destructive),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
