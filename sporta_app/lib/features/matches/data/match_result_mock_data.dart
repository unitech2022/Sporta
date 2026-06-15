import 'dart:ui';

import '../../../core/constants/app_colors.dart';

/// ──────────────────────────────────────────────
/// Tailwind palette used locally by the match
/// result page and its widgets.
/// ──────────────────────────────────────────────
abstract class MRColors {
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue200 = Color(0xFFBFDBFE);
  static const Color blue300 = Color(0xFF93C5FD);
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color blue900 = Color(0xFF1E3A8A);

  static const Color purple50 = Color(0xFFFAF5FF);
  static const Color purple100 = Color(0xFFF3E8FF);
  static const Color purple200 = Color(0xFFE9D5FF);
  static const Color purple300 = Color(0xFFD8B4FE);
  static const Color purple400 = Color(0xFFC084FC);
  static const Color purple500 = Color(0xFFA855F7);
  static const Color purple600 = Color(0xFF9333EA);
  static const Color purple700 = Color(0xFF7E22CE);
  static const Color purple900 = Color(0xFF581C87);

  static const Color indigo400 = Color(0xFF818CF8);
  static const Color indigo500 = Color(0xFF6366F1);
  static const Color indigo600 = Color(0xFF4F46E5);
  static const Color indigo700 = Color(0xFF4338CA);

  static const Color teal50 = Color(0xFFF0FDFA);
  static const Color teal100 = Color(0xFFCCFBF1);
  static const Color teal200 = Color(0xFF99F6E4);
  static const Color teal300 = Color(0xFF5EEAD4);
  static const Color teal400 = Color(0xFF2DD4BF);
  static const Color teal500 = Color(0xFF14B8A6);
  static const Color teal600 = Color(0xFF0D9488);
  static const Color teal700 = Color(0xFF0F766E);
  static const Color teal900 = Color(0xFF134E4A);

  static const Color cyan600 = Color(0xFF0891B2);
  static const Color cyan700 = Color(0xFF0E7490);
  static const Color cyan900 = Color(0xFF164E63);

  static const Color green50 = Color(0xFFF0FDF4);
  static const Color green100 = Color(0xFFDCFCE7);
  static const Color green300 = Color(0xFF86EFAC);
  static const Color green400 = Color(0xFF4ADE80);
  static const Color green500 = Color(0xFF22C55E);
  static const Color green600 = Color(0xFF16A34A);
  static const Color green700 = Color(0xFF15803D);

  static const Color orange50 = Color(0xFFFFF7ED);
  static const Color orange100 = Color(0xFFFFEDD5);
  static const Color orange200 = Color(0xFFFED7AA);
  static const Color orange300 = Color(0xFFFDBA74);
  static const Color orange400 = Color(0xFFFB923C);
  static const Color orange500 = Color(0xFFF97316);
  static const Color orange600 = Color(0xFFEA580C);
  static const Color orange700 = Color(0xFFC2410C);

  static const Color red400 = Color(0xFFF87171);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red600 = Color(0xFFDC2626);

  static const Color yellow50 = Color(0xFFFEFCE8);
  static const Color yellow100 = Color(0xFFFEF9C3);
  static const Color yellow200 = Color(0xFFFEF08A);
  static const Color yellow300 = Color(0xFFFDE047);
  static const Color yellow400 = Color(0xFFFACC15);
  static const Color yellow500 = Color(0xFFEAB308);
  static const Color yellow600 = Color(0xFFCA8A04);

  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
}

/// Gradient pairs that mirror the TSX `from-X to-Y` avatar classes.
const List<Color> mrPrimaryGradient = [AppColors.primary, Color(0xCC2AB5CE)];
const List<Color> mrSecondaryGradient = [
  AppColors.secondary,
  Color(0xCC0A2540),
];
const List<Color> mrBlueGradient = [MRColors.blue500, MRColors.blue600];
const List<Color> mrPurpleGradient = [MRColors.purple500, MRColors.purple600];
const List<Color> mrIndigoGradient = [MRColors.indigo500, MRColors.indigo600];
const List<Color> mrOrangeGradient = [MRColors.orange500, MRColors.orange600];
const List<Color> mrRedGradient = [MRColors.red500, MRColors.red600];
const List<Color> mrRedSoftGradient = [MRColors.red400, MRColors.red500];
const List<Color> mrTealGradient = [MRColors.teal500, MRColors.teal600];
const List<Color> mrGreenGradient = [MRColors.green500, MRColors.green600];

