import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gradient_page_header.dart';

const _kGreen50 = Color(0xFFF0FDF4);
const _kGreen500 = Color(0xFF22C55E);
const _kGray50 = Color(0xFFF9FAFB);
const _kGreen600 = Color(0xFF16A34A);
const _kRed600 = Color(0xFFDC2626);
const _kBlue50 = Color(0xFFEFF6FF);
const _kBlue500 = Color(0xFF3B82F6);
const _kBlue600 = Color(0xFF2563EB);
const _kPurple50 = Color(0xFFF5F3FF);
const _kPurple600 = Color(0xFF7C3AED);
const _kYellow50 = Color(0xFFFEFCE8);
const _kYellow400 = Color(0xFFFACC15);
const _kOrange500 = Color(0xFFF97316);
const _kGray200 = Color(0xFFE5E7EB);
const _kGray400 = Color(0xFF9CA3AF);

enum _ExecTab { matches, leaderboard, schedule }

enum _RoundType { time, sets }

class _MatchStatus {
  static const playing = 'playing';
  static const completed = 'completed';
  static const waiting = 'waiting';
}

class _MatchData {
  _MatchData({
    required this.courtNumber,
    required this.team1,
    required this.team2,
    required this.score1,
    required this.score2,
    required this.status,
  });

  final int courtNumber;
  final List<String> team1;
  final List<String> team2;
  int score1;
  int score2;
  String status;
}

class _PlayerData {
  const _PlayerData({
    required this.name,
    required this.points,
    required this.wins,
    required this.losses,
    required this.pointsFor,
    required this.pointsAgainst,
  });

  final String name;
  final int points;
  final int wins;
  final int losses;
  final int pointsFor;
  final int pointsAgainst;

  int get diff => pointsFor - pointsAgainst;
  int get matches => wins + losses;
}

final _kLeaderboard = [
  const _PlayerData(
      name: 'محمد العتيبي',
      points: 15,
      wins: 3,
      losses: 0,
      pointsFor: 24,
      pointsAgainst: 10),
  const _PlayerData(
      name: 'فهد الدوسري',
      points: 12,
      wins: 2,
      losses: 1,
      pointsFor: 20,
      pointsAgainst: 14),
  const _PlayerData(
      name: 'سعود القحطاني',
      points: 12,
      wins: 2,
      losses: 1,
      pointsFor: 18,
      pointsAgainst: 15),
  const _PlayerData(
      name: 'عبدالله السالم',
      points: 10,
      wins: 2,
      losses: 1,
      pointsFor: 16,
      pointsAgainst: 14),
  const _PlayerData(
      name: 'خالد المطيري',
      points: 9,
      wins: 1,
      losses: 2,
      pointsFor: 14,
      pointsAgainst: 18),
  const _PlayerData(
      name: 'ناصر الشمري',
      points: 8,
      wins: 1,
      losses: 2,
      pointsFor: 12,
      pointsAgainst: 16),
  const _PlayerData(
      name: 'علي الغامدي',
      points: 6,
      wins: 1,
      losses: 2,
      pointsFor: 10,
      pointsAgainst: 18),
  const _PlayerData(
      name: 'سلطان العنزي',
      points: 6,
      wins: 0,
      losses: 3,
      pointsFor: 9,
      pointsAgainst: 20),
  const _PlayerData(
      name: 'أحمد الغامدي',
      points: 5,
      wins: 1,
      losses: 2,
      pointsFor: 10,
      pointsAgainst: 18),
  const _PlayerData(
      name: 'يوسف القرني',
      points: 4,
      wins: 0,
      losses: 3,
      pointsFor: 8,
      pointsAgainst: 22),
  const _PlayerData(
      name: 'عمر الزهراني',
      points: 3,
      wins: 0,
      losses: 3,
      pointsFor: 7,
      pointsAgainst: 20),
  const _PlayerData(
      name: 'سامي العمري',
      points: 2,
      wins: 0,
      losses: 3,
      pointsFor: 5,
      pointsAgainst: 22),
];

class AmericanoExecutionPage extends StatefulWidget {
  const AmericanoExecutionPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<AmericanoExecutionPage> createState() =>
      _AmericanoExecutionPageState();
}

class _AmericanoExecutionPageState extends State<AmericanoExecutionPage> {
  _ExecTab _activeTab = _ExecTab.matches;
  _RoundType _roundType = _RoundType.time;
  int _timePerRound = 12;
  int _setsPerRound = 1;
  int _currentRound = 1;
  final int _totalRounds = 6;
  int _roundTimer = 0;
  bool _isTimerRunning = false;
  bool _showSettings = false;

