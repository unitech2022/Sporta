/// Connection status of a player (mirrors `'online' | 'offline'` in the TSX).
enum PlayerStatus { online, offline }

/// Player entity mirroring the `Player` interface in
/// JoinMatchPage.tsx / SelectTeammatePage.tsx.
class Player {
  const Player({
    required this.id,
    required this.name,
    required this.level,
    required this.gamesPlayed,
    this.winRate,
    this.status = PlayerStatus.offline,
  });

  final String id;
  final String name;

  /// Skill level, e.g. '5.2'.
  final String level;
  final int gamesPlayed;

  /// Win percentage (0-100), null when unknown.
  final double? winRate;
  final PlayerStatus status;

  bool get isOnline => status == PlayerStatus.online;
}

/// Match summary passed to SelectTeammatePage (mirrors the
/// `matchDetails` prop object in SelectTeammatePage.tsx).
class TeammateMatchDetails {
  const TeammateMatchDetails({
    required this.courtName,
    required this.date,
    required this.time,
    required this.costPerPlayer,
    required this.minLevel,
    required this.maxLevel,
  });

  final String courtName;

  /// ISO date, e.g. '2024-06-02'.
  final String date;

  /// 24h time, e.g. '18:00'.
  final String time;
  final double costPerPlayer;
  final String minLevel;
  final String maxLevel;
}
