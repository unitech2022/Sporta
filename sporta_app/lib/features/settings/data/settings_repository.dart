import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../auth/data/models/api_exception.dart';
import '../domain/setting_entity.dart';

/// Talks to `GET /api/settings/public` — the admin-managed, non-sensitive
/// settings (maintenance mode, force-update version, policy text, support
/// contact...) consumed by the app.
class SettingsRepository {
  SettingsRepository(this._dio);

  final Dio _dio;

  /// Map keyed by setting `key` for convenient lookup.
  Future<Map<String, SettingEntity>> fetchPublicSettings() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.publicSettings);
      final data = _unwrap(res.data) as List;
      final settings = data
          .map((e) => SettingEntity.fromJson(e as Map<String, dynamic>))
          .toList();
      return {for (final s in settings) s.key: s};
    });
  }

  /// نقاط المكافآت المخصومة عن كل انسحاب من حدث (`points_withdrawal_penalty`).
  /// غير مضبوط على الخادم أو تعذّر جلبه ← القيمة الافتراضية 10. تُحفظ بعد أول
  /// جلب ناجح طوال الجلسة.
  Future<int> withdrawalPenaltyPoints() async {
    final cached = _withdrawalPenalty;
    if (cached != null) return cached;
    try {
      final res = await _dio.get(
        '${ApiEndpoints.publicSettings}/points_withdrawal_penalty',
      );
      final data = _unwrap(res.data);
      final value = int.tryParse(
        (data is Map ? data['valueAr'] : null)?.toString().trim() ?? '',
      );
      return _withdrawalPenalty = value ?? defaultWithdrawalPenalty;
    } catch (_) {
      return defaultWithdrawalPenalty;
    }
  }

  static const int defaultWithdrawalPenalty = 10;
  int? _withdrawalPenalty;

  dynamic _unwrap(dynamic body) =>
      body is Map<String, dynamic> ? (body['data'] ?? body) : body;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw e.response != null
          ? ApiException.fromResponse(e.response!)
          : ApiException.network;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException.unexpected;
    }
  }
}
