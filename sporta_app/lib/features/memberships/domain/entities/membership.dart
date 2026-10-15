import '../../../../core/localization/tr_global.dart';

double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;
int? _i(dynamic v) => (v as num?)?.toInt();

/// تواريخ العضوية تُخزَّن بتوقيت UTC وقد تصل بلا لاحقة Z.
DateTime _utc(dynamic v) {
  final s = v?.toString() ?? '';
  if (s.isEmpty) return DateTime.now();
  final hasZone = s.endsWith('Z') || RegExp(r'[+-]\d\d:\d\d$').hasMatch(s);
  return DateTime.parse(hasZone ? s : '${s}Z').toLocal();
}

/// حصة اللاعب في حدث بعد خصم عضويته في النادي: السعر الأصلي وما سيُخصم فعلاً.
class MemberShareQuote {
  const MemberShareQuote({
    required this.price,
    required this.amount,
    this.discount = 0,
    this.planName,
  });

  /// بلا عضوية (أو تعذّر السؤال): السعر كما هو.
  const MemberShareQuote.full(double price) : this(price: price, amount: price);

  final double price;
  final double amount;
  final double discount;
  final String? planName;

  bool get hasDiscount => discount > 0;

  factory MemberShareQuote.fromJson(Map<String, dynamic> j) => MemberShareQuote(
    price: _d(j['price']),
    amount: _d(j['amount']),
    discount: _d(j['discount']),
    planName: j['membershipPlanName']?.toString(),
  );
}

/// خطة عضوية شهرية يعرضها النادي: خصم على الحجز (بسقف ساعات اختياري)
/// وأيام أولوية في الحجز المسبق.
class MembershipPlan {
  const MembershipPlan({
    required this.id,
    required this.venueId,
    required this.name,
    this.nameAr = '',
    this.nameEn,
    this.description,
    required this.monthlyPrice,
    required this.discountPercent,
    this.monthlyDiscountHours,
    required this.priorityDays,
    this.isActive = true,
    this.activeMembers = 0,
  });

  final int id;
  final int venueId;

  /// الاسم بلغة الواجهة.
  final String name;

  /// الاسمان كما حفظهما المالك (للتعديل).
  final String nameAr;
  final String? nameEn;
  final String? description;
  final double monthlyPrice;
  final double discountPercent;

  /// سقف ساعات الخصم في الشهر (null = بلا حد).
  final int? monthlyDiscountHours;
  final int priorityDays;
  final bool isActive;
  final int activeMembers;

  factory MembershipPlan.fromJson(Map<String, dynamic> j) => MembershipPlan(
    id: _i(j['id']) ?? 0,
    venueId: _i(j['venueId']) ?? 0,
    name: localizedServerName(j['name'], j['nameEn']),
    nameAr: j['name']?.toString() ?? '',
    nameEn: j['nameEn']?.toString(),
    description: j['description']?.toString(),
    monthlyPrice: _d(j['monthlyPrice']),
    discountPercent: _d(j['discountPercent']),
    monthlyDiscountHours: _i(j['monthlyDiscountHours']),
    priorityDays: _i(j['priorityDays']) ?? 0,
    isActive: j['isActive'] != false,
    activeMembers: _i(j['activeMembers']) ?? 0,
  );

  static List<MembershipPlan> listFrom(dynamic v) => [
    for (final e in (v as List? ?? const []))
      MembershipPlan.fromJson(e as Map<String, dynamic>),
  ];
}

/// عضوية اللاعب في نادٍ: لقطة من شروط الخطة وقت الاشتراك/التجديد.
class Membership {
  const Membership({
    required this.id,
    required this.planId,
    required this.venueId,
    required this.venueName,
    this.venueImageUrl,
    required this.planName,
    required this.price,
    required this.discountPercent,
    this.monthlyDiscountHours,
    required this.priorityDays,
    required this.periodStart,
    required this.periodEnd,
    required this.autoRenew,
    required this.isActive,
    this.usedDiscountMinutes = 0,
  });

  final int id;
  final int planId;
  final int venueId;
  final String venueName;
  final String? venueImageUrl;
  final String planName;
  final double price;
  final double discountPercent;
  final int? monthlyDiscountHours;
  final int priorityDays;
  final DateTime periodStart;
  final DateTime periodEnd;
  final bool autoRenew;
  final bool isActive;
  final int usedDiscountMinutes;

  /// دقائق الخصم المتبقية هذا الشهر (null = بلا سقف).
  int? get remainingMinutes => monthlyDiscountHours == null
      ? null
      : (monthlyDiscountHours! * 60 - usedDiscountMinutes).clamp(0, 1 << 30);

