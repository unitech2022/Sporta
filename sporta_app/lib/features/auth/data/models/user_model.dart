import 'dart:convert';

import '../../../../core/state/app_settings.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    this.avatarUrl,
    required this.roles,
    required this.language,
    required this.country,
    required this.city,
    this.district,
    this.favoriteSport,
    this.level,
    this.levelAssessed = false,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final List<UserRole> roles;
  final String language;
  final String country;
  final String city;
  final String? district;

  /// The user's chosen favorite sport (null if not chosen yet).
  final String? favoriteSport;

  /// Player level 1..7 (null when the user has no player profile).
  final int? level;

  /// Whether the player has completed the level self-assessment.
  final bool levelAssessed;

  String get fullName => '$firstName $lastName';

  bool get isPlayer => roles.contains(UserRole.player);

  /// Returns a copy with player onboarding fields updated.
  UserModel copyWith({
    String? favoriteSport,
    int? level,
    bool? levelAssessed,
  }) =>
      UserModel(
        id: id,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
        avatarUrl: avatarUrl,
        roles: roles,
        language: language,
        country: country,
        city: city,
        district: district,
        favoriteSport: favoriteSport ?? this.favoriteSport,
        level: level ?? this.level,
        levelAssessed: levelAssessed ?? this.levelAssessed,
      );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id']?.toString() ?? '',
        firstName: json['firstName']?.toString() ?? '',
        lastName: json['lastName']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        email: json['email']?.toString(),
        avatarUrl: json['avatarUrl']?.toString(),
        roles: (json['roles'] as List? ?? [])
            .map((r) => _roleFromString(r.toString()))
            .whereType<UserRole>()
            .toList(),
        language: json['language']?.toString() ?? 'ar',
        country: json['country']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        district: json['district']?.toString(),
        favoriteSport: json['favoriteSport']?.toString(),
        level: (json['level'] as num?)?.toInt(),
        levelAssessed: json['levelAssessed'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        if (email != null) 'email': email,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'roles': roles.map((r) => r.name).toList(),
        'language': language,
        'country': country,
        'city': city,
        if (district != null) 'district': district,
        if (favoriteSport != null) 'favoriteSport': favoriteSport,
        if (level != null) 'level': level,
        'levelAssessed': levelAssessed,
      };

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String raw) =>
      UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  static UserRole? _roleFromString(String role) => switch (role) {
        'player' => UserRole.player,
        'coach' => UserRole.coach,
        'venue' => UserRole.venue,
        _ => null,
      };
}
