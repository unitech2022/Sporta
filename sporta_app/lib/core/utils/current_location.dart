import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng;

/// أقصى خطأ أفقي (بالأمتار) نعتبره «دقيقاً» فنتوقف عن انتظار عيّنات أفضل.
const _goodEnoughAccuracyMeters = 25.0;

/// أقصى زمن ننتظر فيه عيّنات GPS قبل أن نكتفي بأفضل ما وصل.
const _sampleWindow = Duration(seconds: 15);

/// The device's current GPS position, or null if location is off or the user
/// declined permission. Shared so callers don't each re-implement the
/// service-enabled / permission dance.
///
/// الدقة أولوية: الموقع يُخزَّن في الحساب ويُبنى عليه ترتيب «الأقرب إليك»،
/// فقراءة تقريبية من أبراج الشبكة أو أول عيّنة قديمة من الكاش لا تكفي.
Future<LatLng?> currentDeviceLocation() async {
  if (!await Geolocator.isLocationServiceEnabled()) return null;

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null;
  }

  // iOS 14+: لو اختار المستخدم «موقع تقريبي» (Precise Location off) فكل ما
  // يصلنا دائرة نصف قطرها كيلومترات. نطلب الدقة الكاملة مؤقتاً لهذه الجلسة؛
  // مفتاح الغرض معرّف في Info.plist تحت NSLocationTemporaryUsageDescriptionDictionary.
  try {
    if (await Geolocator.getLocationAccuracy() ==
        LocationAccuracyStatus.reduced) {
      await Geolocator.requestTemporaryFullAccuracy(purposeKey: 'ExactLocation');
    }
  } catch (_) {
    // أندرويد أو إصدار أقدم — لا شيء يُفعل.
  }

  // أول قراءة من GPS غالباً قديمة أو خشنة (كاش/شبكة) ثم تتحسّن خلال ثوانٍ.
  // نستمع للتيار ونحتفظ بالأدقّ حتى نبلغ دقة كافية أو تنتهي المهلة.
  final best = await _bestSample();
  if (best != null) return LatLng(best.latitude, best.longitude);

  // لم يصل أي شيء من التيار (نادر): قراءة واحدة مباشرة ثم آخر موقع معروف.
  try {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return LatLng(pos.latitude, pos.longitude);
  } catch (_) {
    try {
      final last = await Geolocator.getLastKnownPosition();
      return last == null ? null : LatLng(last.latitude, last.longitude);
    } catch (_) {
      return null;
    }
  }
}

Future<Position?> _bestSample() async {
  Position? best;
  StreamSubscription<Position>? sub;
  final done = Completer<void>();
  try {
    sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen(
      (p) {
        if (best == null || p.accuracy < best!.accuracy) best = p;
        if (p.accuracy <= _goodEnoughAccuracyMeters && !done.isCompleted) {
          done.complete();
        }
      },
      onError: (_) {
        if (!done.isCompleted) done.complete();
      },
      onDone: () {
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future.timeout(_sampleWindow, onTimeout: () {});
  } catch (_) {
    // يسقط إلى القراءة المباشرة في المستدعي.
  } finally {
    await sub?.cancel();
  }
  return best;
}
