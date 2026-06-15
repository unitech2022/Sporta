import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../domain/entities/registration_data.dart';
import '../state/auth_scope.dart';
import 'forgot_password_page.dart';
import 'language_selection_page.dart';
import 'login_page.dart';
import 'registration_success_page.dart';
import 'sports_selection_page.dart';
import 'unified_registration_page.dart';
import 'welcome_page.dart';

enum _AuthStage {
  welcome,
  login,
  sportsSelection,
  language,
  registration,
  success,
  forgotPassword,
  otp,
  resetPassword,
  resetSuccess,
}

class AuthFlowPage extends StatefulWidget {
  const AuthFlowPage({super.key, required this.onLoginSuccess});

  final VoidCallback onLoginSuccess;

  @override
  State<AuthFlowPage> createState() => _AuthFlowPageState();
}

class _AuthFlowPageState extends State<AuthFlowPage> {
  _AuthStage _stage = _AuthStage.welcome;
  RegistrationData _registrationData = RegistrationData();

  // Passed through forgot-password → OTP → reset stages.
  String _fpPhone = '';
  String _fpOtp = '';

  void _goTo(_AuthStage stage) {
    context.auth.clearError();
    setState(() => _stage = stage);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_stage) {
      _AuthStage.welcome => WelcomePage(
          onRegister: () => _goTo(_AuthStage.language),
          onLogin: () => _goTo(_AuthStage.login),
        ),

      _AuthStage.login => LoginPage(
          onLoginSuccess: () => _goTo(_AuthStage.sportsSelection),
          onBack: () => _goTo(_AuthStage.welcome),
          onForgotPassword: () => _goTo(_AuthStage.forgotPassword),
          onRegister: () => _goTo(_AuthStage.language),
        ),

      _AuthStage.sportsSelection =>
        SportsSelectionPage(onContinue: widget.onLoginSuccess),

      _AuthStage.language => LanguageSelectionPage(
          onSelectLanguage: (language) {
            context.appSettings.setLanguage(language);
            _goTo(_AuthStage.registration);
          },
          onBack: () => _goTo(_AuthStage.welcome),
        ),

      _AuthStage.registration => UnifiedRegistrationPage(
          onComplete: (data) {
            _registrationData = data;
            _goTo(_AuthStage.success);
          },
          onBack: () => _goTo(_AuthStage.welcome),
        ),

      _AuthStage.success => RegistrationSuccessPage(
          data: _registrationData,
          onStart: widget.onLoginSuccess,
        ),

      _AuthStage.forgotPassword => ForgotPasswordPage(
          onOtpSent: (phone) {
            _fpPhone = phone;
            _goTo(_AuthStage.otp);
          },
          onBack: () => _goTo(_AuthStage.login),
        ),

      _AuthStage.otp => OtpPage(
          phone: _fpPhone,
          onVerified: (otp) {
            _fpOtp = otp;
            _goTo(_AuthStage.resetPassword);
          },
          onBack: () => _goTo(_AuthStage.forgotPassword),
        ),

      _AuthStage.resetPassword => ResetPasswordPage(
          phone: _fpPhone,
          otp: _fpOtp,
          onSuccess: () => _goTo(_AuthStage.resetSuccess),
          onBack: () => _goTo(_AuthStage.otp),
        ),

      _AuthStage.resetSuccess => _ResetSuccessPage(
          onDone: () => _goTo(_AuthStage.login),
        ),
    };
  }
}

// ── Reset success screen ──────────────────────────────────────────────────────

class _ResetSuccessPage extends StatelessWidget {
  const _ResetSuccessPage({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: AppSizes.xxl),
              Text(
                context.tr('passwordResetSuccess'),
                textAlign: TextAlign.center,
                style: AppTextStyles.heading2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSizes.xxxl),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onDone,
                  child: Text(context.tr('login')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
