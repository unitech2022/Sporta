import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/phone_input.dart';
import '../../../../core/widgets/sporta_logo.dart';
import '../state/auth_scope.dart';
import '../widgets/circle_back_button.dart';
import '../widgets/language_toggle_button.dart';
import '../widgets/login_biometric_notice.dart';
import '../widgets/login_error_banner.dart';
import '../widgets/login_icon_input_card.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onLoginSuccess,
    required this.onBack,
    required this.onForgotPassword,
    required this.onRegister,
  });

  final VoidCallback onLoginSuccess;
  final VoidCallback onBack;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await context.auth.login(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );
    if (!mounted) return;
    if (ok) widget.onLoginSuccess();
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
                children: [
                  _buildHeader(context),
                  const SizedBox(height: AppSizes.xxxl),
                  const SportaLogo(width: 96, white: true),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    context.tr('welcomeBackExcl'),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xxxl),
                  _buildPhoneField(context),
                  const SizedBox(height: AppSizes.lg),
                  _buildPasswordField(context),
                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: AppSizes.md),
                    LoginErrorBanner(
                      message: auth.errorMessage!,
                      errorCode: auth.errorCode,
                      onRegister: widget.onRegister,
                    ),
                  ],
                  const SizedBox(height: AppSizes.lg),
                  _buildOptionsRow(context),
                  const SizedBox(height: AppSizes.lg),
                  const LoginBiometricNotice(),
                  const SizedBox(height: AppSizes.xxl),
                  _buildSubmitButton(context, auth.isLoading),
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
              context.tr('login'),
              style: AppTextStyles.heading1.copyWith(color: Colors.white),
            ),
          ],
        ),
        const LanguageToggleButton(compact: true),
      ],
    );
  }

  Widget _buildPhoneField(BuildContext context) {
    return LoginIconInputCard(
      icon: Icons.phone_outlined,
      label: context.tr('phone'),
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        textDirection: TextDirection.ltr,
        inputFormatters: phoneInputFormatters,
        style: AppTextStyles.body.copyWith(color: AppColors.secondary),
        decoration: const InputDecoration.collapsed(hintText: '05xxxxxxxx'),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return context.tr('fieldRequired');
          if (!RegExp(r'^05\d{8}$').hasMatch(v.trim())) {
            return context.tr('invalidPhone');
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return LoginIconInputCard(
      icon: Icons.lock_outline,
      label: context.tr('password'),
      trailing: IconButton(
        onPressed: () => setState(() => _showPassword = !_showPassword),
        icon: Icon(
          _showPassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppColors.mutedForeground,
          size: AppSizes.iconMd,
        ),
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: !_showPassword,
        style: AppTextStyles.body.copyWith(color: AppColors.secondary),
        decoration: const InputDecoration.collapsed(hintText: '••••••••'),
        validator: (v) =>
            (v == null || v.isEmpty) ? context.tr('fieldRequired') : null,
      ),
    );
  }

  Widget _buildOptionsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _rememberMe,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _rememberMe = v ?? false),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Text(
              context.tr('rememberMe'),
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
            ),
          ],
        ),
        TextButton(
          onPressed: widget.onForgotPassword,
          child: Text(
            context.tr('forgotPassword'),
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                context.tr('login'),
                style: AppTextStyles.heading3.copyWith(color: Colors.white),
              ),
      ),
    );
  }
}
