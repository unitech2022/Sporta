import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/state/app_settings.dart';
import '../../../../core/widgets/sporta_logo.dart';
import '../../../auth/presentation/pages/add_role_page.dart';
import '../../../auth/presentation/state/auth_scope.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../domain/entities/role_account.dart';
import '../widgets/admin_dashboard.dart';
import '../widgets/coach_dashboard.dart';
import '../widgets/home_account_switcher.dart';
import '../widgets/player_dashboard.dart';
import '../widgets/venue_dashboard.dart';

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
  late final List<RoleAccount> _accounts;

  @override
  void initState() {
    super.initState();
    // Real roles the user registered with (each has a created profile).
    final roles = context.auth.user?.roles ?? const [UserRole.player];
    _accounts = [
      for (final r in roles) RoleAccount(type: r, completed: true),
    ];
  }

  void _selectRole(RoleAccount account) {
    if (account.completed) {
      context.appSettings.setRole(account.type);
    } else {
      context.appSettings.setRole(account.type);
      widget.onNavigate?.call('profile');
    }
  }

  Future<void> _addRole(UserRole role) async {
    // Open the account-details registration page for the chosen role; it
    // registers the role on the backend and returns true on success.
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => AddRolePage(role: role)),
    );
    if (added == true && mounted) {
      setState(() => _accounts.add(RoleAccount(type: role, completed: true)));
    }
  }

  /// حذف ناعم على الخادم: يُنهي التزامات الدور القادمة ويسترد ما يلزم، ثم
  /// يُخفيه ويُبقي بياناته. الردّ جلسة جديدة بلا صلاحية الدور المحذوف، فتُبنى
  /// قائمة الحسابات من المستخدم المحدَّث لا بالحذف من الذاكرة.
  Future<void> _deleteRole(RoleAccount account) async {
    final error = await context.auth.deleteRole(account.type);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final roles = context.auth.user?.roles ?? const [UserRole.player];
    setState(() {
      _accounts
        ..clear()
        ..addAll([for (final r in roles) RoleAccount(type: r, completed: true)]);
    });

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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SportaLogo(width: 80),
              Row(
                children: [
                  HomeAccountSwitcher(
                    userName: context.auth.user?.fullName ?? context.tr('لاعب'),
                    avatarUrl: context.auth.user?.avatarUrl,
                    accounts: _accounts,
                    activeRole: activeRole,
                    onSelectRole: _selectRole,
                    onAddRole: _addRole,
                    onDeleteRole: _deleteRole,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  const NotificationBell(),
                ],
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
      UserRole.admin => const AdminDashboard(),
      UserRole.player => PlayerDashboard(
          onNavigate: (page) => widget.onNavigate?.call(page),
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
            Text(context.tr('يجب إكمال تسجيل حسابك أولاً'),
                style: AppTextStyles.body
                    .copyWith(color: AppColors.secondary)),
            const SizedBox(height: AppSizes.lg),
            ElevatedButton(
              onPressed: () => widget.onNavigate?.call('profile'),
              child: Text(context.tr('إكمال التسجيل')),
            ),
          ],
        ),
      ),
    );
  }
}
