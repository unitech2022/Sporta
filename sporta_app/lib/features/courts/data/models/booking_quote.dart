/// تسعير حجز قبل تأكيده كما يحسبه الخادم — السعر الأساسي بعد قواعد تسعير
/// المالك، وخصم باقة اللاعب، والإجمالي الذي سيُخصم من المحفظة.
class BookingQuote {
  const BookingQuote({
    required this.basePrice,
    required this.discountPercent,
    required this.discountAmount,
    required this.total,
    this.memberDiscountAmount = 0,
    this.membershipPlanName,
  });

  /// سعر الملعب للموعد المختار قبل خصم الباقة (يشمل قاعدة الذروة/الخصم).
  final double basePrice;

  /// نسبة خصم باقة اللاعب (٠ حين لا باقة).
  final double discountPercent;

  /// قيمة الخصم بالريال بعد تطبيق سقف العمولة.
  final double discountAmount;

  /// ما سيُخصم فعلاً.
  final double total;

  /// جزء [discountAmount] الآتي من عضوية النادي.
  final double memberDiscountAmount;

  /// خطة العضوية المطبَّقة (null = لا عضوية).
  final String? membershipPlanName;

  /// باقي الخصم: باقة اللاعب وعروض المنصة.
  double get packageDiscountAmount =>
      (discountAmount - memberDiscountAmount).clamp(0, double.infinity);

  bool get hasDiscount => discountAmount > 0;

  factory BookingQuote.fromJson(Map<String, dynamic> json) {
    final base = (json['basePrice'] as num?)?.toDouble() ?? 0;
    return BookingQuote(
      basePrice: base,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? base,
      memberDiscountAmount:
          (json['memberDiscountAmount'] as num?)?.toDouble() ?? 0,
      membershipPlanName: json['membershipPlanName']?.toString(),
    );
  }
}
