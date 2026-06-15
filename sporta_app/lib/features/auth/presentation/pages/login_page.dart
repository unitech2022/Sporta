import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/phone_input.dart';
import '../../../../core/widgets/sporta_logo.dart';
import '../state/auth_scope.dart';
import '../widgets/circle_back_button.dart';
import '../widgets/glass_panel.dart';
import '../widgets/language_toggle_button.dart';

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
    final auth = context.auth;
    final ok = await auth.login(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleBackButton(onTap: widget.onBack),
                          const SizedBox(width: AppSizes.md),
                          Text(
                            context.tr('login'),
                            style: AppTextStyles.heading1
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                      const LanguageToggleButton(compact: true),
                    ],
                  ),
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
                  _IconInputCard(
                    icon: Icons.phone_outlined,
                    label: context.tr('phone'),
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      inputFormatters: phoneInputFormatters,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.secondary),
                      decoration: const InputDecoration.collapsed(
                          hintText: '05xxxxxxxx'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return context.tr('fieldRequired');
                        }
                        if (!RegExp(r'^05\d{8}$').hasMatch(v.trim())) {
                          return context.tr('invalidPhone');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  _IconInputCard(
                    icon: Icons.lock_outline,
                    label: context.tr('password'),
                    trailing: IconButton(
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
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
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.secondary),
                      decoration: const InputDecoration.collapsed(
                          hintText: '••••••••'),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return context.tr('fieldRequired');
                        }
                        return null;
                      },
                    ),
                  ),
                  // Show API error message
                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: AppSizes.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.destructive.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(
                          color:
                              AppColors.destructive.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.errorMessage!,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.destructive),
                          ),
                          // Phone not registered → offer to create an account.
                          if (auth.errorCode == 'PHONE_NOT_REGISTERED') ...[
                            const SizedBox(height: AppSizes.sm),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: widget.onRegister,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.destructive,
                                  side: const BorderSide(
                                      color: AppColors.destructive),
                                ),
                                icon: const Icon(Icons.person_add_alt_1,
                                    size: AppSizes.iconSm),
                                label: Text(context.tr('register')),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSizes.lg),
                  Row(
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
                              onChanged: (v) =>
                                  setState(() => _rememberMe = v ?? false),
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Text(
                            context.tr('rememberMe'),
                            style: AppTextStyles.bodySmall
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: widget.onForgotPassword,
                        child: Text(
                          context.tr('forgotPassword'),
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.lg),
                  GlassPanel(
                    radius: AppSizes.radiusLg,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: false,
                            activeColor: AppColors.primary,
                            onChanged: null,
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('biometricTitle'),
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: AppSizes.xs),
                              Text(
                                context.tr('biometricDesc'),
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xxl),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor:
                            Colors.white.withValues(alpha: 0.1),
                        disabledForegroundColor:
                            Colors.white.withValues(alpha: 0.5),
                      ),
                      child: auth.isLoading
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
                              style: AppTextStyles.heading3
                                  .copyWith(color: Colors.white),
                            ),
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
}

class _IconInputCard extends StatelessWidget {
  const _IconInputCard({
    required this.icon,
    required this.label,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child:
                Icon(icon, color: AppColors.primary, size: AppSizes.iconMd),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: AppSizes.xs),
                child,
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
