import '../../../core/localization/tr_global.dart';
import '../../../core/utils/server_time.dart';

/// One item in the "نبض المجتمع الرياضي" section of the player dashboard.
class PulseItem {
  const PulseItem({
    required this.type,
    required this.text,
    required this.createdAt,
    this.actorId,
    this.actorName,
    this.highlight,
    this.matchId,
    this.level,
    this.points,
    this.count,
    this.relativeUnit,
    this.relativeValue,
  });

  /// "level" | "points" | "match_seeking" | "level_summary".
  final String type;

  /// Arabic sentence built by the server. Only a fallback: [localizedText]
  /// rebuilds the sentence in the app language from the structured fields.
  final String text;

  final DateTime createdAt;

  /// Null for aggregate items that belong to no single player.
  final int? actorId;
  final String? actorName;

  /// The number inside the sentence the UI emphasises, when there is one.
  final String? highlight;

  /// Set for `match_seeking` only — the match the action button opens.
  final int? matchId;

  /// `level`: the level reached. `points`: points earned today.
  /// `count`: how many players set their level today.
  final int? level;
  final int? points;
  final int? count;

  /// `match_seeking`: how soon the match starts — "soon" | "hours" | "days",
  /// with [relativeValue] holding the hours/days ("soon" carries none). The
  /// server computes these against KSA time, so the device clock never skews them.
  final String? relativeUnit;
  final int? relativeValue;

  bool get isSummary => type == 'level_summary';

  /// The sentence in the app language. Falls back to the server's Arabic [text]
  /// when the structured fields are missing (an older API).
  String get localizedText {
    final name = actorName?.trim().isNotEmpty == true ? actorName! : trg('لاعب');

    switch (type) {
      case 'level' when level != null:
        return trgArgs('{p0} وصل لمستوى {p1}', {'p0': name, 'p1': level});
      case 'points' when points != null:
        return trgArgs(
            '{p0} حقق {p1} خلال اليوم', {'p0': name, 'p1': _pointsPhrase(points!)});
      case 'match_seeking' when relativeUnit != null:
        return trgArgs('{p0} يبحث عن شريك لمباراة {p1}',
            {'p0': name, 'p1': _relativeFuture(relativeUnit!, relativeValue)});
      case 'level_summary' when count != null:
        return _playersSetLevelPhrase(count!);
      default:
        return text;
    }
  }

  /// The number to emphasise inside [localizedText] — recomputed rather than
  /// taken from the server, whose `highlight` indexes the Arabic sentence.
  String? get localizedHighlight => switch (type) {
        'level' when level != null => level.toString(),
        'points' when points != null => points! > 2 ? points.toString() : null,
        'level_summary' when count != null => count! > 2 ? count.toString() : null,
        // No structured fields: [localizedText] is the server sentence, which
        // the server's own highlight indexes into.
        _ => highlight,
      };

  /// Arabic needs singular/dual/plural forms; English collapses them all.
  static String _pointsPhrase(int n) => switch (n) {
        1 => trg('نقطة واحدة'),
        2 => trg('نقطتين'),
        <= 10 => trgArgs('{p0} نقاط', {'p0': n}),
        _ => trgArgs('{p0} نقطة', {'p0': n}),
      };

  static String _playersSetLevelPhrase(int n) => switch (n) {
        1 => trg('لاعب واحد حدّد مستواه اليوم'),
        2 => trg('لاعبان حدّدا مستواهما اليوم'),
        <= 10 => trgArgs('{p0} لاعبين حدّدوا مستواهم اليوم', {'p0': n}),
        _ => trgArgs('{p0} لاعباً حدّدوا مستواهم اليوم', {'p0': n}),
      };

  static String _relativeFuture(String unit, int? value) => switch ((unit, value)) {
        ('hours', 1) => trg('بعد ساعة'),
        ('hours', 2) => trg('بعد ساعتين'),
        ('hours', final v?) when v <= 10 => trgArgs('بعد {p0} ساعات', {'p0': v}),
        ('hours', final v?) => trgArgs('بعد {p0} ساعة', {'p0': v}),
        ('days', 1) => trg('غداً'),
        ('days', 2) => trg('بعد يومين'),
        ('days', final v?) when v <= 10 => trgArgs('بعد {p0} أيام', {'p0': v}),
        ('days', final v?) => trgArgs('بعد {p0} يوماً', {'p0': v}),
        _ => trg('خلال أقل من ساعة'),
      };

  factory PulseItem.fromJson(Map<String, dynamic> json) => PulseItem(
        type: json['type']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
        createdAt: parseServerUtc(json['createdAt']) ?? DateTime.now(),
        actorId: (json['actorId'] as num?)?.toInt(),
        actorName: json['actorName']?.toString(),
        highlight: json['highlight']?.toString(),
        matchId: (json['matchId'] as num?)?.toInt(),
        level: (json['level'] as num?)?.toInt(),
        points: (json['points'] as num?)?.toInt(),
        count: (json['count'] as num?)?.toInt(),
        relativeUnit: json['relativeUnit']?.toString(),
        relativeValue: (json['relativeValue'] as num?)?.toInt(),
      );
}