/// Round scoring mode: by time or by sets.
enum MatchResultMode { time, sets }

/// ══════════════════════════════════════
/// أمريكانو فرق — الفرق الأربعة
/// ══════════════════════════════════════
class MatchResultTeamPlayer {
  const MatchResultTeamPlayer({
    required this.name,
    required this.avatar,
    required this.gradient,
  });

  final String name;
  final String avatar;
  final List<Color> gradient;

  String get firstName => name.split(' ').first;
}

class AmericanoTeam {
  const AmericanoTeam({
    required this.id,
    required this.label,
    required this.avgLevel,
    required this.players,
  });

  final String id;
  final String label;
  final double avgLevel;
  final List<MatchResultTeamPlayer> players;

  String get avgLevelLabel => mrFormatLevel(avgLevel);
}

const List<AmericanoTeam> americanoTeams = [
  AmericanoTeam(
    id: 'at1',
    label: 'الصقور',
    avgLevel: 4.75,
    players: [
      MatchResultTeamPlayer(
          name: 'أحمد الزهراني', avatar: 'أ.ز', gradient: mrPrimaryGradient),
      MatchResultTeamPlayer(
          name: 'سعد المطيري', avatar: 'س.م', gradient: mrBlueGradient),
    ],
  ),
  AmericanoTeam(
    id: 'at2',
    label: 'النسور',
    avgLevel: 4.65,
    players: [
      MatchResultTeamPlayer(
          name: 'خالد العمري', avatar: 'خ.ع', gradient: mrPurpleGradient),
      MatchResultTeamPlayer(
          name: 'عمر الشهري', avatar: 'ع.ش', gradient: mrIndigoGradient),
    ],
  ),
  AmericanoTeam(
    id: 'at3',
    label: 'الأسود',
    avgLevel: 4.60,
    players: [
      MatchResultTeamPlayer(
          name: 'فيصل العتيبي', avatar: 'ف.ع', gradient: mrOrangeGradient),
      MatchResultTeamPlayer(
          name: 'محمد السالم', avatar: 'م.س', gradient: mrRedGradient),
    ],
  ),
  AmericanoTeam(
    id: 'at4',
    label: 'النمور',
    avgLevel: 4.70,
    players: [
      MatchResultTeamPlayer(
          name: 'بندر الحربي', avatar: 'ب.ح', gradient: mrTealGradient),
      MatchResultTeamPlayer(
          name: 'فهد الدوسري', avatar: 'ف.د', gradient: mrGreenGradient),
    ],
  ),
];

AmericanoTeam americanoTeamById(String id) =>
    americanoTeams.firstWhere((t) => t.id == id);

/// Header strip gradient per team (from-X to-Y).
const Map<String, List<Color>> teamHeaderGradients = {
  'at1': [AppColors.primary, MRColors.blue600],
  'at2': [MRColors.purple600, MRColors.indigo600],
  'at3': [MRColors.orange500, MRColors.red500],
  'at4': [MRColors.teal500, MRColors.green600],
};

/// Accent colors of the small level pill per team.
class TeamAccentColors {
  const TeamAccentColors({
    required this.background,
    required this.text,
    required this.border,
  });

  final Color background;
  final Color text;
  final Color border;
}

const Map<String, TeamAccentColors> teamAccents = {
  'at1': TeamAccentColors(
      background: MRColors.blue100,
      text: MRColors.blue700,
      border: MRColors.blue200),
  'at2': TeamAccentColors(
      background: MRColors.purple100,
      text: MRColors.purple700,
      border: MRColors.purple200),
  'at3': TeamAccentColors(
      background: MRColors.orange100,
      text: MRColors.orange700,
      border: MRColors.orange200),
  'at4': TeamAccentColors(
      background: MRColors.teal100,
      text: MRColors.teal700,
      border: MRColors.teal200),
};

const TeamAccentColors tealAccent = TeamAccentColors(
  background: MRColors.teal50,
  text: MRColors.teal700,
  border: MRColors.teal200,
);

/// ══════════════════════════════════════
/// أمريكانو فردي — اللاعبون الثمانية
/// ══════════════════════════════════════
class MatchResultPlayer {
  const MatchResultPlayer({
    required this.id,
    required this.name,
    required this.level,
    required this.avatar,
    required this.gradient,
    required this.short,
  });

