import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/phone_input.dart';
import '../../../../core/widgets/sporta_logo.dart';
import '../state/auth_scope.dart';
import '../widgets/auth_form_fields.dart';
import '../widgets/circle_back_button.dart';
import '../widgets/glass_panel.dart';

/// First step of the password-reset flow: enter the phone number to receive an
/// OTP. (The OTP and reset steps live in [OtpPage] and [ResetPasswordPage].)
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({
    super.key,
    required this.onOtpSent,
    required this.onBack,
  });

  final ValueChanged<String> onOtpSent; // passes the phone to next step
  final VoidCallback onBack;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await context.auth.forgotPassword(_phoneController.text.trim());
    if (!mounted) return;
    if (ok) widget.onOtpSent(_phoneController.text.trim());
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
                  _buildHeader(context),
                  const SizedBox(height: AppSizes.xxxl),
                  GlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('forgotPasswordDesc'),
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: AppSizes.xxl),
                        AuthWhiteInput(
                          label: context.tr('phone'),
                          hint: '05xxxxxxxx',
                          icon: Icons.phone_outlined,
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: phoneInputFormatters,
                          validator: _validatePhone,
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleBackButton(onTap: widget.onBack),
            const SizedBox(width: AppSizes.md),
            Text(
              context.tr('forgotPasswordTitle'),
              style: AppTextStyles.heading1.copyWith(color: Colors.white),
            ),
          ],
        ),
        const SportaLogo(width: 48, white: true),
      ],
    );
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return context.tr('fieldRequired');
    if (!RegExp(r'^05\d{8}$').hasMatch(v.trim())) {
      return context.tr('invalidPhone');
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
            : Text(context.tr('sendOtp')),
      ),
    );
  }
}
