import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/auth/biometric_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../state/auth_scope.dart';
import '../widgets/auth_form_fields.dart';
import '../widgets/glass_panel.dart';
import '../../../../core/utils/system_insets.dart';

/// تسجيل بصمة صاحب الحساب على هذا الهاتف — خطوة إلزامية بعد إنشاء الحساب
/// وبعد أول دخول برمز على هاتف جديد. بعدها يدخل ببصمته وحدها، ولا يدخل أحد
/// برقمه من هاتف آخر دون رمز واتساب.
///
/// لا زرّ تخطٍّ: الحماية كلها تقوم على أن كل جلسة بدأت من هاتف مسجّل.
class DeviceEnrollPage extends StatefulWidget {
  const DeviceEnrollPage({super.key, required this.onDone, this.onSkip});

  final VoidCallback onDone;

  /// مخرج لا يظهر إلا حين يتعذّر الربط أصلاً: هاتف بلا قفل، أو فشل متكرر من
  /// الخادم. بدونه يقف صاحب الحساب أمام شاشة لا زرّ فيها يتقدّم به — وهو ما
  /// ترفضه مراجعة App Store (2.1) قبل أن يزعج المستخدم.
  final VoidCallback? onSkip;

  @override
  State<DeviceEnrollPage> createState() => _DeviceEnrollPageState();
}

class _DeviceEnrollPageState extends State<DeviceEnrollPage> {
  bool? _biometricAvailable;

  /// هل للهاتف قفل أصلاً؟ بلا قفل لا يُربط الجهاز إطلاقاً.
  bool _hasLock = true;
  BiometricType? _type;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final available = await BiometricService.isAvailable();
    final hasLock = available || await BiometricService.hasDeviceLock();
    final type = available ? await BiometricService.primaryType() : null;
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _hasLock = hasLock;
      _type = type;
    });
  }

  Future<void> _enroll() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await context.auth.enrollThisDevice();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final available = _biometricAvailable;
    final isFace = _type == BiometricType.face;

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
              children: [
                const SizedBox(height: AppSizes.xxxl),
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFace ? Icons.face_outlined : Icons.fingerprint,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSizes.xxl),
                Text(
                  context.tr(isFace ? 'enrollFaceTitle' : 'enrollDeviceTitle'),
                  style: AppTextStyles.heading1.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.xxl),
                GlassPanel(
                  child: Column(
                    children: [
                      Text(
                        context.tr(
                          !_hasLock
                              ? 'enrollDeviceNoLockDesc'
                              : available == false
                                  ? 'enrollDeviceNoBiometricDesc'
                                  : 'enrollDeviceDesc',
                        ),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white, height: 1.6),
                        textAlign: TextAlign.center,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppSizes.md),
                        AuthErrorBanner(message: _error!),
                      ],
                      const SizedBox(height: AppSizes.xl),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          // لا يُعرض الزر قبل معرفة حالة البصمة، وإلا تغيّر
                          // نصّه تحت إصبع المستخدم.
                          // بلا قفل شاشة لا تسجيل: الزر يعيد الفحص بعد أن
                          // يفعّله المستخدم من إعدادات هاتفه.
                          onPressed: (_busy || available == null)
                              ? null
                              : (_hasLock ? _enroll : _init),
                          icon: _busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  isFace ? Icons.face_outlined : Icons.fingerprint,
                                  color: Colors.white,
                                ),
                          label: Text(
                            _busy
                                ? ''
                                : context.tr(!_hasLock
                                    ? 'enrollDeviceRecheck'
                                    : available == false
                                        ? 'enrollDeviceContinue'
                                        : 'enrollDeviceButton'),
                            style: AppTextStyles.heading3
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                      if (widget.onSkip != null && (!_hasLock || _error != null)) ...[
                        const SizedBox(height: AppSizes.sm),
                        TextButton(
                          onPressed: _busy ? null : widget.onSkip,
                          child: Text(
                            context.tr('enrollSkipForNow'),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                              decoration: TextDecoration.underline,
                              decorationColor:
                                  Colors.white.withValues(alpha: 0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
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
