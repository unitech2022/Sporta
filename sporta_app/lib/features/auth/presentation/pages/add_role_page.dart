import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/state/app_settings.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../domain/entities/registration_data.dart';
import '../state/auth_scope.dart';
import '../widgets/account_review_notice.dart';
import '../widgets/role_details_step.dart';

/// Collects a new role's account details and registers it on the current
/// account (POST /users/roles). Returns `true` via Navigator.pop on success.
class AddRolePage extends StatefulWidget {
  const AddRolePage({super.key, required this.role});

  final UserRole role;

  @override
  State<AddRolePage> createState() => _AddRolePageState();
}

class _AddRolePageState extends State<AddRolePage> {
  late final RegistrationData _data = RegistrationData()..roles.add(widget.role);
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  bool get _needsDetails =>
      widget.role == UserRole.coach || widget.role == UserRole.venue;

  Future<void> _submit() async {
    if (_submitting) return;
    if (_needsDetails && !(_formKey.currentState?.validate() ?? false)) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    final error = await context.auth.addRole(_data);
    if (!mounted) return;
    if (error == null) {
      if (_needsDetails) {
        // دورا المدرب والملعب ينتظران موافقة الأدمن، فلا يُفعَّل القسم الآن —
        // نعرض رسالة المراجعة ويبقى المستخدم على دوره الحالي.
        await showAccountReviewDialog(context);
        if (!mounted) return;
      } else {
        // Activate the new role so its dashboard shows immediately.
        context.appSettings.setRole(widget.role);
      }
      Navigator.of(context).pop(true);
    } else {
      setState(() => _submitting = false);
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                child: _needsDetails
                    ? RoleDetailsStep(data: _data, formKey: _formKey)
                    : _playerInfo(),
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.pagePadding, AppSizes.md,
              AppSizes.pagePadding, AppSizes.xxl),
          child: Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.2),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(AppSizes.sm),
                    child: DirectionalIcon(
                        rtl: Icons.arrow_forward,
                        ltr: Icons.arrow_back,
                        color: Colors.white,
                        size: AppSizes.iconMd),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('تسجيل بيانات الحساب'),
                        style: AppTextStyles.heading2
                            .copyWith(color: Colors.white)),
                    Text(
                      '${widget.role.emoji} ${context.tr(widget.role.trKey)}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSizes.xl),
        Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.sports_tennis, color: AppColors.primary),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Text(
                  context.tr('حساب اللاعب لا يحتاج بيانات إضافية — اضغط لإضافته'),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.secondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _footer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(context.tr('إضافة الحساب')),
          ),
        ),
      ),
    );
  }
}
