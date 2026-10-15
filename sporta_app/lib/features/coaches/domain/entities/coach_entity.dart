import 'coach_offer_entity.dart';
import '../../../../core/localization/tr_global.dart';

class CoachEntity {
  final String id;
  final String name;
  final String avatarInitials;

  /// الصورة الشخصية للمدرب (رابط نسبي من الخادم)، null إن لم يرفع صورة.
  final String? avatarUrl;
  final double rating;
  final int reviews;
  final int students;
  final int levelMin;
  final int levelMax;
  final String location;

  /// Distance from the player (km), sent by the backend when both sides have
  /// a saved location; null otherwise.
  final double? distanceKm;

  /// سعر الجلسة — كسريٌ كبقية المبالغ (التقريب كان يعرض ملعباً/مدرباً
  /// بأقل من ريال على أنه صفر).
  final double price;
  final List<String> specialties;
  final String badgeLabel;
  final String badgeType;
  final List<String> avatarGradientColors;

  /// "male" | "female" | "unknown" — drives the gender filter chips.
  final String gender;

  /// Raw free-text fields (used by the coach's own profile editor).
  final String? bio;
  final String? specialization;

  // ── حقول صفحة تفاصيل المدرب ────────────────────────────────────────────────
  /// اللعبة التي يدرّبها (بالعربية) — null إن لم تُضبط.
  final String? sportName;

  /// الشهادات والدورات كما كتبها المدرب.
  final String? certifications;

  /// "lessThanYear" | "oneToThree" | "threeToFive" | "moreThanFive".
  final String? experienceLevel;

  /// سعر الباقة (عدة جلسات) إن حدّده المدرب.
  final double? packagePrice;

  /// النادي الذي يدرّب فيه عادةً.
  final String? preferredVenueName;

  /// أيام التوفّر: "sat","sun","mon","tue","wed","thu","fri".
  final List<String> availableDays;

  /// أعلى خصم ساري من عروض المدرب، والسعر بعده.
  final int offerDiscountPercent;
  final double priceAfterOffer;
  bool isBooked;

  /// Active, non-expired offers/discounts (العروض والخصومات) — shown to
  /// players browsing this coach.
  final List<CoachOfferEntity> offers;

  CoachEntity({
    required this.id,
    required this.name,
    required this.avatarInitials,
    this.avatarUrl,
    required this.rating,
    required this.reviews,
    required this.students,
    required this.levelMin,
    required this.levelMax,
    required this.location,
    this.distanceKm,
    required this.price,
    required this.specialties,
    required this.badgeLabel,
    required this.badgeType,
    required this.avatarGradientColors,
    this.gender = 'unknown',
    this.bio,
    this.specialization,
    this.sportName,
    this.certifications,
    this.experienceLevel,
    this.packagePrice,
    this.preferredVenueName,
    this.availableDays = const [],
    this.offerDiscountPercent = 0,
    double? priceAfterOffer,
    this.isBooked = false,
    this.offers = const [],
  }) : priceAfterOffer = priceAfterOffer ?? price;

  /// Numeric backend id (the API uses ints; [id] keeps the string form used
  /// across the UI and navigation).
  int get numericId => int.tryParse(id) ?? 0;

  /// Maps a backend `CoachDto`. Fields the backend doesn't model yet
  /// (level range, distance, avatar gradient) fall back to sensible defaults
  /// and the badge is derived from verification/gender.
  factory CoachEntity.fromJson(Map<String, dynamic> json) {
    final name = localizedServerName(json['name'], json['nameEn']);
    final isVerified = json['isVerified'] == true;
    final gender = json['gender']?.toString();
    final (badgeType, badgeLabel) = _badge(isVerified, gender);

    return CoachEntity(
      id: json['id'].toString(),
      name: name,
      avatarInitials: _initials(name),
      avatarUrl: json['avatarUrl']?.toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviews: (json['reviews'] as num?)?.toInt() ?? 0,
      students: (json['students'] as num?)?.toInt() ?? 0,
      // Level range isn't modelled on the backend yet.
      levelMin: 1,
      levelMax: 7,
      location: localizedServerName(json['city'], json['cityEn']),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      price: (json['hourlyRate'] as num?)?.toDouble() ?? 0,
      specialties:
          (json['specialties'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      badgeLabel: badgeLabel,
      badgeType: badgeType,
      avatarGradientColors: const ['#2AB5CE', '#1E9AB0'],
      gender: gender ?? 'unknown',
      bio: json['bio']?.toString(),
      specialization: json['specialization']?.toString(),
      sportName: json['sportName'] == null
          ? null
          : localizedServerName(json['sportName'], json['sportNameEn']),
      certifications: json['certifications']?.toString(),
      experienceLevel: json['experienceLevel']?.toString(),
      packagePrice: (json['packagePrice'] as num?)?.toDouble(),
      preferredVenueName: json['preferredVenueName']?.toString(),
      availableDays:
          (json['availableDays'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      offerDiscountPercent:
          (json['offerDiscountPercent'] as num?)?.round() ?? 0,
      priceAfterOffer: (json['hourlyRateAfterOffer'] as num?)?.toDouble(),
      offers: CoachOfferEntity.listFrom(json['offers']),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p.substring(0, 1)).join('.');
  }

  static (String, String) _badge(bool isVerified, String? gender) {
    if (isVerified) return ('certified', trg('معتمد'));
    if (gender == 'female') return ('women', trg('نساء'));
    return ('pro', trg('محترف'));
  }
}
