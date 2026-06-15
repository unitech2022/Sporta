import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/matches_mock_data.dart';
import '../../domain/entities/match_info.dart';
import 'matches_americano_stats.dart';
import 'matches_colors.dart';
import 'matches_match_card.dart';
import 'matches_pill.dart';
import 'matches_player_avatar.dart';

/// محتوى أمريكانو — the five americano cards.
class MatchesAmericanoTab extends StatelessWidget {
  const MatchesAmericanoTab({super.key, this.onNavigate});

  final void Function(String page, [String? matchType])? onNavigate;

  void _navigate(String page, [String? matchType]) =>
      onNavigate?.call(page, matchType);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _registrationOpenCard(),
        const SizedBox(height: AppSizes.lg),
        _availableSinglesCard(),
        const SizedBox(height: AppSizes.lg),
        _limitedSpotsCard(),
        const SizedBox(height: AppSizes.lg),
        _completedTeamsCard(),
        const SizedBox(height: AppSizes.lg),
        _completedSinglesCard(),
      ],
    );
  }

  /// أمريكانو فرق — جاري التسجيل (highlighted yellow card).
  Widget _registrationOpenCard() {
    return MatchesMatchCard(
      backgroundGradient: LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [
          MatchesColors.yellow50,
          MatchesColors.yellow100.withValues(alpha: 0.5),
        ],
      ),
      borderColor: MatchesColors.yellow400.withValues(alpha: 0.5),
      borderWidth: 2,
      dividerColor: MatchesColors.yellow300,
      badges: const [
        MatchesPill(
          label: 'جاري التسجيل',
          background: MatchesColors.yellow500,
          foreground: Colors.white,
        ),
        MatchesPill(
          label: 'أمريكانو فرق',
          background: MatchesColors.purple100,
          foreground: MatchesColors.purple600,
        ),
      ],
      level: 'مستوى: 5.0 - 6.5',
      levelTooltip: 'مستوى اللاعبين المطلوب',
      venue: 'أمريكانو البادل الملكي',
      venueBold: true,
      venueDetail: 'نادي البادل الملكي • 1.8 كم',
      locationIconColor: MatchesColors.yellow600,
      body: MatchesAmericanoStats(
        background: Colors.white.withValues(alpha: 0.6),
        registered: '8 / 12',
        registeredColor: MatchesColors.yellow600,
        courts: '3 ملاعب',
        courtsColor: MatchesColors.yellow600,
      ),
      time: 'اليوم، 6:00 مساءً',
      timeIconColor: MatchesColors.yellow600,
      actionLabel: 'انضم الآن',
      actionColor: MatchesColors.yellow500,
      onAction: () => _navigate('join-americano'),
    );
  }

  /// أمريكانو فردي — متاح.
  Widget _availableSinglesCard() {
    return MatchesMatchCard(
      badges: const [
        MatchesPill(
          label: 'متاح',
          background: MatchesColors.green100,
          foreground: MatchesColors.green600,
        ),
        MatchesPill(
          label: 'أمريكانو فردي',
          background: MatchesColors.blue100,
          foreground: MatchesColors.blue600,
        ),
      ],
      level: 'مستوى: 4.0 - 5.0',
      levelTooltip: 'مستوى اللاعبين المطلوب',
      venue: 'أمريكانو الأندية الشرقية',
      venueBold: true,
      venueDetail: 'ملعب الأندية الشرقية • 3.2 كم',
      body: const MatchesAmericanoStats(
        background: MatchesColors.gray50,
        registered: '4 / 16',
        registeredColor: AppColors.primary,
        courts: '4 ملاعب',
        courtsColor: AppColors.primary,
      ),
      time: 'غداً، 5:00 مساءً',
      actionLabel: 'انضم',
      onAction: () => _navigate('join-americano'),
    );
  }

  /// أمريكانو فرق — أماكن محدودة.
  Widget _limitedSpotsCard() {
    return MatchesMatchCard(
      badges: const [
        MatchesPill(
          label: 'أماكن محدودة',
          background: MatchesColors.orange100,
          foreground: MatchesColors.orange600,
        ),
        MatchesPill(
          label: 'أمريكانو فرق',
          background: MatchesColors.purple100,
          foreground: MatchesColors.purple600,
        ),
      ],
      level: 'مستوى: 3.5 - 4.5',
      levelTooltip: 'مستوى اللاعبين المطلوب',
      venue: 'أمريكانو الرياضة',
      venueBold: true,
      venueDetail: 'نادي الرياضة للبادل • 4.5 كم',
      body: const MatchesAmericanoStats(
        background: MatchesColors.gray50,
        registered: '10 / 12',
        registeredColor: MatchesColors.orange600,
        courts: '3 ملاعب',
        courtsColor: AppColors.primary,
      ),
      time: 'بعد غد، 7:00 مساءً',
      actionLabel: 'انضم',
      onAction: () => _navigate('join-americano'),
    );
  }

  /// أمريكانو فرق — مكتمل (purple completed card).
  Widget _completedTeamsCard() {
    return MatchesMatchCard(
      backgroundGradient: LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [
          MatchesColors.purple50,
          MatchesColors.purple100.withValues(alpha: 0.3),
        ],
      ),
      borderColor: MatchesColors.purple300,
      borderWidth: 2,
      dividerColor: MatchesColors.purple200,
      onTap: () => _navigate('match-result', 'أمريكانو فرق'),
      badges: const [
        MatchesPill(
          label: 'مكتمل 8/8',
          background: MatchesColors.purple600,
          foreground: Colors.white,
          icon: Icons.check_circle,
        ),
        MatchesPill(
          label: 'أمريكانو فرق',
          background: MatchesColors.purple100,
          foreground: MatchesColors.purple600,
        ),
      ],
      level: 'مستوى: 4.5 - 5.5',
      venue: 'نادي البادل الملكي',
      venueDetail: '1.8 كم • ملعبان داخليان',
      locationIconColor: MatchesColors.purple600,
      body: Column(
        children: [
          for (var row = 0; row < 2; row++) ...[
            if (row > 0) const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                for (var col = 0; col < 2; col++) ...[
                  if (col > 0) const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _TeamTile(
                      team: MatchesMockData.americanoTeams[row * 2 + col],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
      time: 'اليوم، 6:00 مساءً',
      timeIconColor: MatchesColors.purple600,
      actionLabel: 'مكتمل',
      actionColor: MatchesColors.purple600,
      actionIcon: Icons.check_circle,
      onAction: () => _navigate('match-result', 'أمريكانو فرق'),
    );
  }

  /// أمريكانو فردي — مكتمل (teal completed card).
  Widget _completedSinglesCard() {
    return MatchesMatchCard(
      backgroundGradient: LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [
          MatchesColors.teal50,
          MatchesColors.cyan100.withValues(alpha: 0.3),
        ],
      ),
      borderColor: MatchesColors.teal300,
      borderWidth: 2,
      dividerColor: MatchesColors.teal200,
      onTap: () => _navigate('match-result', 'أمريكانو فردي'),
      badges: const [
        MatchesPill(
          label: 'مكتمل 8/8',
          background: MatchesColors.teal600,
          foreground: Colors.white,
          icon: Icons.check_circle,
        ),
        MatchesPill(
          label: 'أمريكانو فردي',
          background: MatchesColors.teal100,
          foreground: MatchesColors.teal700,
        ),
      ],
      level: 'مستوى: 3.5 - 5.2',
      venue: 'نادي النخبة للبادل',
      venueDetail: '2.1 كم • ملعبان داخليان',
      locationIconColor: MatchesColors.teal600,
      body: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final player in MatchesMockData.americanoSinglesPlayers)
            MatchesPlayerAvatar(
              label: player.initials,
              gradient: player.gradient,
              size: 32,
              fontSize: 9,
              borderColor: Colors.white,
              borderWidth: 1,
            ),
        ],
      ),
      time: 'اليوم، 4:00 مساءً',
      timeIconColor: MatchesColors.teal600,
      actionLabel: 'مكتمل',
      actionColor: MatchesColors.teal600,
      actionIcon: Icons.check_circle,
      onAction: () => _navigate('match-result', 'أمريكانو فردي'),
    );
  }
}

/// One of the four team tiles inside the completed americano teams card.
class _TeamTile extends StatelessWidget {
  const _TeamTile({required this.team});

  final MatchTeamInfo team;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: MatchesColors.purple200),
      ),
      child: Row(
        children: [
          MatchesAvatarStack(
            size: 28,
            overlap: 6,
            children: [
              for (final player in team.players)
                MatchesPlayerAvatar(
                  label: player.initials,
                  gradient: player.gradient,
                  size: 28,
                  fontSize: 9,
                  borderColor: Colors.white,
                  borderWidth: 1,
                ),
            ],
          ),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              team.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}
