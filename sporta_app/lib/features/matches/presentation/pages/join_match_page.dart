import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gradient_page_header.dart';
import '../../domain/entities/player.dart';
import '../widgets/join_match_confirm_dialog.dart';
import '../widgets/join_match_detail_row.dart';
import '../widgets/join_match_friends_picker_sheet.dart';

// Tailwind palette used locally (no design-system equivalent).
const Color _red50 = Color(0xFFFEF2F2);
const Color _red200 = Color(0xFFFECACA);
const Color _red600 = Color(0xFFDC2626);
const Color _red700 = Color(0xFFB91C1C);
const Color _blue50 = Color(0xFFEFF6FF);
const Color _blue200 = Color(0xFFBFDBFE);
const Color _blue500 = Color(0xFF3B82F6);
const Color _green50 = Color(0xFFF0FDF4);
const Color _green100 = Color(0xFFDCFCE7);
const Color _green200 = Color(0xFFBBF7D0);
const Color _green300 = Color(0xFF86EFAC);
const Color _green500 = Color(0xFF22C55E);
const Color _green600 = Color(0xFF16A34A);
const Color _gray50 = Color(0xFFF9FAFB);
const Color _gray100 = Color(0xFFF3F4F6);
const Color _gray300 = Color(0xFFD1D5DB);
const Color _gray500 = Color(0xFF6B7280);
const Color _purple500 = Color(0xFFA855F7);

/// Match data shown on the join page (mirrors the `Match` interface
/// in JoinMatchPage.tsx).
class _MatchInfo {
  const _MatchInfo({
    required this.courtName,
    required this.location,
    required this.distance,
    required this.date,
    required this.time,
    required this.duration,
    required this.matchType,
    required this.minLevel,
    required this.maxLevel,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.costPerPlayer,
    required this.organizerName,
    required this.organizerLevel,
    this.notes,
    this.rounds,
    this.gender,
  });

  final String courtName;
  final String location;
  final String distance;
  final String date;
  final String time;
  final int duration;
  final String matchType;
  final String minLevel;
  final String maxLevel;
  final int currentPlayers;
  final int maxPlayers;
  final double costPerPlayer;
  final String organizerName;
  final String organizerLevel;
  final String? notes;
  final int? rounds;
  final String? gender;
}

class _TeamPlayer {
  const _TeamPlayer(this.name, this.level, this.initials, this.color);

  final String name;
  final String level;
  final String initials;
  final Color color;
}

// الفرق المسجلة في أمريكانو فرق (mock)
const List<List<_TeamPlayer>> _registeredTeams = [
  [
    _TeamPlayer('أحمد الزهراني', '4.5', 'أ.ز', AppColors.primary),
    _TeamPlayer('سعد المطيري', '4.2', 'س.م', _blue500),
  ],
  [
    _TeamPlayer('عمر الشهري', '3.8', 'ع.ش', _purple500),
    _TeamPlayer('فهد السبيعي', '4.0', 'ف.س', _green500),
  ],
];

// مباريات المستخدم المجدولة (mock data)
const List<({String courtName, String date, String time, int duration})>
    _userScheduledMatches = [
  (
    courtName: 'مركز بادل الشرقية',
    date: '2024-06-02',
    time: '18:00',
    duration: 90,
  ),
];

/// Match details + join flow (converted from JoinMatchPage.tsx).
class JoinMatchPage extends StatefulWidget {
  const JoinMatchPage({
    super.key,
    required this.onBack,
    required this.onJoin,
    this.onNavigateToSelectTeammate,
    this.selectedTeammate,
    this.matchType,
    this.isAmericano = false,
    this.americanoType,
  });

  final VoidCallback onBack;
  final VoidCallback onJoin;
  final VoidCallback? onNavigateToSelectTeammate;
  final Player? selectedTeammate;
  final String? matchType;
  final bool isAmericano;

  /// 'فردي' or 'فرق' — defaults to 'فردي' when null.
  final String? americanoType;