  final String id;
  final String name;
  final double level;
  final String avatar;
  final List<Color> gradient;
  final String short;

  String get levelLabel => level.toStringAsFixed(1);
  String get firstName => name.split(' ').first;
}

const List<MatchResultPlayer> americanoSoloPlayers = [
  MatchResultPlayer(
      id: 'as1',
      name: 'أحمد الزهراني',
      level: 5.2,
      avatar: 'أ.ز',
      gradient: mrPrimaryGradient,
      short: 'أحمد'),
  MatchResultPlayer(
      id: 'as2',
      name: 'سعد المطيري',
      level: 4.8,
      avatar: 'س.م',
      gradient: mrBlueGradient,
      short: 'سعد'),
  MatchResultPlayer(
      id: 'as3',
      name: 'عمر الشهري',
      level: 4.5,
      avatar: 'ع.ش',
      gradient: mrPurpleGradient,
      short: 'عمر'),
  MatchResultPlayer(
      id: 'as4',
      name: 'فهد السبيعي',
      level: 4.3,
      avatar: 'ف.س',
      gradient: mrGreenGradient,
      short: 'فهد'),
  MatchResultPlayer(
      id: 'as5',
      name: 'خالد العمري',
      level: 4.1,
      avatar: 'خ.ع',
      gradient: mrOrangeGradient,
      short: 'خالد'),
  MatchResultPlayer(
      id: 'as6',
      name: 'محمد السالم',
      level: 3.9,
      avatar: 'م.س',
      gradient: mrTealGradient,
      short: 'محمد'),
  MatchResultPlayer(
      id: 'as7',
      name: 'فيصل العتيبي',
      level: 3.7,
      avatar: 'ف.ع',
      gradient: mrRedSoftGradient,
      short: 'فيصل'),
  MatchResultPlayer(
      id: 'as8',
      name: 'بندر الحربي',
      level: 3.5,
      avatar: 'ب.ح',
      gradient: mrIndigoGradient,
      short: 'بندر'),
];

MatchResultPlayer americanoSoloPlayerById(String id) =>
    americanoSoloPlayers.firstWhere((p) => p.id == id);

/// جدول عادل: 3 جولات × 2 ملاعب — لا تكرار للشريك
const List<List<List<String>>> soloSchedulePairings = [
  [
    ['as1', 'as8'],
    ['as2', 'as7'],
    ['as3', 'as6'],
    ['as4', 'as5'],
  ],
  [
    ['as1', 'as5'],
    ['as3', 'as7'],
    ['as2', 'as6'],
    ['as4', 'as8'],
  ],
  [
    ['as1', 'as6'],
    ['as4', 'as7'],
    ['as2', 'as5'],
    ['as3', 'as8'],
  ],
];

/// ── بيانات ودية فردي ──
const List<MatchResultPlayer> soloPlayers = [
  MatchResultPlayer(
      id: 'p1',
      name: 'محمد أحمد',
      level: 5.0,
      avatar: 'م.أ',
      gradient: mrPrimaryGradient,
      short: 'محمد'),
  MatchResultPlayer(
      id: 'p2',
      name: 'عمر السالم',
      level: 4.8,
      avatar: 'ع.س',
      gradient: mrBlueGradient,
      short: 'عمر'),
  MatchResultPlayer(
      id: 'p3',
      name: 'فيصل العتيبي',
      level: 5.2,
      avatar: 'ف.ع',
      gradient: mrPurpleGradient,
      short: 'فيصل'),
  MatchResultPlayer(
      id: 'p4',
      name: 'بندر الحربي',
      level: 4.6,
      avatar: 'ب.ح',
      gradient: mrOrangeGradient,
      short: 'بندر'),
];

MatchResultPlayer soloPlayerById(String id) =>
    soloPlayers.firstWhere((p) => p.id == id);

/// ── بيانات تحدي فرق ──
const List<MatchResultPlayer> challengeTeam1 = [
  MatchResultPlayer(
      id: 'p1',
      name: 'أحمد الزهراني',
      level: 5.5,
      avatar: 'أ.ز',
      gradient: mrPrimaryGradient,
      short: 'أحمد'),
  MatchResultPlayer(
      id: 'p2',
      name: 'سعد المطيري',
      level: 5.0,
      avatar: 'س.م',
      gradient: mrBlueGradient,
      short: 'سعد'),
];

