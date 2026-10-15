import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_settings.dart';
import '../../domain/entities/role_account.dart';
import '../../../../core/widgets/network_circle_avatar.dart';

Map<UserRole, String> _roleNames(BuildContext context) => {
  UserRole.player: context.tr('player'),
  UserRole.coach: context.tr('coach'),
  UserRole.venue: context.tr('venueOwner'),
};

const _roleColors = {
  UserRole.player: AppColors.primary,
  UserRole.coach: Color(0xFF7C3AED),
  UserRole.venue: AppColors.secondary,
};

const _roleIcons = {
  UserRole.player: Icons.sports_tennis,
  UserRole.coach: Icons.sports,
  UserRole.venue: Icons.stadium_outlined,
};

/// Compact header control that shows the active account and opens the accounts
/// bottom sheet on tap (replaces the old large "حساباتي" box).
class HomeAccountSwitcher extends StatelessWidget {
  const HomeAccountSwitcher({
    super.key,
    required this.userName,
    this.avatarUrl,
    required this.accounts,
    required this.activeRole,
    required this.onSelectRole,
    required this.onAddRole,
    required this.onDeleteRole,
  });

  final String userName;

  /// الصورة الشخصية للمستخدم الحالي، null إن لم يرفع صورة.
  final String? avatarUrl;
  final List<RoleAccount> accounts;
  final UserRole activeRole;
  final ValueChanged<RoleAccount> onSelectRole;
  final ValueChanged<UserRole> onAddRole;
  final ValueChanged<RoleAccount> onDeleteRole;

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AccountsSheet(
        userName: userName,
        accounts: accounts,
        activeRole: activeRole,
        onSelectRole: onSelectRole,
        onAddRole: onAddRole,
        onDeleteRole: onDeleteRole,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _roleColors[activeRole]!;
    return Material(
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: InkWell(
        onTap: () => _openSheet(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(6, 6, AppSizes.md, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              NetworkCircleAvatar(
                imageUrl: avatarUrl,
                radius: 16,
                backgroundColor: color,
                child: Text(
                        userName.isNotEmpty ? userName.characters.first : 'أ',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(width: AppSizes.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_roleNames(context)[activeRole]!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.secondary, height: 1)),
                  Text(context.tr('تبديل الحساب'),
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedForeground,
                          fontSize: 10,
                          height: 1.2)),
                ],
              ),
              const SizedBox(width: AppSizes.xs),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: AppSizes.iconSm, color: AppColors.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountsSheet extends StatelessWidget {
  const _AccountsSheet({
    required this.userName,
    required this.accounts,
    required this.activeRole,
    required this.onSelectRole,
    required this.onAddRole,
    required this.onDeleteRole,
  });

  final String userName;
  final List<RoleAccount> accounts;
  final UserRole activeRole;
  final ValueChanged<RoleAccount> onSelectRole;
  final ValueChanged<UserRole> onAddRole;
  final ValueChanged<RoleAccount> onDeleteRole;

  List<UserRole> get _rolesToAdd => UserRole.values
      // Admin is not a self-service account type (no color/icon mapping).
      .where((role) => role != UserRole.admin)
      .where((role) => !accounts.any((a) => a.type == role))
      .toList();

  void _confirmDelete(BuildContext context, RoleAccount account) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: Directionality.of(context),
        child: AlertDialog(
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
              const SizedBox(height: AppSizes.lg),
              Text(context.tr('حذف حساب %s').replaceAll('%s', _roleNames(context)[account.type] ?? ''),
                  style: AppTextStyles.heading3, textAlign: TextAlign.center),
            ],
          ),
          content: Text(context.tr('هل أنت متأكد من حذف هذا الحساب؟ سيتم فقدان جميع بياناتك المرتبطة به ولا يمكن التراجع عن هذا الإجراء.'),
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.mutedForeground),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('إلغاء')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context); // close the sheet too
                onDeleteRole(account);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.destructive),
              child: Text(context.tr('حذف الحساب')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.pagePadding,
                AppSizes.md, AppSizes.pagePadding, AppSizes.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                Text(context.tr('حساباتي في التطبيق'),
                    style: AppTextStyles.heading3
                        .copyWith(color: AppColors.secondary)),
                Text(context.tr('بدّل بين حساباتك أو أضِف حسابًا جديدًا'),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedForeground)),
                const SizedBox(height: AppSizes.lg),
                for (final account in accounts) ...[
                  _accountTile(context, account),
                  const SizedBox(height: AppSizes.sm),
                ],
                if (_rolesToAdd.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.sm),
                  Text(context.tr('إضافة حساب جديد'),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.secondary)),
                  const SizedBox(height: AppSizes.sm),
                  for (final role in _rolesToAdd) ...[
                    _addTile(context, role),
                    const SizedBox(height: AppSizes.sm),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _accountTile(BuildContext context, RoleAccount account) {
    final color = _roleColors[account.type]!;
    final active = account.type == activeRole;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onSelectRole(account);
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: active ? color : AppColors.border,
              width: active ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(_roleIcons[account.type], color: color),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: AppTextStyles.body.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600)),
                    Text(_roleNames(context)[account.type]!,
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
              if (active)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: color),
                      const SizedBox(width: 2),
                      Text(context.tr('نشط'),
                          style: AppTextStyles.caption.copyWith(color: color)),
                    ],
                  ),
                )
              else if (accounts.length > 1)
                IconButton(
                  onPressed: () => _confirmDelete(context, account),
                  icon: const Icon(Icons.delete_outline,
                      size: AppSizes.iconSm, color: AppColors.destructive),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addTile(BuildContext context, UserRole role) {
    final color = _roleColors[role]!;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onAddRole(role);
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(_roleIcons[role], color: color, size: 18),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Text(context.tr('إضافة حساب %s').replaceAll('%s', _roleNames(context)[role] ?? ''),
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.secondary)),
              ),
              const Icon(Icons.add_circle_outline,
                  size: AppSizes.iconMd, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
