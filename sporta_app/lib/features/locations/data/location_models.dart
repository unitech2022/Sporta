/// A Saudi city returned by `/locations/cities`.
class CityEntity {
  const CityEntity({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.region,
    this.latitude,
    this.longitude,
    this.districtsCount = 0,
  });

  final int id;
  final String nameAr;
  final String nameEn;
  final String? region;
  final double? latitude;
  final double? longitude;
  final int districtsCount;

  bool get hasCoordinates => latitude != null && longitude != null;

  factory CityEntity.fromJson(Map<String, dynamic> json) => CityEntity(
        id: (json['id'] as num).toInt(),
        nameAr: json['nameAr']?.toString() ?? '',
        nameEn: json['nameEn']?.toString() ?? '',
        region: json['region']?.toString(),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        districtsCount: (json['districtsCount'] as num?)?.toInt() ?? 0,
      );
}

/// A district (حي) belonging to a city, from `/locations/cities/{id}/districts`.
class DistrictEntity {
  const DistrictEntity({
    required this.id,
    required this.cityId,
    required this.nameAr,
    required this.nameEn,
  });

  final int id;
  final int cityId;
  final String nameAr;
  final String nameEn;

  factory DistrictEntity.fromJson(Map<String, dynamic> json) => DistrictEntity(
        id: (json['id'] as num).toInt(),
        cityId: (json['cityId'] as num).toInt(),
        nameAr: json['nameAr']?.toString() ?? '',
        nameEn: json['nameEn']?.toString() ?? '',
      );
}