const List<MatchResultPlayer> challengeTeam2 = [
  MatchResultPlayer(
      id: 'p3',
      name: 'خالد العمري',
      level: 5.2,
      avatar: 'خ.ع',
      gradient: mrSecondaryGradient,
      short: 'خالد'),
  MatchResultPlayer(
      id: 'p4',
      name: 'فهد السبيعي',
      level: 5.8,
      avatar: 'ف.س',
      gradient: mrPurpleGradient,
      short: 'فهد'),
];

/// ──────────────────────────────
/// Helpers
/// ──────────────────────────────
String mrFormatLevel(double v) {
  var s = v.toStringAsFixed(2);
  while (s.endsWith('0')) {
    s = s.substring(0, s.length - 1);
  }
  if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  return s;
}

String mrAddMinutes(String time, int mins) {
  final parts = time.split(':').map(int.parse).toList();
  final total = parts[0] * 60 + parts[1] + mins;
  final nh = (total ~/ 60) % 24;
  final nm = total % 60;
  return '${nh.toString().padLeft(2, '0')}:${nm.toString().padLeft(2, '0')}';
}

String mrFmtTime(String t) {
  final parts = t.split(':').map(int.parse).toList();
  final h = parts[0];
  final m = parts[1];
  final per = h >= 12 ? 'م' : 'ص';
  final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
  return '$h12:${m.toString().padLeft(2, '0')} $per';
}

String mrSetsCountLabel(int count) => count == 1
    ? 'شوط واحد'
    : count == 2
        ? 'شوطان'
        : '$count أشواط';

/// ──────────────────────────────
/// نماذج جدول الأمريكانو (فرق وفردي)
/// ──────────────────────────────
class AmericanoSetScore {
  AmericanoSetScore({this.sA = '', this.sB = ''});

  String sA;
  String sB;
}

class AmericanoMatch {
  AmericanoMatch({
    required this.id,
    required this.teamA,
    required this.teamB,
    required int setsCount,
  }) : sets = List.generate(setsCount, (_) => AmericanoSetScore());

  final String id;

  /// Member ids — a single team id for "أمريكانو فرق",
  /// a pair of player ids for "أمريكانو فردي".
  final List<String> teamA;
  final List<String> teamB;

  String scoreA = '';
  String scoreB = '';
  final List<AmericanoSetScore> sets;

  int totalA(MatchResultMode mode) => mode == MatchResultMode.time
      ? (int.tryParse(scoreA) ?? 0)
      : sets.fold(0, (sum, s) => sum + (int.tryParse(s.sA) ?? 0));

  int totalB(MatchResultMode mode) => mode == MatchResultMode.time
      ? (int.tryParse(scoreB) ?? 0)
      : sets.fold(0, (sum, s) => sum + (int.tryParse(s.sB) ?? 0));

  bool isComplete(MatchResultMode mode) => mode == MatchResultMode.time
      ? scoreA.isNotEmpty && scoreB.isNotEmpty
      : sets.every((s) => s.sA.isNotEmpty && s.sB.isNotEmpty);

  bool hasAnyScore(MatchResultMode mode) => mode == MatchResultMode.time
      ? scoreA.isNotEmpty || scoreB.isNotEmpty
      : sets.any((s) => s.sA.isNotEmpty || s.sB.isNotEmpty);

  bool hasScores(MatchResultMode mode) => mode == MatchResultMode.time
      ? scoreA.isNotEmpty && scoreB.isNotEmpty
      : sets.any((s) => s.sA.isNotEmpty && s.sB.isNotEmpty);
}

class AmericanoRound {
  AmericanoRound({
    required this.id,
    required this.roundNum,
    required this.court1,
    required this.court2,
    required this.timeSlot,
  });

  final String id;
  final int roundNum;
  final AmericanoMatch court1;
  final AmericanoMatch court2;
  final String timeSlot;

  List<AmericanoMatch> get matches => [court1, court2];

  bool isComplete(MatchResultMode mode) =>
      matches.every((m) => m.isComplete(mode));

  bool hasAnyScore(MatchResultMode mode) =>
      matches.any((m) => m.hasAnyScore(mode));
}

