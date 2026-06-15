import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/player.dart';

// Tailwind palette used locally for friend avatar tints.
const Color _blue500 = Color(0xFF3B82F6);
const Color _green500 = Color(0xFF22C55E);
const Color _green600 = Color(0xFF16A34A);
const Color _green50 = Color(0xFFF0FDF4);
const Color _orange500 = Color(0xFFF97316);
const Color _purple500 = Color(0xFFA855F7);
const Color _teal500 = Color(0xFF14B8A6);
const Color _gray100 = Color(0xFFF3F4F6);
const Color _gray400 = Color(0xFF9CA3AF);
const Color _yellow500 = Color(0xFFEAB308);

/// Friend entry shown in the invite-friends picker
/// (converted from `friendsList` in JoinMatchPage.tsx).
class JoinMatchFriend {
  const JoinMatchFriend({
    required this.id,
    required this.name,
    required this.level,
    required this.gamesPlayed,
    required this.winRate,
    required this.status,
    required this.initials,
    required this.color,
  });

  final String id;
  final String name;
  final String level;
  final int gamesPlayed;
  final int winRate;
  final PlayerStatus status;
  final String initials;
  final Color color;

  String get firstName => name.split(' ').first;
}

/// Mock friends list (mirrors `friendsList` in JoinMatchPage.tsx).
const List<JoinMatchFriend> joinMatchFriendsList = [
  JoinMatchFriend(
    id: 'f1',
    name: 'سعد الغامدي',
    level: '4.5',
    gamesPlayed: 62,
    winRate: 58,
    status: PlayerStatus.online,
    initials: 'س.غ',
    color: AppColors.primary,
  ),
  JoinMatchFriend(
    id: 'f2',
    name: 'عمر الشهري',
    level: '3.8',
    gamesPlayed: 38,
    winRate: 44,
    status: PlayerStatus.online,
    initials: 'ع.ش',
    color: _blue500,
  ),
  JoinMatchFriend(
    id: 'f3',
    name: 'فيصل العتيبي',
    level: '5.0',
    gamesPlayed: 95,
    winRate: 63,
    status: PlayerStatus.offline,
    initials: 'ف.ع',
    color: _purple500,
  ),
  JoinMatchFriend(
    id: 'f4',
    name: 'ماجد الدوسري',
    level: '4.2',
    gamesPlayed: 51,
    winRate: 49,
    status: PlayerStatus.online,
    initials: 'م.د',
    color: _green500,
  ),
  JoinMatchFriend(
    id: 'f5',
    name: 'بندر الحربي',
    level: '4.8',
    gamesPlayed: 74,
    winRate: 55,
    status: PlayerStatus.offline,
    initials: 'ب.ح',
    color: _orange500,
  ),
  JoinMatchFriend(
    id: 'f6',
    name: 'تركي الزهراني',
    level: '3.5',
    gamesPlayed: 29,
    winRate: 41,
    status: PlayerStatus.online,
    initials: 'ت.ز',
    color: _teal500,
  ),
];

/// Bottom sheet for picking friends to invite
/// (converted from the friends picker overlay in JoinMatchPage.tsx).
/// Pops with the selected friend ids (`List<String>`).
class JoinMatchFriendsPickerSheet extends StatefulWidget {
  const JoinMatchFriendsPickerSheet({
    super.key,
    required this.friends,
    required this.initiallyInvited,
    required this.maxInvites,
  });

  final List<JoinMatchFriend> friends;
  final List<String> initiallyInvited;
  final int maxInvites;

  @override
  State<JoinMatchFriendsPickerSheet> createState() =>
      _JoinMatchFriendsPickerSheetState();
}

