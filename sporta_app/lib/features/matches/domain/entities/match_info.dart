import 'dart:ui';

/// A player shown on a match card (initials avatar + optional level).
class MatchPlayerInfo {
  const MatchPlayerInfo({
    required this.initials,
    this.level,
    required this.gradient,
  });

  /// Arabic initials shown inside the avatar (e.g. 'م.أ').
  final String initials;

  /// Optional skill level shown under the avatar (e.g. '5.0').
  final String? level;

  /// Two-stop gradient used as the avatar background.
  final List<Color> gradient;
}

/// A two-player team shown on americano cards.
class MatchTeamInfo {
  const MatchTeamInfo({required this.name, required this.players});

  final String name;
  final List<MatchPlayerInfo> players;
}
