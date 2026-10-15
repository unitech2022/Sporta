import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/api_endpoints.dart';

/// بيانات الجهاز الموثوق: معرّفه وسرّه والرقم الذي سُجّل له. السرّ لا يُقرأ إلا
/// بعد بصمة نظام التشغيل (انظر `AuthCubit.loginWithDevice`).
class DeviceCredential {
  const DeviceCredential({
    required this.deviceId,
    required this.secret,
    required this.phone,
  });

  final String deviceId;
  final String secret;
  final String phone;
}

abstract class SecureStorage {
  static const _store = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// سرّ الجهاز يجب ألّا ينتقل مع نسخة iCloud الاحتياطية إلى هاتف آخر — وإلا
  /// صار «الجهاز الموثوق» أيَّ هاتف استُعيدت عليه النسخة.
  static const _thisDeviceOnly = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kRememberMe = 'remember_me';
  static const _kSessionApiBase = 'session_api_base';
  static const _kDeviceId = 'device_id';
  static const _kDeviceSecret = 'device_secret';
  static const _kDevicePhone = 'device_phone';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required bool rememberMe,
  }) async {
    await _store.write(key: _kAccessToken, value: accessToken);
    // الخادم الذي أصدر التوكنات — انظر [discardSessionFromOtherApi].
    await _store.write(key: _kSessionApiBase, value: ApiEndpoints.baseUrl);
    if (rememberMe) {
      await _store.write(key: _kRefreshToken, value: refreshToken);
      await _store.write(key: _kRememberMe, value: '1');
    } else {
      await _store.delete(key: _kRefreshToken);
      await _store.delete(key: _kRememberMe);
    }
  }

  static Future<void> updateAccessToken(String accessToken) =>
      _store.write(key: _kAccessToken, value: accessToken);

  static Future<String?> getAccessToken() => _store.read(key: _kAccessToken);

  static Future<String?> getRefreshToken() => _store.read(key: _kRefreshToken);

  /// جلسة محفوظة لخادم غير الحالي (التطبيق يُشغَّل على الإنتاج افتراضياً،
  /// وعلى الخادم المحلي بـ `--dart-define`) لا تصلح هنا: توكناتها ترفض كلها
  /// أو — أسوأ — يُعرض مستخدم مخزَّن من خادم آخر. تُمسح وتُعامَل كأنها غير
  /// موجودة. يُرجِع true إن مُسحت. الجلسة القديمة بلا ختم (قبل هذا الحقل)
  /// تُختم بالخادم الحالي بدل إخراج كل المستخدمين عند التحديث.
  static Future<bool> discardSessionFromOtherApi() async {
    final saved = await _store.read(key: _kSessionApiBase);
    final current = ApiEndpoints.baseUrl;
    if (saved == current) return false;
    if (saved == null) {
      if (await _store.read(key: _kAccessToken) != null) {
        await _store.write(key: _kSessionApiBase, value: current);
      }
      return false;
    }
    await clearSession();
    return true;
  }

  static Future<bool> hasRememberMe() async {
    final v = await _store.read(key: _kRememberMe);
    return v == '1';
  }

  // ── الجهاز الموثوق ──────────────────────────────────────────────────────────

  /// معرّف ثابت لهذا التثبيت، يُولَّد مرة واحدة. لا نعتمد على معرّفات النظام
  /// (تتغيّر، وتحتاج حزماً إضافية) — العشوائي يكفي لأن السرّ هو ما يُثبت الهوية.
  static Future<String> getOrCreateDeviceId() async {
    final existing = await _store.read(key: _kDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final rng = Random.secure();
    final id = List.generate(
      16,
      (_) => rng.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await _store.write(key: _kDeviceId, value: id, iOptions: _thisDeviceOnly);
    return id;
  }

  static Future<void> saveDeviceCredential(DeviceCredential c) async {
    await _store.write(
      key: _kDeviceId,
      value: c.deviceId,
      iOptions: _thisDeviceOnly,
    );
    await _store.write(
      key: _kDeviceSecret,
      value: c.secret,
      iOptions: _thisDeviceOnly,
    );
    await _store.write(
      key: _kDevicePhone,
      value: c.phone,
      iOptions: _thisDeviceOnly,
    );
  }

  static Future<DeviceCredential?> getDeviceCredential() async {
    final id = await _store.read(key: _kDeviceId, iOptions: _thisDeviceOnly);
    final secret = await _store.read(
      key: _kDeviceSecret,
      iOptions: _thisDeviceOnly,
    );
    final phone = await _store.read(
      key: _kDevicePhone,
      iOptions: _thisDeviceOnly,
    );
    if (id == null || secret == null || phone == null) return null;
    return DeviceCredential(deviceId: id, secret: secret, phone: phone);
  }

  /// يُبقي معرّف الجهاز (ليُعاد تسجيله بنفس الصفّ في الخادم) ويمسح السرّ.
  static Future<void> clearDeviceCredential() async {
    await _store.delete(key: _kDeviceSecret, iOptions: _thisDeviceOnly);
    await _store.delete(key: _kDevicePhone, iOptions: _thisDeviceOnly);
  }

  // ── مسح ────────────────────────────────────────────────────────────────────

  /// تسجيل الخروج: تُمسح الجلسة ويبقى الجهاز موثوقاً، فيعود صاحبه ببصمته
  /// بلا رمز واتساب.
  static Future<void> clearSession() async {
    await _store.delete(key: _kAccessToken);
    await _store.delete(key: _kRefreshToken);
    await _store.delete(key: _kRememberMe);
    await _store.delete(key: _kSessionApiBase);
  }

  /// حذف الحساب: لا يبقى شيء.
  static Future<void> clearAll() => _store.deleteAll();
}
