import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/presentation/widgets/circle_back_button.dart';
import '../widgets/create_match_choice_button.dart';
import '../widgets/create_match_cost_summary.dart';
import '../widgets/create_match_field_label.dart';
import '../widgets/create_match_invite_section.dart';
import '../widgets/create_match_picker_field.dart';
import '../widgets/create_match_preview_card.dart';
import '../widgets/create_match_select_field.dart';

// أسعار الملاعب (سعر الساعة)
const Map<String, int> _courtPrices = {
  'نادي البادل الملكي': 120,
  'ملعب الأندية الشرقية': 100,
  'بادل كلوب الشرقية': 110,
  'ملعب النادي الرياضي': 95,
};

const List<CreateMatchSelectOption> _courtOptions = [
  CreateMatchSelectOption('نادي البادل الملكي', 'نادي البادل الملكي'),
  CreateMatchSelectOption('ملعب الأندية الشرقية', 'ملعب الأندية الشرقية'),
  CreateMatchSelectOption('بادل كلوب الشرقية', 'بادل كلوب الشرقية'),
  CreateMatchSelectOption('ملعب النادي الرياضي', 'ملعب النادي الرياضي'),
];

const List<CreateMatchSelectOption> _levelOptions = [
  CreateMatchSelectOption('3.0', '3.0 - مبتدئ'),
  CreateMatchSelectOption('3.5', '3.5 - مبتدئ متقدم'),
  CreateMatchSelectOption('4.0', '4.0 - متوسط'),
  CreateMatchSelectOption('4.5', '4.5 - متوسط متقدم'),
  CreateMatchSelectOption('5.0', '5.0 - متقدم'),
  CreateMatchSelectOption('5.5', '5.5 - متقدم جداً'),
  CreateMatchSelectOption('6.0', '6.0 - محترف'),
  CreateMatchSelectOption('6.5', '6.5 - محترف متقدم'),
  CreateMatchSelectOption('7.0', '7.0 - نخبة'),
];

/// "إنشاء مباراة جديدة" — full-screen form to create an open match,
/// converted from CreateMatchPage.tsx.
class CreateMatchPage extends StatefulWidget {
  const CreateMatchPage({
    super.key,
    required this.onBack,
    required this.onComplete,
  });

  final VoidCallback onBack;
  final VoidCallback onComplete;

