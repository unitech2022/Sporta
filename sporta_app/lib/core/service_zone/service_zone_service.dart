import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../di/service_locator.dart';
import '../localization/tr_global.dart';
import '../network/api_endpoints.dart';

/// نتيجة فحص موقع ضد مناطق الخدمة (`GET /service-zones/check`).
class ServiceZoneCheck {
  const ServiceZoneCheck({
    required this.hasZones,
    required this.insideServiceArea,
    this.messageAr = '',
    this.messageEn = '',
  });

  /// «لا نعرف» — لا موقع أو فشل الشبكة. يُعامل كـ «لا حجب».
  static const unknown = ServiceZoneCheck(
    hasZones: false,
    insideServiceArea: true,
  );

  final bool hasZones;
  final bool insideServiceArea;
  final String messageAr;
  final String messageEn;

  bool get isOutside => hasZones && !insideServiceArea;

  /// رسالة اللوحة بلغة التطبيق، وإلا النص الافتراضي.
  String get message {
    final custom = localizedServerName(messageAr, messageEn);
    return custom.isNotEmpty ? custom : trg('أنت حالياً خارج نطاق خدمة التطبيق');
  }

  factory ServiceZoneCheck.fromJson(Map<String, dynamic> json) =>
      ServiceZoneCheck(
        hasZones: json['hasZones'] == true,
        insideServiceArea: json['insideServiceArea'] != false,
        messageAr: json['messageAr'] as String? ?? '',
        messageEn: json['messageEn'] as String? ?? '',
      );
}

/// حالة نطاق الخدمة الجغرافي للمستخدم الحالي.
///
/// مصدر الموقع بالترتيب:
///   1. الموقع المحفوظ في الحساب — لا يحتاج صلاحية.
///   2. آخر موقع GPS معروف، وفقط إن كانت الصلاحية ممنوحة مسبقاً. لا نطلب
///      الصلاحية من أجل هذا الفحص: من رفضها يبقى بلا حجب.
///
/// قاعدة الفشل الآمن: أي خطأ شبكة أو غياب موقع = [ServiceZoneCheck.unknown]،
/// فلا يُقفل التطبيق بسبب عطل مؤقت — نفس سياسة بوابة الصيانة.
class ServiceZoneService {
  ServiceZoneService._();

  static final ServiceZoneService instance = ServiceZoneService._();

  final ValueNotifier<ServiceZoneCheck> _notifier =
      ValueNotifier<ServiceZoneCheck>(ServiceZoneCheck.unknown);

  ValueListenable<ServiceZoneCheck> get listenable => _notifier;

  /// The in-flight check, if any.
  Future<void>? _running;

  /// Latest request received while a check was running. Only the newest one
  /// matters (it replaces older queued ones) and it runs right after the
  /// current check — never dropped, since the caller already recorded these
  /// coordinates as checked.
  ({double? lat, double? lng})? _queued;

  /// Bumped by [reset] so a check that was in flight can't overwrite it.
  int _generation = 0;

  /// يعيد الفحص بإحداثيات الحساب إن وُجدت، وإلا بآخر موقع GPS معروف.
  /// إن كان فحص جارياً تُحفظ آخر إحداثيات وتُفحص بعده مباشرة.
  Future<void> refresh({double? lat, double? lng}) {
    final running = _running;
    if (running != null) {
      _queued = (lat: lat, lng: lng);
      return running;
    }
    final run = _drain((lat: lat, lng: lng));
    _running = run;
    return run.whenComplete(() => _running = null);
  }

  Future<void> _drain(({double? lat, double? lng}) first) async {
    ({double? lat, double? lng})? next = first;
    while (next != null) {
      final gen = _generation;
      final result = await _check(next.lat, next.lng);
      // A newer request is queued → this result is already stale.
      if (gen == _generation && _queued == null) _notifier.value = result;
      next = _queued;
      _queued = null;
    }
  }

  Future<ServiceZoneCheck> _check(double? lat, double? lng) async {
    var point = (lat != null && lng != null) ? (lat, lng) : null;
    point ??= await _lastKnownGps();
    if (point == null) return ServiceZoneCheck.unknown;
    return (await probe(point.$1, point.$2)) ?? ServiceZoneCheck.unknown;
  }

  void reset() {
    _queued = null;
    _generation++;
    _notifier.value = ServiceZoneCheck.unknown;
  }

  /// فحص نقطة بعينها دون تغيير الحالة العامة — لشاشة اختيار الموقع.
  /// يعيد null عند الفشل.
  Future<ServiceZoneCheck?> probe(double lat, double lng) async {
    try {
      final res = await getIt<Dio>().get(
        ApiEndpoints.serviceZoneCheck,
        queryParameters: {'lat': lat, 'lng': lng},
      );
      final body = res.data;
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      return ServiceZoneCheck.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (_) {
      return null;
    }
  }

  Future<(double, double)?> _lastKnownGps() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return null;
      }
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final last = await Geolocator.getLastKnownPosition();
      return last == null ? null : (last.latitude, last.longitude);
    } catch (_) {
      return null;
    }
  }
}
