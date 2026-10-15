import 'dart:convert';

import '../../../../core/state/app_settings.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.avatarUrl,
    required this.roles,
    this.pendingRoles = const [],
    required this.language,
    required this.country,
    required this.city,
    this.district,
    this.cityId,
    this.districtId,
    this.favoriteSport,
    this.level,
    this.levelAssessed = false,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? avatarUrl;
  final List<UserRole> roles;

  /// أدوار بانتظار موافقة الأدمن (مدرب/ملعب بعد التسجيل). لا تُعدّ أدواراً
  /// فعّالة — التطبيق يعرضها كـ«قيد المراجعة» فقط.
  final List<UserRole> pendingRoles;

  final String language;
  final String country;
  final String city;
  final String? district;

  /// IDs of the chosen city/district from the managed lists (null if not set).
  final int? cityId;
  final int? districtId;

  /// The user's chosen favorite sport (null if not chosen yet).
  final String? favoriteSport;

  /// Player level 1..7 (null when the user has no player profile).
  final int? level;

  /// Saved home location (null until the user sets it).
  final double? latitude;
  final double? longitude;

  bool get hasLocation => latitude != null && longitude != null;

  ///Whether the player has completed the level self-assessment.
  final bool levelAssessed;

  String get fullName => '$firstName $lastName';

  bool get isPlayer => roles.contains(UserRole.player);

  /// Returns a copy with player onboarding fields updated.
  UserModel copyWith({
    String? city,
    String? district,
    int? cityId,
    int? districtId,
    String? favoriteSport,
    int? level,
    bool? levelAssessed,
    double? latitude,
    double? longitude,
    String? language,
  }) =>
      UserModel(
        id: id,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        avatarUrl: avatarUrl,
        roles: roles,
        pendingRoles: pendingRoles,
        language: language ?? this.language,
        country: country,
        city: city ?? this.city,
        district: district ?? this.district,
        cityId: cityId ?? this.cityId,
        districtId: districtId ?? this.districtId,
        favoriteSport: favoriteSport ?? this.favoriteSport,
        level: level ?? this.level,
        levelAssessed: levelAssessed ?? this.levelAssessed,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
      );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id']?.toString() ?? '',
        firstName: json['firstName']?.toString() ?? '',
        lastName: json['lastName']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        avatarUrl: json['avatarUrl']?.toString(),
        roles: (json['roles'] as List? ?? [])
            .map((r) => _roleFromString(r.toString()))
            .whereType<UserRole>()
            .toList(),
        pendingRoles: (json['pendingRoles'] as List? ?? [])
            .map((r) => _roleFromString(r.toString()))
            .whereType<UserRole>()
            .toList(),
        language: json['language']?.toString() ?? 'ar',
        country: json['country']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        district: json['district']?.toString(),
        cityId: (json['cityId'] as num?)?.toInt(),
        districtId: (json['districtId'] as num?)?.toInt(),
        favoriteSport: json['favoriteSport']?.toString(),
        level: (json['level'] as num?)?.toInt(),
        levelAssessed: json['levelAssessed'] == true,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'roles': roles.map((r) => r.name).toList(),
        'pendingRoles': pendingRoles.map((r) => r.name).toList(),
        'language': language,
        'country': country,
        'city': city,
        if (district != null) 'district': district,
        if (cityId != null) 'cityId': cityId,
        if (districtId != null) 'districtId': districtId,
        if (favoriteSport != null) 'favoriteSport': favoriteSport,
        if (level != null) 'level': level,
        'levelAssessed': levelAssessed,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String raw) =>
      UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  static UserRole? _roleFromString(String role) => switch (role) {
        'player' => UserRole.player,
        'coach' => UserRole.coach,
        'venue' => UserRole.venue,
        'admin' => UserRole.admin,
        _ => null,
      };
}
