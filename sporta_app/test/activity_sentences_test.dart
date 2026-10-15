import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sporta_app/core/localization/app_translations.dart';
import 'package:sporta_app/core/state/app_settings.dart';
import 'package:sporta_app/features/friends/domain/entities/feed_item.dart';
import 'package:sporta_app/features/home/domain/pulse_item.dart';

/// The pulse/feed sentences are composed in the app (the API only sends the
/// pieces), so both languages are asserted here — Arabic must keep the exact
/// wording the server used to send.
void main() {
  final settings = AppSettings();

  setUpAll(() => GetIt.I.registerSingleton<AppSettings>(settings));
  tearDownAll(() => GetIt.I.reset());

  void inLanguage(AppLanguage lang) => settings.setLanguage(lang);

  PulseItem pulse({
    required String type,
    String? actorName,
    int? level,
    int? points,
    int? count,
    String? relativeUnit,
    int? relativeValue,
    String text = 'FALLBACK',
  }) =>
      PulseItem(
        type: type,
        text: text,
        createdAt: DateTime.now(),
        actorName: actorName,
        level: level,
        points: points,
        count: count,
        relativeUnit: relativeUnit,
        relativeValue: relativeValue,
      );

  group('pulse sentences', () {
    test('level', () {
      final item = pulse(type: 'level', actorName: 'أحمد', level: 4);
      inLanguage(AppLanguage.ar);
      expect(item.localizedText, 'أحمد وصل لمستوى 4');
      inLanguage(AppLanguage.en);
      expect(item.localizedText, 'أحمد reached level 4');
      expect(item.localizedHighlight, '4');
    });

    test('points use Arabic singular/dual/plural forms', () {
      inLanguage(AppLanguage.ar);
      expect(pulse(type: 'points', actorName: 'سارة', points: 1).localizedText,
          'سارة حقق نقطة واحدة خلال اليوم');
      expect(pulse(type: 'points', actorName: 'سارة', points: 2).localizedText,
          'سارة حقق نقطتين خلال اليوم');
      expect(pulse(type: 'points', actorName: 'سارة', points: 5).localizedText,
          'سارة حقق 5 نقاط خلال اليوم');
      expect(pulse(type: 'points', actorName: 'سارة', points: 30).localizedText,
          'سارة حقق 30 نقطة خلال اليوم');

      inLanguage(AppLanguage.en);
      expect(pulse(type: 'points', actorName: 'Sara', points: 1).localizedText,
          'Sara earned 1 point today');
      expect(pulse(type: 'points', actorName: 'Sara', points: 30).localizedText,
          'Sara earned 30 points today');
    });

    test('points highlight only above two', () {
      expect(pulse(type: 'points', points: 2).localizedHighlight, isNull);
      expect(pulse(type: 'points', points: 9).localizedHighlight, '9');
    });

    test('match_seeking relative time', () {
      inLanguage(AppLanguage.ar);
      expect(
          pulse(type: 'match_seeking', actorName: 'خالد', relativeUnit: 'soon')
              .localizedText,
          'خالد يبحث عن شريك لمباراة خلال أقل من ساعة');
      expect(
          pulse(
                  type: 'match_seeking',
                  actorName: 'خالد',
                  relativeUnit: 'hours',
                  relativeValue: 2)
              .localizedText,
          'خالد يبحث عن شريك لمباراة بعد ساعتين');
      expect(
          pulse(
                  type: 'match_seeking',
                  actorName: 'خالد',
                  relativeUnit: 'days',
                  relativeValue: 1)
              .localizedText,
          'خالد يبحث عن شريك لمباراة غداً');

      inLanguage(AppLanguage.en);
      expect(
          pulse(
                  type: 'match_seeking',
                  actorName: 'Khaled',
                  relativeUnit: 'days',
                  relativeValue: 1)
              .localizedText,
          'Khaled is looking for a match partner tomorrow');
      expect(
          pulse(
                  type: 'match_seeking',
                  actorName: 'Khaled',
                  relativeUnit: 'hours',
                  relativeValue: 5)
              .localizedText,
          'Khaled is looking for a match partner in 5 hours');
    });

    test('level summary', () {
      inLanguage(AppLanguage.ar);
      expect(pulse(type: 'level_summary', count: 1).localizedText,
          'لاعب واحد حدّد مستواه اليوم');
      expect(pulse(type: 'level_summary', count: 2).localizedText,
          'لاعبان حدّدا مستواهما اليوم');
      expect(pulse(type: 'level_summary', count: 4).localizedText,
          '4 لاعبين حدّدوا مستواهم اليوم');

      inLanguage(AppLanguage.en);
      expect(pulse(type: 'level_summary', count: 4).localizedText,
          '4 players set their level today');
    });

    test('falls back to the server sentence without structured fields', () {
      inLanguage(AppLanguage.en);
      final item = pulse(type: 'level', text: 'أحمد وصل لمستوى 4');
      expect(item.localizedText, 'أحمد وصل لمستوى 4');
    });
  });

  group('feed sentences', () {
    FeedItem feed({
      required String type,
      String? venueName,
      String? coachName,
      int? level,
      String text = 'FALLBACK',
    }) =>
        FeedItem(
          actorId: 1,
          actorName: 'x',
          type: type,
          text: text,
          createdAt: DateTime.now(),
          venueName: venueName,
          coachName: coachName,
          level: level,
        );

    test('match joined', () {
      inLanguage(AppLanguage.ar);
      expect(feed(type: 'match_joined', venueName: 'نادي الأخضر').localizedText,
          'انضم إلى مباراة في نادي الأخضر');
      expect(feed(type: 'match_joined').localizedText, 'انضم إلى مباراة');

      inLanguage(AppLanguage.en);
      expect(feed(type: 'match_joined', venueName: 'Green Club').localizedText,
          'Joined a match at Green Club');
      expect(feed(type: 'match_joined').localizedText, 'Joined a match');
    });

    test('coach session', () {
      inLanguage(AppLanguage.en);
      expect(feed(type: 'coach_session', coachName: 'Ali').localizedText,
          'Booked a training session with coach Ali');
    });

    test('level uses the localized level name', () {
      inLanguage(AppLanguage.ar);
      expect(feed(type: 'level', level: 4).localizedText, 'حدّد مستواه: 4 - متوسط');
      inLanguage(AppLanguage.en);
      expect(
          feed(type: 'level', level: 4).localizedText, 'Set their level: 4 - Intermediate');
    });
  });
}
