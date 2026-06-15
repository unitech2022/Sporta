import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/match_result_mock_data.dart';
import '../widgets/match_result_court_card.dart';
import '../widgets/match_result_gradient_avatar.dart';
import '../widgets/match_result_round_card.dart';
import '../widgets/match_result_schedule_header.dart';
import '../widgets/match_result_score_input.dart';
import '../widgets/match_result_setup_card.dart';
import '../widgets/match_result_standings_card.dart';
import '../widgets/match_result_team_chip.dart';
import '../widgets/match_result_winner_banner.dart';

/// نتيجة المباراة — converted from MatchResultPage.tsx.
/// Handles 4 match types via [matchType]:
///   null / 'تحدي فرق' → team challenge
///   'ودية فردي'       → friendly individual
///   'أمريكانو فرق'    → americano teams
///   'أمريكانو فردي'   → americano solo
class MatchResultPage extends StatefulWidget {
  const MatchResultPage({super.key, required this.onBack, this.matchType});

  final VoidCallback onBack;
  final String? matchType;

  @override
  State<MatchResultPage> createState() => _MatchResultPageState();
}

// ─── accent palette helpers ───────────────────────────────────────────────
const _purple600 = MRColors.purple600;
const _purple700 = MRColors.purple700;
const _purple50 = MRColors.purple50;
const _purple200 = MRColors.purple200;
const _purple400 = MRColors.purple400;

const _teal600 = MRColors.teal600;
const _teal700 = MRColors.teal700;
const _teal50 = MRColors.teal50;
const _teal200 = MRColors.teal200;
const _teal400 = MRColors.teal400;

const _blue500 = MRColors.blue500;
const _blue100 = MRColors.blue100;
const _blue200 = MRColors.blue200;
const _blue400 = MRColors.blue400;

const _orange50 = MRColors.orange50;
const _orange400 = MRColors.orange400;

class _MatchResultPageState extends State<MatchResultPage> {
  bool get _isSolo => widget.matchType == 'ودية فردي';
  bool get _isATeams => widget.matchType == 'أمريكانو فرق';
  bool get _isASolo => widget.matchType == 'أمريكانو فردي';

  // ── shared ──────────────────────────────────────────────────────────────
  bool _submitted = false;
  final Map<String, int> _ratings = {};

  // ── ودية فردي ────────────────────────────────────────────────────────────
  late List<FriendlyRound> _rounds;

  // ── تحدي فرق ────────────────────────────────────────────────────────────
  late List<TeamChallengeSet> _sets;
  String? _winner; // 'team1' | 'team2'

  // ── أمريكانو فرق ─────────────────────────────────────────────────────────
  bool _aSetupDone = false;
  MatchResultMode _aMode = MatchResultMode.sets;
  int _aTimePerRound = 15;
  int _aSetsCount = 1;
  String _aStartTime = '18:00';
  List<AmericanoRound> _aSchedule = [];
  int? _aExpandedRound;

  // ── أمريكانو فردي ────────────────────────────────────────────────────────
  bool _asSetupDone = false;
  MatchResultMode _asMode = MatchResultMode.sets;
  int _asTimePerRound = 15;
  int _asSetsCount = 1;
  String _asStartTime = '18:00';
  List<AmericanoRound> _asSchedule = [];
  int? _asExpandedRound;

  @override
  void initState() {
    super.initState();
    _rounds = [makeFriendlyRound(0)];
    _sets = [TeamChallengeSet()];
  }

  // ─── computed ─────────────────────────────────────────────────────────────

  Map<String, int> get _soloPoints {
    final pts = <String, int>{};
    for (final r in _rounds) {
      final a = int.tryParse(r.scoreA) ?? 0;
      final b = int.tryParse(r.scoreB) ?? 0;
      for (final id in r.teamA) {
        pts[id] = (pts[id] ?? 0) + a;
      }
      for (final id in r.teamB) {
        pts[id] = (pts[id] ?? 0) + b;
      }
    }
    return pts;
  }

  List<MatchResultPlayer> get _soloRanked => [...soloPlayers]
    ..sort((a, b) => (_soloPoints[b.id] ?? 0) - (_soloPoints[a.id] ?? 0));

  bool get _roundsComplete =>
      _rounds.isNotEmpty &&
      _rounds.every((r) =>
          r.teamA.length == 2 &&
          r.teamB.length == 2 &&
          r.scoreA.isNotEmpty &&
          r.scoreB.isNotEmpty);

  bool get _teamComplete =>
      _sets.every((s) => s.t1.isNotEmpty && s.t2.isNotEmpty) &&
      _winner != null;

  Map<String, int> get _aPoints =>
      calcAmericanoPoints(_aSchedule, _aMode);

  List<AmericanoTeam> get _aRanked => [...americanoTeams]
    ..sort((a, b) => (_aPoints[b.id] ?? 0) - (_aPoints[a.id] ?? 0));

  bool get _aComplete =>
      _aSetupDone && isAmericanoScheduleComplete(_aSchedule, _aMode);

  Map<String, int> get _asPoints =>
      calcAmericanoPoints(_asSchedule, _asMode);

  List<MatchResultPlayer> get _asRanked => [...americanoSoloPlayers]
    ..sort((a, b) => (_asPoints[b.id] ?? 0) - (_asPoints[a.id] ?? 0));

  bool get _asComplete =>
      _asSetupDone && isAmericanoScheduleComplete(_asSchedule, _asMode);

  bool get _canSubmit => _isATeams
      ? _aComplete
      : _isASolo
          ? _asComplete
          : _isSolo
              ? _roundsComplete
              : _teamComplete;

  // ─── accent colors by match type ─────────────────────────────────────────

  Color get _accent =>
      _isATeams ? _purple600 : _isASolo ? _teal600 : AppColors.primary;
  Color get _accentLight =>
      _isATeams ? _purple50 : _isASolo ? _teal50 : _blue100;
  Color get _accentText =>
      _isATeams ? _purple700 : _isASolo ? _teal700 : _blue500;

  List<Color> get _headerGradient => _isATeams
      ? const [Color(0xFF6D28D9), Color(0xFF4C1D95)]
      : _isASolo
          ? const [MRColors.teal700, MRColors.cyan900]
          : _isSolo
              ? const [MRColors.blue700, Color(0xFF1E3A8A)]
              : const [AppColors.secondary, Color(0xE60A2540)];

  // ─── mutations ───────────────────────────────────────────────────────────

  void _updateRound(String id, String field, dynamic value) {
    setState(() {
      final r = _rounds.firstWhere((r) => r.id == id);
      if (field == 'scoreA') r.scoreA = value as String;
      if (field == 'scoreB') r.scoreB = value as String;
      if (field == 'teamA') r.teamA = value as List<String>;
      if (field == 'teamB') r.teamB = value as List<String>;
    });
  }

  void _swapPlayer(String roundId, String pid) {
    setState(() {
      final r = _rounds.firstWhere((r) => r.id == roundId);
      if (r.teamA.contains(pid)) {
        r.teamA = r.teamA.where((x) => x != pid).toList();
        r.teamB = [...r.teamB, pid];
      } else {
        r.teamB = r.teamB.where((x) => x != pid).toList();
        r.teamA = [...r.teamA, pid];
      }
    });
  }