  @override
  State<CreateMatchPage> createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends State<CreateMatchPage> {
  String _courtName = '';
  String _date = '';
  String _time = '';
  String _duration = '90';
  String _matchType = '';
  String _minLevel = '';
  String _maxLevel = '';
  String _playersNeeded = '2';
  final String _costPerPlayer = '';
  String _paymentType = ''; // 'full' أو 'share'
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // حساب التكلفة الإجمالية
  int get _totalCost {
    if (_courtName.isEmpty || _duration.isEmpty) return 0;
    final pricePerHour = _courtPrices[_courtName] ?? 0;
    final hours = int.parse(_duration) / 60;
    return (pricePerHour * hours).round();
  }

  // حساب حصة اللاعب
  int get _playerShare {
    final totalPlayers = int.parse(_playersNeeded) + 1; // +1 لأن منشئ المباراة يُحسب
    return (_totalCost / totalPlayers).round();
  }

  bool get _isFormValid {
    return _courtName.isNotEmpty &&
        _date.isNotEmpty &&
        _time.isNotEmpty &&
        _matchType.isNotEmpty &&
        _minLevel.isNotEmpty &&
        _maxLevel.isNotEmpty;
  }

  String get _matchTypeLabel {
    switch (_matchType) {
      case 'challenge-team':
        return 'تحدي فرق';
      case 'friendly-individual':
        return 'ودية فردي';
      default:
        return '';
    }
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() =>
          _date = '${picked.year}-${_two(picked.month)}-${_two(picked.day)}');
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _time = '${_two(picked.hour)}:${_two(picked.minute)}');
    }
  }

  void _handleSubmit() {
    // سيتم حفظ البيانات وإنشاء المباراة
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.pagePadding,
                  vertical: AppSizes.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCourtField(),
                    const SizedBox(height: AppSizes.xl),
                    _buildDateTimeFields(),
                    const SizedBox(height: AppSizes.xl),
                    _buildDurationField(),
                    const SizedBox(height: AppSizes.xl),
                    _buildMatchTypeField(),
                    const SizedBox(height: AppSizes.xl),
                    _buildLevelFields(),
                    const SizedBox(height: AppSizes.xl),
                    _buildPlayersNeededField(),
                    const SizedBox(height: AppSizes.xl),
                    if (_courtName.isNotEmpty && _duration.isNotEmpty) ...[
                      CreateMatchCostSummary(
                        totalCost: _totalCost,
                        playerShare: _playerShare,
                        totalPlayers: int.parse(_playersNeeded) + 1,
                        paymentType: _paymentType,
                        onPaymentTypeChanged: (type) =>
                            setState(() => _paymentType = type),
                      ),
                      const SizedBox(height: AppSizes.xl),
                    ],
                    _buildNotesField(),
                    const SizedBox(height: AppSizes.xl),
                    const CreateMatchInviteSection(),
                    const SizedBox(height: AppSizes.xl),
                    if (_isFormValid) ...[
                      CreateMatchPreviewCard(
                        courtName: _courtName,
                        date: _date,
                        time: _time,
                        typeLabel: _matchTypeLabel,
                        minLevel: _minLevel,
                        maxLevel: _maxLevel,
                        costPerPlayer: _costPerPlayer,
                      ),
                      const SizedBox(height: AppSizes.xl),
                    ],
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.xxxl,
            AppSizes.pagePadding,
            AppSizes.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleBackButton(onTap: widget.onBack),
                  SizedBox(width: AppSizes.md),
                  Text(
                    'إنشاء مباراة جديدة',
                    style: AppTextStyles.heading1
                        .copyWith(color: AppColors.onSecondary),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.lg),
              Text(
                'املأ التفاصيل لإنشاء مباراة مفتوحة',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.onSecondary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourtField() {
    return CreateMatchSelectField(
      label: 'اسم الملعب *',
      icon: Icons.location_on_outlined,
      hint: 'اختر الملعب',
      options: _courtOptions,
      value: _courtName,
      onChanged: (value) => setState(() => _courtName = value),
    );
  }

  Widget _buildDateTimeFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CreateMatchPickerField(
            label: 'التاريخ *',
            icon: Icons.calendar_today_outlined,
            value: _date,
            hint: 'يوم/شهر/سنة',
            onTap: _pickDate,
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: CreateMatchPickerField(
            label: 'الوقت *',
            icon: Icons.access_time,
            value: _time,
            hint: '--:--',
            onTap: _pickTime,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CreateMatchFieldLabel(text: 'مدة المباراة'),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            for (final duration in const ['60', '90', '120']) ...[
              Expanded(
                child: CreateMatchChoiceButton(
                  label: '$duration دقيقة',
                  selected: _duration == duration,
                  onTap: () => setState(() => _duration = duration),
                ),
              ),
              if (duration != '120') const SizedBox(width: AppSizes.md),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMatchTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CreateMatchFieldLabel(text: 'نوع المباراة *'),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            Expanded(
              child: CreateMatchChoiceButton(
                label: 'تحدي فرق',
                selected: _matchType == 'challenge-team',
                onTap: () => setState(() => _matchType = 'challenge-team'),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: CreateMatchChoiceButton(
                label: 'ودية فردي',
                selected: _matchType == 'friendly-individual',
                onTap: () =>
                    setState(() => _matchType = 'friendly-individual'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLevelFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CreateMatchFieldLabel(
          text: 'المستوى المطلوب *',
          icon: Icons.trending_up,
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CreateMatchSelectField(
                label: 'الحد الأدنى',
                hint: 'اختر',
                dense: true,
                options: _levelOptions,
                value: _minLevel,
                onChanged: (value) => setState(() => _minLevel = value),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: CreateMatchSelectField(
                label: 'الحد الأقصى',
                hint: 'اختر',
                dense: true,
                options: _levelOptions,
                value: _maxLevel,
                onChanged: (value) => setState(() => _maxLevel = value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayersNeededField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CreateMatchFieldLabel(
          text: 'عدد اللاعبين المطلوبين',
          icon: Icons.people_outline,
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            for (final count in const ['1', '2', '3', '4']) ...[
              Expanded(
                child: CreateMatchChoiceButton(
                  label: count,
                  selected: _playersNeeded == count,
                  onTap: () => setState(() => _playersNeeded = count),
                ),
              ),
              if (count != '4') SizedBox(width: AppSizes.md),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CreateMatchFieldLabel(text: 'ملاحظات إضافية'),
        SizedBox(height: AppSizes.sm),
        TextField(
          controller: _notesController,
          maxLines: 3,
          style: AppTextStyles.body.copyWith(color: AppColors.secondary),
          decoration: createMatchInputDecoration(
            hint: 'أي تفاصيل إضافية تريد إضافتها...',
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    const gray100 = Color(0xFFF3F4F6);
    const gray300 = Color(0xFFD1D5DB);
    final valid = _isFormValid;

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.lg),
      child: Row(
        children: [
          // إلغاء
          Material(
            color: gray100,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: InkWell(
              onTap: widget.onBack,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSizes.pagePadding,
                  vertical: AppSizes.md,
                ),
                child: Text(
                  'إلغاء',
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.secondary),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          // إنشاء المباراة
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: valid ? AppColors.primaryGradient : null,
                color: valid ? null : gray300,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                boxShadow: valid
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                child: InkWell(
                  onTap: valid ? _handleSubmit : null,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSizes.md),
                    child: Text(
                      'إنشاء المباراة',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: valid
                            ? Colors.white
                            : AppColors.mutedForeground,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
