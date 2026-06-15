import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/gradient_page_header.dart';
import '../../domain/entities/player.dart';
import '../widgets/select_teammate_duration_picker.dart';
import '../widgets/select_teammate_player_card.dart';
import '../widgets/select_teammate_sent_dialog.dart';

// Tailwind palette used locally (no design-system equivalent).
const Color _green50 = Color(0xFFF0FDF4);
const Color _green100 = Color(0xFFDCFCE7);
const Color _green300 = Color(0xFF86EFAC);
const Color _green600 = Color(0xFF16A34A);
const Color _gray100 = Color(0xFFF3F4F6);
const Color _gray300 = Color(0xFFD1D5DB);
const Color _gray500 = Color(0xFF6B7280);

// قائمة اللاعبين المتاحين (أصدقاء المستخدم) - mock
const List<Player> _availablePlayers = [
  Player(
      id: '1',
      name: 'محمد العتيبي',
      level: '5.2',
      gamesPlayed: 45,
      winRate: 68,
      status: PlayerStatus.online),
  Player(
      id: '2',
      name: 'فهد الدوسري',
      level: '5.8',
      gamesPlayed: 62,
      winRate: 72,
      status: PlayerStatus.online),
  Player(
      id: '3',
      name: 'سعود القحطاني',
      level: '5.5',
      gamesPlayed: 38,
      winRate: 65,
      status: PlayerStatus.offline),
  Player(
      id: '4',
      name: 'عبدالله السالم',
      level: '6.0',
      gamesPlayed: 71,
      winRate: 75,
      status: PlayerStatus.online),
  Player(
      id: '5',
      name: 'خالد المطيري',
      level: '5.3',
      gamesPlayed: 29,
      winRate: 61,
      status: PlayerStatus.offline),
  Player(
      id: '6',
      name: 'ناصر الشمري',
      level: '5.7',
      gamesPlayed: 54,
      winRate: 70,
      status: PlayerStatus.online),
  Player(
      id: '7',
      name: 'علي الغامدي',
      level: '5.4',
      gamesPlayed: 33,
      winRate: 63,
      status: PlayerStatus.offline),
  Player(
      id: '8',
      name: 'سلطان العنزي',
      level: '5.9',
      gamesPlayed: 58,
      winRate: 74,
      status: PlayerStatus.online),
];

enum _SortBy { level, winRate, games }

/// Teammate selection page (converted from SelectTeammatePage.tsx).
class SelectTeammatePage extends StatefulWidget {
  const SelectTeammatePage({
    super.key,
    required this.onBack,
    required this.onComplete,
    required this.matchDetails,
  });

  final VoidCallback onBack;
  final void Function(Player teammate, int requestDuration) onComplete;
  final TeammateMatchDetails matchDetails;

  @override
  State<SelectTeammatePage> createState() => _SelectTeammatePageState();
}

class _SelectTeammatePageState extends State<SelectTeammatePage> {
  Player? _selectedTeammate;
  String _searchQuery = '';
  bool _filterOnlineOnly = false;
  _SortBy _sortBy = _SortBy.level;
  int _requestDuration = 24; // مدة العرض بالساعات

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // فلترة اللاعبين حسب مستوى المباراة
  List<Player> get _filteredPlayers {
    final minLevel = double.tryParse(widget.matchDetails.minLevel) ?? 0;
    final maxLevel = double.tryParse(widget.matchDetails.maxLevel) ?? 10;

    final players = _availablePlayers.where((player) {
      final playerLevel = double.tryParse(player.level) ?? 0;
      final matchesSearch = player.name.contains(_searchQuery) ||
          player.level.contains(_searchQuery);
      final matchesOnlineFilter = !_filterOnlineOnly || player.isOnline;
      final matchesLevelRange =
          playerLevel >= minLevel && playerLevel <= maxLevel;
      return matchesSearch && matchesOnlineFilter && matchesLevelRange;
    }).toList();

    players.sort((a, b) => switch (_sortBy) {
          _SortBy.level => (double.tryParse(b.level) ?? 0)
              .compareTo(double.tryParse(a.level) ?? 0),
          _SortBy.winRate => (b.winRate ?? 0).compareTo(a.winRate ?? 0),
          _SortBy.games => b.gamesPlayed.compareTo(a.gamesPlayed),
        });
    return players;
  }

