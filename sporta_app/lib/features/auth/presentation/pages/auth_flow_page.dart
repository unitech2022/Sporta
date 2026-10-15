import 'package:flutter/material.dart';

import '../../../../core/state/app_scope.dart';
import '../../data/models/otp_models.dart';
import '../../domain/entities/registration_data.dart';
import '../state/auth_scope.dart';
import 'device_enroll_page.dart';
import 'language_selection_page.dart';
import 'login_page.dart';
import 'otp_page.dart';
import 'registration_success_page.dart';
import 'sports_selection_page.dart';
import 'unified_registration_page.dart';
import 'welcome_page.dart';

enum _AuthStage {
  welcome,
  login,
  loginOtp,

  /// تسجيل البصمة على هذا الهاتف — بعد التسجيل وبعد أول دخول برمز.
  enrollDevice,
  sportsSelection,
  language,
  registration,
  success,
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

  // يُحملان من شاشة الرقم إلى شاشة الرمز (هاتف غير موثوق).
  String _loginPhone = '';
  OtpRequested? _loginOtpSent;
  bool _loginRememberMe = false;

  /// إلى أين بعد تسجيل البصمة: اختيار الرياضة بعد الدخول، وشاشة النجاح بعد
  /// التسجيل.
  _AuthStage _afterEnroll = _AuthStage.sportsSelection;

  void _goTo(_AuthStage stage) {
    // الجلسة حين تقوم (دخول/تسجيل) يستبدل `_AppEntry` هذه الشاشة فوراً، فقد
    // يصل نداء الانتقال بعد إسقاطها — بلا هذا الحارس يرمي setState بعد dispose.
    if (!mounted) return;
    context.auth.clearError();
    setState(() => _stage = stage);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_stage) {
      _AuthStage.welcome => WelcomePage(
          onRegister: () => _goTo(_AuthStage.language),
          onLogin: () => _goTo(_AuthStage.login),
          onBrowseAsGuest: context.auth.continueAsGuest,
        ),

      _AuthStage.login => LoginPage(
          // هاتف موثوق: دخل ببصمته والجلسة قائمة.
          onLoginSuccess: () => _goTo(_AuthStage.sportsSelection),
          // هاتف غير موثوق: رمز واتساب أولاً.
          onCodeSent: (phone, sent, {required rememberMe}) {
            _loginPhone = phone;
            _loginOtpSent = sent;
            _loginRememberMe = rememberMe;
            _goTo(_AuthStage.loginOtp);
          },
          onBack: () => _goTo(_AuthStage.welcome),
          onRegister: () => _goTo(_AuthStage.language),
        ),

      // الدخول يكتمل داخل الشاشة نفسها؛ بعده يسجّل بصمته فيصير الهاتف موثوقاً.
      _AuthStage.loginOtp => OtpPage(
          phone: _loginPhone,
          purpose: OtpPurpose.login,
          initial: _loginOtpSent!,
          rememberMe: _loginRememberMe,
          onVerified: (_) {
            _afterEnroll = _AuthStage.sportsSelection;
            _goTo(_AuthStage.enrollDevice);
          },
          onBack: () => _goTo(_AuthStage.login),
        ),

      _AuthStage.enrollDevice =>
        DeviceEnrollPage(onDone: () => _goTo(_afterEnroll)),

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
            // الحساب أُنشئ والجلسة قائمة — تُسجَّل البصمة قبل أي شيء آخر.
            _afterEnroll = _AuthStage.success;
            _goTo(_AuthStage.enrollDevice);
          },
          onBack: () => _goTo(_AuthStage.welcome),
        ),

      _AuthStage.success => RegistrationSuccessPage(
          roles: _registrationData.roles,
          onStart: widget.onLoginSuccess,
          // حساب مدرب/ملعب بلا دور لاعب لا يدخل التطبيق قبل موافقة الأدمن،
          // فنُنهي الجلسة ونعيده لتسجيل الدخول.
          onBackToLogin: () async {
            await context.auth.logout();
            if (mounted) _goTo(_AuthStage.welcome);
          },
        ),

    };
  }
}
