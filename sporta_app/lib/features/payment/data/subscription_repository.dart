import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../auth/data/models/api_exception.dart';
import '../domain/entities/subscription_entity.dart';

/// Talks to the subscription REST endpoints (Sporta Plus).
class SubscriptionRepository {
  SubscriptionRepository(this._dio);

  final Dio _dio;

  Future<SubscriptionEntity> fetch() => _get(ApiEndpoints.subscription);

  /// كل أنواع الاشتراك المفعّلة، بأسعارها بعد خصم هذا المستخدم إن وُجد.
  Future<List<PackageEntity>> fetchPackages() => _guard(() async {
        final data = _unwrap((await _dio.get(
          ApiEndpoints.subscriptionPackages,
        )).data);
        return (data as List? ?? const [])
            .map((e) => PackageEntity.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  /// [packageId] فارغ يعني الاشتراك الافتراضي (توافقاً مع النسخ القديمة).
  Future<SubscriptionEntity> subscribe({int? packageId}) => _post(
        ApiEndpoints.subscribe,
        body: packageId == null ? null : {'packageId': packageId},
      );

  Future<SubscriptionEntity> cancel() => _post(ApiEndpoints.subscriptionCancel);

  // ── helpers ────────────────────────────────────────────────────────────────

  Future<SubscriptionEntity> _get(String path) =>
      _guard(() async => SubscriptionEntity.fromJson(
          _unwrap((await _dio.get(path)).data) as Map<String, dynamic>));

  Future<SubscriptionEntity> _post(String path, {Object? body}) =>
      _guard(() async => SubscriptionEntity.fromJson(
          _unwrap((await _dio.post(path, data: body)).data)
              as Map<String, dynamic>));

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
