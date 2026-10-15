import '../domain/entities/match_entity.dart';
import '../../../core/localization/tr_global.dart';

/// Why a player may not join a match, or null when they may.
///
/// This mirrors the server's `LEVEL_NOT_ALLOWED` guard so the app can say no
/// before charging the player's wallet. The server stays authoritative — this
/// only saves the user from confirming a payment that would be rejected.
String? matchLevelBlockReason(MatchEntity match, int? playerLevel) {
  // No assessed level yet: the server lets these players through, so must we.
  if (playerLevel == null) return null;

  if (playerLevel < match.minLevel || playerLevel > match.maxLevel) {
    return trgArgs('مستواك ({p0}) خارج نطاق هذه المباراة ({p1} - {p2})', {
      'p0': playerLevel,
      'p1': _lvl(match.minLevel),
      'p2': _lvl(match.maxLevel),
    });
  }
  return null;
}

/// Levels are whole numbers 1..7; drop the decimal the API sends.
String _lvl(double v) => v.toStringAsFixed(0);
