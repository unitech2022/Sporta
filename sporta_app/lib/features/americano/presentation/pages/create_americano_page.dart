import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gradient_page_header.dart';

const _kGreen50 = Color(0xFFF0FDF4);
const _kGreen500 = Color(0xFF22C55E);
const _kGreen600 = Color(0xFF16A34A);
const _kGray50 = Color(0xFFF9FAFB);
const _kGray100 = Color(0xFFF3F4F6);

const _kCourtOptions = [
  'نادي البادل الملكي',
  'بادل كلوب الشرقية',
  'مركز بادل المدينة',
  'ملعب الأندية الشرقية',
  'نادي النخبة',
  'ملاعب الواحة',
];

const _kLevelOptions = [
  '3.0',
  '3.5',
  '4.0',
  '4.5',
  '5.0',
  '5.5',
  '6.0',
  '6.5',
  '7.0',
];

const _kAvailablePlayers = [
  {'name': 'محمد العتيبي', 'level': '5.0'},
  {'name': 'فهد الدوسري', 'level': '4.5'},
  {'name': 'سعود القحطاني', 'level': '4.5'},
  {'name': 'عبدالله السالم', 'level': '5.5'},
  {'name': 'خالد المطيري', 'level': '4.0'},
  {'name': 'ناصر الشمري', 'level': '3.5'},
  {'name': 'علي الغامدي', 'level': '4.0'},
  {'name': 'سلطان العنزي', 'level': '5.0'},
];

const _kInviteDurations = [1, 6, 12, 24, 48];

class CreateAmericanoPage extends StatefulWidget {
  const CreateAmericanoPage(
      {super.key, required this.onBack, this.onComplete});

  final VoidCallback onBack;
  final VoidCallback? onComplete;

  @override
  State<CreateAmericanoPage> createState() => _CreateAmericanoPageState();
}

class _CreateAmericanoPageState extends State<CreateAmericanoPage> {
  String _courtName = '';
  List<int> _courtNumbers = [];
  String _type = '';
  String _playersCount = '';
  String _date = '';
  String _time = '';
  String _duration = '';
  String _minLevel = '';
  String _maxLevel = '';
  String _gender = 'رجال';
  bool _showInviteSection = false;
  List<Map<String, String>> _invitedPlayers = [];
  int _inviteDuration = 24;
  bool _showConfirmation = false;

