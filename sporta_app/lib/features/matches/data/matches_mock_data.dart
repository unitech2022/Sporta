import '../../../core/constants/app_colors.dart';
import '../domain/entities/match_info.dart';
import '../presentation/widgets/matches_colors.dart';

/// Static mock data backing the matches page cards.
abstract class MatchesMockData {
  /// اللاعبون الأربعة — completed friendly singles match.
  static const List<MatchPlayerInfo> completedFriendlyPlayers = [
    MatchPlayerInfo(
      initials: 'م.أ',
      level: '5.0',
      gradient: [AppColors.primary, MatchesColors.primary80],
    ),
    MatchPlayerInfo(
      initials: 'ع.س',
      level: '4.8',
      gradient: [MatchesColors.blue500, MatchesColors.blue600],
    ),
    MatchPlayerInfo(
      initials: 'ف.ع',
      level: '5.2',
      gradient: [MatchesColors.purple500, MatchesColors.purple600],
    ),
    MatchPlayerInfo(
      initials: 'ب.ح',
      level: '4.6',
      gradient: [MatchesColors.orange500, MatchesColors.orange600],
    ),
  ];

  /// Completed team challenge match (first two = team 1, last two = team 2).
  static const List<MatchPlayerInfo> completedChallengePlayers = [
    MatchPlayerInfo(
      initials: 'أ.ز',
      gradient: [AppColors.primary, MatchesColors.primary80],
    ),
    MatchPlayerInfo(
      initials: 'س.م',
      gradient: [AppColors.primary, MatchesColors.primary80],
    ),
    MatchPlayerInfo(
      initials: 'خ.ع',
      gradient: [AppColors.secondary, MatchesColors.secondary80],
    ),
    MatchPlayerInfo(
      initials: 'ف.س',
      gradient: [AppColors.secondary, MatchesColors.secondary80],
    ),
  ];

  /// الفرق الأربعة — completed americano teams event.
  static const List<MatchTeamInfo> americanoTeams = [
    MatchTeamInfo(
      name: 'الصقور',
      players: [
        MatchPlayerInfo(
          initials: 'أ.ز',
          gradient: [AppColors.primary, MatchesColors.primary80],
        ),
        MatchPlayerInfo(
          initials: 'س.م',
          gradient: [MatchesColors.blue500, MatchesColors.blue600],
        ),
      ],
    ),
    MatchTeamInfo(
      name: 'النسور',
      players: [
        MatchPlayerInfo(
          initials: 'خ.ع',
          gradient: [MatchesColors.purple500, MatchesColors.purple600],
        ),
        MatchPlayerInfo(
          initials: 'ع.ش',
          gradient: [MatchesColors.indigo500, MatchesColors.indigo600],
        ),
      ],
    ),
    MatchTeamInfo(
      name: 'الأسود',
      players: [
        MatchPlayerInfo(
          initials: 'ف.ع',
          gradient: [MatchesColors.orange500, MatchesColors.orange600],
        ),
        MatchPlayerInfo(
          initials: 'م.س',
          gradient: [MatchesColors.red500, MatchesColors.red600],
        ),
      ],
    ),
    MatchTeamInfo(
      name: 'النمور',
      players: [
        MatchPlayerInfo(
          initials: 'ب.ح',
          gradient: [MatchesColors.teal500, MatchesColors.teal600],
        ),
        MatchPlayerInfo(
          initials: 'ف.د',
          gradient: [MatchesColors.green500, MatchesColors.green600],
        ),
      ],
    ),
  ];

  /// اللاعبون الثمانية — completed americano singles event.
  static const List<MatchPlayerInfo> americanoSinglesPlayers = [
    MatchPlayerInfo(
      initials: 'أ.ز',
      gradient: [AppColors.primary, MatchesColors.primary80],
    ),
    MatchPlayerInfo(
      initials: 'س.م',
      gradient: [MatchesColors.blue500, MatchesColors.blue600],
    ),
    MatchPlayerInfo(
      initials: 'ع.ش',
      gradient: [MatchesColors.purple500, MatchesColors.purple600],
    ),
    MatchPlayerInfo(
      initials: 'ف.س',
      gradient: [MatchesColors.green500, MatchesColors.green600],
    ),
    MatchPlayerInfo(
      initials: 'خ.ع',
      gradient: [MatchesColors.orange500, MatchesColors.orange600],
    ),
    MatchPlayerInfo(
      initials: 'م.س',
      gradient: [MatchesColors.teal500, MatchesColors.teal600],
    ),
    MatchPlayerInfo(
      initials: 'ف.ع',
      gradient: [MatchesColors.red400, MatchesColors.red500],
    ),
    MatchPlayerInfo(
      initials: 'ب.ح',
      gradient: [MatchesColors.indigo500, MatchesColors.indigo600],
    ),
  ];
}
