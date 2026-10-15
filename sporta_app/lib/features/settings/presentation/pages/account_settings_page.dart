import 'package:sporta_app/core/state/app_scope.dart';
import 'package:sporta_app/core/widgets/directional_icon.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/phone_input.dart';
import '../../../auth/presentation/state/auth_scope.dart';
import '../../../profile/presentation/pages/edit_profile_page.dart';
import 'delete_account_page.dart';
import '../../../venue/presentation/pages/location_picker_page.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/system_insets.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  bool _showPhoneModal = false;

  @override
  void didUpdateWidget(AccountSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_showPhoneModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPhoneDialog());
    }
  }

  void _openPhoneDialog() {
    setState(() => _showPhoneModal = false);
    showDialog(
      context: context,
      builder: (ctx) => _PhoneModal(onClose: () => Navigator.of(ctx).pop()),
    );
  }

  void _openEditProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            EditProfilePage(onBack: () => Navigator.of(context).pop()),
      ),
    );
  }

  void _openDeleteAccount() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            DeleteAccountPage(onBack: () => Navigator.of(context).pop()),
      ),
    );
  }

  Future<void> _openLocation() async {
    final user = context.auth.user;
    final initial = (user?.latitude != null && user?.longitude != null)
        ? LatLng(user!.latitude!, user.longitude!)
        : null;
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          initial: initial,
          title: context.tr('حدد موقعي على الخريطة'),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.auth.updateLocation(
      picked.latLng.latitude,
      picked.latLng.longitude,
    );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? context.tr('تم تحديث الموقع'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: ColoredBox(
        color: AppColors.background,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: context.safeBottom(
                  const EdgeInsets.all(AppSizes.pagePadding),
                ),
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: AppSizes.lg),
                  _buildCurrentInfoCard(),
                  const SizedBox(height: AppSizes.lg),
                  _buildActionsCard(),
                  const SizedBox(height: AppSizes.lg),
                  _buildDangerZone(),
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
                    child: DirectionalIcon(
                      rtl: Icons.chevron_right,
                      ltr: Icons.chevron_left,
                      size: AppSizes.iconMd,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  context.tr('إعدادات الحساب'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
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
            child: const Icon(
              Icons.info_outline,
              size: AppSizes.iconSm,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(
              context.tr('إدارة معلومات حسابك'),
              style: TextStyle(
                fontSize: 13,
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('المعلومات الحالية'),
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            _infoRow(
              Icons.phone_outlined,
              trg('رقم الجوال'),
              context.auth.user?.phone ?? '—',
              isLtr: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool isLtr = false,
  }) {
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
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
              Directionality(
                textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
                child: Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          _actionRow(
            iconBg: const Color(0xFFEFF6FF),
            iconColor: AppColors.primary,
            icon: Icons.person_outline,
            title: context.tr('تعديل المعلومات الشخصية'),
            subtitle: context.tr('الاسم والمدينة والحي'),
            onTap: _openEditProfile,
            isFirst: true,
          ),
          const Divider(height: 1, indent: AppSizes.lg),
          _actionRow(
            iconBg: const Color(0xFFEFF6FF),
            iconColor: AppColors.primary,
            icon: Icons.map_outlined,
            title: context.tr('موقعي'),
            subtitle: context.tr('لعرض الأقرب من المباريات والملاعب'),
            onTap: _openLocation,
          ),
          const Divider(height: 1, indent: AppSizes.lg),
          _actionRow(
            iconBg: const Color(0xFFDBEAFE),
            iconColor: const Color(0xFF2563EB),
            icon: Icons.phone_outlined,
            title: context.tr('تغيير رقم الجوال'),
            subtitle: context.tr('يتطلب موافقة الإدارة'),
            onTap: _openPhoneDialog,
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
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(AppSizes.radiusXl) : Radius.zero,
        bottom: isLast ? const Radius.circular(AppSizes.radiusXl) : Radius.zero,
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
                  Text(
                    title,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: titleColor ?? AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            DirectionalIcon(
              rtl: Icons.chevron_left,
              ltr: Icons.chevron_right,
              size: AppSizes.iconMd,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }

  /// حذف الحساب — مسار إلزامي داخل التطبيق (App Store 5.1.1(v))، معزول في
  /// بطاقة حمراء أسفل الإجراءات حتى لا يُلمس بالخطأ.
  Widget _buildDangerZone() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: _actionRow(
        iconBg: const Color(0xFFFEF2F2),
        iconColor: const Color(0xFFDC2626),
        icon: Icons.delete_forever_outlined,
        title: context.tr('حذف الحساب'),
        subtitle: context.tr('حذف نهائي لحسابك وبياناتك'),
        onTap: _openDeleteAccount,
        isFirst: true,
        isLast: true,
        titleColor: const Color(0xFFDC2626),
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
          const Icon(
            Icons.shield_outlined,
            size: AppSizes.iconMd,
            color: Color(0xFFD97706),
          ),
          SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              context.tr(
                'تأكد من أن معلوماتك محدّثة لضمان أمان حسابك والتواصل معك بكفاءة.',
              ),
              style: AppTextStyles.bodySmall.copyWith(
                color: const Color(0xFF92400E),
                height: 1.6,
              ),
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
        borderRadius: BorderRadius.circular(AppSizes.radiusXl + 4),
      ),
      child: Directionality(
        textDirection: Directionality.of(context),
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
                    const Icon(
                      Icons.phone_outlined,
                      color: Colors.white,
                      size: AppSizes.iconMd,
                    ),
                    SizedBox(width: AppSizes.sm),
                    Text(
                      context.tr('تغيير رقم الجوال'),
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusFull,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF16A34A),
                        size: 36,
                      ),
                    ),
                    SizedBox(height: AppSizes.md),
                    Text(
                      context.tr('تم إرسال طلبك بنجاح!'),
                      style: AppTextStyles.body.copyWith(
                        color: const Color(0xFF16A34A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSizes.sm),
                    Text(
                      context.tr('سيتم مراجعة طلبك من قِبل الإدارة.'),
                      style: AppTextStyles.caption,
                    ),
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
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: AppSizes.iconSm,
                        color: Color(0xFFEA580C),
                      ),
                      SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          context.tr(
                            'تغيير رقم الجوال يتطلب موافقة الإدارة. سيُراجع الطلب خلال 24-48 ساعة.',
                          ),
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF92400E),
                          ),
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
                    labelText: context.tr('رقم الجوال الجديد'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                TextField(
                  controller: _reasonCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: context.tr('سبب التغيير'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
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
                            vertical: AppSizes.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusLg,
                            ),
                          ),
                        ),
                        child: Text(context.tr('cancel')),
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
                            vertical: AppSizes.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusLg,
                            ),
                          ),
                        ),
                        child: Text(context.tr('إرسال الطلب')),
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