  final _notesController = TextEditingController();
  final _playersController = TextEditingController();
  final _durationController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    _playersController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final players = int.tryParse(_playersCount);
    return _courtName.isNotEmpty &&
        _courtNumbers.isNotEmpty &&
        _type.isNotEmpty &&
        players != null &&
        players >= 1 &&
        players <= 20 &&
        _date.isNotEmpty &&
        _time.isNotEmpty &&
        _duration.isNotEmpty &&
        _minLevel.isNotEmpty &&
        _maxLevel.isNotEmpty;
  }

  bool get _showSummary =>
      _courtName.isNotEmpty && _type.isNotEmpty && _playersCount.isNotEmpty;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final arabicDays = [
        'الاثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت',
        'الأحد'
      ];
      final arabicMonths = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر'
      ];
      final dayName = arabicDays[picked.weekday - 1];
      final monthName = arabicMonths[picked.month - 1];
      setState(() {
        _date = '$dayName، ${picked.day} $monthName';
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'صباحاً' : 'مساءً';
      setState(() {
        _time = '$hour:$minute $period';
      });
    }
  }

  void _toggleCourtNumber(int n) {
    setState(() {
      if (_courtNumbers.contains(n)) {
        _courtNumbers = List.from(_courtNumbers)..remove(n);
      } else {
        _courtNumbers = List.from(_courtNumbers)..add(n);
      }
    });
  }

  void _toggleInvitePlayer(Map<String, String> player) {
    setState(() {
      final idx = _invitedPlayers.indexWhere((p) => p['name'] == player['name']);
      if (idx >= 0) {
        _invitedPlayers = List.from(_invitedPlayers)..removeAt(idx);
      } else {
        _invitedPlayers = List.from(_invitedPlayers)..add(player);
      }
    });
  }

  void _submit() {
    if (!_isValid) return;
    setState(() => _showConfirmation = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showConfirmation = false);
        widget.onComplete?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          ColoredBox(
            color: AppColors.background,
            child: Column(
              children: [
                GradientPageHeader(
                  title: 'إنشاء أمريكانو',
                  subtitle: 'أنشئ بطولة أمريكانو جديدة',
                  onBack: widget.onBack,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.pagePadding,
                      vertical: AppSizes.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                          title: 'الملعب',
                          icon: Icons.sports_tennis_outlined,
                          child: _buildCourtDropdown(),
                        ),
                        const SizedBox(height: AppSizes.lg),
                        _buildSection(
                          title: 'أرقام الملاعب',
                          icon: Icons.grid_view_outlined,
                          child: _buildCourtNumbersGrid(),
                        ),
                        const SizedBox(height: AppSizes.lg),
                        _buildSection(
                          title: 'نوع الأمريكانو',
                          icon: Icons.people_outline,
                          child: _buildTypeButtons(),
                        ),
                        const SizedBox(height: AppSizes.lg),
                        _buildSection(
                          title: 'عدد اللاعبين',
                          icon: Icons.person_outline,
                          child: _buildPlayersCountField(),
                        ),
                        const SizedBox(height: AppSizes.lg),
                        _buildSection(
                          title: 'الجنس',
                          icon: Icons.wc_outlined,
                          child: _buildGenderButtons(),
                        ),
                        const SizedBox(height: AppSizes.lg),
                        _buildSection(
                          title: 'التاريخ والوقت',
                          icon: Icons.event_outlined,
                          child: _buildDateTimeRow(),
                        ),
                        const SizedBox(height: AppSizes.lg),
                        _buildSection(
                          title: 'مدة الأمريكانو (دقيقة)',
                          icon: Icons.timer_outlined,
                          child: _buildDurationField(),
                        ),
                        const SizedBox(height: AppSizes.lg),
                        _buildSection(
                          title: 'نطاق المستوى',
                          icon: Icons.bar_chart_outlined,
                          child: _buildLevelRange(),
                        ),
                        const SizedBox(height: AppSizes.lg),
                        _buildSection(
                          title: 'ملاحظات (اختياري)',
                          icon: Icons.notes_outlined,
                          child: _buildNotesField(),
                        ),
                        const SizedBox(height: AppSizes.lg),
                        _buildInviteToggle(),
                        if (_showInviteSection) ...[
                          const SizedBox(height: AppSizes.lg),
                          _buildInviteSection(),
                        ],
                        if (_showSummary) ...[
                          const SizedBox(height: AppSizes.lg),
                          _buildSummaryCard(),
                        ],
                        const SizedBox(height: AppSizes.xl),
                        _buildFooterButtons(),
                        SizedBox(height: AppSizes.xl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showConfirmation) _buildSuccessOverlay(),
        ],
      ),
    );
  }

  Widget _buildSection(
      {required String title,
      required IconData icon,
      required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: AppSizes.iconSm, color: AppColors.primary),
            SizedBox(width: AppSizes.xs),
            Text(
              title,
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SizedBox(height: AppSizes.sm),
        child,
      ],
    );
  }

  Widget _buildCourtDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _courtName.isEmpty ? null : _courtName,
          hint: Text('اختر الملعب',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.mutedForeground)),
          isExpanded: true,
          items: _kCourtOptions
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, style: AppTextStyles.bodySmall),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _courtName = v);
          },
        ),
      ),
    );
  }

  Widget _buildCourtNumbersGrid() {
    final sorted = List<int>.from(_courtNumbers)..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSizes.sm,
          crossAxisSpacing: AppSizes.sm,
          childAspectRatio: 1.4,
          children: List.generate(
            10,
            (i) {
              final n = i + 1;
              final selected = _courtNumbers.contains(n);
              return Material(
                color: selected ? AppColors.primary : AppColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  side: selected
                      ? BorderSide.none
                      : const BorderSide(color: AppColors.border),
                ),
                child: InkWell(
                  onTap: () => _toggleCourtNumber(n),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusLg),
                  child: Center(
                    child: Text(
                      '$n',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: selected
                            ? AppColors.onPrimary
                            : AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_courtNumbers.isNotEmpty) ...[
          SizedBox(height: AppSizes.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md, vertical: AppSizes.xs),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Text(
              'تم اختيار ${_courtNumbers.length} ملعب: ${sorted.join(', ')}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTypeButtons() {
    return Row(
      children: ['فردي', 'فرق'].map((t) {
        final selected = _type == t;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                left: t == 'فردي' ? AppSizes.sm : 0),
            child: _ChoiceButton(
              label: t,
              selected: selected,
              icon: t == 'فردي' ? Icons.person : Icons.group,
              onTap: () => setState(() => _type = t),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlayersCountField() {
    return TextField(
      controller: _playersController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: AppTextStyles.bodySmall,
      decoration: InputDecoration(
        hintText: 'عدد اللاعبين (1-20)',
        hintStyle: AppTextStyles.bodySmall
            .copyWith(color: AppColors.mutedForeground),
        filled: true,
        fillColor: AppColors.card,
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
      ),
      onChanged: (v) => setState(() => _playersCount = v),
    );
  }

  Widget _buildGenderButtons() {
    return Row(
      children: ['رجال', 'نساء'].map((g) {
        final selected = _gender == g;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                left: g == 'رجال' ? AppSizes.sm : 0),
            child: _ChoiceButton(
              label: g,
              selected: selected,
              icon: g == 'رجال' ? Icons.male : Icons.female,
              onTap: () => setState(() => _gender = g),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateTimeRow() {
    return Row(
      children: [
        Expanded(
          child: _PickerField(
            icon: Icons.calendar_today_outlined,
            label: _date.isEmpty ? 'اختر التاريخ' : _date,
            hasValue: _date.isNotEmpty,
            onTap: _pickDate,
          ),
        ),
        SizedBox(width: AppSizes.sm),
        Expanded(
          child: _PickerField(
            icon: Icons.access_time_outlined,
            label: _time.isEmpty ? 'اختر الوقت' : _time,
            hasValue: _time.isNotEmpty,
            onTap: _pickTime,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationField() {
    return TextField(
      controller: _durationController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: AppTextStyles.bodySmall,
      decoration: InputDecoration(
        hintText: 'مدة الأمريكانو (30-300 دقيقة)',
        hintStyle: AppTextStyles.bodySmall
            .copyWith(color: AppColors.mutedForeground),
        suffixText: 'دقيقة',
        suffixStyle:
            AppTextStyles.caption.copyWith(color: AppColors.mutedForeground),
        filled: true,
        fillColor: AppColors.card,
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
      ),
      onChanged: (v) => setState(() => _duration = v),
    );
  }

  Widget _buildLevelRange() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الحد الأدنى',
                  style: AppTextStyles.caption),
              SizedBox(height: AppSizes.xs),
              _LevelDropdown(
                value: _minLevel.isEmpty ? null : _minLevel,
                onChanged: (v) {
                  if (v != null) setState(() => _minLevel = v);
                },
              ),
            ],
          ),
        ),
        SizedBox(width: AppSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الحد الأقصى',
                  style: AppTextStyles.caption),
              SizedBox(height: AppSizes.xs),
              _LevelDropdown(
                value: _maxLevel.isEmpty ? null : _maxLevel,
                onChanged: (v) {
                  if (v != null) setState(() => _maxLevel = v);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      maxLines: 3,
      style: AppTextStyles.bodySmall,
      decoration: InputDecoration(
        hintText: 'أضف ملاحظات أو تعليمات للاعبين...',
        hintStyle: AppTextStyles.bodySmall
            .copyWith(color: AppColors.mutedForeground),
        filled: true,
        fillColor: AppColors.card,
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
      ),
      onChanged: (_) {},
    );
  }

  Widget _buildInviteToggle() {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => setState(() => _showInviteSection = !_showInviteSection),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.lg, vertical: AppSizes.md),
          child: Row(
            children: [
              const Icon(Icons.person_add_outlined,
                  size: AppSizes.iconMd, color: AppColors.primary),
              SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text('دعوة لاعبين',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
              if (_invitedPlayers.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm, vertical: AppSizes.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    '${_invitedPlayers.length}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.onPrimary),
                  ),
                ),
              SizedBox(width: AppSizes.sm),
              Icon(
                _showInviteSection
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppColors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInviteSection() {
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
          Text('مدة الدعوة',
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSizes.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _kInviteDurations.map((h) {
                final selected = _inviteDuration == h;
                return Padding(
                  padding: const EdgeInsets.only(left: AppSizes.sm),
                  child: Material(
                    color:
                        selected ? AppColors.primary : _kGray100,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                    child: InkWell(
                      onTap: () =>
                          setState(() => _inviteDuration = h),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md,
                            vertical: AppSizes.xs),
                        child: Text(
                          '$h س',
                          style: AppTextStyles.caption.copyWith(
                            color: selected
                                ? AppColors.onPrimary
                                : AppColors.mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: AppSizes.md),
          Text('اللاعبون المتاحون',
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSizes.sm),
          ..._kAvailablePlayers.map((p) {
            final isInvited =
                _invitedPlayers.any((ip) => ip['name'] == p['name']);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: Material(
                color: isInvited
                    ? AppColors.primary.withValues(alpha: 0.07)
                    : _kGray50,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusLg),
                  side: BorderSide(
                    color: isInvited
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.border,
                  ),
                ),
                child: InkWell(
                  onTap: () => _toggleInvitePlayer(p),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusLg),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.lg,
                        vertical: AppSizes.sm),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          child: Text(
                            p['name']![0],
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(p['name']!,
                                  style: AppTextStyles.bodySmall
                                      .copyWith(
                                          fontWeight:
                                              FontWeight.w600)),
                              Text('مستوى ${p['level']}',
                                  style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        Icon(
                          isInvited
                              ? Icons.check_circle
                              : Icons.add_circle_outline,
                          size: AppSizes.iconMd,
                          color: isInvited
                              ? AppColors.primary
                              : AppColors.mutedForeground,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final sortedNums = List<int>.from(_courtNumbers)..sort();
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
              const Icon(Icons.preview_outlined,
                  size: AppSizes.iconSm, color: _kGreen600),
              SizedBox(width: AppSizes.xs),
              Text(
                'ملخص الأمريكانو',
                style: AppTextStyles.bodySmall.copyWith(
                    color: _kGreen600, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          _SummaryRow(label: 'النوع', value: _type),
          _SummaryRow(label: 'الملعب', value: _courtName),
          if (_courtNumbers.isNotEmpty)
            _SummaryRow(
                label: 'الملاعب',
                value: sortedNums.join(', ')),
          _SummaryRow(label: 'اللاعبون', value: '$_playersCount لاعب'),
          if (_date.isNotEmpty) _SummaryRow(label: 'التاريخ', value: _date),
          if (_time.isNotEmpty) _SummaryRow(label: 'الوقت', value: _time),
        ],
      ),
    );
  }

  Widget _buildFooterButtons() {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: _kGray100,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: InkWell(
              onTap: widget.onBack,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSizes.lg),
                child: Center(
                  child: Text('إلغاء',
                      style: AppTextStyles.body.copyWith(
                          color: AppColors.mutedForeground)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          flex: 2,
          child: Opacity(
            opacity: _isValid ? 1.0 : 0.5,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kGreen500, _kGreen600],
                ),
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusLg),
                boxShadow: _isValid
                    ? [
                        BoxShadow(
                          color:
                              _kGreen500.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusLg),
                child: InkWell(
                  onTap: _isValid ? _submit : null,
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusLg),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.emoji_events_outlined,
                            size: AppSizes.iconMd,
                            color: Colors.white),
                        SizedBox(width: AppSizes.sm),
                        Text(
                          'إنشاء الأمريكانو',
                          style: AppTextStyles.body
                              .copyWith(color: Colors.white),
                        ),
                      ],
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

  Widget _buildSuccessOverlay() {
    final sortedNums = List<int>.from(_courtNumbers)..sort();
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Container(
            margin:
                const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
            padding: const EdgeInsets.all(AppSizes.xl),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: _kGreen50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline,
                      color: _kGreen500, size: 48),
                ),
                SizedBox(height: AppSizes.lg),
                Text(
                  'تم إنشاء الأمريكانو!',
                  style: AppTextStyles.heading2
                      .copyWith(color: _kGreen600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.md),
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kGreen50, Color(0x80DCF4E7)],
                    ),
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(
                        color: _kGreen500.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      if (_type.isNotEmpty)
                        _SummaryRow(label: 'النوع', value: _type),
                      if (_courtName.isNotEmpty)
                        _SummaryRow(
                            label: 'الملعب', value: _courtName),
                      if (_courtNumbers.isNotEmpty)
                        _SummaryRow(
                            label: 'الملاعب',
                            value: sortedNums.join(', ')),
                      if (_date.isNotEmpty)
                        _SummaryRow(label: 'التاريخ', value: _date),
                      if (_time.isNotEmpty)
                        _SummaryRow(label: 'الوقت', value: _time),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.icon,
    this.onTap,
  });

  final String label;
  final bool selected;
  final IconData icon;
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
              vertical: AppSizes.md, horizontal: AppSizes.sm),
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
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
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

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.label,
    required this.hasValue,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool hasValue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.lg, vertical: AppSizes.md),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppSizes.iconSm,
                color: hasValue
                    ? AppColors.primary
                    : AppColors.mutedForeground,
              ),
              SizedBox(width: AppSizes.sm),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: hasValue
                        ? AppColors.secondary
                        : AppColors.mutedForeground,
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

class _LevelDropdown extends StatelessWidget {
  const _LevelDropdown({this.value, this.onChanged});

  final String? value;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text('اختر',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.mutedForeground)),
          isExpanded: true,
          items: _kLevelOptions
              .map((l) => DropdownMenuItem(
                    value: l,
                    child: Text(l, style: AppTextStyles.bodySmall),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.xs),
      child: Row(
        children: [
          Text('$label: ',
              style: AppTextStyles.caption
                  .copyWith(color: _kGreen600.withValues(alpha: 0.7))),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.caption.copyWith(
                  color: _kGreen600, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
