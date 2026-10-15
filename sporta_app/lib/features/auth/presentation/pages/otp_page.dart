import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../data/models/otp_models.dart';
import '../state/auth_scope.dart';
import '../widgets/auth_form_fields.dart';
import '../widgets/circle_back_button.dart';
import '../widgets/glass_panel.dart';
import '../../../../core/utils/system_insets.dart';

/// شاشة إدخال رمز التحقق المُرسل على واتساب. تخدم كل الأغراض:
/// [OtpPurpose.login] تُنهي الدخول بنفسها وتستدعي [onVerified] بنص فارغ، وبقية
/// الأغراض تُبدّل الرمز بتذكرة تمرّرها للخطوة التالية.
///
/// الإرسال الأول يقع في الشاشة السابقة (هي من تعرف الرقم وتتحقق منه)، ونتيجته
/// تصل هنا في [initial] — منها مهلة إعادة الإرسال والقناة التي وصل عبرها.
class OtpPage extends StatefulWidget {
  const OtpPage({
    super.key,
    required this.phone,
    required this.purpose,
    required this.initial,
    required this.onVerified,
    required this.onBack,
    this.rememberMe = true,
  });

  final String phone;
  final OtpPurpose purpose;

  /// نتيجة الإرسال الأول، كما عادت من الشاشة السابقة.
  final OtpRequested initial;

  /// تُستدعى بعد نجاح التحقق: التذكرة للأغراض التي يليها إجراء، ونصّ فارغ
  /// لغرض الدخول (فالجلسة تكون قد بدأت فعلاً).
  final ValueChanged<String> onVerified;

  final VoidCallback onBack;

  /// تُمرَّر لتسجيل الدخول وحده.
  final bool rememberMe;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  /// عدد الخانات يأتي من الخادم مع نتيجة الإرسال — لا يُثبَّت هنا. تثبيتُه على
  /// ٦ بينما يرسل المزوّد ٤ يعني شاشةً لا تقبل الرمز الواصل إطلاقاً.
  late int _length;

  late List<TextEditingController> _controllers;
  late List<FocusNode> _nodes;

  Timer? _timer;
  int _resendSeconds = 0;

  /// يمنع تكرار التحقق التلقائي حين يعيد المستخدم تحرير الخانات أثناء الطلب.
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _length = widget.initial.codeLength.clamp(4, 8);
    _controllers = List.generate(_length, (_) => TextEditingController());
    _nodes = List.generate(_length, (_) => FocusNode());
    _startResendTimer(widget.initial.resendAfterSeconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  /// خادم التطوير يعيد الرمز في الردّ، فنملأه ليُختبر المسار بلا رسالة. في
  /// الإنتاج يعود `null` فلا يحدث شيء.
  void _startResendTimer(int seconds) {
    _timer?.cancel();
    setState(() => _resendSeconds = seconds);
    if (seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) t.cancel();
      });
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  bool get _canResend => _resendSeconds <= 0;

  /// يوزّع ما أُدخل على الخانات. الحالة الشائعة حرف واحد، لكن لصق الرمز كاملاً
  /// من إشعار واتساب يصل كنصّ في خانة واحدة — فيُفرَّق على ما بعدها.
  void _onDigitChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length > 1) {
      for (var i = 0; i + index < _length && i < digits.length; i++) {
        _controllers[index + i].text = digits[i];
      }
      final last = (index + digits.length).clamp(0, _length - 1);
      _nodes[last].requestFocus();
    } else {
      _controllers[index].text = digits;
      if (digits.isNotEmpty && index < _length - 1) {
        _nodes[index + 1].requestFocus();
      } else if (digits.isEmpty && index > 0) {
        _nodes[index - 1].requestFocus();
      }
    }

    setState(() {});

    // إكمال الخانات هو نية التحقق — لا معنى لزرٍّ إضافي بعده. الزر يبقى
    // لمن رجع وعدّل خانة، ولمن فشلت محاولته الأولى.
    if (_otp.length == _length) {
      FocusScope.of(context).unfocus();
      _verify();
    }
  }

  Future<void> _verify() async {
    if (_otp.length != _length || _submitting) return;
    setState(() => _submitting = true);

    final auth = context.auth;
    var succeeded = false;
    try {
      if (widget.purpose == OtpPurpose.login) {
        succeeded = await auth.loginWithOtp(
          phone: widget.phone,
          otp: _otp,
          rememberMe: widget.rememberMe,
        );
        if (!mounted) return;
        if (succeeded) widget.onVerified('');
      } else {
        final token =
            await auth.verifyOtpForPurpose(widget.phone, _otp, widget.purpose);
        if (!mounted) return;
        succeeded = token != null;
        if (succeeded) widget.onVerified(token);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }

    // فشلت المحاولة: تُفرَّغ الخانات ويعود التركيز لأولها. بدون هذا تبقى
    // ممتلئة بالرمز الخاطئ، والتحقق التلقائي لا يُعاد إطلاقه لأن الطول مكتمل
    // أصلاً — فيضطر المستخدم لمسح كل خانة بيده وقد نفدت محاولاته.
    if (!succeeded && mounted) _clearBoxes();
  }

  void _clearBoxes() {
    for (final c in _controllers) {
      c.clear();
    }
    _nodes.first.requestFocus();
    setState(() {});
  }

  Future<void> _resend() async {
    if (!_canResend) return;

    final result = await context.auth.requestOtp(widget.phone, widget.purpose);
    if (!mounted) return;
    if (result == null) return;

    setState(() {
      // قد يعود الطول مختلفاً (رقم اختبار برمز ثابت، أو قالب تغيّر بين
      // الطلبين)، فتُعاد الخانات بدل تركها على طول لا يقبل ما وصل.
      final length = result.codeLength.clamp(4, 8);
      if (length != _length) {
        for (final c in _controllers) {
          c.dispose();
        }
        for (final n in _nodes) {
          n.dispose();
        }
        _length = length;
        _controllers = List.generate(_length, (_) => TextEditingController());
        _nodes = List.generate(_length, (_) => FocusNode());
      } else {
        for (final c in _controllers) {
          c.clear();
        }
      }
    });
    _nodes.first.requestFocus();
    _startResendTimer(result.resendAfterSeconds);
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
                        '${context.trArgs('otpDesc', {'n': '$_length'})} ${widget.phone}',
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
        children: List.generate(_length, (i) {
          return SizedBox(
            width: 44,
            height: 54,
            child: TextField(
              controller: _controllers[i],
              focusNode: _nodes[i],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              // خانة واحدة بحدّ أقصى حرف تمنع اللصق؛ نسمح بأكثر ونوزّعه بأنفسنا.
              maxLength: _length,
              autofocus: i == 0,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) => _onDigitChanged(i, v),
              style:
                  AppTextStyles.heading2.copyWith(color: AppColors.secondary),
              decoration: InputDecoration(
                counterText: '',
                fillColor: Colors.white,
                filled: true,
                contentPadding: EdgeInsets.zero,
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
        onPressed: (isLoading || _otp.length != _length) ? null : _verify,
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
