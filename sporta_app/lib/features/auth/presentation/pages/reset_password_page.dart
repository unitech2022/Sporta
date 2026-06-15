import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../state/auth_scope.dart';
import '../widgets/auth_form_fields.dart';
import '../widgets/circle_back_button.dart';
import '../widgets/glass_panel.dart';

/// Final step of the password-reset flow: choose and confirm a new password.
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({
    super.key,
    required this.phone,
    required this.otp,
    required this.onSuccess,
    required this.onBack,
  });

  final String phone;
  final String otp;
  final VoidCallback onSuccess;
  final VoidCallback onBack;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await context.auth.resetPassword(
      widget.phone,
      widget.otp,
      _passwordController.text,
    );
    if (!mounted) return;
    if (ok) widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.auth;

    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.pagePadding,
              vertical: AppSizes.xxxl,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleBackButton(onTap: widget.onBack),
                      const SizedBox(width: AppSizes.md),
                      Text(
                        context.tr('newPasswordTitle'),
                        style: AppTextStyles.heading1
                            .copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xxxl),
                  GlassPanel(
                    child: Column(
                      children: [
                        AuthWhiteInput(
                          label: context.tr('newPassword'),
                          hint: '••••••••',
                          controller: _passwordController,
                          obscureText: !_showNew,
                          suffixIcon: _visibilityToggle(
                            visible: _showNew,
                            onTap: () => setState(() => _showNew = !_showNew),
                          ),
                          validator: _validateNewPassword,
                        ),
                        const SizedBox(height: AppSizes.xl),
                        AuthWhiteInput(
                          label: context.tr('confirmPassword'),
                          hint: '••••••••',
                          controller: _confirmController,
                          obscureText: !_showConfirm,
                          suffixIcon: _visibilityToggle(
                            visible: _showConfirm,
                            onTap: () =>
                                setState(() => _showConfirm = !_showConfirm),
                          ),
                          validator: (v) => v != _passwordController.text
                              ? context.tr('passwordsNotMatch')
                              : null,
                        ),
                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: AppSizes.md),
                          AuthErrorBanner(message: auth.errorMessage!),
                        ],
                        const SizedBox(height: AppSizes.xxl),
                        _buildSubmitButton(context, auth.isLoading),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _visibilityToggle({required bool visible, required VoidCallback onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppColors.mutedForeground,
      ),
    );
  }

  String? _validateNewPassword(String? v) {
    if (v == null || v.isEmpty) return context.tr('fieldRequired');
    if (v.length < 8) return context.tr('passwordTooShort');
    if (!RegExp(r'[a-zA-Z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return context.tr('passwordWeak');
    }
    return null;
  }

  Widget _buildSubmitButton(BuildContext context, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _submit,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(context.tr('resetPassword')),
      ),
    );
  }
}
