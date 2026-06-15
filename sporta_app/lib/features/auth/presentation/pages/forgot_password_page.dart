import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/phone_input.dart';
import '../../../../core/widgets/sporta_logo.dart';
import '../state/auth_scope.dart';
import '../widgets/circle_back_button.dart';
import '../widgets/glass_panel.dart';

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
    final auth = context.auth;
    final ok = await auth.forgotPassword(_phoneController.text.trim());
    if (!mounted) return;
    if (ok) {
      widget.onOtpSent(_phoneController.text.trim());
    }
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleBackButton(onTap: widget.onBack),
                          const SizedBox(width: AppSizes.md),
                          Text(
                            context.tr('forgotPasswordTitle'),
                            style: AppTextStyles.heading1
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                      const SportaLogo(width: 48, white: true),
                    ],
                  ),
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
                        _WhiteInput(
                          label: context.tr('phone'),
                          hint: '05xxxxxxxx',
                          icon: Icons.phone_outlined,
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: phoneInputFormatters,
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
                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: AppSizes.md),
                          _ErrorBanner(message: auth.errorMessage!),
                        ],
                        const SizedBox(height: AppSizes.xxl),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _submit,
                            child: auth.isLoading
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
                        ),
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
}

// ── OTP page ──────────────────────────────────────────────────────────────────

class OtpPage extends StatefulWidget {
  const OtpPage({
    super.key,
    required this.phone,
    required this.onVerified,
    required this.onBack,
  });

  final String phone;
  final ValueChanged<String> onVerified; // passes OTP to next step
  final VoidCallback onBack;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  int _resendSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _canResend = false;
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        if (_resendSeconds > 1) {
          _resendSeconds--;
          _tick();
        } else {
          _resendSeconds = 0;
          _canResend = true;
        }
      });
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _nodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _verify() async {
    if (_otp.length != 6) return;
    final auth = context.auth;
    final ok = await auth.verifyOtp(widget.phone, _otp);
    if (!mounted) return;
    if (ok) widget.onVerified(_otp);
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    final auth = context.auth;
    await auth.forgotPassword(widget.phone);
    if (!mounted) return;
    _startResendTimer();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleBackButton(onTap: widget.onBack),
                    const SizedBox(width: AppSizes.md),
                    Text(
                      context.tr('otpTitle'),
                      style:
                          AppTextStyles.heading1.copyWith(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.xxxl),
                GlassPanel(
                  child: Column(
                    children: [
                      Text(
                        '${context.tr('otpDesc')} ${widget.phone}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.xxl),
                      // OTP input boxes
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (i) {
                            return SizedBox(
                              width: 44,
                              height: 54,
                              child: TextField(
                                controller: _controllers[i],
                                focusNode: _nodes[i],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                onChanged: (v) => _onDigitChanged(i, v),
                                style: AppTextStyles.heading2
                                    .copyWith(color: AppColors.secondary),
                                decoration: InputDecoration(
                                  counterText: '',
                                  fillColor: Colors.white,
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppSizes.radiusMd),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      if (auth.errorMessage != null) ...[
                        const SizedBox(height: AppSizes.md),
                        _ErrorBanner(message: auth.errorMessage!),
                      ],
                      const SizedBox(height: AppSizes.lg),
                      // Resend
                      TextButton(
                        onPressed: _canResend ? _resend : null,
                        child: Text(
                          _canResend
                              ? context.tr('resendOtp')
                              : '${context.tr('resendIn')} $_resendSeconds ${context.tr('seconds')}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _canResend
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.lg),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              (auth.isLoading || _otp.length != 6) ? null : _verify,
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(context.tr('verifyOtp')),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reset Password page ───────────────────────────────────────────────────────

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
    final auth = context.auth;
    final ok = await auth.resetPassword(
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
                        _WhiteInput(
                          label: context.tr('newPassword'),
                          hint: '••••••••',
                          controller: _passwordController,
                          obscureText: !_showNew,
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _showNew = !_showNew),
                            icon: Icon(
                              _showNew
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return context.tr('fieldRequired');
                            }
                            if (v.length < 8) {
                              return context.tr('passwordTooShort');
                            }
                            if (!RegExp(r'[a-zA-Z]').hasMatch(v) ||
                                !RegExp(r'\d').hasMatch(v)) {
                              return context.tr('passwordWeak');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSizes.xl),
                        _WhiteInput(
                          label: context.tr('confirmPassword'),
                          hint: '••••••••',
                          controller: _confirmController,
                          obscureText: !_showConfirm,
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _showConfirm = !_showConfirm),
                            icon: Icon(
                              _showConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          validator: (v) {
                            if (v != _passwordController.text) {
                              return context.tr('passwordsNotMatch');
                            }
                            return null;
                          },
                        ),
                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: AppSizes.md),
                          _ErrorBanner(message: auth.errorMessage!),
                        ],
                        const SizedBox(height: AppSizes.xxl),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _submit,
                            child: auth.isLoading
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
                        ),
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
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _WhiteInput extends StatelessWidget {
  const _WhiteInput({
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.icon,
    this.suffixIcon,
    this.validator,
    this.inputFormatters,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? icon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall
              .copyWith(color: Colors.white.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: AppSizes.sm),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          inputFormatters: inputFormatters,
          style: AppTextStyles.body.copyWith(color: AppColors.secondary),
          decoration: InputDecoration(
            hintText: hint,
            fillColor: Colors.white,
            prefixIcon: icon == null
                ? null
                : Icon(icon,
                    size: AppSizes.iconMd, color: AppColors.mutedForeground),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.destructive.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodySmall
            .copyWith(color: AppColors.destructive),
      ),
    );
  }
}
