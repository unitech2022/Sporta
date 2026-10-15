/// A training specialization (تخصص تدريبي) returned by
/// `/coach-specializations` — admin-managed list the coach picks from at
/// registration (e.g. "تدريب المبتدئين", "اللياقة البدنية").
class CoachSpecializationEntity {
  const CoachSpecializationEntity({
    required this.id,
    required this.nameAr,
    required this.nameEn,
  });

  final int id;
  final String nameAr;
  final String nameEn;

  factory CoachSpecializationEntity.fromJson(Map<String, dynamic> json) =>
      CoachSpecializationEntity(
        id: (json['id'] as num?)?.toInt() ?? 0,
        nameAr: json['nameAr']?.toString() ?? '',
        nameEn: json['nameEn']?.toString() ?? '',
      );
}
