import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/phone_input.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  bool _showPhoneModal = false;
  bool _showEmailModal = false;
  bool _showPasswordModal = false;

  @override
  void didUpdateWidget(AccountSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_showPhoneModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPhoneDialog());
    }
    if (_showEmailModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openEmailDialog());
    }
    if (_showPasswordModal) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _openPasswordDialog());
    }
  }

  void _openPhoneDialog() {
    setState(() => _showPhoneModal = false);
    showDialog(
      context: context,
      builder: (ctx) => _PhoneModal(
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _openEmailDialog() {
    setState(() => _showEmailModal = false);
    showDialog(
      context: context,
      builder: (ctx) => _EmailModal(
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _openPasswordDialog() {
    setState(() => _showPasswordModal = false);
    showDialog(
      context: context,
      builder: (ctx) => _PasswordModal(
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ColoredBox(
        color: AppColors.background,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: AppSizes.lg),
                  _buildCurrentInfoCard(),
                  const SizedBox(height: AppSizes.lg),
                  _buildActionsCard(),
                  const SizedBox(height: AppSizes.lg),
                  _buildSecurityNote(),
                  const SizedBox(height: AppSizes.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF0EA5D4)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.xl,
            AppSizes.pagePadding,
            AppSizes.xl,
          ),
          child: Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.2),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: widget.onBack,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(AppSizes.sm),
                    child: Icon(Icons.chevron_right,
                        size: AppSizes.iconMd, color: Colors.white),
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'إعدادات الحساب',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: const Icon(Icons.info_outline,
                size: AppSizes.iconSm, color: AppColors.primary),
          ),
          const SizedBox(width: AppSizes.md),
          const Expanded(
            child: Text(
              'إدارة معلومات حسابك وكلمة المرور',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المعلومات الحالية',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            _infoRow(Icons.phone_outlined, 'رقم الجوال', '+966 50 123 4567',
                isLtr: true),
            const Divider(height: AppSizes.xl),
            _infoRow(Icons.email_outlined, 'البريد الإلكتروني', 'ahmad@email.com'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {bool isLtr = false}) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: Icon(icon, size: AppSizes.iconSm, color: AppColors.primary),
        ),
        SizedBox(width: AppSizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedForeground)),
              Directionality(
                textDirection:
                    isLtr ? TextDirection.ltr : TextDirection.rtl,
                child: Text(value,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          _actionRow(
            iconBg: const Color(0xFFDBEAFE),
            iconColor: const Color(0xFF2563EB),
            icon: Icons.phone_outlined,
            title: 'تغيير رقم الجوال',
            subtitle: 'يتطلب موافقة الإدارة',
            onTap: _openPhoneDialog,
            isFirst: true,
          ),
          const Divider(height: 1, indent: AppSizes.lg),
          _actionRow(
            iconBg: const Color(0xFFF0FDF4),
            iconColor: const Color(0xFF16A34A),
            icon: Icons.email_outlined,
            title: 'تغيير البريد الإلكتروني',
            subtitle: 'تحديث فوري',
            onTap: _openEmailDialog,
          ),
          const Divider(height: 1, indent: AppSizes.lg),
          _actionRow(
            iconBg: const Color(0xFFFFF7ED),
            iconColor: const Color(0xFFEA580C),
            icon: Icons.lock_outline,
            title: 'تغيير كلمة المرور',
            subtitle: 'آخر تغيير: منذ 3 أشهر',
            onTap: _openPasswordDialog,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(AppSizes.radiusXl) : Radius.zero,
        bottom:
            isLast ? const Radius.circular(AppSizes.radiusXl) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Icon(icon, size: AppSizes.iconSm, color: iconColor),
            ),
            SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500)),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_left,
                size: AppSizes.iconMd, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined,
              size: AppSizes.iconMd, color: Color(0xFFD97706)),
          SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              'تأكد من أن معلوماتك محدّثة لضمان أمان حسابك والتواصل معك بكفاءة.',
              style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF92400E), height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneModal extends StatefulWidget {
  const _PhoneModal({required this.onClose});
  final VoidCallback onClose;

  @override
  State<_PhoneModal> createState() => _PhoneModalState();
}

class _PhoneModalState extends State<_PhoneModal> {
  final _phoneCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _requestSent = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_phoneCtrl.text.isEmpty || _reasonCtrl.text.isEmpty) return;
    setState(() => _requestSent = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXl + 4)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF0EA5D4)],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        color: Colors.white, size: AppSizes.iconMd),
                    SizedBox(width: AppSizes.sm),
                    Text('تغيير رقم الجوال',
                        style: AppTextStyles.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              SizedBox(height: AppSizes.lg),
              if (_requestSent)
                Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: const Icon(Icons.check_circle_outline,
                          color: Color(0xFF16A34A), size: 36),
                    ),
                    SizedBox(height: AppSizes.md),
                    Text('تم إرسال طلبك بنجاح!',
                        style: AppTextStyles.body.copyWith(
                            color: const Color(0xFF16A34A),
                            fontWeight: FontWeight.w600)),
                    SizedBox(height: AppSizes.sm),
                    Text('سيتم مراجعة طلبك من قِبل الإدارة.',
                        style: AppTextStyles.caption),
                    const SizedBox(height: AppSizes.lg),
                  ],
                )
              else ...[
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: AppSizes.iconSm, color: Color(0xFFEA580C)),
                      SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          'تغيير رقم الجوال يتطلب موافقة الإدارة. سيُراجع الطلب خلال 24-48 ساعة.',
                          style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                TextField(
                  controller: _phoneCtrl,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.phone,
                  inputFormatters: phoneInputFormatters,
                  decoration: InputDecoration(
                    labelText: 'رقم الجوال الجديد',
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLg)),
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                TextField(
                  controller: _reasonCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'سبب التغيير',
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLg)),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onClose,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.md),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusLg)),
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.md),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusLg)),
                        ),
                        child: const Text('إرسال الطلب'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmailModal extends StatefulWidget {
  const _EmailModal({required this.onClose});
  final VoidCallback onClose;

  @override
  State<_EmailModal> createState() => _EmailModalState();
}

class _EmailModalState extends State<_EmailModal> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXl + 4)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined,
                        color: Colors.white, size: AppSizes.iconMd),
                    SizedBox(width: AppSizes.sm),
                    Text('تغيير البريد الإلكتروني',
                        style: AppTextStyles.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني الجديد',
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusLg)),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusLg)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onClose,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.md),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLg)),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.md),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLg)),
                      ),
                      child: const Text('تأكيد'),
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
}

class _PasswordModal extends StatefulWidget {
  const _PasswordModal({required this.onClose});
  final VoidCallback onClose;

  @override
  State<_PasswordModal> createState() => _PasswordModalState();
}

class _PasswordModalState extends State<_PasswordModal> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXl + 4)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEA580C), Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline,
                        color: Colors.white, size: AppSizes.iconMd),
                    SizedBox(width: AppSizes.sm),
                    Text('تغيير كلمة المرور',
                        style: AppTextStyles.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              TextField(
                controller: _currentCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور الحالية',
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusLg)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              TextField(
                controller: _newCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور الجديدة',
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusLg)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              TextField(
                controller: _confirmCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'تأكيد كلمة المرور الجديدة',
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusLg)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: AppSizes.iconSm, color: Color(0xFF2563EB)),
                    SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        'يجب أن تحتوي كلمة المرور على 8 أحرف على الأقل مع أرقام وحروف.',
                        style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF1D4ED8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onClose,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.md),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLg)),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.md),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLg)),
                      ),
                      child: const Text('تغيير'),
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
}
