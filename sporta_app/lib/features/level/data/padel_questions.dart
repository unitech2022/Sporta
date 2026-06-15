import '../domain/level_question.dart';

/// Padel self-assessment questionnaire (path 1 — self assessment).
/// Each option's score (0..3) feeds the backend level computation.
const List<LevelQuestion> padelQuestions = [
  LevelQuestion(
    ar: 'منذ متى وأنت تلعب البادل؟',
    en: 'How long have you been playing padel?',
    options: [
      LevelOption(ar: 'لم ألعب من قبل', en: 'Never played before', score: 0),
      LevelOption(ar: 'أقل من 6 أشهر', en: 'Less than 6 months', score: 1),
      LevelOption(ar: 'من 6 أشهر إلى سنتين', en: '6 months to 2 years', score: 2),
      LevelOption(ar: 'أكثر من سنتين', en: 'More than 2 years', score: 3),
    ],
  ),
  LevelQuestion(
    ar: 'كيف تقيّم تحكمك في المضرب والكرة؟',
    en: 'How do you rate your racket and ball control?',
    options: [
      LevelOption(ar: 'أتعلم الأساسيات', en: 'Learning the basics', score: 0),
      LevelOption(
          ar: 'أستطيع تبادل كرات بسيط', en: 'I can do simple rallies', score: 1),
      LevelOption(
          ar: 'تحكم جيد في معظم الضربات',
          en: 'Good control on most shots',
          score: 2),
      LevelOption(ar: 'تحكم ممتاز واحترافي', en: 'Excellent control', score: 3),
    ],
  ),
  LevelQuestion(
    ar: 'هل تجيد اللعب باستخدام الجدران؟',
    en: 'Can you play off the walls?',
    options: [
      LevelOption(ar: 'لا أعرف كيف', en: "I don't know how", score: 0),
      LevelOption(ar: 'أحياناً وبصعوبة', en: 'Sometimes, with difficulty', score: 1),
      LevelOption(ar: 'نعم في معظم الأحيان', en: 'Yes, most of the time', score: 2),
      LevelOption(ar: 'بإتقان تام', en: 'With full mastery', score: 3),
    ],
  ),
  LevelQuestion(
    ar: 'كيف هي ضرباتك الهجومية (سماش / بانديخا)؟',
    en: 'How are your attacking shots (smash / bandeja)?',
    options: [
      LevelOption(ar: 'لا أستخدمها', en: "I don't use them", score: 0),
      LevelOption(ar: 'أحاول أحياناً', en: 'I try sometimes', score: 1),
      LevelOption(ar: 'أستخدمها بفعالية', en: 'I use them effectively', score: 2),
      LevelOption(ar: 'أتقنها وألعبها بثقة', en: 'I master them confidently', score: 3),
    ],
  ),
  LevelQuestion(
    ar: 'هل شاركت في مباريات أو بطولات تنافسية؟',
    en: 'Have you played competitive matches or tournaments?',
    options: [
      LevelOption(
          ar: 'لا، ودياً فقط أو لم ألعب',
          en: 'No, friendly only or never',
          score: 0),
      LevelOption(
          ar: 'مباريات ودية منتظمة', en: 'Regular friendly matches', score: 1),
      LevelOption(ar: 'بطولات محلية', en: 'Local tournaments', score: 2),
      LevelOption(
          ar: 'بطولات تنافسية متقدمة',
          en: 'Advanced competitive tournaments',
          score: 3),
    ],
  ),
];
