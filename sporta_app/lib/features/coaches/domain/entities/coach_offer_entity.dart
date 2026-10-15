/// An offer or discount the coach has added to their profile — shown to
/// players before booking (العروض والخصومات).
class CoachOfferEntity {
  const CoachOfferEntity({
    required this.id,
    required this.title,
    required this.discountPercent,
    required this.targetLabel,
    required this.expiresAt,
    required this.isActive,
    required this.isExpired,
  });

  final int id;
  final String title;
  final int discountPercent;

  /// "individual" | "group" | "all".
  final String targetLabel;
  final DateTime expiresAt;
  final bool isActive;
  final bool isExpired;

  factory CoachOfferEntity.fromJson(Map<String, dynamic> json) =>
      CoachOfferEntity(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title']?.toString() ?? '',
        discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
        targetLabel: json['targetLabel']?.toString() ?? 'all',
        expiresAt:
            DateTime.tryParse(json['expiresAt']?.toString() ?? '') ??
            DateTime.now(),
        isActive: json['isActive'] == true,
        isExpired: json['isExpired'] == true,
      );

  static List<CoachOfferEntity> listFrom(dynamic raw) =>
      (raw as List?)
          ?.map((e) => CoachOfferEntity.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [];
}
