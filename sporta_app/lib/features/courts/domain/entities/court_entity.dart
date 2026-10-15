import '../../../../core/localization/tr_global.dart';

enum CourtType { indoor, outdoor }

enum CourtGender { all, men, women, family }

/// A single duration→price tier defined by the venue owner. Matches use these
/// same booking tiers, split evenly across players.
class CourtPriceTier {
  const CourtPriceTier({
    required this.durationMinutes,
    required this.price,
    this.basePrice = 0,
  });

  final int durationMinutes;

  /// الإجمالي — gross price (base + نسبة سبورتا); what the player pays.
  final double price;

  /// السعر الأساسي — the owner-set price before the Sporta markup.
  final double basePrice;

  factory CourtPriceTier.fromJson(Map<String, dynamic> json) => CourtPriceTier(
    durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
    price: (json['price'] as num?)?.toDouble() ?? 0,
    basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
  );

  static List<CourtPriceTier> listFrom(dynamic raw) =>
      (raw as List?)
          ?.map((e) => CourtPriceTier.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [];
}

/// دوام يوم واحد من أيام الأسبوع، كما يعرضه ملف الملعب للاعب. نسخة للعرض فقط
/// من دوام الملعب الذي يحرّره المالك.
class CourtDaySchedule {
  const CourtDaySchedule({
    required this.day,
    this.isClosed = false,
    this.openHour = 6,
    this.closeHour = 24,
  });

  /// 0 = الأحد … 6 = السبت.
  final int day;
  final bool isClosed;

  /// ساعة الفتح (0–23) شاملة، وساعة الإغلاق (1–24) غير شاملة.
  final int openHour;
  final int closeHour;

  static const _dayNames = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  String get dayLabel => trg(_dayNames[day % 7]);

  String get rangeLabel => isClosed
      ? trg('مغلق')
      : '${openHour.toString().padLeft(2, '0')}:00 - '
            '${closeHour.toString().padLeft(2, '0')}:00';

  factory CourtDaySchedule.fromJson(Map<String, dynamic> json) =>
      CourtDaySchedule(
        day: (json['day'] as num?)?.toInt() ?? 0,
        isClosed: json['isClosed'] == true,
        openHour: (json['openHour'] as num?)?.toInt() ?? 6,
        closeHour: (json['closeHour'] as num?)?.toInt() ?? 24,
      );

  /// Sunday-first week; an empty/short list from the API is left as-is so the
  /// UI can hide the section instead of inventing a schedule.
  static List<CourtDaySchedule> listFrom(dynamic raw) {
    final rows =
        (raw as List?)
            ?.map((e) => CourtDaySchedule.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <CourtDaySchedule>[];
    rows.sort((a, b) => a.day.compareTo(b.day));
    return rows;
  }
}

class TimeSlot {
  final String time;
  final bool isBooked;

  const TimeSlot({required this.time, required this.isBooked});
}

class CourtEntity {
  final String id;
  final String name;

  /// اسم النادي المالك للملعب.
  final String venueName;

  /// صورة الملعب (مسار نسبي من الخادم أو رابط كامل).
  final String? imageUrl;

  final double rating;
  final int reviews;
  final String distance;
  final double distanceValue;
  final String city;

  /// الحي — as chosen by the venue owner from the districts list. Empty for
  /// older venues created before districts existed.
  final String district;

  final String neighborhood;

  /// المنطقة كما تُعرض في البطاقات المختصرة: الحي (وله اسم إنجليزي في جدول
  /// الأحياء) وإلا العنوان الحر — وهو نص عربي كتبه المالك ولا يُترجم.
  String get areaLabel => district.trim().isNotEmpty ? district : neighborhood;

  final String country;
  final CourtType type;

  /// عدد الملاعب — number of identical physical courts; the player picks a
  /// court number in 1..courtCount when booking.
  final int courtCount;
  final CourtGender gender;

  /// السعر الأساسي — owner-set hourly rate before the Sporta markup.
  final int basePrice;

  /// نسبة سبورتا — platform markup (%) added on top of the base price.
  final double sportaCommissionPercent;

