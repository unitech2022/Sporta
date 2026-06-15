import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/match_result_mock_data.dart';
import 'match_result_gradient_avatar.dart';

/// Compact team label: overlapping player avatars + team name
/// (TSX `TeamChip`).
class MatchResultTeamChip extends StatelessWidget {
  const MatchResultTeamChip({
    super.key,
    required this.team,
    this.medium = false,
  });

  final AmericanoTeam team;
  final bool medium;

  @override
  Widget build(BuildContext context) {
    final avatarSize = medium ? 32.0 : 24.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MatchResultAvatarStack(
          size: avatarSize,
          overlap: 6,
          avatars: [
            for (final p in team.players)
              MatchResultGradientAvatar(
                text: p.avatar,
                gradient: p.gradient,
                size: avatarSize,
                borderWidth: 2,
              ),
          ],
        ),
        const SizedBox(width: 6),
        Text(
          team.label,
          style: TextStyle(
            fontSize: medium ? 14 : 12,
            color: AppColors.secondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Two overlapping player avatars + short names + average level,
/// used for "أمريكانو فردي" court sides (TSX `TeamSide`).
class MatchResultSoloTeamSide extends StatelessWidget {
  const MatchResultSoloTeamSide({
    super.key,
    required this.players,
    required this.avgLabel,
  });

  final List<MatchResultPlayer> players;
  final String avgLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MatchResultAvatarStack(
          size: 32,
          overlap: 6,
          avatars: [
            for (final p in players)
              MatchResultGradientAvatar(
                text: p.avatar,
                gradient: p.gradient,
                size: 32,
                borderWidth: 2,
                fontSize: 9,
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          players.map((p) => p.short).join(' & '),
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.secondary,
            height: 1.4,
          ),
        ),
        Text(
          'متوسط $avgLabel',
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.mutedForeground,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