  Timer? _timer;

  late List<_MatchData> _matches;

  final _timeController = TextEditingController(text: '12');
  final _setsController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _matches = [
      _MatchData(
        courtNumber: 1,
        team1: ['محمد العتيبي', 'عبدالله السالم'],
        team2: ['فهد الدوسري', 'سعود القحطاني'],
        score1: 8,
        score2: 6,
        status: _MatchStatus.playing,
      ),
      _MatchData(
        courtNumber: 2,
        team1: ['خالد المطيري', 'سلطان العنزي'],
        team2: ['ناصر الشمري', 'علي الغامدي'],
        score1: 4,
        score2: 4,
        status: _MatchStatus.playing,
      ),
      _MatchData(
        courtNumber: 3,
        team1: ['أحمد الغامدي', 'سامي العمري'],
        team2: ['يوسف القرني', 'عمر الزهراني'],
        score1: 0,
        score2: 0,
        status: _MatchStatus.waiting,
      ),
    ];
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timeController.dispose();
    _setsController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _isTimerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _roundTimer++);
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() => _isTimerRunning = false);
  }

  void _nextRound() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _roundTimer = 0;
      _isTimerRunning = false;
      if (_currentRound < _totalRounds) _currentRound++;
    });
  }

  String get _timerDisplay {
    final mins = (_roundTimer ~/ 60).toString().padLeft(2, '0');
    final secs = (_roundTimer % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ColoredBox(
        color: AppColors.background,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showSettings) ...[
                      _buildSettingsPanel(),
                      const SizedBox(height: AppSizes.lg),
                    ],
                    if (_roundType == _RoundType.time)
                      _buildTimerBar()
                    else
                      _buildSetsBar(),
                    const SizedBox(height: AppSizes.lg),
                    _buildTabs(),
                    const SizedBox(height: AppSizes.lg),
                    if (_activeTab == _ExecTab.matches)
                      _buildMatchesTab()
                    else if (_activeTab == _ExecTab.leaderboard)
                      _buildLeaderboardTab()
                    else
                      _buildScheduleTab(),
                    const SizedBox(height: AppSizes.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GradientPageHeader(
      title: 'أمريكانو البادل الملكي',
      subtitle: 'أمريكانو فردي',
      onBack: widget.onBack,
      trailing: [
        IconButton(
          onPressed: () =>
              setState(() => _showSettings = !_showSettings),
          icon: Icon(
            _showSettings ? Icons.settings : Icons.settings_outlined,
            color: AppColors.onPrimary,
            size: AppSizes.iconMd,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
      bottom: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _InfoChip(
                icon: Icons.people_outline,
                label: 'اللاعبين 12'),
            const SizedBox(width: AppSizes.sm),
            _InfoChip(
                icon: Icons.loop_outlined,
                label: 'الجولة $_currentRound/$_totalRounds'),
            SizedBox(width: AppSizes.sm),
            _InfoChip(
                icon: Icons.sports_tennis_outlined,
                label: 'الملاعب 3'),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel() {
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
          Text(
            'إعدادات الجولات',
            style: AppTextStyles.bodySmall
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                child: _ChoiceBtn(
                  label: 'بالوقت',
                  icon: Icons.timer_outlined,
                  selected: _roundType == _RoundType.time,
                  onTap: () =>
                      setState(() => _roundType = _RoundType.time),
                ),
              ),
              SizedBox(width: AppSizes.sm),
              Expanded(
                child: _ChoiceBtn(
                  label: 'بعدد الأشواط',
                  icon: Icons.repeat_outlined,
                  selected: _roundType == _RoundType.sets,
                  onTap: () =>
                      setState(() => _roundType = _RoundType.sets),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.md),
          if (_roundType == _RoundType.time) ...[
            Text('الوقت لكل جولة (دقيقة)',
                style: AppTextStyles.caption),
            SizedBox(height: AppSizes.sm),
            TextField(
              controller: _timeController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.bodySmall,
              decoration: _inputDecoration('مثال: 12'),
              onChanged: (v) {
                final n = int.tryParse(v);
                if (n != null) setState(() => _timePerRound = n);
              },
            ),
          ] else ...[
            Text('عدد الأشواط لكل جولة',
                style: AppTextStyles.caption),
            SizedBox(height: AppSizes.sm),
            TextField(
              controller: _setsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.bodySmall,
              decoration: _inputDecoration('مثال: 1'),
              onChanged: (v) {
                final n = int.tryParse(v);
                if (n != null) setState(() => _setsPerRound = n);
              },
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodySmall
          .copyWith(color: AppColors.mutedForeground),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _buildTimerBar() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg, vertical: AppSizes.sm),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Text(
              _timerDisplay,
              style: AppTextStyles.body.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الجولة $_currentRound / $_totalRounds',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
                Text('$_timePerRound دقيقة لكل جولة',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          _buildTimerButton(),
        ],
      ),
    );
  }

  Widget _buildTimerButton() {
    if (_isTimerRunning) {
      return _TimerActionButton(
        label: 'إيقاف مؤقت',
        color: _kOrange500,
        icon: Icons.pause,
        onTap: _pauseTimer,
      );
    }
    if (_roundTimer == 0) {
      if (_currentRound < _totalRounds) {
        return _TimerActionButton(
          label: 'بدء الجولة',
          color: _kGreen500,
          icon: Icons.play_arrow,
          onTap: _startTimer,
        );
      }
      return _TimerActionButton(
        label: 'الجولة التالية',
        color: AppColors.primary,
        icon: Icons.skip_next,
        onTap: _nextRound,
      );
    }
    return _TimerActionButton(
      label: 'استئناف',
      color: _kGreen500,
      icon: Icons.play_arrow,
      onTap: _startTimer,
    );
  }

  Widget _buildSetsBar() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: _kPurple50,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
            color: _kPurple600.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg, vertical: AppSizes.sm),
            decoration: BoxDecoration(
              color: _kPurple600,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Text(
              '$_setsPerRound',
              style: AppTextStyles.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الجولة $_currentRound / $_totalRounds',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
                Text('$_setsPerRound شوط لكل جولة',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          _TimerActionButton(
            label: 'الجولة التالية',
            color: _kPurple600,
            icon: Icons.skip_next,
            onTap: _nextRound,
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            label: 'المباريات',
            icon: Icons.sports,
            selected: _activeTab == _ExecTab.matches,
            onTap: () => setState(() => _activeTab = _ExecTab.matches),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _TabButton(
            label: 'الترتيب',
            icon: Icons.leaderboard_outlined,
            selected: _activeTab == _ExecTab.leaderboard,
            onTap: () =>
                setState(() => _activeTab = _ExecTab.leaderboard),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _TabButton(
            label: 'الجدول',
            icon: Icons.calendar_view_week_outlined,
            selected: _activeTab == _ExecTab.schedule,
            onTap: () =>
                setState(() => _activeTab = _ExecTab.schedule),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchesTab() {
    return Column(
      children: _matches
          .map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.lg),
              child: _MatchCard(
                match: m,
                onScoreChange: (isTeam1, delta) {
                  setState(() {
                    if (isTeam1) {
                      m.score1 = (m.score1 + delta).clamp(0, 99);
                    } else {
                      m.score2 = (m.score2 + delta).clamp(0, 99);
                    }
                  });
                },
                onComplete: () {
                  setState(() => m.status = _MatchStatus.completed);
                },
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildLeaderboardTab() {
    return Column(
      children: List.generate(_kLeaderboard.length, (i) {
        final p = _kLeaderboard[i];
        final rank = i + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.sm),
          child: _LeaderboardCard(player: p, rank: rank),
        );
      }),
    );
  }

  Widget _buildScheduleTab() {
    return Column(
      children: [
        _buildAlgorithmInfoCard(),
        const SizedBox(height: AppSizes.lg),
        _buildRemainingRounds(),
        SizedBox(height: AppSizes.lg),
        _buildScoringSystemCard(),
      ],
    );
  }

  Widget _buildAlgorithmInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: _kBlue50,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: _kBlue600.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: _kBlue600, size: AppSizes.iconMd),
              SizedBox(width: AppSizes.sm),
              Text(
                'خوارزمية التوزيع العادل',
                style: AppTextStyles.bodySmall.copyWith(
                    color: _kBlue600, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: AppSizes.md),
          for (final t in [
            'يلعب كل لاعب مع جميع اللاعبين الآخرين مرة واحدة على الأقل',
            'يتم تدوير الشركاء بشكل متساوٍ في كل جولة',
            'يضمن النظام عدم تكرار نفس الزوج في نفس الجولة',
            'يتم احتساب النقاط بشكل فردي لكل لاعب',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, size: 6, color: _kBlue500),
                  SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(t,
                        style: AppTextStyles.caption
                            .copyWith(color: _kBlue600)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRemainingRounds() {
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
          Text('الجولات المتبقية',
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSizes.md),
          ...List.generate(_totalRounds - _currentRound + 1, (i) {
            final r = _currentRound + i;
            final isCurrent = r == _currentRound;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                    vertical: AppSizes.sm),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : _kGray50,
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(
                    color: isCurrent
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.primary
                            : _kGray200,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$r',
                          style: AppTextStyles.caption.copyWith(
                            color: isCurrent
                                ? AppColors.onPrimary
                                : AppColors.mutedForeground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSizes.sm),
                    Text(
                      isCurrent ? 'الجولة الحالية' : 'الجولة $r',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight:
                            isCurrent ? FontWeight.w600 : FontWeight.w400,
                        color: isCurrent
                            ? AppColors.secondary
                            : AppColors.mutedForeground,
                      ),
                    ),
                    if (isCurrent) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm,
                            vertical: AppSizes.xs),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                        ),
                        child: Text(
                          'جارية',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.onPrimary,
                              fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildScoringSystemCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kGreen50, Color(0x80DCF4E7)],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
            color: _kGreen500.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined,
                  color: _kGreen600, size: AppSizes.iconMd),
              SizedBox(width: AppSizes.sm),
              Text(
                'نظام التسجيل',
                style: AppTextStyles.bodySmall.copyWith(
                    color: _kGreen600, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: AppSizes.md),
          for (final e in [
            ('فوز', '5 نقاط', _kGreen600),
            ('تعادل', '2 نقطة', _kBlue600),
            ('خسارة', '0 نقاط', _kGray400),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: e.$3,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: AppSizes.sm),
                  Text(e.$1,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: _kGreen600)),
                  const Spacer(),
                  Text(e.$2,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: e.$3,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
          const Divider(color: Color(0x40DCFCE7), height: AppSizes.md),
          Row(
            children: [
              const Icon(Icons.swap_vert,
                  size: AppSizes.iconSm, color: _kGreen600),
              SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  'عند التساوي في النقاط: يُقدَّم اللاعب بفارق النقاط (نقاط له - نقاط عليه)',
                  style: AppTextStyles.caption
                      .copyWith(color: _kGreen600, height: 1.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.xs),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: Colors.white),
          SizedBox(width: AppSizes.xs),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

class _TimerActionButton extends StatelessWidget {
  const _TimerActionButton({
    required this.label,
    required this.color,
    required this.icon,
    this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md, vertical: AppSizes.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSizes.iconSm, color: Colors.white),
              SizedBox(width: AppSizes.xs),
              Text(label,
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: selected
            ? BorderSide.none
            : const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: AppSizes.sm, horizontal: AppSizes.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppSizes.iconSm,
                color: selected
                    ? AppColors.onPrimary
                    : AppColors.mutedForeground,
              ),
              SizedBox(width: AppSizes.xs),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: selected
                        ? AppColors.onPrimary
                        : AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceBtn extends StatelessWidget {
  const _ChoiceBtn({
    required this.label,
    required this.icon,
    required this.selected,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: selected
            ? BorderSide.none
            : const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: AppSizes.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: AppSizes.iconSm,
                  color: selected
                      ? AppColors.onPrimary
                      : AppColors.mutedForeground),
              SizedBox(width: AppSizes.xs),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: selected
                      ? AppColors.onPrimary
                      : AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.match,
    required this.onScoreChange,
    required this.onComplete,
  });

  final _MatchData match;
  final void Function(bool isTeam1, int delta) onScoreChange;
  final VoidCallback onComplete;

  Color get _statusColor {
    switch (match.status) {
      case _MatchStatus.playing:
        return _kGreen500;
      case _MatchStatus.completed:
        return _kGray400;
      case _MatchStatus.waiting:
        return _kBlue500;
      default:
        return _kGray400;
    }
  }

  String get _statusLabel {
    switch (match.status) {
      case _MatchStatus.playing:
        return 'جارية';
      case _MatchStatus.completed:
        return 'منتهية';
      case _MatchStatus.waiting:
        return 'في الانتظار';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = match.status == _MatchStatus.completed;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md, vertical: AppSizes.xs),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    'ملعب ${match.courtNumber}',
                    style: AppTextStyles.caption
                        .copyWith(color: Colors.white),
                  ),
                ),
                SizedBox(width: AppSizes.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm, vertical: AppSizes.xs),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    _statusLabel,
                    style: AppTextStyles.caption
                        .copyWith(color: _statusColor),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: _TeamScoreColumn(
                    players: match.team1,
                    score: match.score1,
                    isCompleted: isCompleted,
                    onMinus: () => onScoreChange(true, -1),
                    onPlus: () => onScoreChange(true, 1),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm),
                  child: Text(
                    'ضد',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedForeground),
                  ),
                ),
                Expanded(
                  child: _TeamScoreColumn(
                    players: match.team2,
                    score: match.score2,
                    isCompleted: isCompleted,
                    onMinus: () => onScoreChange(false, -1),
                    onPlus: () => onScoreChange(false, 1),
                  ),
                ),
              ],
            ),
            if (!isCompleted) ...[
              const SizedBox(height: AppSizes.md),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: AppColors.secondary,
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusLg),
                  child: InkWell(
                    onTap: onComplete,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusLg),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.sm),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: AppSizes.iconSm,
                              color: Colors.white),
                          SizedBox(width: AppSizes.xs),
                          Text(
                            'إنهاء المباراة',
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TeamScoreColumn extends StatelessWidget {
  const _TeamScoreColumn({
    required this.players,
    required this.score,
    required this.isCompleted,
    required this.onMinus,
    required this.onPlus,
  });

  final List<String> players;
  final int score;
  final bool isCompleted;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...players.map((p) => Text(
              p,
              style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            )),
        SizedBox(height: AppSizes.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isCompleted)
              _ScoreBtn(icon: Icons.remove, onTap: onMinus),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm),
              child: Text(
                '$score',
                style: AppTextStyles.heading2
                    .copyWith(color: AppColors.secondary),
              ),
            ),
            if (!isCompleted)
              _ScoreBtn(icon: Icons.add, onTap: onPlus),
          ],
        ),
      ],
    );
  }
}

class _ScoreBtn extends StatelessWidget {
  const _ScoreBtn({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xs),
          child: Icon(icon,
              size: AppSizes.iconSm,
              color: AppColors.secondary),
        ),
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.player, required this.rank});

  final _PlayerData player;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final isFirst = rank == 1;
    final isSecond = rank == 2;
    final isThird = rank == 3;

    Color? bgStart;
    Color? bgEnd;
    Color rankBgColor;
    Widget rankWidget;

    if (isFirst) {
      bgStart = _kYellow50;
      bgEnd = const Color(0x80FEFCE8);
      rankBgColor = _kYellow400;
      rankWidget = const Icon(Icons.workspace_premium,
          color: Colors.white, size: AppSizes.iconSm);
    } else if (isSecond) {
      bgStart = const Color(0xFFF8FAFC);
      bgEnd = const Color(0x80F1F5F9);
      rankBgColor = _kGray400;
      rankWidget = const Icon(Icons.military_tech,
          color: Colors.white, size: AppSizes.iconSm);
    } else if (isThird) {
      bgStart = const Color(0xFFFFF7ED);
      bgEnd = const Color(0x80FFEDD5);
      rankBgColor = _kOrange500;
      rankWidget = const Icon(Icons.military_tech,
          color: Colors.white, size: AppSizes.iconSm);
    } else {
      bgStart = AppColors.card;
      bgEnd = AppColors.card;
      rankBgColor = AppColors.primary;
      rankWidget = Text(
        '$rank',
        style: AppTextStyles.caption.copyWith(
            color: AppColors.onPrimary, fontWeight: FontWeight.w700),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgStart, bgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: isFirst
              ? _kYellow400.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankBgColor,
              shape: BoxShape.circle,
            ),
            child: Center(child: rankWidget),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name,
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    Text('م: ${player.matches}',
                        style: AppTextStyles.caption),
                    SizedBox(width: AppSizes.sm),
                    Text('له: ${player.pointsFor}',
                        style: AppTextStyles.caption
                            .copyWith(color: _kGreen600)),
                    SizedBox(width: AppSizes.sm),
                    Text('عليه: ${player.pointsAgainst}',
                        style: AppTextStyles.caption
                            .copyWith(color: _kRed600)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${player.points}',
                style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary),
              ),
              Text('نقطة',
                  style:
                      AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