  /// الإجمالي — gross hourly rate (base + نسبة سبورتا); what the player pays.
  final int totalPrice;

  /// Gross peak hourly rate (incl. نسبة سبورتا).
  final int peakHourPrice;

  /// أدنى سعر ساعة يدفعه اللاعب فعلاً (ساعات الخصم).
  final int lowestPrice;

  /// دوام الملعب لكل يوم من أيام الأسبوع (فارغ إن لم يرسله الخادم).
  final List<CourtDaySchedule> openingHours;
  final List<String> availableTimes;
  final List<int> availableDurations;
  final List<String> facilities;
  final bool isAvailable;
  final double? latitude;
  final double? longitude;

  /// Owner-set booking price tiers (duration → price).
  final List<CourtPriceTier> bookingPrices;

  /// هل أضافه المستخدم لمفضّلته؟ يأتي من الخادم مع كل بطاقة.
  final bool isFavorite;

  /// فترات أسعار المالك حسب الوقت (فارغة = سعر موحّد).
  final List<CourtPriceBand> priceBands;

  /// النادي الذي يتبعه الملعب (لعضويات النادي).
  final int venueId;

  /// أقصى عدد أيام مقدماً يُسمح فيها للمستخدم الحالي بالحجز (نافذة النادي
  /// + أيام أولوية عضويته). null = بلا حد.
  final int? bookingWindowDays;

  /// المستخدم الحالي عضو فعّال في نادي هذا الملعب.
  final bool isMember;

  /// بحث الملاعب بالوقت: المواعيد الفارغة (HH:mm) داخل النافذة المطلوبة.
  /// null حين لم يُطلب بحث بالوقت.
  final List<String>? freeSlots;

  /// بحث الملاعب بالوقت: أقل سعر يدفعه اللاعب للمدة المطلوبة داخل النافذة.
  final int? fromPrice;

  CourtEntity({
    required this.id,
    required this.name,
    this.venueName = '',
    this.imageUrl,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.distanceValue,
    required this.city,
    this.district = '',
    required this.neighborhood,
    required this.country,
    required this.type,
    this.courtCount = 1,
    required this.gender,
    required this.basePrice,
    this.sportaCommissionPercent = 0,
    int? totalPrice,
    required this.peakHourPrice,
    int? lowestPrice,
    this.openingHours = const [],
    required this.availableTimes,
    required this.availableDurations,
    required this.facilities,
    this.isAvailable = true,
    this.latitude,
    this.longitude,
    this.bookingPrices = const [],
    this.isFavorite = false,
    this.priceBands = const [],
    this.venueId = 0,
    this.bookingWindowDays,
    this.isMember = false,
    this.freeSlots,
    this.fromPrice,
  }) : totalPrice = totalPrice ?? basePrice,
       lowestPrice = lowestPrice ?? totalPrice ?? basePrice;

  bool get hasLocation => latitude != null && longitude != null;

  /// The owner-set booking price for [duration], or null if none.
  double? bookingPriceFor(int duration) {
    for (final t in bookingPrices) {
      if (t.durationMinutes == duration) return t.price;
    }
    return null;
  }

  /// Numeric backend id (the API uses ints; [id] keeps the string form used
  /// across the UI and navigation).
  int get numericId => int.tryParse(id) ?? 0;

  factory CourtEntity.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => (v as num?)?.round() ?? 0;

    // The API reports proximity as `distanceKm` (km from the requesting
    // user, null when either side has no saved location).
    final distanceKm = (json['distanceKm'] as num?)?.toDouble();