class _JoinMatchFriendsPickerSheetState
    extends State<JoinMatchFriendsPickerSheet> {
  late List<String> _invited = List.of(widget.initiallyInvited);
  String _search = '';

  void _toggleInvite(String id) {
    setState(() {
      if (_invited.contains(id)) {
        _invited.remove(id);
      } else {
        _invited.add(id);
      }
    });
  }

  JoinMatchFriend _friendById(String id) =>
      widget.friends.firstWhere((f) => f.id == id);

  @override
  Widget build(BuildContext context) {
    final filtered = widget.friends
        .where((f) => f.name.contains(_search) || f.level.contains(_search))
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // رأس ثابت
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.xl,
              AppSizes.xl,
              AppSizes.xl,
              AppSizes.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ادعُ أصدقاءك',
                          style: AppTextStyles.heading3
                              .copyWith(color: AppColors.secondary),
                        ),
                        Text(
                          '${_invited.length}/${widget.maxInvites} مدعو • يمكنك اختيار حتى ${widget.maxInvites}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    Material(
                      color: _gray100,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).pop(_invited),
                        child: Padding(
                          padding: EdgeInsets.all(AppSizes.sm),
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
                SizedBox(height: AppSizes.md),
                // شريط البحث
                TextField(
                  onChanged: (value) => setState(() => _search = value),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.secondary),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن صديق...',
                    hintStyle: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.mutedForeground),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: AppSizes.iconSm,
                      color: AppColors.mutedForeground,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.lg,
                      vertical: AppSizes.md,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                // الأصدقاء المختارون
                if (_invited.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.md),
                  SizedBox(
                    height: 66,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _invited.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSizes.sm),
                      itemBuilder: (context, index) {
                        final friend = _friendById(_invited[index]);
                        return _SelectedFriendChip(
                          friend: friend,
                          onRemove: () => _toggleInvite(friend.id),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // قائمة الأصدقاء
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.xl,
                vertical: AppSizes.md,
              ),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
              itemBuilder: (context, index) {
                final friend = filtered[index];
                final invited = _invited.contains(friend.id);
                final disabled =
                    !invited && _invited.length >= widget.maxInvites;
                return _FriendTile(
                  friend: friend,
                  invited: invited,
                  disabled: disabled,
                  onTap: disabled ? null : () => _toggleInvite(friend.id),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // زر التأكيد
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.xl,
                vertical: AppSizes.lg,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Material(
                  color: _invited.isNotEmpty ? AppColors.primary : _gray100,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(_invited),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.lg,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.send,
                            size: AppSizes.iconSm,
                            color: _invited.isNotEmpty
                                ? AppColors.onPrimary
                                : AppColors.secondary,
                          ),
                          SizedBox(width: AppSizes.sm),
                          Text(
                            _invited.isNotEmpty
                                ? 'تأكيد دعوة ${_invited.length} ${_invited.length == 1 ? 'صديق' : 'أصدقاء'}'
                                : 'متابعة بدون دعوة',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: _invited.isNotEmpty
                                  ? AppColors.onPrimary
                                  : AppColors.secondary,
                            ),
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
      ),
    );
  }
}

class _SelectedFriendChip extends StatelessWidget {
  const _SelectedFriendChip({required this.friend, required this.onRemove});

  final JoinMatchFriend friend;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            JoinMatchFriendAvatar(friend: friend, size: 40),
            PositionedDirectional(
              top: -4,
              end: -4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.destructive,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSizes.xs),
        SizedBox(
          width: 48,
          child: Text(
            friend.firstName,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.friend,
    required this.invited,
    required this.disabled,
    this.onTap,
  });

  final JoinMatchFriend friend;
  final bool invited;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = invited
        ? AppColors.primary.withValues(alpha: 0.1)
        : disabled
            ? const Color(0xFFF9FAFB)
            : AppColors.card;
    final Color borderColor = invited
        ? AppColors.primary
        : disabled
            ? AppColors.border
            : AppColors.border;

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          side: BorderSide(color: borderColor, width: 2),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // صورة الصديق + حالة الاتصال
                Stack(
                  children: [
                    JoinMatchFriendAvatar(friend: friend, size: 48),
                    PositionedDirectional(
                      bottom: 0,
                      end: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: friend.status == PlayerStatus.online
                              ? _green500
                              : _gray400,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: AppSizes.md),
                // معلومات الصديق
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              friend.name,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.secondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (friend.status == PlayerStatus.online) ...[
                            SizedBox(width: AppSizes.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _green50,
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusFull),
                              ),
                              child: Text(
                                'متصل',
                                style: AppTextStyles.caption
                                    .copyWith(color: _green600),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          Text('مستوى ${friend.level}',
                              style: AppTextStyles.caption),
                          Text(' • ', style: AppTextStyles.caption),
                          Text('${friend.gamesPlayed} مباراة',
                              style: AppTextStyles.caption),
                          Text(' • ', style: AppTextStyles.caption),
                          const Icon(Icons.star,
                              size: 12, color: _yellow500),
                          Text('${friend.winRate}%',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                // زر الدعوة
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: invited ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: invited ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    invited ? Icons.check_circle : Icons.person_add_alt_1,
                    size: invited ? 18 : 14,
                    color: invited
                        ? AppColors.onPrimary
                        : AppColors.mutedForeground,
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

/// Gradient circular avatar showing the friend's initials.
class JoinMatchFriendAvatar extends StatelessWidget {
  const JoinMatchFriendAvatar({
    super.key,
    required this.friend,
    required this.size,
  });

  final JoinMatchFriend friend;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [friend.color, friend.color.withValues(alpha: 0.8)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        friend.initials,
        style: AppTextStyles.caption.copyWith(color: Colors.white),
      ),
    );
  }
}
