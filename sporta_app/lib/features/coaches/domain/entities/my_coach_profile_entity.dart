/// The signed-in coach's full profile — every field of the coach model,
/// used by the "my profile" edit screen (as opposed to [CoachEntity], which
/// is the lighter shape used across the public coach-listing screens).
class MyCoachProfileEntity {
  const MyCoachProfileEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.city,
    required this.bio,
    required this.specialization,
    required this.sportId,
    required this.sportName,
    required this.hourlyRate,
    required this.rating,
    required this.reviews,
    required this.students,
    required this.isVerified,
    required this.certifications,
    required this.experienceLevel,
    required this.targetGender,
    required this.packagePrice,
    required this.preferredVenueId,
    required this.preferredVenueName,
    required this.availableDays,
    required this.residency,
    required this.nationalIdFrontUrl,
    required this.nationalIdBackUrl,
    required this.specializationIds,
    required this.specializationNames,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String? city;
  final String? bio;
  final String? specialization;
  final int? sportId;
  final String? sportName;
  final double hourlyRate;
  final double rating;
  final int reviews;
  final int students;
  final bool isVerified;

  final String? certifications;

  /// "lessThanYear" | "oneToThree" | "threeToFive" | "moreThanFive".
  final String experienceLevel;

  /// "male" | "female".
  final String targetGender;
  final double? packagePrice;
  final int? preferredVenueId;
  final String? preferredVenueName;

  /// Day keys: "sat","sun","mon","tue","wed","thu","fri".
  final List<String> availableDays;

  /// "saudi" | "resident".
  final String residency;
  final String? nationalIdFrontUrl;
  final String? nationalIdBackUrl;
  final List<int> specializationIds;
  final List<String> specializationNames;

  factory MyCoachProfileEntity.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? '';
    final parts = name.trim().split(RegExp(r'\s+'));
    return MyCoachProfileEntity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      firstName: parts.isNotEmpty ? parts.first : '',
      lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
      city: json['city']?.toString(),
      bio: json['bio']?.toString(),
      specialization: json['specialization']?.toString(),
      sportId: (json['sportId'] as num?)?.toInt(),
      sportName: json['sportName']?.toString(),
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviews: (json['reviews'] as num?)?.toInt() ?? 0,
      students: (json['students'] as num?)?.toInt() ?? 0,
      isVerified: json['isVerified'] == true,
      certifications: json['certifications']?.toString(),
      experienceLevel: json['experienceLevel']?.toString() ?? 'lessThanYear',
      targetGender: json['targetGender']?.toString() ?? 'male',
      packagePrice: (json['packagePrice'] as num?)?.toDouble(),
      preferredVenueId: (json['preferredVenueId'] as num?)?.toInt(),
      preferredVenueName: json['preferredVenueName']?.toString(),
      availableDays:
          (json['availableDays'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      residency: json['residency']?.toString() ?? 'saudi',
      nationalIdFrontUrl: json['nationalIdFrontUrl']?.toString(),
      nationalIdBackUrl: json['nationalIdBackUrl']?.toString(),
      specializationIds:
          (json['specializationIds'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      specializationNames:
          (json['specializationNames'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
