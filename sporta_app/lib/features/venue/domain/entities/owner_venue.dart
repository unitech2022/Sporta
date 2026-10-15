import '../../../../core/localization/tr_global.dart';

/// A minimal venue entry for a picker (e.g. coach registration's "preferred
/// training venue" field), from the public `/venues/options` endpoint.
class VenueOption {
  const VenueOption({required this.id, required this.name, required this.city});

  final int id;
  final String name;
  final String city;

  factory VenueOption.fromJson(Map<String, dynamic> json) => VenueOption(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name']?.toString() ?? '',
    city: json['city']?.toString() ?? '',
  );
}

/// A single duration→price tier set by the owner. Matches use these same
/// booking tiers, split evenly across players.
class CourtTier {
  const CourtTier({required this.durationMinutes, required this.price});

  final int durationMinutes;
  final double price;

  factory CourtTier.fromJson(Map<String, dynamic> json) => CourtTier(
    durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
    price: (json['price'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'durationMinutes': durationMinutes,
    'price': price,
  };

  static List<CourtTier> listFrom(dynamic raw) =>
      (raw as List?)
          ?.map((e) => CourtTier.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [];
}

/// دوام الملعب في يوم واحد من أيام الأسبوع (0 = الأحد … 6 = السبت).
class CourtOpeningHour {
  const CourtOpeningHour({
    required this.day,
    this.isClosed = false,
    this.openHour = 6,
    this.closeHour = 24,
  });

  final int day;
  final bool isClosed;

  /// ساعة الفتح (0–23)، شاملة.
  final int openHour;

  /// ساعة الإغلاق (1–24)، غير شاملة.
  final int closeHour;

  static const dayNames = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  String get dayLabel => trg(dayNames[day % 7]);

  String get rangeLabel => isClosed
      ? trg('مغلق')
      : '${openHour.toString().padLeft(2, '0')}:00 - '
            '${closeHour.toString().padLeft(2, '0')}:00';

  CourtOpeningHour copyWith({bool? isClosed, int? openHour, int? closeHour}) =>
      CourtOpeningHour(
        day: day,
        isClosed: isClosed ?? this.isClosed,
        openHour: openHour ?? this.openHour,
        closeHour: closeHour ?? this.closeHour,
      );

  factory CourtOpeningHour.fromJson(Map<String, dynamic> json) =>
      CourtOpeningHour(
        day: (json['day'] as num?)?.toInt() ?? 0,
        isClosed: json['isClosed'] == true,
        openHour: (json['openHour'] as num?)?.toInt() ?? 6,
        closeHour: (json['closeHour'] as num?)?.toInt() ?? 24,
      );

  Map<String, dynamic> toJson() => {
    'day': day,
    'isClosed': isClosed,
    'openHour': openHour,
    'closeHour': closeHour,
  };

  /// سبعة أيام بالدوام الافتراضي — أساس الشاشة قبل تحميل أي بيانات.
  static List<CourtOpeningHour> defaultWeek() => [
    for (var d = 0; d < 7; d++) CourtOpeningHour(day: d),
  ];

  static List<CourtOpeningHour> listFrom(dynamic raw) {
    final rows =
        (raw as List?)
            ?.map((e) => CourtOpeningHour.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <CourtOpeningHour>[];
    if (rows.isEmpty) return defaultWeek();
    // الخادم يرسل الأيام السبعة، لكن نُكمل أي نقص حتى لا تنكسر الشاشة.
    return [
      for (var d = 0; d < 7; d++)
        rows.firstWhere(
          (r) => r.day == d,
          orElse: () => CourtOpeningHour(day: d),
        ),
    ];
  }
}

/// قاعدة تسعير حسب اليوم والوقت: ‎+50‎ تعني زيادة 50% على السعر الأساسي.
class CourtPriceRule {
  const CourtPriceRule({
    this.day,
    required this.startHour,
    required this.endHour,
    this.adjustmentPercent = 0,
    this.hourlyPrice,
  });

  /// 0 = الأحد … 6 = السبت، أو null لكل الأيام.
  final int? day;
  final int startHour;
  final int endHour;
  final double adjustmentPercent;

  /// سعر ساعة ثابت لهذا النطاق (سعر المالك) — null يعني قاعدة بالنسبة.
  final double? hourlyPrice;

  bool get isFixedPrice => hourlyPrice != null;

  /// سعر ساعة المالك في هذا النطاق من سعره الأساسي.
  double rateFrom(double basePrice) =>
      hourlyPrice ?? basePrice * (100 + adjustmentPercent) / 100;

  String get dayLabel =>
      day == null ? trg('كل الأيام') : trg(CourtOpeningHour.dayNames[day! % 7]);

  String get rangeLabel =>
      '${startHour.toString().padLeft(2, '0')}:00 - '
      '${endHour.toString().padLeft(2, '0')}:00';

  /// السعر الثابت («100 ر.س/ساعة») أو النسبة («+25%»).
  String get adjustmentLabel {
    if (hourlyPrice != null) {
      final v = hourlyPrice! == hourlyPrice!.roundToDouble()
          ? hourlyPrice!.toStringAsFixed(0)
          : hourlyPrice!.toStringAsFixed(2);
      return trgArgs('{p0} ر.س/ساعة', {'p0': v});
    }
    final sign = adjustmentPercent >= 0 ? '+' : '';
    return '$sign${adjustmentPercent.toStringAsFixed(0)}%';
  }

  CourtPriceRule copyWith({
    int? day,
    bool clearDay = false,
    int? startHour,
    int? endHour,
    double? adjustmentPercent,
    double? hourlyPrice,
    bool clearHourlyPrice = false,
  }) => CourtPriceRule(
    day: clearDay ? null : (day ?? this.day),
    startHour: startHour ?? this.startHour,
    endHour: endHour ?? this.endHour,
    adjustmentPercent: adjustmentPercent ?? this.adjustmentPercent,
    hourlyPrice: clearHourlyPrice ? null : (hourlyPrice ?? this.hourlyPrice),
  );

  /// يتداخل مع قاعدة أخرى لنفس اليوم؟ (الخادم يرفض التداخل).
  bool overlaps(CourtPriceRule o) =>
      day == o.day && startHour < o.endHour && o.startHour < endHour;

  factory CourtPriceRule.fromJson(Map<String, dynamic> json) => CourtPriceRule(
    day: (json['day'] as num?)?.toInt(),
    startHour: (json['startHour'] as num?)?.toInt() ?? 0,
    endHour: (json['endHour'] as num?)?.toInt() ?? 24,
    adjustmentPercent: (json['adjustmentPercent'] as num?)?.toDouble() ?? 0,
    hourlyPrice: (json['hourlyPrice'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'day': day,
    'startHour': startHour,
    'endHour': endHour,
    'adjustmentPercent': isFixedPrice ? 0 : adjustmentPercent,
    'hourlyPrice': ?hourlyPrice,
  };

  static List<CourtPriceRule> listFrom(dynamic raw) =>
      (raw as List?)
          ?.map((e) => CourtPriceRule.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [];
}

/// A court owned by the venue owner (management view).
class OwnerCourt {
  const OwnerCourt({
    required this.id,
    required this.name,
    required this.type,
    required this.pricePerHour,
    required this.isAvailable,
    this.courtCount = 1,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.bookingTiers = const [],
    this.openingHours = const [],
    this.priceRules = const [],
  });

  final int id;
  final String name;

  /// "indoor" | "outdoor".
  final String type;

  /// عدد الملاعب — number of identical physical courts.
  final int courtCount;
  final double pricePerHour;
  final bool isAvailable;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;

  /// Owner-set booking price tiers (duration → price).
  final List<CourtTier> bookingTiers;

  /// دوام الأسبوع — سبعة صفوف (الأحد → السبت).
  final List<CourtOpeningHour> openingHours;

  /// قواعد التسعير حسب اليوم والوقت — فارغة تعني سعراً موحّداً.
  final List<CourtPriceRule> priceRules;

  String get typeLabel => type == 'outdoor' ? trg('خارجي') : trg('داخلي');

  /// ملخص الدوام لعرضه في بطاقة الملعب، مثل "يومياً 06:00 - 24:00" أو
  /// "دوام مختلف حسب اليوم".
  String get scheduleSummary {
    final open = openingHours.where((h) => !h.isClosed).toList();
    if (open.isEmpty) return trg('مغلق طوال الأسبوع');

    final sameHours = open.every(
      (h) =>
          h.openHour == open.first.openHour &&
          h.closeHour == open.first.closeHour,
    );
    if (!sameHours) return trg('دوام مختلف حسب اليوم');

    final closedDays = openingHours.where((h) => h.isClosed).toList();
    final range = open.first.rangeLabel;
    if (closedDays.isEmpty) return trgArgs('يومياً {p0}', {'p0': range});
    return trgArgs('{p0} · مغلق {p1}', {
      'p0': range,
      'p1': closedDays.map((d) => d.dayLabel).join('، '),
    });
  }

  factory OwnerCourt.fromJson(Map<String, dynamic> json) => OwnerCourt(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name']?.toString() ?? '',
    type: json['type']?.toString() ?? 'indoor',
    courtCount: (json['courtCount'] as num?)?.toInt() ?? 1,
    pricePerHour: (json['pricePerHour'] as num?)?.toDouble() ?? 0,
    isAvailable: json['isAvailable'] == true,
    imageUrl: json['imageUrl']?.toString(),
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    bookingTiers: CourtTier.listFrom(json['bookingTiers']),
    openingHours: CourtOpeningHour.listFrom(json['openingHours']),
    priceRules: CourtPriceRule.listFrom(json['priceRules']),
  );
}

/// A venue owned by the user, with its courts.
class OwnerVenue {
  const OwnerVenue({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.genderPolicy,
    required this.courts,
    this.district,
    this.imageUrl,
    this.imageUrls = const [],
    this.isApproved = false,
  });

  final int id;
  final String name;
  final String city;
  final String? district;
  final String address;
  final String? imageUrl;
  final List<String> imageUrls;

  /// لا يظهر الملعب للاعبين حتى توافق عليه الإدارة.
  final bool isApproved;

  /// "men" | "womenOnly" | "familyOnly".
  final String genderPolicy;
  final List<OwnerCourt> courts;

  String get genderLabel => switch (genderPolicy) {
    'womenOnly' => trg('نساء فقط'),
    'familyOnly' => trg('عائلات فقط'),
    _ => trg('رجال'),
  };

  factory OwnerVenue.fromJson(Map<String, dynamic> json) => OwnerVenue(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name']?.toString() ?? '',
    city: json['city']?.toString() ?? '',
    district: json['district']?.toString(),
    address: json['address']?.toString() ?? '',
    imageUrl: json['imageUrl']?.toString(),
    imageUrls:
        (json['imageUrls'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
    genderPolicy: json['genderPolicy']?.toString() ?? 'men',
    isApproved: json['isApproved'] == true,
    courts:
        (json['courts'] as List?)
            ?.map((e) => OwnerCourt.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}

/// أسعار النادي حسب الوقت — `GET /venues/{id}/pricing`.
class VenuePricing {
  const VenuePricing({
    required this.venueId,
    required this.venueName,
    required this.courts,
  });

  final int venueId;
  final String venueName;
  final List<VenuePricingCourt> courts;

  factory VenuePricing.fromJson(Map<String, dynamic> json) => VenuePricing(
    venueId: (json['venueId'] as num?)?.toInt() ?? 0,
    venueName: json['venueName']?.toString() ?? '',
    courts: [
      for (final c in (json['courts'] as List? ?? const []))
        VenuePricingCourt.fromJson(c as Map<String, dynamic>),
    ],
  );
}

class VenuePricingCourt {
  const VenuePricingCourt({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.commissionPercent,
    required this.openingHours,
    required this.priceRules,
  });

  final int id;
  final String name;

  /// سعر الساعة الأساسي (سعر المالك قبل نسبة سبورتا).
  final double basePrice;
  final double commissionPercent;
  final List<CourtOpeningHour> openingHours;
  final List<CourtPriceRule> priceRules;

  factory VenuePricingCourt.fromJson(Map<String, dynamic> json) =>
      VenuePricingCourt(
        id: (json['id'] as num).toInt(),
        name: localizedServerName(json['name'], json['nameEn']),
        basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
        commissionPercent:
            (json['sportaCommissionPercent'] as num?)?.toDouble() ?? 0,
        openingHours: CourtOpeningHour.listFrom(json['openingHours']),
        priceRules: CourtPriceRule.listFrom(json['priceRules']),
      );
}
