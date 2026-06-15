import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../state/auth_scope.dart';
import '../widgets/auth_form_fields.dart';
import '../widgets/circle_back_button.dart';
import '../widgets/glass_panel.dart';

/// Second step of the password-reset flow: enter the 6-digit OTP sent to the
/// phone, with a resend countdown.
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
    final ok = await context.auth.verifyOtp(widget.phone, _otp);
    if (!mounted) return;
    if (ok) widget.onVerified(_otp);
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    await context.auth.forgotPassword(widget.phone);
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
                      _buildOtpBoxes(),
                      if (auth.errorMessage != null) ...[
                        const SizedBox(height: AppSizes.md),
                        AuthErrorBanner(message: auth.errorMessage!),
                      ],
                      const SizedBox(height: AppSizes.lg),
                      _buildResendButton(context),
                      const SizedBox(height: AppSizes.lg),
                      _buildVerifyButton(context, auth.isLoading),
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

  Widget _buildOtpBoxes() {
    return Directionality(
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
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildResendButton(BuildContext context) {
    return TextButton(
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
    );
  }

  Widget _buildVerifyButton(BuildContext context, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (isLoading || _otp.length != 6) ? null : _verify,
        child: isLoading
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
    );
  }
}