  @override
  State<JoinMatchPage> createState() => _JoinMatchPageState();
}

class _JoinMatchPageState extends State<JoinMatchPage> {
  String? _timeConflict;
  List<String> _invitedFriends = [];

  String get _americanoType => widget.americanoType ?? 'فردي';

  bool get _isAmericanoTeams =>
      widget.isAmericano && _americanoType == 'فرق';

  late final _MatchInfo _match = _buildMatch();

  bool get _isTeamsMatch =>
      _match.matchType.contains('فرق') && _match.matchType != 'أمريكانو فردي';

  bool get _canInviteFriends =>
      (widget.isAmericano && _americanoType == 'فردي') ||
      _match.matchType == 'ودية فردي' ||
      _isAmericanoTeams;

  int get _spotsLeft {
    final maxInvites = _isAmericanoTeams
        ? ((_match.maxPlayers - _match.currentPlayers) ~/ 2) - 1
        : _match.maxPlayers - _match.currentPlayers - 1;
    return maxInvites < 0 ? 0 : maxInvites;
  }

  // بيانات المباراة المراد الانضمام إليها (mock data)
  _MatchInfo _buildMatch() {
    if (widget.isAmericano) {
      final isTeams = _americanoType == 'فرق';
      return _MatchInfo(
        courtName: 'بادل كلوب الشرقية',
        location: 'الخبر',
        distance: '3.2 كم',
        date: '2024-06-04',
        time: '18:30',
        duration: 150,
        matchType: isTeams ? 'أمريكانو فرق' : 'أمريكانو فردي',
        minLevel: '3.5',
        maxLevel: '5.0',
        currentPlayers: isTeams ? 4 : 3,
        maxPlayers: 16,
        costPerPlayer: 45,
        organizerName: 'خالد السالم',
        organizerLevel: '4.2',
        rounds: 3,
        gender: 'رجال',
        notes: !isTeams
            ? 'نظام أمريكانو فردي - سيتم تبديل الشركاء في كل جولة لضمان اللعب مع جميع اللاعبين'
            : 'نظام أمريكانو فرق - ستلعب مع شريكك في جميع الجولات وسيتم احتساب النقاط للفريق',
      );
    }
    switch (widget.matchType) {
      case 'ودية فردي':
        return const _MatchInfo(
          courtName: 'ملعب الأندية الشرقية',
          location: 'الخبر',
          distance: '3.2 كم',
          date: '2024-06-03',
          time: '19:30',
          duration: 90,
          matchType: 'ودية فردي',
          minLevel: '4.5',
          maxLevel: '5.5',
          currentPlayers: 1,
          maxPlayers: 4,
          costPerPlayer: 40,
          organizerName: 'محمد الأحمد',
          organizerLevel: '4.8',
          notes: 'مباراة ودية فردية للاعبين من مستوى متوسط. كل لاعب يلعب لوحده',
        );
      case 'ودية فرق':
        return const _MatchInfo(
          courtName: 'نادي الرياضة للبادل',
          location: 'الدمام',
          distance: '4.5 كم',
          date: '2024-06-05',
          time: '17:30',
          duration: 90,
          matchType: 'ودية فرق',
          minLevel: '3.5',
          maxLevel: '4.5',
          currentPlayers: 2,
          maxPlayers: 4,
          costPerPlayer: 35,
          organizerName: 'عبدالله السعيد',
          organizerLevel: '4.0',
          notes: 'مباراة ودية للفرق في جو ممتع. نبحث عن فريق واحد للانضمام',
        );
      default:
        return const _MatchInfo(
          courtName: 'نادي البادل الملكي',
          location: 'الدمام',
          distance: '1.8 كم',
          date: '2024-06-02',
          time: '18:00',
          duration: 90,
          matchType: 'تحدي فرق',
          minLevel: '5.0',
          maxLevel: '6.0',
          currentPlayers: 2,
          maxPlayers: 4,
          costPerPlayer: 45,
          organizerName: 'أحمد المطيري',
          organizerLevel: '5.5',
          notes: 'نبحث عن لاعبين ذوي خبرة للمشاركة في مباراة تحدي قوية',
        );
    }
  }

