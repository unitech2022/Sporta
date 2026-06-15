import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gradient_page_header.dart';
import '../../../../core/widgets/app_card.dart';

enum _ProfileView { roles, playerDashboard, coachDashboard, venueDashboard }

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.onBack, this.onLogout, this.onNavigate});
  final VoidCallback? onBack;
  final VoidCallback? onLogout;
  final void Function(String page)? onNavigate;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  _ProfileView _view = _ProfileView.roles;
  bool _showDeleteWarning = false;
  String? _roleToDelete;
  final String _userName = 'أحمد السعيد';
  final Map<String, bool> _roles = {
    'player': true,
    'coach': false,
    'venue': false,
  };

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 'n1',
      'type': 'friend',
      'name': 'محمد العتيبي',
      'meta': 'مستوى 4.8',
      'time': 'منذ 5 دقائق',
      'read': false,
    },
    {
      'id': 'n2',
      'type': 'match_invite',
      'name': 'سعد القحطاني',
      'meta': 'ودية فرق · نادي البادل الملكي · اليوم 7:00 مساءً',
      'time': 'منذ 10 دقائق',
      'read': false,
    },
    {
      'id': 'n3',
      'type': 'teammate',
      'name': 'خالد المطيري',
      'meta': 'أمريكانو فردي · ملعب الأندية الشرقية · غداً 5:00 مساءً',
      'time': 'منذ 20 دقيقة',
      'read': false,
    },
    {
      'id': 'n4',
      'type': 'app',
      'name': 'تم تأكيد حجزك',
      'meta': '',
      'time': 'منذ ساعة',
      'read': true,
    },
    {
      'id': 'n5',
      'type': 'app',
      'name': 'عرض حصري!',
      'meta': 'احصل على خصم 20% على حجزك القادم',
      'time': 'منذ يومين',
      'read': true,
    },
  ];

  bool _court1Expanded = false;
  bool _court2Expanded = false;

  void _confirmDeleteRole(String role) {
    setState(() {
      _showDeleteWarning = true;
      _roleToDelete = role;
    });
  }

  void _doDeleteRole() {
    if (_roleToDelete != null) {
      setState(() {
        _roles[_roleToDelete!] = false;
        _showDeleteWarning = false;
        _roleToDelete = null;
      });
    }
  }

  void _addRole(String role) {
    setState(() {
      _roles[role] = true;
    });
  }

  void _dismissNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            _buildCurrentView(),
            if (_showDeleteWarning) _buildDeleteDialog(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_view) {
      case _ProfileView.roles:
        return _buildRolesView();
      case _ProfileView.playerDashboard:
        return _buildPlayerDashboard();
      case _ProfileView.coachDashboard:
        return _buildCoachDashboard();
      case _ProfileView.venueDashboard:
        return _buildVenueDashboard();
    }
  }

  Widget _buildDeleteDialog() {
    final roleLabel = switch (_roleToDelete) {
      'player' => 'لاعب',
      'coach' => 'مدرب',
      'venue' => 'ملعب',
      _ => 'الدور',
    };
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AppSizes.pagePadding),
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: AppSizes.iconLg,
                ),
              ),
              SizedBox(height: AppSizes.lg),
              Text(
                'حذف دور $roleLabel',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              SizedBox(height: AppSizes.sm),
              Text(
                'هل أنت متأكد من حذف دور $roleLabel؟ لن تتمكن من الوصول إلى هذا الملف الشخصي.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.mutedForeground),
              ),
              const SizedBox(height: AppSizes.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showDeleteWarning = false;
                          _roleToDelete = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.mutedForeground,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.md),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _doDeleteRole,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.md),
                      ),
                      child: const Text('حذف'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRolesView() {
    final addedRoles =
        _roles.entries.where((e) => e.value).map((e) => e.key).toList();
    final missingRoles =
        _roles.entries.where((e) => !e.value).map((e) => e.key).toList();

    return Column(
      children: [
        GradientPageHeader(
          title: 'صفحتي',
          onBack: widget.onBack,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserCard(),
                SizedBox(height: AppSizes.xl),
                if (addedRoles.isNotEmpty) ...[
                  Text(
                    'أدواري',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  ...addedRoles.map((role) => _buildRoleCard(role)),
                ],
                if (missingRoles.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.md),
                  _buildAddRoleButton(missingRoles),
                ],
                SizedBox(height: AppSizes.xl),
                _buildSettingsSection(),
                SizedBox(height: AppSizes.pagePadding),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard() {
    return AppCard(
      radius: AppSizes.radiusXl,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Center(
              child: Text(
                'أ.س',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  'عضو في سبورتا',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md, vertical: AppSizes.xs),
            ),
            child: Text(
              'تعديل',
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(String role) {
    final data = switch (role) {
      'player' => (
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          icon: Icons.sports_tennis_rounded,
          title: 'لاعب',
          stat1: '42 مباراة',
          stat2: '68% فوز',
          view: _ProfileView.playerDashboard,
        ),
      'coach' => (
          gradient: const LinearGradient(
            colors: [Color(0xFF16A34A), Color(0xFF15803D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          icon: Icons.fitness_center_rounded,
          title: 'مدرب',
          stat1: '87 طالب',
          stat2: '200 ر.س/جلسة',
          view: _ProfileView.coachDashboard,
        ),
      _ => (
          gradient: const LinearGradient(
            colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          icon: Icons.stadium_rounded,
          title: 'ملعب',
          stat1: '2 ملاعب',
          stat2: '5 حجوزات اليوم',
          view: _ProfileView.venueDashboard,
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: AppCard(
        radius: AppSizes.radiusXl,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: data.gradient,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Icon(data.icon, color: Colors.white, size: AppSizes.iconMd),
            ),
            SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  SizedBox(height: AppSizes.xs),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          data.stat1,
                          style: AppTextStyles.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: AppSizes.sm),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: AppColors.mutedForeground,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: AppSizes.sm),
                      Flexible(
                        child: Text(
                          data.stat2,
                          style: AppTextStyles.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () => setState(() => _view = data.view),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm, vertical: AppSizes.xs),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'عرض الملف',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: AppSizes.xs),
                GestureDetector(
                  onTap: () => _confirmDeleteRole(role),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFDC2626),
                      size: AppSizes.iconSm,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRoleButton(List<String> missingRoles) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: AppColors.card,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusXl),
            ),
          ),
          builder: (context) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إضافة دور جديد',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    ...missingRoles.map((role) {
                      final label = switch (role) {
                        'player' => 'لاعب',
                        'coach' => 'مدرب',
                        _ => 'ملعب',
                      };
                      final icon = switch (role) {
                        'player' => Icons.sports_tennis_rounded,
                        'coach' => Icons.fitness_center_rounded,
                        _ => Icons.stadium_rounded,
                      };
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 0),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLg),
                            border: const Border.fromBorderSide(
                                BorderSide(color: AppColors.border)),
                          ),
                          child: Icon(icon,
                              color: AppColors.primary, size: AppSizes.iconMd),
                        ),
                        title: Text(label, style: AppTextStyles.body),
                        trailing: const Icon(Icons.add_circle_outline_rounded,
                            color: AppColors.primary),
                        onTap: () {
                          Navigator.pop(context);
                          _addRole(role);
                        },
                      );
                    }),
                    const SizedBox(height: AppSizes.sm),
                  ],
                ),
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded,
                color: AppColors.primary, size: AppSizes.iconMd),
            SizedBox(width: AppSizes.sm),
            Text(
              'إضافة دور جديد',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    final items = [
      (
        icon: Icons.language_rounded,
        color: const Color(0xFF2563EB),
        label: 'اللغة',
        page: 'language',
        isLogout: false,
      ),
      (
        icon: Icons.settings_outlined,
        color: const Color(0xFFEA580C),
        label: 'إعدادات الحساب',
        page: 'account-settings',
        isLogout: false,
      ),
      (
        icon: Icons.message_outlined,
        color: const Color(0xFF16A34A),
        label: 'اتصل بنا',
        page: 'contact',
        isLogout: false,
      ),
      (
        icon: Icons.star_outline_rounded,
        color: AppColors.primary,
        label: 'نظام النقاط',
        page: 'points-system',
        isLogout: false,
      ),
      (
        icon: Icons.description_outlined,
        color: const Color(0xFF9CA3AF),
        label: 'الشروط والأحكام',
        page: 'terms',
        isLogout: false,
      ),
      (
        icon: Icons.shield_outlined,
        color: const Color(0xFF9CA3AF),
        label: 'سياسة الخصوصية',
        page: 'privacy',
        isLogout: false,
      ),
      (
        icon: Icons.attach_money_rounded,
        color: const Color(0xFF9CA3AF),
        label: 'سياسة الاسترجاع',
        page: 'refund',
        isLogout: false,
      ),
      (
        icon: Icons.logout_rounded,
        color: const Color(0xFFDC2626),
        label: 'تسجيل الخروج',
        page: '',
        isLogout: true,
      ),
    ];

    return AppCard(
      padding: EdgeInsets.zero,
      radius: AppSizes.radiusXl,
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.xs,
                ),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  child: Icon(item.icon, color: item.color, size: AppSizes.iconSm),
                ),
                title: Text(
                  item.label,
                  style: AppTextStyles.body.copyWith(
                    color: item.isLogout
                        ? const Color(0xFFDC2626)
                        : AppColors.secondary,
                  ),
                ),
                trailing: item.isLogout
                    ? null
                    : const Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.mutedForeground,
                      ),
                onTap: () async {
                  if (item.isLogout) {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('تسجيل الخروج'),
                        content:
                            const Text('هل أنت متأكد من تسجيل الخروج؟'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('إلغاء'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.destructive,
                            ),
                            child: const Text('تسجيل الخروج'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) widget.onLogout?.call();
                  } else {
                    widget.onNavigate?.call(item.page);
                  }
                },
              ),
              if (i < items.length - 1)
                const Divider(
                  height: 1,
                  indent: AppSizes.lg,
                  endIndent: AppSizes.lg,
                  color: AppColors.border,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPlayerDashboard() {
    return Column(
      children: [
        GradientPageHeader(
          title: 'صفحتي',
          subtitle: 'اللاعب أحمد',
          onBack: () => setState(() => _view = _ProfileView.roles),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPlayerProfileCard(),
                const SizedBox(height: AppSizes.lg),
                _buildPlayerStatsCard(),
                const SizedBox(height: AppSizes.lg),
                _buildPlayerRivalriesSection(),
                const SizedBox(height: AppSizes.lg),
                _buildPlayerBookingsCard(),
                const SizedBox(height: AppSizes.lg),
                _buildWalletCard(),
                SizedBox(height: AppSizes.lg),
                _buildNotificationsSection(),
                SizedBox(height: AppSizes.pagePadding),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerProfileCard() {
    return AppCard(
      radius: AppSizes.radiusXl,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Center(
                  child: Text(
                    'أ',
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                            border: const Border.fromBorderSide(
                                BorderSide(color: Color(0xFFD97706))),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 12, color: Color(0xFFD97706)),
                              SizedBox(width: 2),
                              Text(
                                '4.5',
                                style: AppTextStyles.caption.copyWith(
                                  color: const Color(0xFFD97706),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: AppSizes.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: Text(
                            'متقدم',
                            style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFF2563EB),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'ELO',
                    style: AppTextStyles.caption,
                  ),
                  Text(
                    '1845',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: AppSizes.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تقدم الموسم',
                    style: AppTextStyles.caption,
                  ),
                  Text(
                    '65%',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                child: LinearProgressIndicator(
                  value: 0.65,
                  backgroundColor: AppColors.background,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStatsCard() {
    return AppCard(
      radius: AppSizes.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إحصائياتي',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          _StatRow(label: 'المباريات', value: '42'),
          _StatRow(
            label: 'نسبة الفوز',
            value: '68%',
            valueColor: const Color(0xFF16A34A),
          ),
          _StatRow(
            label: 'ترتيبك في التطبيق',
            value: '#123',
            valueColor: AppColors.primary,
          ),
          _StatRow(
            label: 'ترتيبك مدينة الرياض',
            value: '#18',
            valueColor: AppColors.primary,
          ),
          _StatRow(label: 'ساعات اللعب', value: '87', isLast: true),
        ],
      ),
    );
  }

  Widget _buildPlayerRivalriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'منافساتي',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        _RivalryCard(
          bg: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFDC2626),
          icon: Icons.trending_down_rounded,
          iconColor: const Color(0xFFDC2626),
          label: 'أكثر لاعب فاز عليك',
          name: 'خالد المطيري',
          stat: '8 مرات',
          statColor: const Color(0xFFDC2626),
        ),
        const SizedBox(height: AppSizes.sm),
        _RivalryCard(
          bg: const Color(0xFFF0FDF4),
          borderColor: const Color(0xFF22C55E),
          icon: Icons.trending_up_rounded,
          iconColor: const Color(0xFF16A34A),
          label: 'أكثر لاعب فزت عليه',
          name: 'فهد العتيبي',
          stat: '11 مرات',
          statColor: const Color(0xFF16A34A),
        ),
        const SizedBox(height: AppSizes.sm),
        _RivalryCard(
          bg: const Color(0xFFEFF6FF),
          borderColor: const Color(0xFF2563EB),
          icon: Icons.group_rounded,
          iconColor: const Color(0xFF2563EB),
          label: 'أكثر لاعب لعبت معه',
          name: 'سعود القحطاني',
          stat: '15 مباراة',
          statColor: const Color(0xFF2563EB),
        ),
        const SizedBox(height: AppSizes.sm),
        _RivalryCard(
          bg: const Color(0xFFFFF7ED),
          borderColor: const Color(0xFFEA580C),
          icon: Icons.swap_horiz_rounded,
          iconColor: const Color(0xFFEA580C),
          label: 'أكثر لاعب لعبت ضده',
          name: 'محمد الشمري',
          stat: '12 مباراة',
          statColor: const Color(0xFFEA580C),
        ),
      ],
    );
  }

  Widget _buildPlayerBookingsCard() {
    final bookings = [
      (
        club: 'نادي البادل الملكي',
        court: 'ملعب 3',
        day: 'الخميس 6 يونيو',
        time: '05:00 مساءً',
        duration: '60 دقيقة',
        price: '100 ر.س',
        status: 'مؤكدة',
        statusColor: const Color(0xFF16A34A),
        statusBg: const Color(0xFFF0FDF4),
      ),
      (
        club: 'بادل كلوب الشرقية',
        court: 'ملعب 1',
        day: 'الجمعة 7 يونيو',
        time: '07:00 مساءً',
        duration: '90 دقيقة',
        price: '120 ر.س',
        status: 'مؤكدة',
        statusColor: const Color(0xFF16A34A),
        statusBg: const Color(0xFFF0FDF4),
      ),
      (
        club: 'مركز بادل المدينة',
        court: 'ملعب 2',
        day: 'السبت 8 يونيو',
        time: '04:00 مساءً',
        duration: '120 دقيقة',
        price: '150 ر.س',
        status: 'في الانتظار',
        statusColor: const Color(0xFFD97706),
        statusBg: const Color(0xFFFFFBEB),
      ),
    ];

    return AppCard(
      radius: AppSizes.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'حجوزاتي الحالية',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              SizedBox(width: AppSizes.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  '${bookings.length}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          ...List.generate(bookings.length, (i) {
            final b = bookings[i];
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            b.club,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: b.statusBg,
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusFull),
                            ),
                            child: Text(
                              b.status,
                              style: AppTextStyles.caption.copyWith(
                                color: b.statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Wrap(
                        spacing: AppSizes.md,
                        runSpacing: AppSizes.xs,
                        children: [
                          _BookingChip(
                              icon: Icons.sports_tennis_rounded,
                              label: b.court),
                          _BookingChip(
                              icon: Icons.calendar_today_outlined,
                              label: b.day),
                          _BookingChip(
                              icon: Icons.access_time_rounded, label: b.time),
                          _BookingChip(
                              icon: Icons.timer_outlined, label: b.duration),
                          _BookingChip(
                              icon: Icons.attach_money_rounded, label: b.price),
                        ],
                      ),
                    ],
                  ),
                ),
                if (i < bookings.length - 1)
                  const SizedBox(height: AppSizes.sm),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    return AppCard(
      radius: AppSizes.radiusXl,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: Colors.white, size: AppSizes.iconMd),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'محفظتي',
                  style: AppTextStyles.caption,
                ),
                Text(
                  '150 ر.س',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => widget.onNavigate?.call('top-up-wallet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md, vertical: AppSizes.sm),
            ),
            child: const Text('شحن الرصيد'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.notifications_outlined,
                color: AppColors.secondary, size: AppSizes.iconMd),
            SizedBox(width: AppSizes.sm),
            Text(
              'الإشعارات',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            SizedBox(width: AppSizes.sm),
            if (_notifications.any((n) => !(n['read'] as bool)))
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  '${_notifications.where((n) => !(n['read'] as bool)).length}',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: AppSizes.md),
        if (_notifications.isEmpty)
          AppCard(
            radius: AppSizes.radiusXl,
            child: Center(
              child: Text(
                'لا توجد إشعارات',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.mutedForeground),
              ),
            ),
          )
        else
          ...List.generate(_notifications.length, (i) {
            final n = _notifications[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: _buildNotificationCard(n),
            );
          }),
      ],
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> n) {
    final isUnread = !(n['read'] as bool);
    final type = n['type'] as String;

    IconData icon;
    Color iconColor;
    Color iconBg;

    switch (type) {
      case 'friend':
        icon = Icons.person_add_outlined;
        iconColor = const Color(0xFF2563EB);
        iconBg = const Color(0xFFEFF6FF);
      case 'match_invite':
        icon = Icons.sports_tennis_rounded;
        iconColor = const Color(0xFF16A34A);
        iconBg = const Color(0xFFF0FDF4);
      case 'teammate':
        icon = Icons.group_add_outlined;
        iconColor = const Color(0xFFEA580C);
        iconBg = const Color(0xFFFFF7ED);
      default:
        icon = Icons.notifications_outlined;
        iconColor = AppColors.primary;
        iconBg = AppColors.primary.withValues(alpha: 0.1);
    }

    return AppCard(
      radius: AppSizes.radiusXl,
      color:
          isUnread ? AppColors.primary.withValues(alpha: 0.04) : AppColors.card,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Icon(icon, color: iconColor, size: AppSizes.iconMd),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n['name'] as String,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: type == 'app' && n['name'] == 'تم تأكيد حجزك'
                              ? const Color(0xFF2563EB)
                              : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if ((n['meta'] as String).isNotEmpty) ...[
                  SizedBox(height: 2),
                  Text(
                    n['meta'] as String,
                    style: AppTextStyles.caption,
                  ),
                ],
                SizedBox(height: AppSizes.xs),
                Text(
                  n['time'] as String,
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.mutedForeground),
                ),
                if (type == 'friend') ...[
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _dismissNotification(n['id'] as String),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusLg),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.xs),
                            minimumSize: const Size(0, 32),
                          ),
                          child: const Text('قبول',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _dismissNotification(n['id'] as String),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side:
                                const BorderSide(color: Color(0xFFDC2626)),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusLg),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.xs),
                            minimumSize: const Size(0, 32),
                          ),
                          child: const Text('رفض',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
                if (type == 'match_invite') ...[
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _dismissNotification(n['id'] as String),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusLg),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.xs),
                            minimumSize: const Size(0, 32),
                          ),
                          child: const Text('انضمام',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _dismissNotification(n['id'] as String),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side:
                                const BorderSide(color: Color(0xFFDC2626)),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusLg),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.xs),
                            minimumSize: const Size(0, 32),
                          ),
                          child: const Text('رفض',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
                if (type == 'teammate') ...[
                  const SizedBox(height: AppSizes.sm),
                  GestureDetector(
                    onTap: () => _dismissNotification(n['id'] as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md, vertical: AppSizes.xs),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLg),
                        border: const Border.fromBorderSide(
                            BorderSide(color: Color(0xFFEA580C))),
                      ),
                      child: Text(
                        'عرض التفاصيل',
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFFEA580C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _dismissNotification(n['id'] as String),
            child: const Padding(
              padding: EdgeInsets.only(right: AppSizes.xs),
              child: Icon(Icons.close_rounded,
                  size: AppSizes.iconSm, color: AppColors.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachDashboard() {
    return Column(
      children: [
        GradientPageHeader(
          title: 'لوحة المدرب',
          onBack: () => setState(() => _view = _ProfileView.roles),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCoachProfileCard(),
                const SizedBox(height: AppSizes.lg),
                _buildCoachStatsRow(),
                const SizedBox(height: AppSizes.lg),
                _buildCoachRevenueCard(),
                const SizedBox(height: AppSizes.lg),
                _buildCoachTraineesSection(),
                SizedBox(height: AppSizes.pagePadding),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoachProfileCard() {
    return AppCard(
      radius: AppSizes.radiusXl,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Center(
              child: Text(
                'م.أ',
                style: AppTextStyles.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'محمد أحمد',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                SizedBox(height: AppSizes.xs),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: Color(0xFFD97706)),
                    SizedBox(width: 2),
                    Text(
                      '4.9',
                      style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                        border: const Border.fromBorderSide(
                            BorderSide(color: Color(0xFF22C55E))),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded,
                              size: 12, color: Color(0xFF16A34A)),
                          SizedBox(width: 2),
                          Text(
                            'معتمد',
                            style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFF16A34A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('طالب مسجل', style: AppTextStyles.caption),
              Text(
                '87',
                style: AppTextStyles.heading2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoachStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            value: '87',
            label: 'إجمالي الطلاب',
            color: const Color(0xFF2563EB),
            bg: const Color(0xFFEFF6FF),
          ),
        ),
        SizedBox(width: AppSizes.sm),
        Expanded(
          child: _StatChip(
            value: '24',
            label: 'الجلسات هذا الشهر',
            color: const Color(0xFF16A34A),
            bg: const Color(0xFFF0FDF4),
          ),
        ),
        SizedBox(width: AppSizes.sm),
        Expanded(
          child: _StatChip(
            value: '4.9',
            label: 'معدل التقييم',
            color: const Color(0xFFD97706),
            bg: const Color(0xFFFFFBEB),
          ),
        ),
      ],
    );
  }

  Widget _buildCoachRevenueCard() {
    return AppCard(
      radius: AppSizes.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإيرادات',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          SizedBox(height: AppSizes.md),
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('هذا الشهر', style: AppTextStyles.caption),
                    Text(
                      '4,800 ر.س',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                    Text(
                      '4 جلسات × 200 ر.س متوسط',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('الإجمالي', style: AppTextStyles.caption),
                    Text(
                      '28,400 ر.س',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachTraineesSection() {
    final trainees = [
      (
        name: 'محمد السالم',
        level: 'مستوى 4.2',
        sessions: '12 جلسة',
        status: 'نشط',
        statusColor: const Color(0xFF16A34A),
        statusBg: const Color(0xFFF0FDF4),
      ),
      (
        name: 'فهد القحطاني',
        level: 'مستوى 3.8',
        sessions: '8 جلسات',
        status: 'نشط',
        statusColor: const Color(0xFF16A34A),
        statusBg: const Color(0xFFF0FDF4),
      ),
      (
        name: 'سعد المطيري',
        level: 'مستوى 5.1',
        sessions: '20 جلسة',
        status: 'موقوف مؤقتاً',
        statusColor: const Color(0xFFEA580C),
        statusBg: const Color(0xFFFFF7ED),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المتدربون',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        AppCard(
          padding: EdgeInsets.zero,
          radius: AppSizes.radiusXl,
          child: Column(
            children: List.generate(trainees.length, (i) {
              final t = trainees[i];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: Center(
                            child: Text(
                              t.name.substring(0, 1),
                              style: AppTextStyles.body.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.name,
                                style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary),
                              ),
                              SizedBox(height: AppSizes.xs),
                              Text(
                                '${t.level} · ${t.sessions}',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.sm, vertical: 3),
                          decoration: BoxDecoration(
                            color: t.statusBg,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: Text(
                            t.status,
                            style: AppTextStyles.caption.copyWith(
                                color: t.statusColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < trainees.length - 1)
                    const Divider(
                        height: 1,
                        indent: AppSizes.lg,
                        endIndent: AppSizes.lg,
                        color: AppColors.border),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildVenueDashboard() {
    return Column(
      children: [
        GradientPageHeader(
          title: 'لوحة المنشأة',
          onBack: () => setState(() => _view = _ProfileView.roles),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVenueProfileCard(),
                const SizedBox(height: AppSizes.lg),
                _buildVenueStatsRow(),
                const SizedBox(height: AppSizes.lg),
                _buildCourtsSection(),
                const SizedBox(height: AppSizes.pagePadding),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVenueProfileCard() {
    return AppCard(
      radius: AppSizes.radiusXl,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: const Icon(Icons.stadium_rounded,
                color: Colors.white, size: AppSizes.iconMd),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نادي البادل الملكي',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                SizedBox(height: AppSizes.xs),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.mutedForeground),
                    SizedBox(width: 2),
                    Text('الدمام', style: AppTextStyles.caption),
                    SizedBox(width: AppSizes.sm),
                    const Icon(Icons.star_rounded,
                        size: 14, color: Color(0xFFD97706)),
                    SizedBox(width: 2),
                    Text(
                      '4.8',
                      style: AppTextStyles.caption
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            value: '2',
            label: 'الملاعب النشطة',
            color: const Color(0xFF2563EB),
            bg: const Color(0xFFEFF6FF),
          ),
        ),
        SizedBox(width: AppSizes.sm),
        Expanded(
          child: _StatChip(
            value: '5',
            label: 'الحجوزات اليوم',
            color: const Color(0xFF16A34A),
            bg: const Color(0xFFF0FDF4),
          ),
        ),
        SizedBox(width: AppSizes.sm),
        Expanded(
          child: _StatChip(
            value: '12,400',
            label: 'الإيراد الشهري ر.س',
            color: const Color(0xFFEA580C),
            bg: const Color(0xFFFFF7ED),
          ),
        ),
      ],
    );
  }

  Widget _buildCourtsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الملاعب',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        _buildCourtItem(
          index: 0,
          name: 'ملعب 1',
          type: 'داخلي',
          daysPerWeek: '6 أيام',
          isExpanded: _court1Expanded,
          onTap: () => setState(() => _court1Expanded = !_court1Expanded),
          slots: const [
            ('صباحي', '06:00 - 12:00', '100 ر.س'),
            ('ظهري', '12:00 - 17:00', '120 ر.س'),
            ('مسائي', '17:00 - 23:00', '150 ر.س'),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        _buildCourtItem(
          index: 1,
          name: 'ملعب 2',
          type: 'خارجي',
          daysPerWeek: '7 أيام',
          isExpanded: _court2Expanded,
          onTap: () => setState(() => _court2Expanded = !_court2Expanded),
          slots: const [
            ('صباحي', '07:00 - 12:00', '80 ر.س'),
            ('مسائي', '16:00 - 23:00', '130 ر.س'),
          ],
        ),
      ],
    );
  }

  Widget _buildCourtItem({
    required int index,
    required String name,
    required String type,
    required String daysPerWeek,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<(String, String, String)> slots,
  }) {
    return AppCard(
      padding: EdgeInsets.zero,
      radius: AppSizes.radiusXl,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: isExpanded
                ? const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl))
                : BorderRadius.circular(AppSizes.radiusXl),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
                    child: const Icon(Icons.sports_tennis_rounded,
                        color: Color(0xFFEA580C), size: AppSizes.iconMd),
                  ),
                  SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary),
                        ),
                        SizedBox(height: AppSizes.xs),
                        Row(
                          children: [
                            _CourtBadge(label: type),
                            SizedBox(width: AppSizes.xs),
                            _CourtBadge(label: 'نشط', isActive: true),
                            SizedBox(width: AppSizes.xs),
                            Text(daysPerWeek, style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الأوقات والأسعار',
                    style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold, color: AppColors.secondary),
                  ),
                  SizedBox(height: AppSizes.sm),
                  ...slots.map((slot) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSizes.xs),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEA580C),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: AppSizes.sm),
                            Text('${slot.$1}:', style: AppTextStyles.caption),
                            SizedBox(width: AppSizes.xs),
                            Text(slot.$2,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.secondary)),
                            const Spacer(),
                            Text(
                              slot.$3,
                              style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF16A34A)),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.bodySmall),
              Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

class _RivalryCard extends StatelessWidget {
  const _RivalryCard({
    required this.bg,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.name,
    required this.stat,
    required this.statColor,
  });

  final Color bg;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String name;
  final String stat;
  final Color statColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: borderColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: borderColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Icon(icon, color: iconColor, size: AppSizes.iconSm),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption,
                ),
                SizedBox(height: 2),
                Text(
                  name,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            stat,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: statColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
  });

  final String value;
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm, vertical: AppSizes.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BookingChip extends StatelessWidget {
  const _BookingChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.mutedForeground),
        SizedBox(width: 3),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

class _CourtBadge extends StatelessWidget {
  const _CourtBadge({required this.label, this.isActive = false});
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xs, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF0FDF4) : AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(
            color: isActive ? const Color(0xFF22C55E) : AppColors.border),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: isActive ? const Color(0xFF16A34A) : AppColors.mutedForeground,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
