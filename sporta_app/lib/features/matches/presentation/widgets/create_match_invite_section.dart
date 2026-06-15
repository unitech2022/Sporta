import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'create_match_choice_button.dart';
import 'create_match_select_field.dart';

class _Player {
  const _Player({required this.id, required this.name, required this.level});

  final String id;
  final String name;
  final String level;
}

// قائمة اللاعبين المتاحة (mock data)
const List<_Player> _availablePlayers = [
  _Player(id: '1', name: 'محمد العتيبي', level: '5.2'),
  _Player(id: '2', name: 'فهد الدوسري', level: '5.8'),
  _Player(id: '3', name: 'سعود القحطاني', level: '5.5'),
  _Player(id: '4', name: 'عبدالله السالم', level: '6.0'),
  _Player(id: '5', name: 'خالد المطيري', level: '5.3'),
  _Player(id: '6', name: 'ناصر الشمري', level: '5.7'),
  _Player(id: '7', name: 'علي الغامدي', level: '5.4'),
  _Player(id: '8', name: 'سلطان العنزي', level: '5.9'),
];

/// "دعوة لاعبين (اختياري)" card: expandable section to invite specific
/// players and pick how long the invitation offer stays valid.
class CreateMatchInviteSection extends StatefulWidget {
  const CreateMatchInviteSection({super.key});

  @override
  State<CreateMatchInviteSection> createState() =>
      _CreateMatchInviteSectionState();
}

class _CreateMatchInviteSectionState extends State<CreateMatchInviteSection> {
  final List<_Player> _invitedPlayers = [];
  bool _showInviteSection = false;
  int _inviteDuration = 24;
  bool _showCustomDuration = false;
  final TextEditingController _customDurationController =
      TextEditingController();

  @override
  void dispose() {
    _customDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border, width: 2),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Tooltip(
                message: 'دعوة لاعبين محددين للانضمام للمباراة',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_add_alt_1_outlined,
                        size: AppSizes.iconMd, color: AppColors.primary),
                    SizedBox(width: AppSizes.sm),
                    Text(
                      'دعوة لاعبين (اختياري)',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => setState(
                    () => _showInviteSection = !_showInviteSection),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.xs),
                  child: Text(
                    _showInviteSection ? 'إخفاء' : 'إضافة دعوات',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          if (_showInviteSection) ...[
            SizedBox(height: AppSizes.md),
            if (_invitedPlayers.isNotEmpty) ...[
              Text(
                'اللاعبين المدعوين (${_invitedPlayers.length})',
                style: AppTextStyles.caption,
              ),
              SizedBox(height: AppSizes.sm),
              for (final player in _invitedPlayers) ...[
                _invitedPlayerTile(player),
                SizedBox(height: AppSizes.sm),
              ],
              SizedBox(height: AppSizes.sm),
            ],
            Text('اختر اللاعبين', style: AppTextStyles.caption),
            const SizedBox(height: AppSizes.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 192),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final player in _availablePlayers.where((p) =>
                        !_invitedPlayers.any((ip) => ip.id == p.id))) ...[
                      _availablePlayerTile(player),
                      SizedBox(height: AppSizes.sm),
                    ],
                  ],
                ),
              ),
            ),
            if (_invitedPlayers.isNotEmpty) ...[
              SizedBox(height: AppSizes.sm),
              _offerDurationSection(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _levelCircle(String level, Gradient gradient) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        level,
        style: AppTextStyles.bodySmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _playerInfo(_Player player) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          player.name,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text('مستوى ${player.level}', style: AppTextStyles.caption),
      ],
    );
  }

  Widget _invitedPlayerTile(_Player player) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        children: [
          _levelCircle(player.level, AppColors.primaryGradient),
          const SizedBox(width: AppSizes.md),
          Expanded(child: _playerInfo(player)),
          IconButton(
            onPressed: () => setState(
                () => _invitedPlayers.removeWhere((p) => p.id == player.id)),
            icon: const Icon(Icons.close,
                size: AppSizes.iconSm, color: AppColors.destructive),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _availablePlayerTile(_Player player) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => setState(() => _invitedPlayers.add(player)),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              _levelCircle(player.level, AppColors.headerGradient),
              SizedBox(width: AppSizes.md),
              Expanded(child: _playerInfo(player)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _offerDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مدة العرض للموافقة',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            for (final hours in const [1, 6, 12, 24, 48]) ...[
              Expanded(
                child: CreateMatchChoiceButton(
                  label: '$hours',
                  subLabel: hours == 1 ? 'ساعة' : 'س',
                  selected:
                      _inviteDuration == hours && !_showCustomDuration,
                  onTap: () => setState(() {
                    _inviteDuration = hours;
                    _showCustomDuration = false;
                    _customDurationController.clear();
                  }),
                  selectedBackground: AppColors.primary,
                  selectedForeground: Colors.white,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.sm,
                  ),
                ),
              ),
              if (hours != 48) const SizedBox(width: AppSizes.sm),
            ],
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        if (!_showCustomDuration)
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: InkWell(
                onTap: () => setState(() => _showCustomDuration = true),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                  child: Text(
                    '+ مدة مخصصة',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customDurationController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.secondary),
                  decoration: createMatchInputDecoration(
                          hint: 'أدخل عدد الساعات')
                      .copyWith(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null && parsed >= 1 && parsed <= 48) {
                      setState(() => _inviteDuration = parsed);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Material(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                child: InkWell(
                  onTap: () => setState(() {
                    _showCustomDuration = false;
                    _customDurationController.clear();
                    _inviteDuration = 24;
                  }),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  child: Padding(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: AppSizes.lg,
                      vertical: AppSizes.md,
                    ),
                    child: Icon(Icons.close,
                        size: AppSizes.iconSm, color: AppColors.secondary),
                  ),
                ),
              ),
            ],
          ),
        SizedBox(height: AppSizes.sm),
        SizedBox(
          width: double.infinity,
          child: Text(
            'سيتلقى اللاعبون إشعاراً ويجب عليهم الموافقة خلال '
            '$_inviteDuration ${_inviteDuration == 1 ? 'ساعة' : 'ساعات'}',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }
}
