import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../friends/data/friend_repository.dart';
import '../../../friends/domain/entities/player_summary.dart';
import 'create_match_choice_button.dart';
import 'create_match_select_field.dart';
import '../../../../core/localization/tr_global.dart';

/// "دعوة لاعبين (اختياري)" card: expandable section to invite specific
/// players (loaded from the user's friends) and pick how long the invitation
/// offer stays valid. Selected player ids are reported via [onInvitedChanged].
class CreateMatchInviteSection extends StatefulWidget {
  const CreateMatchInviteSection({
    super.key,
    this.onInvitedChanged,
    this.onDurationChanged,
    this.excludeUserIds = const {},
    this.tooltip,
  });

  /// Called whenever the set of invited players changes.
  final void Function(List<int> userIds)? onInvitedChanged;

  /// Called whenever the offer duration (in hours) changes.
  final void Function(int hours)? onDurationChanged;

  /// Friends hidden from the list (e.g. the already-picked partner).
  final Set<int> excludeUserIds;

  /// Header tooltip; defaults to the match wording.
  final String? tooltip;

  @override
  State<CreateMatchInviteSection> createState() =>
      _CreateMatchInviteSectionState();
}

class _CreateMatchInviteSectionState extends State<CreateMatchInviteSection> {
  final _friendRepo = getIt<FriendRepository>();

  List<PlayerSummary> _available = [];
  bool _loading = true;
  final List<PlayerSummary> _invitedPlayers = [];
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

  Future<void> _loadFriends() async {
    try {
      final friends = await _friendRepo.fetchFriends();
      if (!mounted) return;
      setState(() {
        _available = friends;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _setDuration(int hours) {
    _inviteDuration = hours;
    widget.onDurationChanged?.call(hours);
  }

  void _notify() => widget.onInvitedChanged?.call(
    _invitedPlayers.map((p) => p.userId).toList(),
  );

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
                message:
                    widget.tooltip ??
                    context.tr('دعوة لاعبين محددين للانضمام للمباراة'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_add_alt_1_outlined,
                      size: AppSizes.iconMd,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: AppSizes.sm),
                    Text(
                      context.tr('دعوة لاعبين (اختياري)'),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() => _showInviteSection = !_showInviteSection);
                  if (_showInviteSection && _loading) _loadFriends();
                },
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.xs),
                  child: Text(
                    _showInviteSection
                        ? context.tr('إخفاء')
                        : context.tr('إضافة دعوات'),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_showInviteSection) ...[
            SizedBox(height: AppSizes.md),
            if (_invitedPlayers.isNotEmpty) ...[
              Text(
                context.trArgs('اللاعبين المدعوين ({p0})', {
                  'p0': _invitedPlayers.length,
                }),
                style: AppTextStyles.caption,
              ),
              SizedBox(height: AppSizes.sm),
              for (final player in _invitedPlayers) ...[
                _invitedPlayerTile(player),
                SizedBox(height: AppSizes.sm),
              ],
              SizedBox(height: AppSizes.sm),
            ],
            Text(context.tr('اختر اللاعبين'), style: AppTextStyles.caption),
            const SizedBox(height: AppSizes.sm),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.lg),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_available.isEmpty)
              Text(
                context.tr('لا يوجد أصدقاء لدعوتهم بعد — أضِف أصدقاء أولاً'),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedForeground,
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 192),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final player in _available.where(
                        (p) =>
                            !widget.excludeUserIds.contains(p.userId) &&
                            !_invitedPlayers.any((ip) => ip.userId == p.userId),
                      )) ...[
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

  String _levelLabel(PlayerSummary p) =>
      p.level != null ? '${p.level}' : trg('؟');

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

  Widget _playerInfo(PlayerSummary player) {
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
        Text(
          player.level != null
              ? context.trArgs('مستوى {p0}', {'p0': player.level})
              : context.tr('لاعب'),
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _invitedPlayerTile(PlayerSummary player) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        children: [
          _levelCircle(_levelLabel(player), AppColors.primaryGradient),
          const SizedBox(width: AppSizes.md),
          Expanded(child: _playerInfo(player)),
          IconButton(
            onPressed: () {
              setState(
                () => _invitedPlayers.removeWhere(
                  (p) => p.userId == player.userId,
                ),
              );
              _notify();
            },
            icon: const Icon(
              Icons.close,
              size: AppSizes.iconSm,
              color: AppColors.destructive,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _availablePlayerTile(PlayerSummary player) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () {
          setState(() => _invitedPlayers.add(player));
          _notify();
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              _levelCircle(_levelLabel(player), AppColors.headerGradient),
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
          context.tr('مدة العرض للموافقة'),
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            for (final hours in const [1, 6, 12, 24, 48]) ...[
              Expanded(
                child: CreateMatchChoiceButton(
                  label: '$hours',
                  subLabel: hours == 1 ? trg('ساعة') : trg('س'),
                  selected: _inviteDuration == hours && !_showCustomDuration,
                  onTap: () => setState(() {
                    _setDuration(hours);
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
                    context.tr('+ مدة مخصصة'),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
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
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                  ),
                  decoration:
                      createMatchInputDecoration(
                        hint: context.tr('أدخل عدد الساعات'),
                      ).copyWith(
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusLg,
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusLg,
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null && parsed >= 1 && parsed <= 48) {
                      setState(() => _setDuration(parsed));
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
                    _setDuration(24);
                  }),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  child: Padding(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: AppSizes.lg,
                      vertical: AppSizes.md,
                    ),
                    child: Icon(
                      Icons.close,
                      size: AppSizes.iconSm,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        SizedBox(height: AppSizes.sm),
        SizedBox(
          width: double.infinity,
          child: Text(
            context.trArgs(
              'سيتلقى اللاعبون إشعاراً ويجب عليهم الموافقة خلال {d}',
              {
                'd':
                    '$_inviteDuration ${context.tr(_inviteDuration == 1 ? 'ساعة' : 'ساعات')}',
              },
            ),
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }
}
