import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStorage {
  static const _store = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kRememberMe = 'remember_me';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required bool rememberMe,
  }) async {
    await _store.write(key: _kAccessToken, value: accessToken);
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

  static Future<bool> hasRememberMe() async {
    final v = await _store.read(key: _kRememberMe);
    return v == '1';
  }

  static Future<void> clearAll() => _store.deleteAll();
}
