import '../../../core/localization/tr_global.dart';

/// A home-slider ad/banner served by `/api/ads`.
///
/// النص يُخزَّن بالعربي والإنجليزي معًا، ويُختار وقت العرض حسب لغة التطبيق
/// (مع الرجوع للعربي إن كانت الترجمة الإنجليزية فاضية).
class AdEntity {
  const AdEntity({
    required this.id,
    required this.titleAr,
    required this.subtitleAr,
    required this.imageUrl,
    this.titleEn,
    this.subtitleEn,
    this.target,
  });

  final int id;
  final String titleAr;
  final String subtitleAr;
  final String? titleEn;
  final String? subtitleEn;
  final String imageUrl;

  /// Tab name ("courts" | "matches" | "coaches") or external URL; may be null.
  final String? target;

  String get title => localizedServerName(titleAr, titleEn);
  String get subtitle => localizedServerName(subtitleAr, subtitleEn);

  factory AdEntity.fromJson(Map<String, dynamic> json) => AdEntity(
        id: (json['id'] as num?)?.toInt() ?? 0,
        titleAr: json['title']?.toString() ?? '',
        subtitleAr: json['subtitle']?.toString() ?? '',
        titleEn: json['titleEn']?.toString(),
        subtitleEn: json['subtitleEn']?.toString(),
        imageUrl: json['imageUrl']?.toString() ?? '',
        target: json['target']?.toString(),
      );
}
