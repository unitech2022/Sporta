import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/state/app_settings.dart';
import '../../../../core/widgets/sporta_logo.dart';
import '../../domain/entities/role_account.dart';
import '../widgets/coach_dashboard.dart';
import '../widgets/home_roles_box.dart';
import '../widgets/player_dashboard.dart';
import '../widgets/venue_dashboard.dart';
import 'points_system_page.dart';

/// Home hub (converted from HomePage.tsx): white header with the roles
/// box, then the dashboard of the active role.
class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onNavigate});

  /// Receives page ids: 'matches', 'courts', 'coaches', 'profile',
  /// 'americano'.
  final void Function(String page)? onNavigate;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<RoleAccount> _accounts = [
    RoleAccount(type: UserRole.player, completed: true),
  ];

  void _openPoints() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: SafeArea(
            child: PointsSystemPage(
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }

  void _selectRole(RoleAccount account) {
    if (account.completed) {
      context.appSettings.setRole(account.type);
    } else {
      context.appSettings.setRole(account.type);
      widget.onNavigate?.call('profile');
    }
  }

  void _addRole(UserRole role) {
    setState(() => _accounts.add(RoleAccount(type: role)));
    context.appSettings.setRole(role);
    widget.onNavigate?.call('profile');
  }

  void _deleteRole(RoleAccount account) {
    setState(() => _accounts.remove(account));
    if (context.appSettings.role == account.type && _accounts.isNotEmpty) {
      context.appSettings.setRole(_accounts.first.type);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeRole = context.appSettings.role;
    final activeAccount = _accounts
        .where((account) => account.type == activeRole)
        .firstOrNull;

    return Column(
      children: [
        _header(activeRole),
        Expanded(
          child: activeAccount != null && activeAccount.completed
              ? SingleChildScrollView(child: _dashboard(activeRole))
              : _incompleteRoleView(),
        ),
      ],
    );
  }

  Widget _header(UserRole activeRole) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.lg,
            AppSizes.pagePadding,
            AppSizes.lg,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SportaLogo(width: 80),
                  Material(
                    color: const Color(0xFFF3F4F6),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () {},
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(AppSizes.sm),
                        child: Icon(Icons.notifications_outlined,
                            size: AppSizes.iconMd,
                            color: AppColors.secondary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.xl),
              HomeRolesBox(
                accounts: _accounts,
                activeRole: activeRole,
                onSelectRole: _selectRole,
                onAddRole: _addRole,
                onDeleteRole: _deleteRole,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboard(UserRole role) {
    return switch (role) {
      UserRole.coach => const CoachDashboard(),
      UserRole.venue => const VenueDashboard(),
      UserRole.player => PlayerDashboard(
          onOpenPoints: _openPoints,
          onOpenCourts: () => widget.onNavigate?.call('courts'),
        ),
    };
  }

  Widget _incompleteRoleView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEDD5),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text('!',
                  style:
                      TextStyle(fontSize: 24, color: Color(0xFFF97316))),
            ),
            SizedBox(height: AppSizes.lg),
            Text('يجب إكمال تسجيل حسابك أولاً',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.secondary)),
            const SizedBox(height: AppSizes.lg),
            ElevatedButton(
              onPressed: () => widget.onNavigate?.call('profile'),
              child: const Text('إكمال التسجيل'),
            ),
          ],
        ),
      ),
    );
  }
}