  // دالة لتحويل الوقت والتاريخ إلى DateTime
  DateTime _matchDateTime(String date, String time) {
    final dateParts = date.split('-').map(int.parse).toList();
    final timeParts = time.split(':').map(int.parse).toList();
    return DateTime(
      dateParts[0],
      dateParts[1],
      dateParts[2],
      timeParts[0],
      timeParts[1],
    );
  }

  // دالة للتحقق من تعارض المواعيد (± ساعتين)
  bool _checkTimeConflict() {
    final matchStart = _matchDateTime(_match.date, _match.time);
    final matchEnd = matchStart.add(Duration(minutes: _match.duration));

    for (final scheduled in _userScheduledMatches) {
      final scheduledStart = _matchDateTime(scheduled.date, scheduled.time);
      final scheduledEnd =
          scheduledStart.add(Duration(minutes: scheduled.duration));

      const twoHours = Duration(hours: 2);
      final bufferStart = scheduledStart.subtract(twoHours);
      final bufferEnd = scheduledEnd.add(twoHours);

      final startsInside = !matchStart.isBefore(bufferStart) &&
          matchStart.isBefore(bufferEnd);
      final endsInside =
          matchEnd.isAfter(bufferStart) && !matchEnd.isAfter(bufferEnd);
      final covers = !matchStart.isAfter(bufferStart) &&
          !matchEnd.isBefore(bufferEnd);

      if (startsInside || endsInside || covers) {
        setState(() {
          _timeConflict =
              'لديك مباراة في ${scheduled.courtName} الساعة ${scheduled.time}';
        });
        return true;
      }
    }

    setState(() => _timeConflict = null);
    return false;
  }

  void _handleJoinClick() {
    if (_checkTimeConflict()) return;
    if (_isTeamsMatch) {
      widget.onNavigateToSelectTeammate?.call();
    } else {
      _showConfirmationDialog();
    }
  }

