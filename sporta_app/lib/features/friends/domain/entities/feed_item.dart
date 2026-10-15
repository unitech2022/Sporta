import '../../../../core/localization/app_translations.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../level/domain/level_question.dart';
import '../../../../core/utils/server_time.dart';

/// One activity item in the followed-players feed.
class FeedItem {
  const FeedItem({
    required this.actorId,
    required this.actorName,
    required this.type,
    required this.text,
    required this.createdAt,
    this.venueName,
    this.level,
    this.coachName,
  });

  final int actorId;
  final String actorName;

  /// "match_joined" | "coach_session" | "level".
  final String type;

  /// Arabic sentence built by the server. Only a fallback: [localizedText]
  /// rebuilds the sentence in the app language from the structured fields.
  final String text;
  final DateTime createdAt;

  /// `match_joined`: the venue, already picked per app language (null when the
  /// match has no court). `coach_session`: the coach. `level`: the level set.
  final String? venueName;
  final String? coachName;
  final int? level;

  /// The sentence in the app language, or the server's Arabic [text] when the
  /// structured fields are missing (an older API).
  String get localizedText {
    switch (type) {
      case 'match_joined':
        final venue = venueName;
        return venue == null || venue.isEmpty
            ? trg('انضم إلى مباراة')
            : trgArgs('انضم إلى مباراة في {p0}', {'p0': venue});
      case 'coach_session' when coachName != null:
        return trgArgs('حجز جلسة تدريب مع المدرب {p0}', {'p0': coachName});
      case 'level' when level != null:
        final lang = isAppArabic ? AppLanguage.ar : AppLanguage.en;
        return trgArgs('حدّد مستواه: {p0} - {p1}',
            {'p0': level, 'p1': playerLevelName(level!, lang)});
      default:
        return text;
    }
  }

  factory FeedItem.fromJson(Map<String, dynamic> json) => FeedItem(
        actorId: (json['actorId'] as num?)?.toInt() ?? 0,
        actorName: json['actorName']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
        venueName: json['venueName'] == null
            ? null
            : localizedServerName(json['venueName'], json['venueNameEn']),
        coachName: json['coachName']?.toString(),
        level: (json['level'] as num?)?.toInt(),
        createdAt: parseServerUtc(json['createdAt']) ?? DateTime.now(),
      );
}