  factory Membership.fromJson(Map<String, dynamic> j) => Membership(
    id: _i(j['id']) ?? 0,
    planId: _i(j['planId']) ?? 0,
    venueId: _i(j['venueId']) ?? 0,
    venueName: localizedServerName(j['venueName'], j['venueNameEn']),
    venueImageUrl: j['venueImageUrl']?.toString(),
    planName: j['planName']?.toString() ?? '',
    price: _d(j['price']),
    discountPercent: _d(j['discountPercent']),
    monthlyDiscountHours: _i(j['monthlyDiscountHours']),
    priorityDays: _i(j['priorityDays']) ?? 0,
    periodStart: _utc(j['periodStart']),
    periodEnd: _utc(j['periodEnd']),
    autoRenew: j['autoRenew'] == true,
    isActive: j['isActive'] == true,
    usedDiscountMinutes: _i(j['usedDiscountMinutes']) ?? 0,
  );
}

/// ما يراه اللاعب في صفحة الملعب عن عضويات ناديه.
class VenueMembership {
  const VenueMembership({
    required this.venueId,
    required this.venueName,
    this.bookingWindowDays,
    this.myBookingWindowDays,
    this.plans = const [],
    this.myMembership,
    this.isOwnVenue = false,
  });

  final int venueId;
  final String venueName;

  /// المستخدم مالك النادي — يرى الخطط بلا زر اشتراك.
  final bool isOwnVenue;
  final int? bookingWindowDays;
  final int? myBookingWindowDays;
  final List<MembershipPlan> plans;
  final Membership? myMembership;

  factory VenueMembership.fromJson(Map<String, dynamic> j) => VenueMembership(
    venueId: _i(j['venueId']) ?? 0,
    venueName: localizedServerName(j['venueName'], j['venueNameEn']),
    bookingWindowDays: _i(j['bookingWindowDays']),
    myBookingWindowDays: _i(j['myBookingWindowDays']),
    plans: MembershipPlan.listFrom(j['plans']),
    myMembership: j['myMembership'] is Map<String, dynamic>
        ? Membership.fromJson(j['myMembership'] as Map<String, dynamic>)
        : null,
    isOwnVenue: j['isOwnVenue'] == true,
  );
}

/// لوحة المالك: الخطط والأعضاء ونافذة الحجز.
class VenueMembers {
  const VenueMembers({
    required this.venueId,
    this.bookingWindowDays,
    required this.sportaFeePercent,
    this.plans = const [],
    this.members = const [],
    this.monthlyRevenue = 0,
  });

  final int venueId;
  final int? bookingWindowDays;
  final double sportaFeePercent;
  final List<MembershipPlan> plans;
  final List<VenueMember> members;

  /// صافي ما استلمه المالك من العضويات هذا الشهر.
  final double monthlyRevenue;

  factory VenueMembers.fromJson(Map<String, dynamic> j) => VenueMembers(
    venueId: _i(j['venueId']) ?? 0,
    bookingWindowDays: _i(j['bookingWindowDays']),
    sportaFeePercent: _d(j['sportaFeePercent']),
    plans: MembershipPlan.listFrom(j['plans']),
    members: [
      for (final e in (j['members'] as List? ?? const []))
        VenueMember.fromJson(e as Map<String, dynamic>),
    ],
    monthlyRevenue: _d(j['monthlyRevenue']),
  );
}

class VenueMember {
  const VenueMember({
    required this.membershipId,
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.level,
    required this.planName,
    required this.periodEnd,
    required this.autoRenew,
    this.usedDiscountMinutes = 0,
    this.monthlyDiscountHours,
  });

  final int membershipId;
  final int userId;
  final String name;
  final String? avatarUrl;
  final int? level;
  final String planName;
  final DateTime periodEnd;
  final bool autoRenew;
  final int usedDiscountMinutes;
  final int? monthlyDiscountHours;

  factory VenueMember.fromJson(Map<String, dynamic> j) => VenueMember(
    membershipId: _i(j['membershipId']) ?? 0,
    userId: _i(j['userId']) ?? 0,
    name: j['name']?.toString() ?? '',
    avatarUrl: j['avatarUrl']?.toString(),
    level: _i(j['level']),
    planName: j['planName']?.toString() ?? '',
    periodEnd: _utc(j['periodEnd']),
    autoRenew: j['autoRenew'] == true,
    usedDiscountMinutes: _i(j['usedDiscountMinutes']) ?? 0,
    monthlyDiscountHours: _i(j['monthlyDiscountHours']),
  );
}