/// جدولة عادلة (round-robin مع توازن المستويات)
/// لـ 4 فرق: 3 جولات × 2 ملاعب = 6 مباريات
List<List<String>> buildFairSchedule(List<AmericanoTeam> teams) {
  final s = [...teams]..sort((a, b) => b.avgLevel.compareTo(a.avgLevel));
  return [
    [s[0].id, s[3].id, s[1].id, s[2].id],
    [s[0].id, s[2].id, s[3].id, s[1].id],
    [s[0].id, s[1].id, s[2].id, s[3].id],
  ];
}

List<AmericanoRound> generateTeamsSchedule(
  MatchResultMode mode,
  String startTime,
  int timePerRound,
  int setsCount,
) {
  final pairings = buildFairSchedule(americanoTeams);
  return List.generate(pairings.length, (ri) {
    final p = pairings[ri];
    final slotStart = mrAddMinutes(
        startTime, ri * (mode == MatchResultMode.time ? timePerRound + 2 : 0));
    final slotEnd = mrAddMinutes(slotStart, timePerRound);
    return AmericanoRound(
      id: 'ar$ri',
      roundNum: ri + 1,
      court1: AmericanoMatch(
          id: 'm${ri}c1', teamA: [p[0]], teamB: [p[1]], setsCount: setsCount),
      court2: AmericanoMatch(
          id: 'm${ri}c2', teamA: [p[2]], teamB: [p[3]], setsCount: setsCount),
      timeSlot: mode == MatchResultMode.time
          ? '${mrFmtTime(slotStart)} – ${mrFmtTime(slotEnd)}'
          : 'جولة ${ri + 1}',
    );
  });
}

List<AmericanoRound> generateSoloSchedule(
  MatchResultMode mode,
  String startTime,
  int timePerRound,
  int setsCount,
) {
  return List.generate(soloSchedulePairings.length, (ri) {
    final p = soloSchedulePairings[ri];
    final slotStart = mrAddMinutes(
        startTime, ri * (mode == MatchResultMode.time ? timePerRound + 2 : 0));
    final slotEnd = mrAddMinutes(slotStart, timePerRound);
    return AmericanoRound(
      id: 'asr$ri',
      roundNum: ri + 1,
      court1: AmericanoMatch(
          id: 'asm${ri}c1', teamA: p[0], teamB: p[1], setsCount: setsCount),
      court2: AmericanoMatch(
          id: 'asm${ri}c2', teamA: p[2], teamB: p[3], setsCount: setsCount),
      timeSlot: mode == MatchResultMode.time
          ? '${mrFmtTime(slotStart)} – ${mrFmtTime(slotEnd)}'
          : 'جولة ${ri + 1}',
    );
  });
}

/// Sums points per member id (team id or player id).
Map<String, int> calcAmericanoPoints(
  List<AmericanoRound> schedule,
  MatchResultMode mode,
) {
  final pts = <String, int>{};
  for (final r in schedule) {
    for (final m in r.matches) {
      final a = m.totalA(mode);
      final b = m.totalB(mode);
      for (final id in m.teamA) {
        pts[id] = (pts[id] ?? 0) + a;
      }
      for (final id in m.teamB) {
        pts[id] = (pts[id] ?? 0) + b;
      }
    }
  }
  return pts;
}

bool isAmericanoScheduleComplete(
  List<AmericanoRound> schedule,
  MatchResultMode mode,
) =>
    schedule.isNotEmpty && schedule.every((r) => r.isComplete(mode));

/// ──────────────────────────────
/// ودية فردي — الجولات
/// ──────────────────────────────
class FriendlyRound {
  FriendlyRound({
    required this.id,
    required this.teamA,
    required this.teamB,
  });

  final String id;
  List<String> teamA;
  List<String> teamB;
  String scoreA = '';
  String scoreB = '';
}

const List<List<List<String>>> friendlyDefaultPairings = [
  [
    ['p1', 'p2'],
    ['p3', 'p4'],
  ],
  [
    ['p1', 'p3'],
    ['p2', 'p4'],
  ],
  [
    ['p1', 'p4'],
    ['p2', 'p3'],
  ],
];

FriendlyRound makeFriendlyRound(int idx) {
  final pairing = friendlyDefaultPairings[idx % 3];
  return FriendlyRound(
    id: 'r${DateTime.now().microsecondsSinceEpoch}-$idx',
    teamA: [...pairing[0]],
    teamB: [...pairing[1]],
  );
}

/// ── تحدي فرق — الأشواط ──
class TeamChallengeSet {
  TeamChallengeSet({this.t1 = '', this.t2 = ''});

  String t1;
  String t2;
}
