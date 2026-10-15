import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// غلاف رقيق حول [LocalAuthentication] لبصمة الإصبع / الوجه.
///
/// البصمة لا تغادر الهاتف أبداً — النظام يقارنها ويخبرنا بنجاح أو فشل فقط.
/// لذا «تسجيل البصمة» في التطبيق يعني: ربط الحساب بهذا الجهاز بسرٍّ لا يُفرَج
/// عنه إلا بعد أن يجتاز صاحبه فحص البصمة.
/// على الويب لا تنفيذ لـ local_auth، وما يرميه هو `MissingPluginException`
/// وليس `PlatformException` فلا تلتقطه الـ catch أدناه — لذا تُحسم كل دالة
/// بـ [kIsWeb] أولاً، وإلا بقيت شاشة تسجيل البصمة معلّقة بزرٍّ معطّل.
abstract class BiometricService {
  static final _auth = LocalAuthentication();

  /// هل يملك الهاتف عتاد بصمة وسجّل المستخدم بصمة واحدة على الأقل؟
  static Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// نوع البصمة الأساسي، لتسمية الزر («بصمة الوجه» أو «البصمة»).
  static Future<BiometricType?> primaryType() async {
    if (kIsWeb) return null;
    try {
      final types = await _auth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) return BiometricType.face;
      if (types.contains(BiometricType.fingerprint)) {
        return BiometricType.fingerprint;
      }
      if (types.contains(BiometricType.strong)) return BiometricType.strong;
      return types.isNotEmpty ? types.first : null;
    } on PlatformException {
      return null;
    }
  }

  /// هل للهاتف قفل أصلاً (بصمة أو رمز/نمط)؟ هاتفٌ بلا قفل لا يُقبل: لا شيء
  /// يمنع من يحمله من فتح التطبيق باسم صاحبه.
  static Future<bool> hasDeviceLock() async {
    if (kIsWeb) return false;
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// يطلب من النظام إثبات أن حامل الهاتف هو صاحبه: **بصمة حين تكون مسجّلة،
  /// وإلا رمز قفل الشاشة**. وهاتفٌ بلا قفل إطلاقاً يعود false ولا يمرّ —
  /// لا جلسة تبدأ بلا تحقق فعلي من النظام.
  /// الإلغاء أو أي خطأ يعود false ولا يرمي.
  static Future<bool> confirmOwner(String reason) async {
    if (kIsWeb) return false;
    try {
      if (!await hasDeviceLock()) return false;
      // البصمة حين تكون مسجّلة تُطلب وحدها؛ وإلا يُقبل رمز القفل بديلاً.
      final biometricOnly = await isAvailable();
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