    return CourtEntity(
      id: json['id'].toString(),
      name: localizedServerName(json['name'], json['nameEn']),
      venueName: localizedServerName(json['venueName'], json['venueNameEn']),
      imageUrl: (json['imageUrl']?.toString().isNotEmpty ?? false)
          ? json['imageUrl'].toString()
          : null,
      // Rating/reviews/facilities are not yet modelled on the backend.
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviews: asInt(json['reviews']),
      distance:
          json['distance']?.toString() ??
          (distanceKm != null ? trgArgs('{p0} كم', {'p0': distanceKm}) : ''),
      distanceValue:
          (json['distanceValue'] as num?)?.toDouble() ?? distanceKm ?? 0,
      city: localizedServerName(json['city'], json['cityEn']),
      district: localizedServerName(json['district'], json['districtEn']),
      neighborhood: json['neighborhood']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      type: json['type']?.toString() == 'outdoor'
          ? CourtType.outdoor
          : CourtType.indoor,
      courtCount: (json['courtCount'] as num?)?.toInt() ?? 1,
      gender: _genderFromString(json['gender']?.toString()),
      basePrice: asInt(json['basePrice']),
      sportaCommissionPercent:
          (json['sportaCommissionPercent'] as num?)?.toDouble() ?? 0,
      totalPrice: json['totalPrice'] == null ? null : asInt(json['totalPrice']),
      peakHourPrice: asInt(json['peakHourPrice']),
      lowestPrice: json['lowestPrice'] == null
          ? null
          : asInt(json['lowestPrice']),
      openingHours: CourtDaySchedule.listFrom(json['openingHours']),
      availableTimes:
          (json['availableTimes'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      availableDurations:
          (json['availableDurations'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [60, 90, 120],
      facilities:
          (json['facilities'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      isAvailable: json['isAvailable'] != false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      bookingPrices: CourtPriceTier.listFrom(json['bookingPrices']),
      isFavorite: json['isFavorite'] == true,
      venueId: asInt(json['venueId']),
      bookingWindowDays: (json['bookingWindowDays'] as num?)?.toInt(),
      isMember: json['isMember'] == true,
      freeSlots: (json['freeSlots'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      fromPrice: json['fromPrice'] == null ? null : asInt(json['fromPrice']),
      priceBands: CourtPriceBand.listFrom(
        json['priceRules'],
        basePrice: asInt(json['basePrice']).toDouble(),
        commissionPercent:
            (json['sportaCommissionPercent'] as num?)?.toDouble() ?? 0,
      ),
    );
  }

  static CourtGender _genderFromString(String? value) {
    switch (value) {
      case 'men':
        return CourtGender.men;
      case 'women':
        return CourtGender.women;
      case 'family':
        return CourtGender.family;
      default:
        return CourtGender.all;
    }
  }
}

/// فترة سعر للعرض على اللاعب: اليوم ونطاق الساعات وسعر الساعة الذي يدفعه
/// (شاملاً نسبة سبورتا).
class CourtPriceBand {
  const CourtPriceBand({
    required this.day,
    required this.startHour,
    required this.endHour,
    required this.playerRate,
  });

  /// 0 = الأحد … 6 = السبت، أو null لكل الأيام.
  final int? day;
  final int startHour;
  final int endHour;
  final double playerRate;

  static const _dayNames = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  String get dayLabel =>
      day == null ? trg('كل الأيام') : trg(_dayNames[day! % 7]);

  String get rangeLabel =>
      '${startHour.toString().padLeft(2, '0')}:00 - '
      '${endHour.toString().padLeft(2, '0')}:00';

  /// [basePrice] سعر الساعة الأساسي كما يدفعه اللاعب (شاملاً النسبة)؛
  /// السعر الثابت في القاعدة سعر المالك فتُضاف إليه نسبة سبورتا.
  static List<CourtPriceBand> listFrom(
    dynamic raw, {
    required double basePrice,
    required double commissionPercent,
  }) {
    final list = <CourtPriceBand>[];
    for (final e in (raw as List? ?? const [])) {
      final m = e as Map<String, dynamic>;
      final fixed = (m['hourlyPrice'] as num?)?.toDouble();
      final pct = (m['adjustmentPercent'] as num?)?.toDouble() ?? 0;
      list.add(
        CourtPriceBand(
          day: (m['day'] as num?)?.toInt(),
          startHour: (m['startHour'] as num?)?.toInt() ?? 0,
          endHour: (m['endHour'] as num?)?.toInt() ?? 24,
          playerRate: fixed != null
              ? fixed * (100 + commissionPercent) / 100
              : basePrice * (100 + pct) / 100,
        ),
      );
    }
    return list;
  }
}
