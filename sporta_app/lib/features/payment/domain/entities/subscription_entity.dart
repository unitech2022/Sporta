import '../../../../core/localization/tr_global.dart';

/// نوع اشتراك معروض في شاشة «الاشتراكات» — كما ضبطه الأدمن في لوحة التحكم.
class PackageEntity {
  const PackageEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.priceAfterDiscount,
    required this.discountPercent,
    required this.durationDays,
    this.period = 'monthly',
    this.features = const [],
    this.pointsMultiplier = 1,
    this.bookingDiscountPercent = 0,
    this.welcomePoints = 0,
    this.commissionDiscountPercent = 0,
    this.commissionPercent = 0,
  });

  final int id;
  final String name;

  /// السعر قبل الخصم (يُشطب في الواجهة حين يوجد خصم).
  final double price;

  /// ما سيُخصم فعلاً من المحفظة.
  final double priceAfterDiscount;
  final double discountPercent;
  final int durationDays;

  /// "monthly" | "yearly" | "commission" — نوع الاشتراك كما ضبطه الأدمن.
  final String period;

  bool get isYearly => period == 'yearly';

  /// «بالنسبة»: بلا رسوم مقدَّمة وبلا تاريخ انتهاء — سبورتا تأخذ نسبة من كل
  /// عملية بدل الاشتراك الثابت.
  bool get isCommission => period == 'commission';

  /// تسمية النوع للعرض.
  String get periodLabel =>
      isCommission ? trg('بالنسبة') : (isYearly ? trg('سنوي') : trg('شهري'));

  /// المميزات النصية التي يكتبها الأدمن.
  final List<String> features;

  // مزايا مهيكلة تُطبَّق فعلياً على المشتركين.
  final double pointsMultiplier;
  final double bookingDiscountPercent;
  final int welcomePoints;

  /// نسبة تخفيض عمولة سبورتا على المشترك (مدرب/مالك ملعب).
  final double commissionDiscountPercent;

  /// نسبة سبورتا من كل عملية — لنوع «بالنسبة» فقط.
  final double commissionPercent;

  bool get hasDiscount =>
      !isCommission && discountPercent > 0 && priceAfterDiscount < price;

  /// كل المزايا مجمَّعة للعرض: المهيكلة أولاً ثم النصية.
  List<String> get allBenefits => [
        if (isCommission)
          trgArgs('سبورتا تأخذ {p0}% من كل عملية بدل رسوم الاشتراك', {'p0': fmt(commissionPercent)}),
        if (pointsMultiplier > 1)
          trgArgs('نقاط ولاء مضاعفة ×{p0} على كل نشاط', {'p0': fmt(pointsMultiplier)}),
        if (bookingDiscountPercent > 0)
          trgArgs('خصم {p0}% على حجوزات الملاعب', {'p0': fmt(bookingDiscountPercent)}),
        if (welcomePoints > 0) trgArgs('{p0} نقطة ترحيبية عند الاشتراك', {'p0': welcomePoints}),
        if (!isCommission && commissionDiscountPercent > 0)
          trgArgs('خصم {p0}% على عمولة سبورتا من مستحقاتك', {'p0': fmt(commissionDiscountPercent)}),
        ...features,
      ];

  /// يعرض الرقم بلا كسور عندما يكون صحيحاً (2 بدل 2.0).
  static String fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  factory PackageEntity.fromJson(Map<String, dynamic> json) {
    final price = (json['price'] as num?)?.toDouble() ?? 0;
    return PackageEntity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      price: price,
      priceAfterDiscount:
          (json['priceAfterDiscount'] as num?)?.toDouble() ?? price,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
      durationDays: (json['duration'] as num?)?.toInt() ?? 30,
      period: json['period']?.toString() ?? 'monthly',
      features: (json['features'] as List?)
              ?.map((f) => f.toString())
              .where((f) => f.trim().isNotEmpty)
              .toList() ??
          const [],
      pointsMultiplier: (json['pointsMultiplier'] as num?)?.toDouble() ?? 1,
      bookingDiscountPercent:
          (json['bookingDiscountPercent'] as num?)?.toDouble() ?? 0,
      welcomePoints: (json['welcomePoints'] as num?)?.toInt() ?? 0,
      commissionDiscountPercent:
          (json['commissionDiscountPercent'] as num?)?.toDouble() ?? 0,
      commissionPercent: (json['commissionPercent'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// The user's Sporta Plus subscription state.
class SubscriptionEntity {
  const SubscriptionEntity({
    required this.plan,
    required this.isActive,
    required this.endDate,
    required this.monthlyPrice,
    this.packageId,
    this.packageName = '',
    this.period = 'monthly',
    this.features = const [],
    this.pointsMultiplier = 1,
    this.bookingDiscountPercent = 0,
    this.welcomePoints = 0,
  });

  /// "free" | "plus".
  final String plan;
  final bool isActive;
  final DateTime? endDate;
  final double monthlyPrice;

  /// معرّف الاشتراك الجاري (null للحساب المجاني).
  final int? packageId;

  /// اسم الاشتراك ومميزاته كما ضبطها الأدمن في لوحة التحكم.
  final String packageName;

  /// "monthly" | "yearly" | "commission".
  final String period;

  bool get isCommission => period == 'commission';
  final List<String> features;

  /// Structured, actually-enforced package benefits.
  final double pointsMultiplier;
  final double bookingDiscountPercent;
  final int welcomePoints;

  bool get isPlus => plan == 'plus' && isActive;

  factory SubscriptionEntity.fromJson(Map<String, dynamic> json) =>
      SubscriptionEntity(
        plan: json['plan']?.toString() ?? 'free',
        isActive: json['isActive'] == true,
        endDate: DateTime.tryParse(json['endDate']?.toString() ?? ''),
        monthlyPrice: (json['monthlyPrice'] as num?)?.toDouble() ?? 0,
        packageId: (json['packageId'] as num?)?.toInt(),
        packageName: json['packageName']?.toString() ?? '',
        period: json['period']?.toString() ?? 'monthly',
        features: (json['features'] as List?)
                ?.map((f) => f.toString())
                .where((f) => f.trim().isNotEmpty)
                .toList() ??
            const [],
        pointsMultiplier: (json['pointsMultiplier'] as num?)?.toDouble() ?? 1,
        bookingDiscountPercent:
            (json['bookingDiscountPercent'] as num?)?.toDouble() ?? 0,
        welcomePoints: (json['welcomePoints'] as num?)?.toInt() ?? 0,
      );
}