  void _handleSendInvitation() {
    final teammate = _selectedTeammate;
    if (teammate == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SelectTeammateSentDialog(
        teammate: teammate,
        requestDuration: _requestDuration,
      ),
    );

    // محاكاة إرسال الإشعار
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      widget.onComplete(teammate, _requestDuration);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredPlayers = _filteredPlayers;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientPageHeader(
            title: 'اختر زميل للمتابعة',
            subtitle: 'اختر زميلك في الفريق وأرسل له دعوة',
            onBack: widget.onBack,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInstructionsCard(),
                  const SizedBox(height: AppSizes.xl),
                  // اختيار مدة العرض
                  SelectTeammateDurationPicker(
                    duration: _requestDuration,
                    onDurationChanged: (value) =>
                        setState(() => _requestDuration = value),
                  ),
                  const SizedBox(height: AppSizes.xl),
                  // البحث
                  AppSearchField(
                    hint: 'ابحث بالاسم أو المستوى...',
                    controller: _searchController,
                    onChanged: (value) =>
                        setState(() => _searchQuery = value),
                  ),
                  SizedBox(height: AppSizes.md),
                  // الفلاتر
                  _buildFilterChips(),
                  SizedBox(height: AppSizes.xl),
                  // عداد النتائج
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'اللاعبين المتاحين (${filteredPlayers.length})',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_selectedTeammate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md,
                            vertical: AppSizes.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: Text(
                            'تم الاختيار',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.primary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  // قائمة اللاعبين
                  if (filteredPlayers.isEmpty)
                    _buildEmptyState()
                  else
                    for (final player in filteredPlayers) ...[
                      SelectTeammatePlayerCard(
                        player: player,
                        selected: _selectedTeammate?.id == player.id,
                        onTap: () =>
                            setState(() => _selectedTeammate = player),
                      ),
                      const SizedBox(height: AppSizes.md),
                    ],
                  // اللاعب المختار
                  if (_selectedTeammate != null) ...[
                    const SizedBox(height: AppSizes.sm),
                    _buildSelectedTeammateCard(_selectedTeammate!),
                  ],
                  const SizedBox(height: AppSizes.lg),
                  // الأزرار
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

  // تعليمات سريعة
  Widget _buildInstructionsCard() {
    final details = widget.matchDetails;
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primary,
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
                  'كل الزملاء في نفس مستوى المباراة',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: AppSizes.sm),
                Text(
                  'المستوى المطلوب: ${details.minLevel} - ${details.maxLevel}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.mutedForeground),
                ),
                const SizedBox(height: AppSizes.md),
                const _InstructionItem('اختر زميلك من القائمة أدناه'),
                const _InstructionItem('سيتم إرسال إشعار له فوراً'),
                const _InstructionItem(
                    'يجب أن يوافق خلال المدة المحددة ويكمل الدفع'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Tooltip(
            message: 'إظهار اللاعبين المتصلين فقط',
            child: AppChip(
              label: 'متصل فقط',
              icon: Icons.circle,
              selected: _filterOnlineOnly,
              onTap: () =>
                  setState(() => _filterOnlineOnly = !_filterOnlineOnly),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Tooltip(
            message: 'ترتيب حسب المستوى الأعلى',
            child: AppChip(
              label: 'أعلى مستوى',
              icon: Icons.trending_up,
              selected: _sortBy == _SortBy.level,
              onTap: () => setState(() => _sortBy = _SortBy.level),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Tooltip(
            message: 'ترتيب حسب نسبة الفوز الأعلى',
            child: AppChip(
              label: 'أعلى فوز',
              icon: Icons.star_outline,
              selected: _sortBy == _SortBy.winRate,
              onTap: () => setState(() => _sortBy = _SortBy.winRate),
            ),
          ),
          SizedBox(width: AppSizes.sm),
          Tooltip(
            message: 'ترتيب حسب عدد المباريات',
            child: AppChip(
              label: 'الأكثر لعباً',
              icon: Icons.people_outline,
              selected: _sortBy == _SortBy.games,
              onTap: () => setState(() => _sortBy = _SortBy.games),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          const Icon(Icons.people_outline, size: 80, color: _gray300),
          SizedBox(height: AppSizes.lg),
          Text(
            'لا يوجد لاعبين',
            style: AppTextStyles.body.copyWith(color: AppColors.secondary),
          ),
          SizedBox(height: AppSizes.xs),
          Text(
            'جرب تغيير الفلاتر أو البحث',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }

  // اللاعب المختار
  Widget _buildSelectedTeammateCard(Player teammate) {
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
                'الزميل المختار',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.md),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  teammate.level,
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                ),
              ),
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
                      'مستوى ${teammate.level} • نسبة فوز ${teammate.winRate?.toStringAsFixed(0) ?? '-'}%',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedTeammate = null),
                icon: const Icon(
                  Icons.close,
                  size: AppSizes.iconSm,
                  color: AppColors.mutedForeground,
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
            child: Column(
              children: [
                _SelectedInfoRow(
                  icon: Icons.person_add_alt_1,
                  text:
                      'سيتم إرسال إشعار لـ ${teammate.name} للموافقة وإكمال الدفع',
                ),
                const SizedBox(height: AppSizes.sm),
                _SelectedInfoRow(
                  icon: Icons.access_time,
                  text:
                      'مدة العرض: $_requestDuration ${_requestDuration == 1 ? 'ساعة' : 'ساعات'}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasSelection = _selectedTeammate != null;

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
                style:
                    AppTextStyles.body.copyWith(color: AppColors.secondary),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Material(
            color: hasSelection ? Colors.transparent : _gray300,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: Ink(
              decoration: BoxDecoration(
                gradient: hasSelection ? AppColors.primaryGradient : null,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: InkWell(
                onTap: hasSelection ? _handleSendInvitation : null,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSizes.md),
                  child: Text(
                    hasSelection
                        ? 'إرسال الدعوة والمتابعة'
                        : 'اختر زميل للمتابعة',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color:
                          hasSelection ? AppColors.onPrimary : _gray500,
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

class _InstructionItem extends StatelessWidget {
  const _InstructionItem(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.primary),
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

class _SelectedInfoRow extends StatelessWidget {
  const _SelectedInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: AppColors.primary),
        ),
        SizedBox(width: AppSizes.sm),
        Expanded(child: Text(text, style: AppTextStyles.caption)),
      ],
    );
  }
}
