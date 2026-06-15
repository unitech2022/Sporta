import '../../../../core/localization/app_translations.dart';

/// A single self-assessment answer option with the score it contributes (0..3).
class LevelOption {
  const LevelOption({required this.ar, required this.en, required this.score});

  final String ar;
  final String en;
  final int score;

  String label(AppLanguage lang) => lang == AppLanguage.ar ? ar : en;
}

/// A self-assessment question with its options.
class LevelQuestion {
  const LevelQuestion({
    required this.ar,
    required this.en,
    required this.options,
  });

  final String ar;
  final String en;
  final List<LevelOption> options;

  String text(AppLanguage lang) => lang == AppLanguage.ar ? ar : en;
}

/// Localized name of a player level (1..7), matching the backend scale.
String playerLevelName(int level, AppLanguage lang) {
  const ar = [
    'مبتدئ',
    'ناشئ',
    'متعلم',
    'متوسط',
    'متقدم',
    'محترف',
    'نخبة',
  ];
  const en = [
    'Beginner',
    'Novice',
    'Learner',
    'Intermediate',
    'Advanced',
    'Professional',
    'Elite',
  ];
  if (level < 1 || level > 7) return '';
  return (lang == AppLanguage.ar ? ar : en)[level - 1];
}