  void _generateATeamsSchedule() {
    setState(() {
      _aSchedule =
          generateTeamsSchedule(_aMode, _aStartTime, _aTimePerRound, _aSetsCount);
      _aSetupDone = true;
      _aExpandedRound = 0;
    });
  }

  void _generateASoloSchedule() {
    setState(() {
      _asSchedule =
          generateSoloSchedule(_asMode, _asStartTime, _asTimePerRound, _asSetsCount);
      _asSetupDone = true;
      _asExpandedRound = 0;
    });
  }

  void _updateAScore(int ri, String court, String field, String val) {
    setState(() {
      final m = court == 'court1' ? _aSchedule[ri].court1 : _aSchedule[ri].court2;
      if (field == 'scoreA') m.scoreA = val;
      if (field == 'scoreB') m.scoreB = val;
    });
  }

  void _updateASet(int ri, String court, int si, bool isSideA, String val) {
    setState(() {
      final m = court == 'court1' ? _aSchedule[ri].court1 : _aSchedule[ri].court2;
      if (isSideA) {
        m.sets[si].sA = val;
      } else {
        m.sets[si].sB = val;
      }
    });
  }

  void _updateAsScore(int ri, String court, String field, String val) {
    setState(() {
      final m =
          court == 'court1' ? _asSchedule[ri].court1 : _asSchedule[ri].court2;
      if (field == 'scoreA') m.scoreA = val;
      if (field == 'scoreB') m.scoreB = val;
    });
  }

  void _updateAsSet(int ri, String court, int si, bool isSideA, String val) {
    setState(() {
      final m =
          court == 'court1' ? _asSchedule[ri].court1 : _asSchedule[ri].court2;
      if (isSideA) {
        m.sets[si].sA = val;
      } else {
        m.sets[si].sB = val;
      }
    });
  }

  // ─── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccessScreen();
    return _buildMainScreen();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SUCCESS SCREENS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSuccessScreen() {
    if (_isATeams) return _buildATeamsSuccess();
    if (_isASolo) return _buildASoloSuccess();
    return _buildSimpleSuccess();
  }

