import '../domain/entities/court_entity.dart';
import '../../../core/localization/tr_global.dart';

/// تقدير محلي فقط: يُستخدم قبل وصول تسعير الخادم (POST /bookings/quote) أو حين
/// يتعذّر جلبه. السعر النهائي يأتي دائماً من الخادم لأنه وحده يعرف قواعد تسعير
/// المالك وخصم باقة اللاعب.
///
/// ساعات الذروة الافتراضية من ١٦:٠٠ — دقيقة فقط للملاعب التي لم يضبط مالكها
/// قواعد تسعير خاصة.
bool isPeakHour(String time) {
  final hour = int.tryParse(time.split(':').first) ?? 0;
  return hour >= 16;
}

/// Gross hourly rate (incl. نسبة سبورتا) for a slot starting at [time].
int slotPrice(CourtEntity court, String time) =>
    isPeakHour(time) ? court.peakHourPrice : court.totalPrice;

/// Total price for a session of [durationMinutes] starting at [time].
/// Prefers the owner's booking tier (matches the backend), falling back to the
/// legacy hourly computation when no tier is defined for the duration.
int sessionTotalPrice(CourtEntity court, String time, int durationMinutes) {
  final tier = court.bookingPriceFor(durationMinutes);
  if (tier != null) return tier.round();
  final hourly = slotPrice(court, time);
  // ملعب سعّره مالكه بالمدد وحدها: سعر ساعته صفر، فتُشتقّ من أطول شريحة —
  // نفس ما يفعله الخادم في CourtSchedule.BasePrice.
  if (hourly <= 0) {
    final longest = court.bookingPrices
        .where((t) => t.durationMinutes > 0 && t.price > 0)
        .fold<CourtPriceTier?>(
          null,
          (best, t) => best == null || t.durationMinutes > best.durationMinutes
              ? t
              : best,
        );
    if (longest != null) {
      return (longest.price / longest.durationMinutes * durationMinutes)
          .round();
    }
  }
  return (hourly * (durationMinutes / 60)).round();
}

String courtTypeLabel(CourtType type) {
  switch (type) {
    case CourtType.indoor:
      return trg('مغطى');
    case CourtType.outdoor:
      return trg('مفتوح');
  }
}

String courtGenderLabel(CourtGender gender) {
  switch (gender) {
    case CourtGender.all:
      return trg('مختلط');
    case CourtGender.men:
      return trg('رجال');
    case CourtGender.women:
      return trg('نساء');
    case CourtGender.family:
      return trg('عائلي');
  }
}

/// Client-side filtering/sorting applied on top of the courts returned by the
/// API (search text, price band, rating, sort order). The city is *not* handled
/// here — the API filters by it, so a local pass would only see the loaded page.
List<CourtEntity> filterCourts({
  required List<CourtEntity> courts,
  required String query,
  required String sortBy,
  required CourtType? selectedType,
  required CourtGender? selectedGender,
  required String priceRange,
  required String ratingFilter,
}) {
  List<CourtEntity> result = List.from(courts);

  if (query.isNotEmpty) {
    result = result
        .where((c) =>
            c.name.contains(query) ||
            c.city.contains(query) ||
            c.neighborhood.contains(query))
        .toList();
  }

  if (selectedType != null) {
    result = result.where((c) => c.type == selectedType).toList();
  }

  if (selectedGender != null) {
    result = result.where((c) => c.gender == selectedGender).toList();
  }

  switch (priceRange) {
    case 'low':
      result = result.where((c) => c.basePrice < 80).toList();
      break;
    case 'medium':
      result = result
          .where((c) => c.basePrice >= 80 && c.basePrice <= 110)
          .toList();
      break;
    case 'high':
      result = result.where((c) => c.basePrice > 110).toList();
      break;
  }

  switch (ratingFilter) {
    case '4+':
      result = result.where((c) => c.rating >= 4.0).toList();
      break;
    case '4.5+':
      result = result.where((c) => c.rating >= 4.5).toList();
      break;
  }

  switch (sortBy) {
    case 'rating':
      result.sort((a, b) => b.rating.compareTo(a.rating));
      break;
    case 'price':
      result.sort((a, b) => a.basePrice.compareTo(b.basePrice));
      break;
    case 'distance':
      result.sort((a, b) => a.distanceValue.compareTo(b.distanceValue));
      break;
  }

  return result;
}
