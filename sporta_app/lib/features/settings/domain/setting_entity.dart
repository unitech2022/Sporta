/// A single admin-managed system setting (maintenance mode, policy text,
/// support contact, etc.) served by `GET /api/settings/public`.
class SettingEntity {
  const SettingEntity({
    required this.key,
    required this.nameAr,
    required this.nameEn,
    required this.type,
    required this.valueAr,
    required this.valueEn,
  });

  final String key;
  final String nameAr;
  final String nameEn;
  final String type; // text | switch | number
  final String valueAr;
  final String valueEn;

  bool get boolValue => valueAr.trim().toLowerCase() == 'true';

  factory SettingEntity.fromJson(Map<String, dynamic> json) => SettingEntity(
    key: json['key']?.toString() ?? '',
    nameAr: json['nameAr']?.toString() ?? '',
    nameEn: json['nameEn']?.toString() ?? '',
    type: json['type']?.toString() ?? 'text',
    valueAr: json['valueAr']?.toString() ?? '',
    valueEn: json['valueEn']?.toString() ?? '',
  );
}
