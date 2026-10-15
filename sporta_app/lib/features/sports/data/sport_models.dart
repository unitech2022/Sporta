/// A sport (لعبة) returned by `/sports` — admin-managed list the coach picks
/// his specialization from at registration.
class SportEntity {
  const SportEntity({
    required this.id,
    required this.key,
    required this.nameAr,
    required this.nameEn,
    this.imageUrl,
  });

  final int id;
  final String key;
  final String nameAr;
  final String nameEn;
  final String? imageUrl;

  factory SportEntity.fromJson(Map<String, dynamic> json) => SportEntity(
        id: (json['id'] as num).toInt(),
        key: json['key']?.toString() ?? '',
        nameAr: json['name']?.toString() ?? '',
        nameEn: json['nameEn']?.toString() ?? '',
        imageUrl: json['image']?.toString(),
      );
}
