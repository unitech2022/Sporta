import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/otp_models.dart';
import '../../domain/entities/registration_data.dart';
import '../state/auth_scope.dart';
import '../pages/otp_page.dart';
import '../widgets/basic_info_step.dart';
import '../widgets/registration_nav.dart';
import '../widgets/role_details_step.dart';
import '../widgets/roles_step.dart';
import '../widgets/summary_step.dart';

/// The ordered stages of the registration flow. [roleDetails] is conditional —
/// it appears only when a coach or venue role is selected.
enum _RegStep { basicInfo, roles, roleDetails, summary }

class UnifiedRegistrationPage extends StatefulWidget {
  const UnifiedRegistrationPage({
    super.key,
    required this.onComplete,
    required this.onBack,
  });

  final ValueChanged<RegistrationData> onComplete;
  final VoidCallback onBack;

  @override
  State<UnifiedRegistrationPage> createState() =>
      _UnifiedRegistrationPageState();
}

class _UnifiedRegistrationPageState extends State<UnifiedRegistrationPage> {
  final _data = RegistrationData();
  final _step1FormKey = GlobalKey<FormState>();
  final _step1Key = GlobalKey<BasicInfoStepState>();
  final _roleDetailsFormKey = GlobalKey<FormState>();
  final _roleDetailsKey = GlobalKey<RoleDetailsStepState>();
  int _step = 1;
  String? _apiError;

  /// الرقم الذي صدرت التذكرة لأجله. تعديله بعد التحقق يُبطل التذكرة، فنعيد
  /// الإرسال بدل أن نسجّل الحساب على رقم لم يُثبت أحد ملكيته.
  String _verifiedPhone = '';

  /// The active steps for the current role selection (recomputed each build).
  List<_RegStep> get _steps => [
        _RegStep.basicInfo,
        _RegStep.roles,
        if (_data.needsRoleDetails) _RegStep.roleDetails,
        _RegStep.summary,
      ];

  int get _totalSteps => _steps.length;
  _RegStep get _currentStep => _steps[_step - 1];

  Future<void> _next() async {
    switch (_currentStep) {
      case _RegStep.basicInfo:
        final stepState = _step1Key.currentState;
        if (stepState == null || !stepState.validate()) return;
        // التحقق من الرقم هنا لا في النهاية: رفضُه بعد ملء نماذج المدرب ورفع
        // صور الهوية يعني ضياع كل ذلك على رقم كان يمكن كشفه في الخطوة الأولى.
        if (!await _verifyPhone()) return;
      case _RegStep.roles:
        if (_data.roles.isEmpty) return;
      case _RegStep.roleDetails:
        if (!(_roleDetailsKey.currentState?.validate() ?? false)) return;
      case _RegStep.summary:
        break;
    }

    // خطوة التحقق من الرقم تنتظر شاشةً كاملة، فقد تُترك الصفحة أثناءها.
    if (!mounted) return;

    if (_step < _totalSteps) {
      setState(() {
        _step++;
        _apiError = null;
      });
      return;
    }

    // Final step: call API.
    // التذكرة شرطٌ في الخادم؛ إرسال الطلب بدونها يعود بخطأ تحقق لا يفهمه
    // المستخدم. إن ضاعت — أو تغيّر الرقم بعد صدورها — نُعيد التحقق أولاً.
    if (_data.verificationToken.isEmpty ||
        _data.phone.trim() != _verifiedPhone) {
      if (!await _verifyPhone()) return;
      if (!mounted) return;
    }

    final auth = context.auth;
    var ok = await auth.register(_data);
    if (!mounted) return;

    // لا حساب في القاعدة قبل التحقق، والتذكرة تعيش دقائق معدودة قد تنقضي في
    // نماذج المدرب/الملعب الطويلة. انقضاؤها ليس خطأً يُعرض بل رمزٌ جديد
    // ومحاولة ثانية — وإلا وقف المستخدم أمام رفضٍ لا يعرف كيف يخرج منه.
    if (!ok && auth.errorCode == 'OTP_NOT_VERIFIED') {
      _data.verificationToken = '';
      _verifiedPhone = '';
      if (!await _verifyPhone()) return;
      if (!mounted) return;
      ok = await auth.register(_data);
      if (!mounted) return;
    }

    if (ok) {
      widget.onComplete(_data);
    } else {
      setState(() => _apiError = auth.errorMessage);
    }
  }

  /// يرسل رمزاً على واتساب ويفتح شاشة إدخاله، ويحفظ التذكرة عند النجاح.
  /// يُرجِع true إذا صار الرقم موثّقاً — أو كان موثّقاً من محاولة سابقة.
  Future<bool> _verifyPhone() async {
    final phone = _data.phone.trim();
    if (_data.verificationToken.isNotEmpty && phone == _verifiedPhone) {
      return true;
    }

    final auth = context.auth;
    final sent = await auth.requestOtp(phone, OtpPurpose.register);
    if (!mounted) return false;
    if (sent == null) {
      setState(() => _apiError = auth.errorMessage);
      return false;
    }

    final token = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => OtpPage(
          phone: phone,
          purpose: OtpPurpose.register,
          initial: sent,
          onVerified: (token) => Navigator.of(context).pop(token),
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (!mounted || token == null) return false;

    setState(() {
      _data.verificationToken = token;
      _verifiedPhone = phone;
      _apiError = null;
    });
    return true;
  }

  void _back() {
    if (_step > 1) {
      setState(() {
        _step--;
        _apiError = null;
      });
    } else {
      widget.onBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.auth;

    return Scaffold(
      body: Column(
        children: [
          RegistrationHeader(
            step: _step,
            totalSteps: _totalSteps,
            onBack: _back,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              child: _buildStep(),
            ),
          ),
          if (_apiError != null) _buildError(),
          RegistrationFooter(
            step: _step,
            totalSteps: _totalSteps,
            canProceed:
                _currentStep != _RegStep.roles || _data.roles.isNotEmpty,
            isLoading: auth.isLoading,
            onNext: _next,
            onBack: _back,
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    return switch (_currentStep) {
      _RegStep.basicInfo => BasicInfoStep(
          key: _step1Key,
          data: _data,
          formKey: _step1FormKey,
        ),
      _RegStep.roles => RolesStep(
          data: _data,
          onChanged: () => setState(() {}),
        ),
      _RegStep.roleDetails => RoleDetailsStep(
          key: _roleDetailsKey,
          data: _data,
          formKey: _roleDetailsFormKey,
        ),
      _RegStep.summary => SummaryStep(data: _data),
    };
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.destructive.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.destructive.withValues(alpha: 0.3)),
        ),
        child: Text(
          _apiError!,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.destructive),
        ),
      ),
    );
  }
}
