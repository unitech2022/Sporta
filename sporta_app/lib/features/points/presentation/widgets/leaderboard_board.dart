import 'package:flutter/material.dart';
import 'package:sporta_app/core/state/app_scope.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../data/points_repository.dart';
import '../../domain/entities/points_entity.dart';
import '../../../../core/widgets/network_circle_avatar.dart';

const _gold = Color(0xFFEAB308);
const _silver = Color(0xFF9CA3AF);
const _bronze = Color(0xFFD97706);

/// لوحة المتصدرين: مفتاح النوع (مكافآت/مستوى) + فترة (الكل/يومي/أسبوعي/شهري)
/// + أعلى [limit] لاعباً، وصف المستخدم إن لم يكن ضمنهم. تحمّل بياناتها بنفسها
/// فتُستخدم في الرئيسية وفي صفحة «عرض الكل» على السواء.
class LeaderboardBoard extends StatefulWidget {
  const LeaderboardBoard({super.key, this.limit = 5, this.compact = true});

  final int limit;

  /// الرئيسية تعرض القائمة داخل بطاقة واحدة؛ الصفحة الكاملة بلا إطار.
  final bool compact;

  @override
  State<LeaderboardBoard> createState() => _LeaderboardBoardState();
}

class _LeaderboardBoardState extends State<LeaderboardBoard> {
  final _repo = getIt<PointsRepository>();

  String _kind = 'reward';
  String _period = 'all';
  LeaderboardEntity? _board;
  bool _loading = true;
  String? _error;
  int _request = 0;

  static const _periods = ['all', 'daily', 'weekly', 'monthly'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final board = await _repo.fetchLeaderboard(
          kind: _kind, period: _period, limit: widget.limit);
      if (!mounted || request != _request) return;
      setState(() {
        _board = board;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = e.display;
        _loading = false;
      });
    }
  }

  void _setKind(String kind) {
    if (_kind == kind) return;
    setState(() => _kind = kind);
    _load();
  }

  void _setPeriod(String period) {
    if (_period == period) return;
    setState(() => _period = period);
    _load();
  }

  String _periodLabel(BuildContext context, String p) => switch (p) {
        'daily' => context.tr('يومي'),
        'weekly' => context.tr('أسبوعي'),
        'monthly' => context.tr('شهري'),
        _ => context.tr('الكل'),
      };

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kindSwitch(context),
        const SizedBox(height: AppSizes.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final p in _periods) ...[
                _periodChip(context, p),
                const SizedBox(width: AppSizes.xs),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSizes.md),
        _list(context),
      ],
    );

    if (!widget.compact) return content;
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: content,
    );
  }

  Widget _kindSwitch(BuildContext context) {
    Widget option(String kind, IconData icon, String label) {
      final selected = _kind == kind;
      return Expanded(
        child: GestureDetector(
          onTap: () => _setKind(kind),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 16,
                    color: selected ? AppColors.primary : AppColors.mutedForeground),
                const SizedBox(width: AppSizes.xs),
                Text(label,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: selected ? AppColors.secondary : AppColors.mutedForeground,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.xs),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg + 2),
      ),
      child: Row(
        children: [
          option('reward', Icons.stars_rounded, context.tr('نقاط المكافآت')),
          option('level', Icons.trending_up_rounded, context.tr('نقاط المستوى')),
        ],
      ),
    );
  }

  Widget _periodChip(BuildContext context, String p) {
    final selected = _period == p;
    return GestureDetector(
      onTap: () => _setPeriod(p),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: AppSizes.xs),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(_periodLabel(context, p),
            style: AppTextStyles.caption.copyWith(
                color: selected ? Colors.white : AppColors.secondary)),
      ),
    );
  }

  Widget _list(BuildContext context) {
    if (_loading && _board == null) return _skeleton();
    if (_error != null && _board == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
        child: Center(
          child: Text(_error!,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.destructive)),
        ),
      );
    }
    final board = _board!;
    if (board.entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
        child: Center(
          child: Text(
            context.tr('لا يوجد متصدرون في هذه الفترة بعد'),
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.mutedForeground),
          ),
        ),
      );
    }
    final me = board.me;
    final showMe = me != null && !board.entries.any((e) => e.isMe);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: _loading ? 0.5 : 1,
      child: Column(
        children: [
          for (final e in board.entries) _row(context, e),
          if (showMe) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.xs),
              child: Divider(height: 1),
            ),
            _row(context, me),
          ],
        ],
      ),
    );
  }

  /// هيكل صفوف المتصدرين: ترتيب، صورة، اسم ومستوى، ثم النقاط.
  Widget _skeleton() {
    final rows = widget.limit.clamp(1, 5);
    return Shimmer(
      child: Column(
        children: [
          for (var i = 0; i < rows; i++)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm, vertical: AppSizes.sm + 2),
              child: Row(
                children: [
                  const SkeletonBox.circle(size: 22),
                  const SizedBox(width: AppSizes.md),
                  const SkeletonBox.circle(size: 36),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 12, width: i.isEven ? 120 : 95),
                        const SizedBox(height: AppSizes.xs),
                        const SkeletonBox(height: 10, width: 60),
                      ],
                    ),
                  ),
                  const SkeletonBox(width: 44, height: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, LeaderboardEntryEntity e) {
    final rankColor = switch (e.rank) {
      1 => _gold,
      2 => _silver,
      3 => _bronze,
      _ => AppColors.mutedForeground,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.xs),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm, vertical: AppSizes.sm),
      decoration: BoxDecoration(
        color: e.isMe
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: e.rank <= 3
                ? Icon(Icons.emoji_events_rounded, color: rankColor, size: 22)
                : Text('#${e.rank}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: rankColor, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: AppSizes.sm),
          NetworkCircleAvatar(
            imageUrl: e.avatarUrl,
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(e.initials,
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 11)),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.isMe ? context.tr('أنت') : e.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.secondary,
                        fontWeight: e.isMe ? FontWeight.w700 : FontWeight.w500)),
                if (e.level != null)
                  Text(context.trArgs('مستوى {p0}', {'p0': e.level}),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mutedForeground)),
              ],
            ),
          ),
          Text(
            e.points > 0 && _kind == 'level' ? '+${e.points}' : '${e.points}',
            style: AppTextStyles.heading3.copyWith(
                color: _kind == 'level' ? AppColors.primary : const Color(0xFFB45309)),
          ),
          const SizedBox(width: AppSizes.xs),
          Icon(_kind == 'level' ? Icons.trending_up_rounded : Icons.stars_rounded,
              size: 16,
              color: _kind == 'level' ? AppColors.primary : _gold),
        ],
      ),
    );
  }
}
