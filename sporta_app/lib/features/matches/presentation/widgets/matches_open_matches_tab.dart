import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/matches_mock_data.dart';
import 'matches_colors.dart';
import 'matches_match_card.dart';
import 'matches_pill.dart';
import 'matches_player_avatar.dart';

/// محتوى المباريات المفتوحة — the five open-match cards.
class MatchesOpenMatchesTab extends StatelessWidget {
  const MatchesOpenMatchesTab({super.key, this.onNavigate});

  final void Function(String page, [String? matchType])? onNavigate;

  void _navigate(String page, [String? matchType]) =>
      onNavigate?.call(page, matchType);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _availableTeamChallengeCard(),
        const SizedBox(height: AppSizes.lg),
        _needsOnePlayerCard(),
        const SizedBox(height: AppSizes.lg),
        _availableFriendlyTeamsCard(),
        const SizedBox(height: AppSizes.lg),
        _completedFriendlySinglesCard(),
        const SizedBox(height: AppSizes.lg),
        _completedTeamChallengeCard(),
      ],
    );
  }

  /// تحدي فرق — متاحة الآن (highlighted primary card).
  Widget _availableTeamChallengeCard() {
    return MatchesMatchCard(
      backgroundGradient: LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [
          AppColors.primary.withValues(alpha: 0.05),
          AppColors.primary.withValues(alpha: 0.10),
        ],
      ),
      borderColor: AppColors.primary.withValues(alpha: 0.3),
      borderWidth: 2,
      dividerColor: AppColors.primary.withValues(alpha: 0.2),
      badges: const [
        MatchesPill(
          label: 'متاحة الآن',
          background: AppColors.primary,
          foreground: AppColors.onPrimary,
        ),
        MatchesPill(
          label: 'تحدي فرق',
          background: MatchesColors.purple100,
          foreground: MatchesColors.purple600,
          tooltip: 'مباراة تحدي للفرق (2 ضد 2)',
        ),
      ],
      level: 'مستوى: 5.0 - 6.0',
      levelTooltip: 'مستوى اللاعبين المطلوب',
      venue: 'نادي البادل الملكي',
      venueDetail: '1.8 كم • ملعب خارجي',
      body: Row(
        children: [
          const MatchesAvatarStack(
            children: [
              MatchesPlayerAvatar(
                label: '4.5',
                gradient: [AppColors.primary, MatchesColors.primary80],
                borderColor: Colors.white,
              ),
              MatchesPlayerAvatar(
                label: '4.2',
                gradient: [AppColors.secondary, MatchesColors.secondary80],
                borderColor: Colors.white,
              ),
              MatchesPlayerAvatar(
                icon: Icons.group,
                dashed: true,
              ),
            ],
          ),
          SizedBox(width: AppSizes.md),
          Flexible(
            child: Text('يحتاج لاعبين (2)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption),
          ),
        ],
      ),
      time: 'اليوم، 6:00 مساءً',
      actionLabel: 'انضم الآن',
      onAction: () => _navigate('join-match', 'تحدي فرق'),
    );
  }

  /// ودية فردي — يحتاج لاعب واحد.
  Widget _needsOnePlayerCard() {
    return MatchesMatchCard(
      badges: const [
        MatchesPill(
          label: 'يحتاج لاعب واحد',
          background: MatchesColors.orange100,
          foreground: MatchesColors.orange600,
        ),
        MatchesPill(
          label: 'ودية فردي',
          background: MatchesColors.blue100,
          foreground: MatchesColors.blue600,
          tooltip: 'مباراة ودية فردية (كل لاعب لوحده)',
        ),
      ],
      level: 'مستوى: 4.5 - 5.5',
      levelTooltip: 'مستوى اللاعبين المطلوب',
      venue: 'ملعب الأندية الشرقية',
      venueDetail: '3.2 كم • ملعب داخلي',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MatchesPlayerAvatar(
                label: '3.8',
                gradient: [AppColors.primary, MatchesColors.primary80],
              ),
              SizedBox(width: AppSizes.sm),
              Text('vs', style: AppTextStyles.caption),
              SizedBox(width: AppSizes.sm),
              const MatchesPlayerAvatar(
                label: '4.1',
                gradient: [AppColors.secondary, MatchesColors.secondary80],
              ),
              SizedBox(width: AppSizes.sm),
              Text('vs', style: AppTextStyles.caption),
              SizedBox(width: AppSizes.sm),
              const MatchesPlayerAvatar(
                label: '4.3',
                gradient: [MatchesColors.orange500, MatchesColors.orange600],
              ),
              SizedBox(width: AppSizes.sm),
              Text('vs', style: AppTextStyles.caption),
              SizedBox(width: AppSizes.sm),
              const MatchesPlayerAvatar(
                label: '?',
                color: MatchesColors.gray300,
              ),
            ],
          ),
          SizedBox(height: AppSizes.lg),
          Text(
            'مباراة فردية (4 لاعبين) • يحتاج لاعب واحد',
            style: AppTextStyles.caption,
          ),
        ],
      ),
      time: 'غداً، 7:30 مساءً',
      actionLabel: 'انضم الآن',
      onAction: () => _navigate('join-match', 'ودية فردي'),
    );
  }

  /// ودية فرق — متاحة.
  Widget _availableFriendlyTeamsCard() {
    return MatchesMatchCard(
      badges: const [
        MatchesPill(
          label: 'متاحة',
          background: MatchesColors.green100,
          foreground: MatchesColors.green600,
        ),
        MatchesPill(
          label: 'ودية فرق',
          background: MatchesColors.teal100,
          foreground: MatchesColors.teal600,
          tooltip: 'مباراة ودية للفرق (2 ضد 2)',
        ),
      ],
      level: 'مستوى: 3.5 - 4.5',
      levelTooltip: 'مستوى اللاعبين المطلوب',
      venue: 'نادي الرياضة للبادل',
      venueDetail: '4.5 كم • ملعب خارجي',
      body: Row(
        children: [
          const MatchesAvatarStack(
            children: [
              MatchesPlayerAvatar(
                label: '3.5',
                gradient: [AppColors.primary, MatchesColors.primary80],
                borderColor: Colors.white,
              ),
              MatchesPlayerAvatar(
                label: '3.9',
                gradient: [AppColors.secondary, MatchesColors.secondary80],
                borderColor: Colors.white,
              ),
            ],
          ),
          SizedBox(width: AppSizes.md),
          Text('يحتاج فريق (2)', style: AppTextStyles.caption),
        ],
      ),
      time: 'بعد غد، 5:30 مساءً',
      actionLabel: 'انضم الآن',
      onAction: () => _navigate('join-match', 'ودية فرق'),
    );
  }

  /// ودية فردي — مكتملة (blue completed card).
  Widget _completedFriendlySinglesCard() {
    return MatchesMatchCard(
      backgroundGradient: LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [
          MatchesColors.blue50,
          MatchesColors.blue100.withValues(alpha: 0.3),
        ],
      ),
      borderColor: MatchesColors.blue300,
      borderWidth: 2,
      dividerColor: MatchesColors.blue200,
      onTap: () => _navigate('match-result', 'ودية فردي'),
      badges: const [
        MatchesPill(
          label: 'مكتملة 4/4',
          background: MatchesColors.blue500,
          foreground: Colors.white,
          icon: Icons.check_circle,
        ),
        MatchesPill(
          label: 'ودية فردي',
          background: MatchesColors.blue100,
          foreground: MatchesColors.blue600,
        ),
      ],
      level: 'مستوى: 4.5 - 5.5',
      venue: 'ملعب الأندية الشرقية',
      venueDetail: '3.2 كم • ملعب داخلي',
      locationIconColor: MatchesColors.blue500,
      body: Row(
        children: [
          for (final player in MatchesMockData.completedFriendlyPlayers) ...[
            Column(
              children: [
                MatchesPlayerAvatar(
                  label: player.initials,
                  gradient: player.gradient,
                  fontSize: 12,
                ),
                SizedBox(height: 2),
                Text(player.level ?? '', style: AppTextStyles.caption),
              ],
            ),
            SizedBox(width: AppSizes.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'جاهزة لإدخال النتيجة',
                  style: AppTextStyles.caption
                      .copyWith(color: MatchesColors.blue600),
                ),
                Text(
                  'مباراة فردية (4 لاعبين)',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
      time: 'اليوم، 7:30 مساءً',
      timeIconColor: MatchesColors.blue500,
      actionLabel: 'مكتملة',
      actionColor: MatchesColors.blue500,
      actionIcon: Icons.check_circle,
      onAction: () => _navigate('match-result', 'ودية فردي'),
    );
  }

  /// تحدي فرق — مكتملة (green completed card).
  Widget _completedTeamChallengeCard() {
    return MatchesMatchCard(
      backgroundGradient: LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [
          MatchesColors.green50,
          MatchesColors.green100.withValues(alpha: 0.3),
        ],
      ),
      borderColor: MatchesColors.green300,
      borderWidth: 2,
      dividerColor: MatchesColors.green200,
      onTap: () => _navigate('match-result', 'تحدي فرق'),
      badges: const [
        MatchesPill(
          label: 'مكتملة 4/4',
          background: MatchesColors.green500,
          foreground: Colors.white,
          icon: Icons.check_circle,
        ),
        MatchesPill(
          label: 'تحدي فرق',
          background: MatchesColors.purple100,
          foreground: MatchesColors.purple600,
          tooltip: 'مباراة تحدي للفرق (2 ضد 2)',
        ),
      ],
      level: 'مستوى: 5.0 - 6.0',
      venue: 'نادي النخبة للبادل',
      venueDetail: '2.1 كم • ملعب داخلي',
      locationIconColor: MatchesColors.green600,
      body: Row(
        children: [
          MatchesAvatarStack(
            children: [
              for (final player
                  in MatchesMockData.completedChallengePlayers)
                MatchesPlayerAvatar(
                  label: player.initials,
                  gradient: player.gradient,
                  borderColor: Colors.white,
                  fontSize: 12,
                ),
            ],
          ),
          SizedBox(width: AppSizes.md),
          Flexible(
            child: Text(
              'جاهزة لإدخال النتيجة',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption
                  .copyWith(color: MatchesColors.green600),
            ),
          ),
        ],
      ),
      time: 'اليوم، 5:00 مساءً',
      timeIconColor: MatchesColors.green600,
      actionLabel: 'مكتملة',
      actionColor: MatchesColors.green500,
      actionIcon: Icons.check_circle,
      onAction: () => _navigate('match-result', 'تحدي فرق'),
    );
  }
}
