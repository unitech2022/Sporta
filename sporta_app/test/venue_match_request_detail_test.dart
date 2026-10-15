import 'package:flutter_test/flutter_test.dart';

import 'package:sporta_app/core/di/service_locator.dart';
import 'package:sporta_app/core/state/app_settings.dart';
import 'package:sporta_app/features/venue/domain/entities/venue_match_request_detail.dart';
import 'package:sporta_app/features/venue/presentation/match_request_format.dart';

/// The payload shape ASP.NET serializes for VenueMatchRequestDetailDto.
const _json = <String, dynamic>{
  'id': 42,
  'courtName': 'ملعب 1',
  'venueName': 'نادي الرياض',
  'creatorName': 'أحمد علي',
  'scheduledAt': '2026-08-14T18:30:00',
  'durationMinutes': 90,
  'maxPlayers': 4,
  'pricePerPlayer': 60.0,
  'paymentMode': 'full',
  'amountHeld': 240.0,
  'status': 'PendingApproval',
  'creatorId': 7,
  'creatorPhone': '0561883558',
  'creatorAvatarUrl': null,
  'matchType': 'doubles',
  'gender': 'female',
  'minLevel': 3.0,
  'maxLevel': 5.5,
  'notes': 'نلعب على ملعب 2',
  'createdAt': '2026-08-12T09:00:00',
  'currentPlayers': 2,
  'totalPrice': 240.0,
  'sportaCommissionPercent': 10.0,
  'ownerEarning': 216.0,
  'players': [
    {
      'userId': 7,
      'name': 'أحمد علي',
      'avatarUrl': null,
      'level': 4,
      'hasPaid': true,
      'status': 'approved',
      'isCreator': true,
      'joinedAt': '2026-08-12T09:00:00',
    },
    {
      'userId': 9,
      'name': 'سارة محمد',
      'level': null,
      'hasPaid': false,
      'status': 'pending',
      'isCreator': false,
      'joinedAt': '2026-08-12T10:00:00',
    },
  ],
};

void main() {
  // التنسيقات تترجم عبر trg/AppDates، وهي تقرأ اللغة من AppSettings في getIt.
  setUpAll(() {
    if (!getIt.isRegistered<AppSettings>()) {
      getIt.registerSingleton<AppSettings>(AppSettings());
    }
  });

  group('VenueMatchRequestDetail.fromJson', () {
    test('reads the card fields and the detail-only fields', () {
      final d = VenueMatchRequestDetail.fromJson(_json);

      // Inherited card fields.
      expect(d.id, 42);
      expect(d.courtName, 'ملعب 1');
      expect(d.status, 'PendingApproval');
      expect(d.isFullPayment, isTrue);
      expect(d.amountHeld, 240);

      // Detail-only fields.
      expect(d.creatorPhone, '0561883558');
      expect(d.isWomen, isTrue);
      expect(d.minLevel, 3);
      expect(d.maxLevel, 5.5);
      expect(d.currentPlayers, 2);
      expect(d.ownerEarning, 216);
      expect(d.notes, 'نلعب على ملعب 2');
    });

    test('parses the players list with their flags', () {
      final d = VenueMatchRequestDetail.fromJson(_json);
      expect(d.players.length, 2);

      final creator = d.players.first;
      expect(creator.isCreator, isTrue);
      expect(creator.hasPaid, isTrue);
      expect(creator.isApproved, isTrue);
      expect(creator.level, 4);

      final joiner = d.players.last;
      expect(joiner.isCreator, isFalse);
      expect(joiner.hasPaid, isFalse);
      expect(joiner.isApproved, isFalse, reason: 'pending join request');
      expect(joiner.level, isNull);
    });

    test('survives a payload with the optional fields missing', () {
      final d = VenueMatchRequestDetail.fromJson(const {'id': 5});
      expect(d.id, 5);
      expect(d.players, isEmpty);
      expect(d.creatorPhone, '');
      expect(d.ownerEarning, 0);
      expect(d.isWomen, isFalse);
    });
  });

  group('match request formatting', () {
    test('formats the schedule in Arabic', () {
      expect(
        formatMatchWhen(DateTime(2026, 8, 14, 18, 30)),
        'الجمعة 14 أغسطس · 6:30 مساءً',
      );
      expect(
        formatMatchWhen(DateTime(2026, 8, 14, 0, 5)),
        'الجمعة 14 أغسطس · 12:05 صباحاً',
      );
    });

    test('labels every status the owner can filter by', () {
      expect(matchStatusLabelAr('PendingApproval'), 'قيد الموافقة');
      expect(matchStatusLabelAr('Open'), 'مقبولة');
      expect(matchStatusLabelAr('Cancelled'), 'ملغاة');
      expect(matchStatusLabelAr('Whatever'), 'Whatever');
    });
  });
}
