import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../data/friend_repository.dart';
import '../../domain/entities/player_summary.dart';
import '../../../../core/widgets/network_circle_avatar.dart';

/// Opens a bottom sheet to pick players (friends first, with search across all
/// players). Selects up to [count]; confirm is enabled once at least [minCount]
/// are picked (defaults to exactly [count]). Returns the selected players, or
/// null if cancelled.
Future<List<PlayerSummary>?> showPlayerPicker(
  BuildContext context, {
  required int count,
  int? minCount,
  String title = 'اختر اللاعبين',
}) {
  return showModalBottomSheet<List<PlayerSummary>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _PlayerPickerSheet(count: count, minCount: minCount ?? count, title: title),
  );
}

class _PlayerPickerSheet extends StatefulWidget {
  const _PlayerPickerSheet({
    required this.count,
    required this.minCount,
    required this.title,
  });

  final int count;
  final int minCount;
  final String title;

  @override
  State<_PlayerPickerSheet> createState() => _PlayerPickerSheetState();
}

class _PlayerPickerSheetState extends State<_PlayerPickerSheet> {
  final _repo = getIt<FriendRepository>();
  final _selected = <int, PlayerSummary>{};

  List<PlayerSummary> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() => _loading = true);
    try {
      final friends = await _repo.fetchFriends();
      if (!mounted) return;
      setState(() {
        _results = friends;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      _loadFriends();
      return;
    }
    setState(() => _loading = true);
    try {
      final results = await _repo.searchPlayers(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _toggle(PlayerSummary p) {
    setState(() {
      if (_selected.containsKey(p.userId)) {
        _selected.remove(p.userId);
      } else if (_selected.length < widget.count) {
        _selected[p.userId] = p;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.xxxl)),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSizes.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.tr(widget.title),
                          style: AppTextStyles.heading3
                              .copyWith(color: AppColors.secondary)),
                      Text('${_selected.length}/${widget.count}',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  AppSearchField(
                    hint: context.tr('ابحث عن لاعب...'),
                    onChanged: _search,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const SkeletonList(
                      itemCount: 5,
                      padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.pagePadding))
                  : _results.isEmpty
                      ? Center(
                          child: Text(context.tr('لا توجد نتائج'),
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.mutedForeground)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.pagePadding),
                          itemCount: _results.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSizes.sm),
                          itemBuilder: (_, i) {
                            final p = _results[i];
                            final selected = _selected.containsKey(p.userId);
                            return _PickerTile(
                              player: p,
                              selected: selected,
                              onTap: () => _toggle(p),
                            );
                          },
                        ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _selected.length >= widget.minCount
                        ? () => Navigator.of(context)
                            .pop(_selected.values.toList())
                        : null,
                    child: Text(context.trArgs('تأكيد ({p0}/{p1})', {'p0': _selected.length, 'p1': widget.count})),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.player,
    required this.selected,
    required this.onTap,
  });

  final PlayerSummary player;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              NetworkCircleAvatar(
                imageUrl: player.avatarUrl,
                radius: 18,
                backgroundColor:
                    selected ? AppColors.primary : AppColors.muted,
                child: Text(player.initials,
                        style: TextStyle(
                            color:
                                selected ? Colors.white : AppColors.secondary,
                            fontSize: 12)),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player.name,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600)),
                    if (player.level != null)
                      Text(context.trArgs('مستوى {p0}', {'p0': player.level}),
                          style: AppTextStyles.caption),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