  // ── أمريكانو فرق success ─────────────────────────────────────────────────
  Widget _buildATeamsSuccess() {
    final totalPts =
        americanoTeams.fold<int>(0, (s, t) => s + (_aPoints[t.id] ?? 0));
    final champion = _aRanked[0];
    final podium = [_aRanked[1], _aRanked[0], _aRanked[2]];

    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          MatchResultWinnerBanner(
            gradient: const [Color(0xFF6D28D9), MRColors.indigo700, Color(0xFF4C1D95)],
            lightTextColor: MRColors.purple200,
            caption: 'الفائز بالأمريكانو',
            championTitle: champion.label,
            championAvatars: MatchResultAvatarStack(
              size: 64,
              overlap: 12,
              avatars: [
                for (final p in champion.players)
                  MatchResultGradientAvatar(
                    text: p.avatar,
                    gradient: p.gradient,
                    size: 64,
                    borderWidth: 4,
                    borderColor: const Color(0xB3FACC15),
                  ),
              ],
            ),
            points: _aPoints[champion.id] ?? 0,
            percent: totalPts > 0
                ? ((_aPoints[champion.id] ?? 0) / totalPts * 100).round()
                : 0,
            matchesCount: _aSchedule.length * 2,
            onBack: widget.onBack,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.xl,
                AppSizes.xl,
                AppSizes.xl,
                AppSizes.xxxl,
              ),
              child: Column(
                children: [
                  _buildPodium(podium, _aPoints, isTeams: true),
                  const SizedBox(height: AppSizes.xl),
                  _buildATeamsFinalStandings(totalPts),
                  const SizedBox(height: AppSizes.xl),
                  _buildATeamsRatingCard(),
                  const SizedBox(height: AppSizes.xl),
                  _backButton(
                    gradient: const [_purple600, MRColors.indigo600],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildATeamsFinalStandings(int totalPts) {
    final maxPts =
        _aRanked.isEmpty ? 1 : (_aPoints[_aRanked[0].id] ?? 1);
    final entries = _aRanked.asMap().entries.map((e) {
      final team = e.value;
      final pts = _aPoints[team.id] ?? 0;
      final acc = teamAccents[team.id];
      return MatchResultStandingsEntry(
        id: team.id,
        leading: MatchResultTeamChip(team: team, medium: true),
        title: team.players.map((p) => p.firstName).join(' & '),
        points: pts,
        fraction: maxPts > 0 ? pts / maxPts : 0,
        badgeText: team.avgLevelLabel,
        badgeColors: acc,
      );
    }).toList();

    return MatchResultStandingsCard(
      title: 'الترتيب النهائي',
      entries: entries,
      accent: _purple600,
      accentLight: _purple50,
      accentBorder: _purple200,
      accentText: _purple700,
      rankGradients: const [
        [MRColors.yellow400, MRColors.yellow500],
        [MRColors.gray300, MRColors.gray400],
        [MRColors.orange300, MRColors.orange400],
        [MRColors.purple300, MRColors.purple400],
      ],
      showCompleteNotice: false,
    );
  }

  Widget _buildATeamsRatingCard() {
    return _buildRatingCard(
      children: [
        for (var ti = 0; ti < _aRanked.length; ti++)
          _buildTeamRatingSection(_aRanked[ti], ti),
      ],
    );
  }

  Widget _buildTeamRatingSection(AmericanoTeam team, int rank) {
    final medals = ['🥇', '🥈', '🥉', '4️⃣'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.sm),
          child: Text(
            '${medals[rank]}  ${team.label}',
            style: AppTextStyles.caption,
          ),
        ),
        for (final p in team.players)
          _buildPlayerRatingRow(
            id: '${team.id}-${p.avatar}',
            avatar: MatchResultGradientAvatar(
              text: p.avatar,
              gradient: p.gradient,
              size: 32,
            ),
            name: p.name,
          ),
        if (rank < _aRanked.length - 1) const Divider(height: 24),
      ],
    );
  }

  // ── أمريكانو فردي success ─────────────────────────────────────────────────
  Widget _buildASoloSuccess() {
    final totalPts = americanoSoloPlayers.fold<int>(
        0, (s, p) => s + (_asPoints[p.id] ?? 0));
    final champion = _asRanked[0];
    final podium = [_asRanked[1], _asRanked[0], _asRanked[2]];

    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          MatchResultWinnerBanner(
            gradient: const [MRColors.teal700, MRColors.cyan700, MRColors.teal900],
            lightTextColor: MRColors.teal200,
            caption: 'الفائز بأمريكانو فردي',
            championTitle: champion.firstName,
            championSubtitle: champion.name,
            championAvatars: MatchResultGradientAvatar(
              text: champion.avatar,
              gradient: champion.gradient,
              size: 80,
              borderWidth: 4,
              borderColor: const Color(0xB3FACC15),
            ),
            points: _asPoints[champion.id] ?? 0,
            percent: totalPts > 0
                ? ((_asPoints[champion.id] ?? 0) / totalPts * 100).round()
                : 0,
            matchesCount: _asSchedule.length * 2,
            onBack: widget.onBack,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.xl,
                AppSizes.xl,
                AppSizes.xl,
                AppSizes.xxxl,
              ),
              child: Column(
                children: [
                  _buildPodium(podium, _asPoints, isTeams: false),
                  const SizedBox(height: AppSizes.xl),
                  _buildASoloFinalStandings(totalPts),
                  const SizedBox(height: AppSizes.xl),
                  _buildASoloRatingCard(),
                  const SizedBox(height: AppSizes.xl),
                  _backButton(
                    gradient: const [_teal600, MRColors.cyan600],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildASoloFinalStandings(int totalPts) {
    final maxPts =
        _asRanked.isEmpty ? 1 : (_asPoints[_asRanked[0].id] ?? 1);
    final entries = _asRanked.asMap().entries.map((e) {
      final player = e.value;
      final pts = _asPoints[player.id] ?? 0;
      return MatchResultStandingsEntry(
        id: player.id,
        leading: MatchResultGradientAvatar(
          text: player.avatar,
          gradient: player.gradient,
          size: 40,
        ),
        title: player.name,
        points: pts,
        fraction: maxPts > 0 ? pts / maxPts : 0,
        badgeText: player.levelLabel,
        badgeColors: tealAccent,
      );
    }).toList();

    return MatchResultStandingsCard(
      title: 'الترتيب النهائي',
      entries: entries,
      accent: _teal600,
      accentLight: _teal50,
      accentBorder: _teal200,
      accentText: _teal700,
      rankGradients: const [
        [MRColors.yellow400, MRColors.yellow500],
        [MRColors.gray300, MRColors.gray400],
        [MRColors.orange300, MRColors.orange400],
        [MRColors.teal300, MRColors.teal400],
      ],
      showCompleteNotice: false,
    );
  }

  Widget _buildASoloRatingCard() {
    return _buildRatingCard(
      children: _asRanked.asMap().entries.map((e) {
        final medals = ['🥇', '🥈', '🥉', '4️⃣', '5️⃣', '6️⃣', '7️⃣', '8️⃣'];
        return _buildPlayerRatingRow(
          id: e.value.id,
          leading: Text(medals[e.key],
              style: const TextStyle(fontSize: 18)),
          avatar: MatchResultGradientAvatar(
            text: e.value.avatar,
            gradient: e.value.gradient,
            size: 36,
          ),
          name: e.value.name,
        );
      }).toList(),
    );
  }

  // ── generic success (ودية فردي / تحدي فرق) ────────────────────────────────
  Widget _buildSimpleSuccess() {
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding, 48, AppSizes.pagePadding, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _headerGradient,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_right,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  SizedBox(height: AppSizes.lg),
                  Center(
                    child: Text('🏆', style: TextStyle(fontSize: 40)),
                  ),
                  SizedBox(height: AppSizes.sm),
                  Center(
                    child: Text(
                      'نتيجة المباراة',
                      style: AppTextStyles.heading2
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.xl),
              child: Column(
                children: [
                  _buildSimpleResultCard(),
                  const SizedBox(height: AppSizes.xl),
                  _buildSimpleRatingCard(),
                  const SizedBox(height: AppSizes.xl),
                  _backButton(
                    color: _isSolo ? _blue500 : AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleResultCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isSolo
              ? const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)]
              : const [MRColors.yellow50, MRColors.yellow100],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: _isSolo ? _blue200 : const Color(0xFFFDE68A),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text('🏆', style: TextStyle(fontSize: 36)),
          SizedBox(height: AppSizes.xs),
          Text('الترتيب النهائي',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.secondary)),
          const SizedBox(height: AppSizes.lg),
          if (_isSolo) ...[
            for (var i = 0; i < _soloRanked.length; i++)
              _buildSimpleRankRow(
                i,
                leading: MatchResultGradientAvatar(
                  text: _soloRanked[i].avatar,
                  gradient: _soloRanked[i].gradient,
                  size: 36,
                ),
                name: _soloRanked[i].name,
                pts: _soloPoints[_soloRanked[i].id] ?? 0,
              ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final p in (_winner == 'team1'
                    ? challengeTeam1
                    : challengeTeam2))
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                    child: Column(
                      children: [
                        MatchResultGradientAvatar(
                          text: p.avatar,
                          gradient: p.gradient,
                          size: 48,
                        ),
                        SizedBox(height: AppSizes.xs),
                        Text(p.firstName,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.secondary)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimpleRankRow(int i, {required Widget leading, required String name, int? pts}) {
    const medals = ['🥇', '🥈', '🥉', '4️⃣'];
    final bgColors = [
      const Color(0xFFFEF9C3),
      MRColors.gray100,
      MRColors.gray50,
      MRColors.gray50,
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.sm + 2),
      decoration: BoxDecoration(
        color: bgColors[i.clamp(0, 3)],
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: i == 0 ? Border.all(color: const Color(0xFFFDE68A)) : null,
      ),
      child: Row(
        children: [
          Text(medals[i.clamp(0, 3)],
              style: const TextStyle(fontSize: 20)),
          SizedBox(width: AppSizes.sm),
          leading,
          SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(name,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.secondary)),
          ),
          if (pts != null)
            Text('$pts نقطة',
                style: AppTextStyles.caption.copyWith(
                  color: i == 0
                      ? const Color(0xFFCA8A04)
                      : AppColors.mutedForeground,
                )),
        ],
      ),
    );
  }

  Widget _buildSimpleRatingCard() {
    final players =
        _isSolo ? soloPlayers : [...challengeTeam1, ...challengeTeam2];
    return _buildRatingCard(
      children: players
          .map((p) => _buildPlayerRatingRow(
                id: p.id,
                avatar: MatchResultGradientAvatar(
                  text: p.avatar,
                  gradient: p.gradient,
                  size: 36,
                ),
                name: p.name,
              ))
          .toList(),
    );
  }

  // ── podium widget ─────────────────────────────────────────────────────────
  Widget _buildPodium(
    List<dynamic> podiumItems,
    Map<String, int> pointsMap, {
    required bool isTeams,
  }) {
    const podiumHeights = [80.0, 112.0, 64.0];
    const podiumColors = [
      [Color(0xFFD1D5DB), Color(0xFF9CA3AF)],
      [MRColors.yellow400, MRColors.yellow500],
      [MRColors.orange300, MRColors.orange400],
    ];
    const podiumLabels = ['🥈', '🥇', '🥉'];

    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.emoji_events, size: 14, color: MRColors.yellow500),
              SizedBox(width: AppSizes.xs),
              Text('المنصة',
                  style: TextStyle(fontSize: 12, color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: AppSizes.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              final item = podiumItems[i];
              final String itemId;
              final String itemLabel;
              final List<Widget> avatarWidgets;
              if (isTeams) {
                final team = item as AmericanoTeam;
                itemId = team.id;
                itemLabel = team.label;
                avatarWidgets = [
                  MatchResultAvatarStack(
                    size: 36,
                    overlap: 8,
                    avatars: [
                      for (final p in team.players)
                        MatchResultGradientAvatar(
                          text: p.avatar,
                          gradient: p.gradient,
                          size: 36,
                          borderWidth: 2,
                        ),
                    ],
                  ),
                ];
              } else {
                final player = item as MatchResultPlayer;
                itemId = player.id;
                itemLabel = player.short;
                avatarWidgets = [
                  MatchResultGradientAvatar(
                    text: player.avatar,
                    gradient: player.gradient,
                    size: 48,
                    borderWidth: 2,
                  ),
                ];
              }
              final pts = pointsMap[itemId] ?? 0;

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ...avatarWidgets,
                    SizedBox(height: AppSizes.xs),
                    Text(
                      itemLabel,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.secondary),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '$pts نقطة',
                      style: AppTextStyles.caption.copyWith(
                        color: i == 1
                            ? const Color(0xFFCA8A04)
                            : AppColors.mutedForeground,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Container(
                      height: podiumHeights[i],
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: podiumColors[i],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSizes.sm),
                        child: Text(
                          podiumLabels[i],
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── shared rating card ────────────────────────────────────────────────────
  Widget _buildRatingCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.xl, vertical: AppSizes.md),
            color: MRColors.gray50,
            child: const Row(
              children: [
                Icon(Icons.star, size: 16, color: MRColors.yellow500),
                SizedBox(width: AppSizes.sm),
                Text('قيّم اللاعبين',
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondary,
                        height: 1.4)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRatingRow({
    required String id,
    Widget? leading,
    required Widget avatar,
    required String name,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        children: [
          if (leading != null) ...[leading, SizedBox(width: AppSizes.sm)],
          avatar,
          SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(name,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.secondary)),
          ),
          Row(
            children: List.generate(5, (s) {
              final filled = (_ratings[id] ?? 0) > s;
              return GestureDetector(
                onTap: () => setState(() => _ratings[id] = s + 1),
                child: Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(
                    Icons.star,
                    size: 20,
                    color: filled
                        ? MRColors.yellow400
                        : const Color(0xFFE5E7EB),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _backButton({List<Color>? gradient, Color? color}) {
    final btn = InkWell(
      onTap: widget.onBack,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
          child: Text('العودة للمباريات',
              style: AppTextStyles.body.copyWith(color: Colors.white)),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: gradient != null
            ? LinearGradient(
                colors: gradient,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: color,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: (gradient?.first ?? color ?? AppColors.primary)
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: btn,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MAIN SCREEN
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMainScreen() {
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          _buildMainHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.xl,
                AppSizes.xl,
                AppSizes.xl,
                AppSizes.xxxl,
              ),
              child: Column(
                children: [
                  _buildMatchInfoCard(),
                  const SizedBox(height: AppSizes.lg),
                  if (_isATeams) ..._buildATeamsSection(),
                  if (_isASolo) ..._buildASoloSection(),
                  if (_isSolo) ..._buildFriendlySoloSection(),
                  if (!_isSolo && !_isATeams && !_isASolo)
                    ..._buildTeamChallengeSection(),
                  const SizedBox(height: AppSizes.lg),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainHeader() {
    final subtitle = _isATeams
        ? 'أمريكانو فرق'
        : _isASolo
            ? 'أمريكانو فردي'
            : _isSolo
                ? 'ودية فردي'
                : 'تحدي فرق';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _headerGradient,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSizes.pagePadding, AppSizes.xl, AppSizes.pagePadding, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_right,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  SizedBox(width: AppSizes.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تفاصيل المباراة',
                        style: AppTextStyles.heading2
                            .copyWith(color: Colors.white),
                      ),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md, vertical: AppSizes.xs),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 14, color: Colors.white),
                    SizedBox(width: AppSizes.xs),
                    Text('مكتمل — أدخل النتائج',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchInfoCard() {
    final completionLabel = (_isATeams || _isASolo)
        ? 'مكتمل 8/8'
        : 'مكتملة 4/4';
    final typeLabel = _isATeams
        ? 'أمريكانو فرق'
        : _isASolo
            ? 'أمريكانو فردي'
            : _isSolo
                ? 'ودية فردي'
                : 'تحدي فرق';
    final venue = _isATeams
        ? 'نادي البادل الملكي • ملعبان'
        : _isASolo
            ? 'نادي النخبة للبادل • ملعبان'
            : _isSolo
                ? 'ملعب الأندية الشرقية'
                : 'نادي النخبة للبادل';
    final time = _isATeams
        ? 'اليوم، السبت 6 يونيو • 6:00 مساءً'
        : _isASolo
            ? 'اليوم، السبت 6 يونيو • 4:00 مساءً'
            : _isSolo
                ? 'اليوم، السبت 6 يونيو • 7:30 مساءً'
                : 'اليوم، السبت 6 يونيو • 5:00 مساءً';

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md, vertical: AppSizes.xs),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  completionLabel,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white, height: 1.4),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md, vertical: AppSizes.xs),
                decoration: BoxDecoration(
                  color: _accentLight,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                      fontSize: 11, color: _accentText, height: 1.4),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.md),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: _accent),
              SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(venue,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.secondary)),
              ),
            ],
          ),
          SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: _accent),
              SizedBox(width: AppSizes.sm),
              Text(time,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.secondary)),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // أمريكانو فرق
  // ──────────────────────────────────────────────────────────────────────────
  List<Widget> _buildATeamsSection() {
    final anyScore = _aSchedule.any((r) => r.hasAnyScore(_aMode));

    return [
      _buildATeamsGrid(),
      const SizedBox(height: AppSizes.lg),
      if (!_aSetupDone)
        MatchResultSetupCard(
          subtitle: 'سيتم توزيع الفرق تلقائياً بشكل عادل',
          headerGradient: const [_purple600, MRColors.indigo600],
          accent: _purple600,
          accentSoft: MRColors.purple500,
          accentBorder: _purple200,
          accentLight: _purple50,
          accentText: _purple700,
          principles: const [
            'توازن المستويات: الأقوى يلعب ضد الأضعف أولاً',
            'تنوع الخصوم: كل فريق يلعب ضد فرق مختلفة',
            'عدم التكرار: 3 جولات × 2 ملاعب = 6 مباريات فريدة',
          ],
          mode: _aMode,
          onModeChanged: (m) => setState(() => _aMode = m),
          timePerRound: _aTimePerRound,
          onTimePerRoundChanged: (v) => setState(() => _aTimePerRound = v),
          setsCount: _aSetsCount,
          onSetsCountChanged: (v) => setState(() => _aSetsCount = v),
          startTime: _aStartTime,
          onStartTimeChanged: (v) => setState(() => _aStartTime = v),
          onGenerate: _generateATeamsSchedule,
        ),
      if (_aSetupDone) ...[
        MatchResultScheduleHeader(
          gradient: const [_purple600, MRColors.indigo600],
          lightTextColor: _purple200,
          subtitle: _aMode == MatchResultMode.time
              ? '$_aTimePerRound دقيقة لكل جولة • ابتداءً ${mrFmtTime(_aStartTime)}'
              : '${mrSetsCountLabel(_aSetsCount)} لكل مباراة',
          schedule: _aSchedule,
          mode: _aMode,
          expandedRound: _aExpandedRound,
          onRoundTap: (ri) =>
              setState(() => _aExpandedRound = _aExpandedRound == ri ? null : ri),
          onEdit: () => setState(() => _aSetupDone = false),
        ),
        const SizedBox(height: AppSizes.md),
        ..._aSchedule.asMap().entries.map((entry) {
          final ri = entry.key;
          final round = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.md),
            child: MatchResultRoundCard(
              round: round,
              mode: _aMode,
              isOpen: _aExpandedRound == ri,
              onToggle: () => setState(
                  () => _aExpandedRound = _aExpandedRound == ri ? null : ri),
              accent: _purple600,
              accentLight: _purple50,
              accentBorder: _purple400,
              accentText: _purple600,
              nextRoundLabel:
                  ri < _aSchedule.length - 1 ? 'الجولة ${ri + 2}' : null,
              onNextRound: ri < _aSchedule.length - 1
                  ? () => setState(() => _aExpandedRound = ri + 1)
                  : null,
              courts: [
                _buildATeamsCourtCard(ri, 'court1', round.court1),
                _buildATeamsCourtCard(ri, 'court2', round.court2),
              ],
            ),
          );
        }),
        if (anyScore) ...[
          MatchResultStandingsCard(
            title: 'ترتيب الفرق',
            entries: _buildATeamsStandingsEntries(),
            accent: _purple600,
            accentLight: _purple50,
            accentBorder: _purple200,
            accentText: _purple700,
            rankGradients: const [
              [MRColors.yellow400, MRColors.yellow500],
              [MRColors.purple400, MRColors.purple500],
              [MRColors.indigo400, MRColors.indigo500],
              [MRColors.gray300, MRColors.gray300],
            ],
            showCompleteNotice: _aComplete,
          ),
          const SizedBox(height: AppSizes.lg),
        ],
      ],
    ];
  }

  Widget _buildATeamsGrid() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.xl, vertical: AppSizes.md),
            color: _purple50,
            child: Row(
              children: [
                const Icon(Icons.layers_outlined,
                    size: 16, color: _purple600),
                const SizedBox(width: AppSizes.sm),
                const Text('الفرق المشاركة',
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondary,
                        height: 1.4)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: _purple50,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: const Text('4 فرق',
                      style: TextStyle(
                          fontSize: 11, color: _purple600, height: 1.4)),
                ),
              ],
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            childAspectRatio: 1.5,
            children: americanoTeams.map((team) {
              final hColors =
                  teamHeaderGradients[team.id] ?? mrPrimaryGradient;
              final acc = teamAccents[team.id];
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  border: Border(
                    right: BorderSide(color: AppColors.border),
                    bottom: BorderSide(color: AppColors.border),
                  ),
                ),
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: hColors),
                        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      ),
                    ),
                    SizedBox(height: AppSizes.md),
                    Row(
                      children: [
                        Expanded(
                          child: Text(team.label,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.secondary)),
                        ),
                        if (acc != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.sm, vertical: 1),
                            decoration: BoxDecoration(
                              color: acc.background,
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusFull),
                              border: Border.all(color: acc.border),
                            ),
                            child: Text(team.avgLevelLabel,
                                style: TextStyle(
                                    fontSize: 10, color: acc.text, height: 1.4)),
                          ),
                      ],
                    ),
                    SizedBox(height: AppSizes.sm),
                    for (final p in team.players)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.xs),
                        child: Row(
                          children: [
                            MatchResultGradientAvatar(
                              text: p.avatar,
                              gradient: p.gradient,
                              size: 28,
                            ),
                            SizedBox(width: AppSizes.xs),
                            Expanded(
                              child: Text(p.name,
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.secondary),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildATeamsCourtCard(int ri, String court, AmericanoMatch match) {
    final tA = americanoTeamById(match.teamA.first);
    final tB = americanoTeamById(match.teamB.first);
    final diff =
        (tA.avgLevel - tB.avgLevel).abs().toStringAsFixed(2);

    return MatchResultCourtCard(
      label: court == 'court1' ? 'ملعب 1' : 'ملعب 2',
      levelDiffLabel: 'فرق المستوى: $diff',
      mode: _aMode,
      match: match,
      sideA: MatchResultTeamChip(team: tA),
      sideB: MatchResultTeamChip(team: tB),
      winnerALabel: tA.label,
      winnerBLabel: tB.label,
      accent: _purple400,
      accentLight: _purple50,
      accentSoftBg: MRColors.purple100,
      accentText: _purple700,
      onScoreAChanged: (v) => _updateAScore(ri, court, 'scoreA', v),
      onScoreBChanged: (v) => _updateAScore(ri, court, 'scoreB', v),
      onSetChanged: (si, isSideA, v) => _updateASet(ri, court, si, isSideA, v),
    );
  }

  List<MatchResultStandingsEntry> _buildATeamsStandingsEntries() {
    final maxPts =
        _aRanked.isEmpty ? 1 : (_aPoints[_aRanked[0].id] ?? 1);
    return _aRanked.asMap().entries.map((e) {
      final team = e.value;
      final pts = _aPoints[team.id] ?? 0;
      final acc = teamAccents[team.id];
      return MatchResultStandingsEntry(
        id: team.id,
        leading: MatchResultTeamChip(team: team),
        title: team.players.map((p) => p.firstName).join(' & '),
        points: pts,
        fraction: maxPts > 0 ? pts / maxPts : 0,
        badgeText: team.avgLevelLabel,
        badgeColors: acc,
      );
    }).toList();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // أمريكانو فردي
  // ──────────────────────────────────────────────────────────────────────────
  List<Widget> _buildASoloSection() {
    final anyScore = _asSchedule.any((r) => r.hasAnyScore(_asMode));

    return [
      _buildASoloPlayersGrid(),
      const SizedBox(height: AppSizes.lg),
      if (!_asSetupDone)
        MatchResultSetupCard(
          subtitle: '3 جولات × 2 ملاعب — لا تكرار للشريك',
          headerGradient: const [_teal600, MRColors.cyan600],
          accent: _teal600,
          accentSoft: MRColors.teal500,
          accentBorder: _teal200,
          accentLight: _teal50,
          accentText: _teal700,
          principles: const [
            'توازن المستويات: الأقوى يلعب مع الأضعف',
            'تنوع الشركاء: لا تكرار للشريك في 3 جولات',
            'توزيع عادل: 8 لاعبين × 3 جولات = 6 مباريات',
          ],
          mode: _asMode,
          onModeChanged: (m) => setState(() => _asMode = m),
          timePerRound: _asTimePerRound,
          onTimePerRoundChanged: (v) => setState(() => _asTimePerRound = v),
          setsCount: _asSetsCount,
          onSetsCountChanged: (v) => setState(() => _asSetsCount = v),
          startTime: _asStartTime,
          onStartTimeChanged: (v) => setState(() => _asStartTime = v),
          onGenerate: _generateASoloSchedule,
        ),
      if (_asSetupDone) ...[
        MatchResultScheduleHeader(
          gradient: const [_teal600, MRColors.cyan600],
          lightTextColor: _teal200,
          subtitle: _asMode == MatchResultMode.time
              ? '$_asTimePerRound دقيقة لكل جولة • ابتداءً ${mrFmtTime(_asStartTime)}'
              : '${mrSetsCountLabel(_asSetsCount)} لكل مباراة',
          schedule: _asSchedule,
          mode: _asMode,
          expandedRound: _asExpandedRound,
          onRoundTap: (ri) => setState(
              () => _asExpandedRound = _asExpandedRound == ri ? null : ri),
          onEdit: () => setState(() => _asSetupDone = false),
        ),
        const SizedBox(height: AppSizes.md),
        ..._asSchedule.asMap().entries.map((entry) {
          final ri = entry.key;
          final round = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.md),
            child: MatchResultRoundCard(
              round: round,
              mode: _asMode,
              isOpen: _asExpandedRound == ri,
              onToggle: () => setState(
                  () => _asExpandedRound = _asExpandedRound == ri ? null : ri),
              accent: _teal600,
              accentLight: _teal50,
              accentBorder: _teal400,
              accentText: _teal600,
              nextRoundLabel:
                  ri < _asSchedule.length - 1 ? 'الجولة ${ri + 2}' : null,
              onNextRound: ri < _asSchedule.length - 1
                  ? () => setState(() => _asExpandedRound = ri + 1)
                  : null,
              courts: [
                _buildASoloCourtCard(ri, 'court1', round.court1),
                _buildASoloCourtCard(ri, 'court2', round.court2),
              ],
            ),
          );
        }),
        if (anyScore) ...[
          MatchResultStandingsCard(
            title: 'ترتيب اللاعبين',
            entries: _buildASoloStandingsEntries(),
            accent: _teal600,
            accentLight: _teal50,
            accentBorder: _teal200,
            accentText: _teal700,
            rankGradients: const [
              [MRColors.yellow400, MRColors.yellow500],
              [MRColors.teal400, MRColors.teal500],
              [MRColors.teal300, MRColors.teal400],
              [MRColors.gray300, MRColors.gray300],
            ],
            showCompleteNotice: _asComplete,
          ),
          const SizedBox(height: AppSizes.lg),
        ],
      ],
    ];
  }

  Widget _buildASoloPlayersGrid() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.xl, vertical: AppSizes.md),
            color: _teal50,
            child: Row(
              children: [
                const Icon(Icons.people_outline, size: 16, color: _teal600),
                const SizedBox(width: AppSizes.sm),
                const Text('اللاعبون',
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondary,
                        height: 1.4)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: _teal50,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: const Text('8 لاعبين',
                      style: TextStyle(
                          fontSize: 11, color: _teal600, height: 1.4)),
                ),
              ],
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            childAspectRatio: 3,
            children: americanoSoloPlayers.map((p) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  border: Border(
                    right: BorderSide(color: AppColors.border),
                    bottom: BorderSide(color: AppColors.border),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md, vertical: AppSizes.sm),
                child: Row(
                  children: [
                    MatchResultGradientAvatar(
                      text: p.avatar,
                      gradient: p.gradient,
                      size: 36,
                    ),
                    SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(p.name,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.secondary),
                              overflow: TextOverflow.ellipsis),
                          Text('مستوى ${p.levelLabel}',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _teal600,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildASoloCourtCard(int ri, String court, AmericanoMatch match) {
    final pA1 = americanoSoloPlayerById(match.teamA[0]);
    final pA2 = americanoSoloPlayerById(match.teamA[1]);
    final pB1 = americanoSoloPlayerById(match.teamB[0]);
    final pB2 = americanoSoloPlayerById(match.teamB[1]);
    final avgA = ((pA1.level + pA2.level) / 2).toStringAsFixed(1);
    final avgB = ((pB1.level + pB2.level) / 2).toStringAsFixed(1);
    final diff = (double.parse(avgA) - double.parse(avgB)).abs().toStringAsFixed(1);

    return MatchResultCourtCard(
      label: court == 'court1' ? 'ملعب 1' : 'ملعب 2',
      levelDiffLabel: 'فرق المستوى: $diff',
      mode: _asMode,
      match: match,
      sideA: MatchResultSoloTeamSide(players: [pA1, pA2], avgLabel: 'متوسط $avgA'),
      sideB: MatchResultSoloTeamSide(players: [pB1, pB2], avgLabel: 'متوسط $avgB'),
      winnerALabel: '${pA1.short} & ${pA2.short}',
      winnerBLabel: '${pB1.short} & ${pB2.short}',
      accent: _teal400,
      accentLight: _teal50,
      accentSoftBg: MRColors.teal100,
      accentText: _teal700,
      onScoreAChanged: (v) => _updateAsScore(ri, court, 'scoreA', v),
      onScoreBChanged: (v) => _updateAsScore(ri, court, 'scoreB', v),
      onSetChanged: (si, isSideA, v) =>
          _updateAsSet(ri, court, si, isSideA, v),
    );
  }

  List<MatchResultStandingsEntry> _buildASoloStandingsEntries() {
    final maxPts =
        _asRanked.isEmpty ? 1 : (_asPoints[_asRanked[0].id] ?? 1);
    return _asRanked.asMap().entries.map((e) {
      final player = e.value;
      final pts = _asPoints[player.id] ?? 0;
      return MatchResultStandingsEntry(
        id: player.id,
        leading: MatchResultGradientAvatar(
          text: player.avatar,
          gradient: player.gradient,
          size: 36,
        ),
        title: player.name,
        points: pts,
        fraction: maxPts > 0 ? pts / maxPts : 0,
        badgeText: player.levelLabel,
        badgeColors: tealAccent,
      );
    }).toList();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ودية فردي
  // ──────────────────────────────────────────────────────────────────────────
  List<Widget> _buildFriendlySoloSection() {
    final anyScore =
        _rounds.any((r) => r.scoreA.isNotEmpty || r.scoreB.isNotEmpty);

    return [
      _buildSoloPlayersGrid(),
      const SizedBox(height: AppSizes.lg),
      ..._rounds.asMap().entries.map((entry) {
        final ri = entry.key;
        final round = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.md),
          child: _buildFriendlyRoundCard(ri, round),
        );
      }),
      _buildAddRoundButton(),
      if (anyScore) ...[
        SizedBox(height: AppSizes.lg),
        _buildSoloLiveStandings(),
      ],
      SizedBox(height: AppSizes.lg),
    ];
  }

  Widget _buildSoloPlayersGrid() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_outline, size: 16, color: _blue500),
              SizedBox(width: AppSizes.sm),
              Text('اللاعبون',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3,
            mainAxisSpacing: AppSizes.sm,
            crossAxisSpacing: AppSizes.sm,
            children: soloPlayers.map((p) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md, vertical: AppSizes.sm),
                decoration: BoxDecoration(
                  color: MRColors.gray50,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    MatchResultGradientAvatar(
                      text: p.avatar,
                      gradient: p.gradient,
                      size: 36,
                    ),
                    SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(p.name,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.secondary),
                              overflow: TextOverflow.ellipsis),
                          Text('مستوى ${p.levelLabel}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: _blue500,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendlyRoundCard(int ri, FriendlyRound round) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg, vertical: AppSizes.md),
            color: _blue100,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: _blue500,
                  child: Text('${ri + 1}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white, height: 1.4)),
                ),
                SizedBox(width: AppSizes.sm),
                Text('جولة ${ri + 1}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.secondary)),
                const Spacer(),
                if (_rounds.length > 1)
                  GestureDetector(
                    onTap: () => setState(
                        () => _rounds.removeWhere((r) => r.id == round.id)),
                    child: const Icon(Icons.delete_outline,
                        size: 18, color: Color(0xFFF87171)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildTeamBox(round, isTeamA: true)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md),
                      child: Column(
                        children: [
                          const Icon(Icons.compare_arrows,
                              size: 20,
                              color: AppColors.mutedForeground),
                          SizedBox(height: AppSizes.xs),
                          Text('اضغط\nللتبديل',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Expanded(child: _buildTeamBox(round, isTeamA: false)),
                  ],
                ),
                SizedBox(height: AppSizes.lg),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text('الفريق أ',
                              style: AppTextStyles.caption
                                  .copyWith(color: _blue500)),
                          const SizedBox(height: AppSizes.xs),
                          MatchResultScoreInput(
                            value: round.scoreA,
                            onChanged: (v) =>
                                _updateRound(round.id, 'scoreA', v),
                            focusBorderColor: _blue400,
                            borderColor: (round.scoreA.isNotEmpty &&
                                    round.scoreB.isNotEmpty &&
                                    (int.tryParse(round.scoreA) ?? 0) >
                                        (int.tryParse(round.scoreB) ?? 0))
                                ? _blue400
                                : null,
                            fillColor: (round.scoreA.isNotEmpty &&
                                    round.scoreB.isNotEmpty &&
                                    (int.tryParse(round.scoreA) ?? 0) >
                                        (int.tryParse(round.scoreB) ?? 0))
                                ? _blue100
                                : null,
                            textColor: (round.scoreA.isNotEmpty &&
                                    round.scoreB.isNotEmpty &&
                                    (int.tryParse(round.scoreA) ?? 0) >
                                        (int.tryParse(round.scoreB) ?? 0))
                                ? _blue500
                                : null,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: AppSizes.md),
                      child: Text('—',
                          style: TextStyle(
                              fontSize: 20,
                              color: AppColors.mutedForeground)),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text('الفريق ب',
                              style: AppTextStyles.caption
                                  .copyWith(color: _orange400)),
                          const SizedBox(height: AppSizes.xs),
                          MatchResultScoreInput(
                            value: round.scoreB,
                            onChanged: (v) =>
                                _updateRound(round.id, 'scoreB', v),
                            focusBorderColor: _orange400,
                            borderColor: (round.scoreA.isNotEmpty &&
                                    round.scoreB.isNotEmpty &&
                                    (int.tryParse(round.scoreB) ?? 0) >
                                        (int.tryParse(round.scoreA) ?? 0))
                                ? _orange400
                                : null,
                            fillColor: (round.scoreA.isNotEmpty &&
                                    round.scoreB.isNotEmpty &&
                                    (int.tryParse(round.scoreB) ?? 0) >
                                        (int.tryParse(round.scoreA) ?? 0))
                                ? _orange50
                                : null,
                            textColor: (round.scoreA.isNotEmpty &&
                                    round.scoreB.isNotEmpty &&
                                    (int.tryParse(round.scoreB) ?? 0) >
                                        (int.tryParse(round.scoreA) ?? 0))
                                ? MRColors.orange600
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (round.scoreA.isNotEmpty && round.scoreB.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSizes.sm),
                    child: _buildWinnerLine(round),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamBox(FriendlyRound round, {required bool isTeamA}) {
    final ids = isTeamA ? round.teamA : round.teamB;
    final accent = isTeamA ? _blue500 : _orange400;
    final bgColor = isTeamA
        ? const Color(0xFFEFF6FF)
        : const Color(0xFFFFF7ED);
    final borderColor = isTeamA ? _blue200 : const Color(0xFFFED7AA);

    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isTeamA ? 'الفريق أ' : 'الفريق ب',
              style: TextStyle(
                  fontSize: 10, color: accent, height: 1.4)),
          const SizedBox(height: AppSizes.xs),
          for (final id in ids)
            GestureDetector(
              onTap: () => _swapPlayer(round.id, id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    MatchResultGradientAvatar(
                      text: soloPlayerById(id).avatar,
                      gradient: soloPlayerById(id).gradient,
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(soloPlayerById(id).short,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.secondary),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const Icon(Icons.swap_horiz,
                        size: 12, color: AppColors.mutedForeground),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWinnerLine(FriendlyRound round) {
    final a = int.tryParse(round.scoreA) ?? 0;
    final b = int.tryParse(round.scoreB) ?? 0;
    final String text;
    final Color bg;
    final Color fg;

    if (a > b) {
      final names = round.teamA.map((id) => soloPlayerById(id).short).join(' & ');
      text = '🏆 فاز الفريق أ ($names)';
      bg = _blue100;
      fg = _blue500;
    } else if (b > a) {
      final names = round.teamB.map((id) => soloPlayerById(id).short).join(' & ');
      text = '🏆 فاز الفريق ب ($names)';
      bg = _orange50;
      fg = _orange400;
    } else {
      text = 'تعادل';
      bg = MRColors.gray50;
      fg = AppColors.mutedForeground;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: fg, height: 1.4)),
    );
  }

  Widget _buildAddRoundButton() {
    return GestureDetector(
      onTap: () => setState(() => _rounds.add(makeFriendlyRound(_rounds.length))),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          border: Border.all(
            color: _blue200,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 16, color: _blue500),
            SizedBox(width: AppSizes.xs),
            Text('إضافة جولة جديدة',
                style: AppTextStyles.bodySmall.copyWith(color: _blue500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSoloLiveStandings() {
    final maxPts =
        _soloRanked.isEmpty ? 1 : (_soloPoints[_soloRanked[0].id] ?? 1);
    final entries = _soloRanked.asMap().entries.map((e) {
      final player = e.value;
      final pts = _soloPoints[player.id] ?? 0;
      return MatchResultStandingsEntry(
        id: player.id,
        leading: MatchResultGradientAvatar(
          text: player.avatar,
          gradient: player.gradient,
          size: 32,
        ),
        title: player.name,
        points: pts,
        fraction: maxPts > 0 ? pts / maxPts : 0,
      );
    }).toList();

    return MatchResultStandingsCard(
      title: 'الترتيب الحالي',
      entries: entries,
      accent: _blue500,
      accentLight: _blue100,
      accentBorder: _blue200,
      accentText: _blue500,
      rankGradients: const [
        [MRColors.yellow400, MRColors.yellow500],
        [MRColors.blue300, MRColors.blue400],
        [MRColors.blue200, MRColors.blue300],
        [MRColors.gray200, MRColors.gray300],
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // تحدي فرق
  // ──────────────────────────────────────────────────────────────────────────
  List<Widget> _buildTeamChallengeSection() {
    return [
      _buildChallengeTeamsCard(),
      const SizedBox(height: AppSizes.lg),
      _buildChallengeSetsCard(),
      const SizedBox(height: AppSizes.lg),
      _buildChallengeWinnerCard(),
      const SizedBox(height: AppSizes.lg),
    ];
  }

  Widget _buildChallengeTeamsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.xl, vertical: AppSizes.md),
            color: MRColors.gray50,
            child: const Row(
              children: [
                Icon(Icons.sports_tennis, size: 16, color: AppColors.primary),
                SizedBox(width: AppSizes.sm),
                Text('اللاعبون',
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondary,
                        height: 1.4)),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(child: _buildChallengeTeamColumn(challengeTeam1, 0)),
              Container(width: 1, color: AppColors.border),
              Expanded(child: _buildChallengeTeamColumn(challengeTeam2, 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeTeamColumn(List<MatchResultPlayer> team, int index) {
    final color = index == 0 ? AppColors.primary : AppColors.secondary;
    final label = index == 0 ? 'الفريق الأول' : 'الفريق الثاني';

    return Padding(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 12, color: color),
              SizedBox(width: 4),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
          SizedBox(height: AppSizes.md),
          for (final p in team)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: Row(
                children: [
                  MatchResultGradientAvatar(
                    text: p.avatar,
                    gradient: p.gradient,
                    size: 36,
                  ),
                  SizedBox(width: AppSizes.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.secondary)),
                      Text(p.levelLabel,
                          style: TextStyle(
                              fontSize: 10, color: color, height: 1.4)),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChallengeSetsCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_outlined,
                  size: 16, color: AppColors.primary),
              SizedBox(width: AppSizes.sm),
              Text('نتيجة الأشواط',
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondary,
                      height: 1.4)),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          Row(
            children: const [
              Expanded(
                  child: Text('الفريق 1',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                          height: 1.4))),
              Expanded(
                  child: Text('الشوط',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                          height: 1.4))),
              Expanded(
                  child: Text('الفريق 2',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                          height: 1.4))),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          ..._sets.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.md),
              child: Row(
                children: [
                  Expanded(
                    child: MatchResultScoreInput(
                      value: s.t1,
                      onChanged: (v) =>
                          setState(() => _sets[i].t1 = v),
                      focusBorderColor: AppColors.primary,
                      borderColor: (s.t1.isNotEmpty &&
                              s.t2.isNotEmpty &&
                              (int.tryParse(s.t1) ?? 0) >
                                  (int.tryParse(s.t2) ?? 0))
                          ? AppColors.primary
                          : null,
                      fillColor: (s.t1.isNotEmpty &&
                              s.t2.isNotEmpty &&
                              (int.tryParse(s.t1) ?? 0) >
                                  (int.tryParse(s.t2) ?? 0))
                          ? AppColors.primary.withValues(alpha: 0.05)
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm, vertical: 4),
                      decoration: BoxDecoration(
                        color: MRColors.gray100,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Text('شوط ${i + 1}',
                          style: AppTextStyles.caption),
                    ),
                  ),
                  Expanded(
                    child: MatchResultScoreInput(
                      value: s.t2,
                      onChanged: (v) =>
                          setState(() => _sets[i].t2 = v),
                      focusBorderColor: AppColors.secondary,
                      borderColor: (s.t1.isNotEmpty &&
                              s.t2.isNotEmpty &&
                              (int.tryParse(s.t2) ?? 0) >
                                  (int.tryParse(s.t1) ?? 0))
                          ? AppColors.secondary
                          : null,
                      fillColor: (s.t1.isNotEmpty &&
                              s.t2.isNotEmpty &&
                              (int.tryParse(s.t2) ?? 0) >
                                  (int.tryParse(s.t1) ?? 0))
                          ? AppColors.secondary.withValues(alpha: 0.05)
                          : null,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (_sets.length < 3)
            GestureDetector(
              onTap: () =>
                  setState(() => _sets.add(TeamChallengeSet())),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSizes.md),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Text(
                  '+ إضافة شوط ${_sets.length + 1}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChallengeWinnerCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events,
                  size: 16, color: MRColors.yellow500),
              SizedBox(width: AppSizes.sm),
              Text('الفريق الفائز',
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondary,
                      height: 1.4)),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          Row(
            children: [
              for (final entry in {'team1': challengeTeam1, 'team2': challengeTeam2}.entries) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _winner = entry.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(AppSizes.lg),
                      decoration: BoxDecoration(
                        color: _winner == entry.key
                            ? (entry.key == 'team1'
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.secondary.withValues(alpha: 0.1))
                            : AppColors.card,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusXl),
                        border: Border.all(
                          color: _winner == entry.key
                              ? (entry.key == 'team1'
                                  ? AppColors.primary
                                  : AppColors.secondary)
                              : AppColors.border,
                          width: _winner == entry.key ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (final p in entry.value)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      right: AppSizes.xs),
                                  child: MatchResultGradientAvatar(
                                    text: p.avatar,
                                    gradient: p.gradient,
                                    size: 32,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: AppSizes.sm),
                          Text(
                            entry.key == 'team1'
                                ? 'الفريق الأول'
                                : 'الفريق الثاني',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.secondary),
                          ),
                          if (_winner == entry.key) ...[
                            SizedBox(height: AppSizes.xs),
                            Text('🏆 فائز',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.primary)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (entry.key == 'team1')
                  const SizedBox(width: AppSizes.md),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── submit button ────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    final label = (_isATeams && !_aSetupDone) || (_isASolo && !_asSetupDone)
        ? 'أنشئ جدول المباريات أولاً'
        : 'تسجيل النتيجة النهائية';

    return AnimatedOpacity(
      opacity: _canSubmit ? 1 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: _canSubmit ? () => setState(() => _submitted = true) : null,
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(vertical: AppSizes.lg + 2),
          decoration: BoxDecoration(
            gradient: _canSubmit
                ? LinearGradient(
                    colors: _isATeams
                        ? const [_purple600, MRColors.indigo600]
                        : _isASolo
                            ? const [_teal600, MRColors.cyan600]
                            : _isSolo
                                ? const [_blue500, MRColors.blue600]
                                : [AppColors.primary, AppColors.primary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: _canSubmit ? null : MRColors.gray200,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            boxShadow: _canSubmit
                ? [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: AppSizes.iconMd,
                color: _canSubmit ? Colors.white : MRColors.gray400,
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: _canSubmit ? Colors.white : MRColors.gray400,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
