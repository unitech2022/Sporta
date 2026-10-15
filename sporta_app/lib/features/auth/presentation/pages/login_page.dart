import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/auth/biometric_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/phone_input.dart';
import '../../../../core/widgets/sporta_logo.dart';
import '../../data/models/otp_models.dart';
import '../cubit/auth_cubit.dart';
import '../state/auth_scope.dart';
import '../widgets/circle_back_button.dart';
import '../widgets/language_toggle_button.dart';
import '../widgets/login_error_banner.dart';
import '../widgets/login_icon_input_card.dart';
import '../../../../core/utils/system_insets.dart';

/// شاشة الدخول. طريقان بحسب الهاتف:
/// • هاتف موثوق (سُجّلت بصمته لهذا الرقم): بصمة → دخول مباشر، بلا رمز.
/// • هاتف غير موثوق: رمز واتساب مرة واحدة ثم تسجيل البصمة — فلا يدخل أحد
///   برقمك من هاتف آخر ما لم يصله رمزك.
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onLoginSuccess,
    required this.onCodeSent,
    required this.onBack,
    required this.onRegister,
  });

  /// دخول من جهاز موثوق: الجلسة قائمة فعلاً.
  final VoidCallback onLoginSuccess;

  /// أُرسل رمز لهاتف غير موثوق؛ تُكمل [OtpPage] الدخول.
  final void Function(String phone, OtpRequested sent, {required bool rememberMe})
      onCodeSent;

  final VoidCallback onBack;
  final VoidCallback onRegister;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  /// مُفعَّل افتراضياً — الغالبية تريد بقاء الجلسة، ومن لا يريدها يزيل العلامة.
  bool _rememberMe = true;

  /// الرقم الذي سُجّل هذا الهاتف له، إن وُجد.
  String? _trustedPhone;
  BiometricType? _biometricType;

  bool get _isTrustedForTypedPhone =>
      _trustedPhone != null && _phoneController.text.trim() == _trustedPhone;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
    _initTrustedDevice();
  }

  Future<void> _initTrustedDevice() async {
    final auth = context.auth;
    final phone = await auth.trustedDevicePhone();
    final type = await BiometricService.primaryType();
    if (!mounted) return;
    setState(() {
      _trustedPhone = phone;
      _biometricType = type;
      if (phone != null) _phoneController.text = phone;
    });
    // الهاتف موثوق: تُعرض البصمة فوراً بدل انتظار ضغطة على زر واضح أصلاً.
    if (phone != null) _submit();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.auth;
    final phone = _phoneController.text.trim();

    if (_isTrustedForTypedPhone) {
      final result =
          await auth.loginWithDevice(phone: phone, rememberMe: _rememberMe);
      if (!mounted) return;
      switch (result) {
        case DeviceLoginResult.success:
          widget.onLoginSuccess();
          return;
        case DeviceLoginResult.cancelled:
        case DeviceLoginResult.failed:
          return;
        case DeviceLoginResult.notTrusted:
          // الخادم لم يعد يعرف الجهاز: يُكمل كهاتف جديد برمز واتساب.
          setState(() => _trustedPhone = null);
      }
    }

    await _sendCode();
  }

  /// مسار الرمز مباشرةً — مخرج لمن تعذّرت بصمته (ألغى النافذة، أو أزال البصمة
  /// من هاتفه): بلا هذا الزر يقف صاحب جهازٍ موثوق بلا طريق إلى حسابه.
  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.auth;
    final phone = _phoneController.text.trim();
    final sent = await auth.requestOtp(phone, OtpPurpose.login);
    if (!mounted || sent == null) return;
    widget.onCodeSent(phone, sent, rememberMe: _rememberMe);
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
            padding: context.safeBottom(const EdgeInsets.symmetric(
              horizontal: AppSizes.pagePadding,
              vertical: AppSizes.xxxl,
            )),
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
                  const SizedBox(height: AppSizes.md),
                  _buildHint(context),
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
                  const SizedBox(height: AppSizes.xxl),
                  _buildSubmitButton(context, auth.isLoading),
                  if (_isTrustedForTypedPhone) ...[
                    const SizedBox(height: AppSizes.sm),
                    TextButton(
                      onPressed: auth.isLoading ? null : _sendCode,
                      child: Text(
                        context.tr('loginWithCodeInstead'),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
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
        onFieldSubmitted: (_) => _submit(),
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

  /// يقول للمستخدم ما سيحدث عند الضغط: بصمة، أم رمز واتساب لأن الهاتف جديد.
  Widget _buildHint(BuildContext context) {
    final trusted = _isTrustedForTypedPhone;
    return Row(
      children: [
        Icon(
          trusted ? _biometricIcon : Icons.chat_bubble_outline,
          size: AppSizes.iconSm,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(
            context.tr(trusted ? 'loginTrustedHint' : 'loginUntrustedHint'),
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsRow(BuildContext context) {
    return Row(
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
    );
  }

  IconData get _biometricIcon => _biometricType == BiometricType.face
      ? Icons.face_outlined
      : Icons.fingerprint;

  Widget _buildSubmitButton(BuildContext context, bool isLoading) {
    final trusted = _isTrustedForTypedPhone;
    final label = context.tr(
      trusted
          ? (_biometricType == BiometricType.face
              ? 'loginWithFaceId'
              : 'loginWithFingerprint')
          : 'sendCode',
    );
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Icon(
                trusted ? _biometricIcon : Icons.chat_bubble_outline,
                color: Colors.white,
                size: AppSizes.iconMd,
              ),
        label: isLoading
            ? const SizedBox.shrink()
            : Text(
                label,
                style: AppTextStyles.heading3.copyWith(color: Colors.white),
              ),
      ),
    );
  }
}