  Future<void> _openFriendsPicker() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JoinMatchFriendsPickerSheet(
        friends: joinMatchFriendsList,
        initiallyInvited: _invitedFriends,
        maxInvites: _spotsLeft,
      ),
    );
    if (result != null && mounted) {
      setState(() => _invitedFriends = result);
    }
  }

  String _confirmationMessage() {
    if (_canInviteFriends && _invitedFriends.isNotEmpty) {
      if (_isAmericanoTeams) {
        return 'سيتم انضمامك وإرسال دعوة لـ ${_invitedFriends.length} لاعب لتشكيل فرق';
      }
      return 'سيتم انضمامك وإرسال دعوة لـ ${_invitedFriends.length} ${_invitedFriends.length == 1 ? 'صديق' : 'أصدقاء'}';
    }
    if (widget.selectedTeammate != null) {
      return 'هل أنت متأكد من الانضمام مع ${widget.selectedTeammate!.name}؟';
    }
    return 'هل أنت متأكد من الانضمام لهذه المباراة؟';
  }

  void _showConfirmationDialog() {
    final teammate = widget.selectedTeammate;
    final showTeammateRow = teammate != null &&
        !(widget.isAmericano && _americanoType == 'فردي');
    final cost = _formatCost(_match.costPerPlayer);

    showDialog<void>(
      context: context,
      builder: (_) => JoinMatchConfirmDialog(
        message: _confirmationMessage(),
        courtName: _match.courtName,
        dateLabel: _formatDate(_match.date),
        timeLabel: _formatTime(_match.time),
        costPerPlayer: _match.costPerPlayer,
        invitedFriendFirstNames: _canInviteFriends
            ? [
                for (final id in _invitedFriends)
                  joinMatchFriendsList
                      .firstWhere((f) => f.id == id)
                      .firstName,
              ]
            : const [],
        teammateName: showTeammateRow ? teammate.name : null,
        teammateNote: teammate != null
            ? '* سيقوم ${teammate.name} بدفع حصته ($cost ر.س)'
                '${_match.matchType == 'ودية فردي' ? ' عند قبول الدعوة والانضمام' : ' بعد الموافقة'}'
            : null,
        onConfirm: () {
          // سيتم حفظ البيانات وإضافة اللاعب للمباراة
          widget.onJoin();
        },
      ),
    );
  }

  String _formatCost(double cost) => cost == cost.roundToDouble()
      ? cost.toStringAsFixed(0)
      : cost.toString();

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    const days = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return '${days[date.weekday - 1]}، ${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'مساءً' : 'صباحاً';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientPageHeader(
            title:
                widget.isAmericano ? 'تفاصيل أمريكانو' : 'تفاصيل المباراة',
            subtitle: 'راجع التفاصيل قبل الانضمام',
            onBack: widget.onBack,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // تنبيه التعارض الزمني
                  if (_timeConflict != null) ...[
                    _buildConflictBanner(),
                    const SizedBox(height: AppSizes.xl),
                  ],
                  _buildMatchInfoCard(),
                  const SizedBox(height: AppSizes.xl),
                  // الفرق الحالية - أمريكانو فرق فقط
                  if (_isAmericanoTeams) ...[
                    _buildRegisteredTeamsCard(),
                    const SizedBox(height: AppSizes.xl),
                  ],
                  _buildOrganizerCard(),
                  const SizedBox(height: AppSizes.xl),
                  // ملاحظات إضافية
                  if (_match.notes != null) ...[
                    _buildNotesCard(),
                    const SizedBox(height: AppSizes.xl),
                  ],
                  // عرض الزميل المختار أو تنبيه لاختيار زميل - للفرق فقط
                  if (_isTeamsMatch) ...[
                    widget.selectedTeammate != null
                        ? _buildSelectedTeammateCard(widget.selectedTeammate!)
                        : _buildSelectTeammateHint(),
                    const SizedBox(height: AppSizes.xl),
                  ],
                  // دعوة أصدقاء
                  if (_canInviteFriends) ...[
                    _buildInviteFriendsSection(),
                    const SizedBox(height: AppSizes.xl),
                  ],
                  _buildRulesCard(),
                  const SizedBox(height: AppSizes.lg),
                  _buildActionButtons(),
                  const SizedBox(height: AppSizes.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: _red50,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: _red200, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline,
              size: AppSizes.iconMd, color: AppColors.destructive),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تعارض في المواعيد',
                  style: AppTextStyles.body.copyWith(
                    color: _red700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: AppSizes.xs),
                Text(
                  _timeConflict!,
                  style: AppTextStyles.bodySmall.copyWith(color: _red600),
                ),
                SizedBox(height: AppSizes.xs),
                Text(
                  'لا يمكنك الانضمام لمباراة أخرى في نفس الوقت ± ساعتين',
                  style: AppTextStyles.bodySmall.copyWith(color: _red600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // معلومات المباراة الأساسية
  Widget _buildMatchInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  _match.matchType,
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.primary),
                ),
              ),
              Text(
                '${_match.currentPlayers}/${_match.maxPlayers} لاعبين',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.secondary),
              ),
            ],
          ),
          if (_match.matchType == 'ودية فردي') ...[
            SizedBox(height: AppSizes.sm),
            Container(
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: _blue50,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                border: Border.all(color: _blue200),
              ),
              child: Text(
                '🎾 مباراة فردية - كل لاعب يلعب لوحده ضد الآخرين (4 لاعبين)',
                style: AppTextStyles.caption,
              ),
            ),
          ],
          const SizedBox(height: AppSizes.lg),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSizes.lg),
          // الموقع
          JoinMatchDetailRow(
            icon: Icons.location_on_outlined,
            title: _match.courtName,
            subtitle: '${_match.location} • ${_match.distance}',
          ),
          const SizedBox(height: AppSizes.lg),
          // التاريخ
          JoinMatchDetailRow(
            icon: Icons.calendar_today_outlined,
            title: _formatDate(_match.date),
          ),
          const SizedBox(height: AppSizes.lg),
          // الوقت والمدة
          JoinMatchDetailRow(
            icon: Icons.access_time,
            title: _formatTime(_match.time),
            subtitle: 'المدة: ${_match.duration} دقيقة',
          ),
          const SizedBox(height: AppSizes.lg),
          // المستوى
          JoinMatchDetailRow(
            icon: Icons.trending_up,
            title: 'المستوى المطلوب',
            subtitle: '${_match.minLevel} - ${_match.maxLevel}',
          ),
          const SizedBox(height: AppSizes.lg),
          // عدد اللاعبين
          JoinMatchDetailRow(
            icon: Icons.people_outline,
            title: 'اللاعبين الحاليين',
            subtitle:
                '${_match.currentPlayers} من ${_match.maxPlayers} • متبقي ${_match.maxPlayers - _match.currentPlayers}',
          ),
          const SizedBox(height: AppSizes.lg),
          // التكلفة
          JoinMatchDetailRow(
            icon: Icons.attach_money,
            title: 'التكلفة لكل لاعب',
            subtitle: '${_formatCost(_match.costPerPlayer)} ر.س',
          ),
          // معلومات أمريكانو الإضافية
          if (widget.isAmericano) ...[
            if (_match.rounds != null) ...[
              const SizedBox(height: AppSizes.lg),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppSizes.lg),
              JoinMatchDetailRow(
                icon: Icons.trending_up,
                title: 'عدد الجولات',
                subtitle: '${_match.rounds} جولات',
              ),
            ],
            if (_match.gender != null) ...[
              const SizedBox(height: AppSizes.lg),
              JoinMatchDetailRow(
                icon: Icons.people_outline,
                title: 'الفئة المستهدفة',
                subtitle: _match.gender,
              ),
            ],
          ],
        ],
      ),
    );
  }

  // الفرق الحالية - أمريكانو فرق فقط
  Widget _buildRegisteredTeamsCard() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.xl,
              vertical: AppSizes.md,
            ),
            decoration: const BoxDecoration(
              color: _gray50,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_outline,
                        size: AppSizes.iconSm, color: AppColors.primary),
                    SizedBox(width: AppSizes.sm),
                    Text(
                      'الفرق الحالية',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.secondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: AppSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    '${_registeredTeams.length} فريق من ${_match.maxPlayers ~/ 2}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < _registeredTeams.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.xl,
                vertical: AppSizes.lg,
              ),
              child: Row(
                children: [
                  _TeamIndexBubble(index: i + 1),
                  const SizedBox(width: AppSizes.lg),
                  for (final player in _registeredTeams[i])
                    Expanded(child: _TeamPlayerCell(player: player)),
                ],
              ),
            ),
          ],
          // سطر "أنت + شريكك"
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.xl,
              vertical: AppSizes.lg,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              border: Border(
                top: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                _TeamIndexBubble(
                  index: _registeredTeams.length + 1,
                  strong: true,
                ),
                SizedBox(width: AppSizes.lg),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'أنت',
                          style: AppTextStyles.caption
                              .copyWith(color: Colors.white),
                        ),
                      ),
                      SizedBox(width: AppSizes.sm),
                      Text(
                        'أنت',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '+',
                          style: AppTextStyles.caption.copyWith(
                            color:
                                AppColors.primary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSizes.sm),
                      Text('شريكك', style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // منظم المباراة
  Widget _buildOrganizerCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: AppSizes.sm),
              Text(
                'منظم المباراة',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _LevelCircle(label: _match.organizerLevel, size: 48),
                  SizedBox(width: AppSizes.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _match.organizerName,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'مستوى ${_match.organizerLevel}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                ],
              ),
              Material(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  child: const Padding(
                    padding: EdgeInsets.all(AppSizes.md),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: AppSizes.iconMd,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ملاحظات إضافية
  Widget _buildNotesCard() {
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
          Text(
            'ملاحظات المنظم',
            style: AppTextStyles.body.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppSizes.sm),
          Text(
            _match.notes!,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.mutedForeground, height: 1.7),
          ),
        ],
      ),
    );
  }

  // زميلك في الفريق
  Widget _buildSelectedTeammateCard(Player teammate) {
    final winRate = teammate.winRate;
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [_green50, _green100],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: _green300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle,
                  size: AppSizes.iconMd, color: _green600),
              SizedBox(width: AppSizes.sm),
              Text(
                'زميلك في الفريق',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    _LevelCircle(label: teammate.level, size: 56),
                    SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teammate.name,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'مستوى ${teammate.level} • ${teammate.gamesPlayed} مباراة'
                            '${winRate != null ? ' • فوز ${winRate.toStringAsFixed(0)}%' : ''}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Material(
                color: AppColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  side: const BorderSide(color: AppColors.primary, width: 2),
                ),
                child: InkWell(
                  onTap: () => widget.onNavigateToSelectTeammate?.call(),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.lg,
                      vertical: AppSizes.sm,
                    ),
                    child: Text(
                      'تغيير',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _green500.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add_alt_1,
                      size: 12, color: _green600),
                ),
                SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    'سيتم إرسال إشعار لـ ${teammate.name} للموافقة وإكمال الدفع',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // اختيار زميل
  Widget _buildSelectTeammateHint() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [_blue50, _blue200.withValues(alpha: 0.5)],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: _blue200, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: _blue500,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_alt_1,
                size: AppSizes.iconMd, color: Colors.white),
          ),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اختيار زميل',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: AppSizes.sm),
                Text(
                  'ستتمكن من اختيار زميلك في الفريق. سيتم إرسال إشعار له للموافقة وإكمال الدفع.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.mutedForeground,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // دعوة أصدقاء
  Widget _buildInviteFriendsSection() {
    final invitedCount = _invitedFriends.length;
    final String title = _isAmericanoTeams
        ? 'دعوة فريق صديق للانضمام'
        : _match.matchType == 'ودية فردي'
            ? 'دعوة أصدقاء للمباراة'
            : 'دعوة أصدقاء للأمريكانو';
    final String subtitle = invitedCount > 0
        ? _isAmericanoTeams
            ? '$invitedCount لاعب مدعو • سيُشكّلون فرقاً'
            : '$invitedCount صديق مدعو • متبقي ${_spotsLeft - invitedCount} مقعد'
        : _isAmericanoTeams
            ? 'حتى $_spotsLeft فريق إضافي • اختياري'
            : 'حتى $_spotsLeft ${_spotsLeft == 1 ? 'مقعد متاح' : 'أصدقاء'} • اختياري';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.primary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 2),
      ),
      child: Column(
        children: [
          // رأس القسم
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.xl,
              vertical: AppSizes.lg,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  child: const Icon(Icons.person_add_alt_1,
                      size: AppSizes.iconMd, color: Colors.white),
                ),
                SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.secondary),
                      ),
                      Text(subtitle, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                SizedBox(width: AppSizes.sm),
                Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  child: InkWell(
                    onTap: _openFriendsPicker,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: 6,
                      ),
                      child: Text(
                        invitedCount > 0 ? 'تعديل' : 'دعوة',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.onPrimary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
          // الأصدقاء المدعوون
          if (invitedCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.xl,
                vertical: AppSizes.md,
              ),
              child: Column(
                children: [
                  for (final id in _invitedFriends) ...[
                    _InvitedFriendRow(
                      friend: joinMatchFriendsList
                          .firstWhere((f) => f.id == id),
                      onRemove: () =>
                          setState(() => _invitedFriends.remove(id)),
                    ),
                    if (id != _invitedFriends.last)
                      SizedBox(height: AppSizes.sm),
                  ],
                ],
              ),
            )
          else
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.xl,
                vertical: AppSizes.md,
              ),
              child: Text(
                '💡 الأصدقاء المدعوون سيحصلون على إشعار فوري ويمكنهم القبول أو الرفض',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  // قواعد الانضمام
  Widget _buildRulesCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [_green50, _green100],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: _green200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle,
                  size: AppSizes.iconMd, color: _green600),
              SizedBox(width: AppSizes.sm),
              Text(
                'قواعد الانضمام',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          const _RuleItem('لا يمكنك الانضمام لمباراة أخرى في نفس الوقت ± ساعتين'),
          if (_match.matchType == 'ودية فردي') ...[
            const _RuleItem('مباراة فردية - كل لاعب يلعب لوحده (4 لاعبين)'),
            const _RuleItem('يمكنك دعوة أصدقاء للانضمام (اختياري)'),
          ],
          if (_isTeamsMatch) ...[
            const _RuleItem('كل الزملاء في نفس مستوى المباراة'),
            const _RuleItem('يجب اختيار زميل للفريق وانتظار موافقته'),
          ],
          const _RuleItem('الدفع مطلوب قبل تأكيد الانضمام'),
          const _RuleItem('يمكن الإلغاء قبل 24 ساعة من موعد المباراة'),
        ],
      ),
    );
  }

  // أزرار الإجراءات
  Widget _buildActionButtons() {
    final bool disabled = _timeConflict != null;
    final String joinLabel = disabled
        ? 'غير متاح'
        : (_isTeamsMatch && widget.selectedTeammate == null)
            ? 'اختر زميل للمتابعة'
            : _match.matchType == 'ودية فردي'
                ? (widget.selectedTeammate != null
                    ? 'انضم وأرسل الدعوة'
                    : 'انضم الآن')
                : 'انضم الآن';

    return Row(
      children: [
        Material(
          color: _gray100,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: InkWell(
            onTap: widget.onBack,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.xxl,
                vertical: AppSizes.md,
              ),
              child: Text(
                'رجوع',
                style: AppTextStyles.body.copyWith(color: AppColors.secondary),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Material(
            color: disabled ? _gray300 : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: Ink(
              decoration: BoxDecoration(
                gradient: disabled ? null : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: InkWell(
                onTap: disabled ? null : _handleJoinClick,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSizes.md),
                  child: Text(
                    joinLabel,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: disabled ? _gray500 : AppColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RuleItem extends StatelessWidget {
  const _RuleItem(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: AppTextStyles.bodySmall.copyWith(color: _green600),
          ),
          SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelCircle extends StatelessWidget {
  const _LevelCircle({required this.label, required this.size});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
          fontSize: size >= 56 ? 18 : 16,
        ),
      ),
    );
  }
}

class _TeamIndexBubble extends StatelessWidget {
  const _TeamIndexBubble({required this.index, this.strong = false});

  final int index;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: strong ? 0.2 : 0.1),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$index',
        style: AppTextStyles.caption.copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _TeamPlayerCell extends StatelessWidget {
  const _TeamPlayerCell({required this.player});

  final _TeamPlayer player;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [player.color, player.color.withValues(alpha: 0.8)],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            player.initials,
            style: AppTextStyles.caption.copyWith(color: Colors.white),
          ),
        ),
        SizedBox(width: AppSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.name,
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.secondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'مستوى ${player.level}',
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InvitedFriendRow extends StatelessWidget {
  const _InvitedFriendRow({required this.friend, required this.onRemove});

  final JoinMatchFriend friend;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          JoinMatchFriendAvatar(friend: friend, size: 36),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.secondary),
                ),
                Text(
                  'مستوى ${friend.level} • ⏳ في انتظار القبول',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Material(
            color: _gray100,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(AppSizes.xs),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
