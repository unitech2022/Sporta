import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/tinted_card.dart';
import '../../domain/pulse_item.dart';
import '../../../../core/localization/tr_global.dart';

const _blue = Color(0xFF3B82F6);
const _orange = Color(0xFFF97316);
const _purple = Color(0xFFA855F7);
const _yellow = Color(0xFFEAB308);

/// Arabic "time ago" label for a pulse timestamp.
String pulseRelativeTime(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return trg('الآن');
  if (d.inMinutes < 60) return trgArgs('منذ {p0} دقيقة', {'p0': d.inMinutes});
  if (d.inHours < 24) return trgArgs('منذ {p0} ساعة', {'p0': d.inHours});
  return trgArgs('منذ {p0} يوم', {'p0': d.inDays});
}

/// The community-pulse list body: one [PulseTile] per item.
///
/// The section header lives with the caller so the dashboard keeps a single
/// title style across all of its sections.
class PulseSection extends StatelessWidget {
  const PulseSection({
    super.key,
    required this.items,
    required this.loading,
    this.onOpenMatch,
  });

  final List<PulseItem> items;
  final bool loading;
  final void Function(int matchId)? onOpenMatch;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SkeletonList(
          itemCount: 3, shrinkWrap: true, padding: EdgeInsets.zero);
    }

    if (items.isEmpty) {
      return TintedCard(
        tint: _blue,
        child: Text(
          context.tr('لا يوجد نشاط في المجتمع بعد'),
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.mutedForeground),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          PulseTile(item: items[i], onOpenMatch: onOpenMatch),
          if (i != items.length - 1) const SizedBox(height: AppSizes.md),
        ],
      ],
    );
  }
}

/// A single community-pulse row: accent icon, sentence, and either a timestamp
/// or (for an open match) the button that opens it.
class PulseTile extends StatelessWidget {
  const PulseTile({super.key, required this.item, this.onOpenMatch});

  final PulseItem item;
  final void Function(int matchId)? onOpenMatch;

  static (Color, IconData) _style(String type) => switch (type) {
        'level' => (_orange, Icons.local_fire_department_rounded),
        'points' => (_yellow, Icons.star_rounded),
        'match_seeking' => (_blue, Icons.bolt_rounded),
        'level_summary' => (_purple, Icons.trending_up_rounded),
        _ => (_blue, Icons.bolt_rounded),
      };

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _style(item.type);
    final matchId = item.matchId;
    final showButton = matchId != null && onOpenMatch != null;

    return TintedCard(
      tint: color,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: AppSizes.iconMd),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sentence(color),
                if (!showButton) ...[
                  const SizedBox(height: AppSizes.xs),
                  Text(pulseRelativeTime(item.createdAt),
                      style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
          if (showButton) ...[
            const SizedBox(width: AppSizes.sm),
            _grabButton(context, color, () => onOpenMatch!(matchId)),
          ],
        ],
      ),
    );
  }

  /// The sentence is composed in the app language by [PulseItem.localizedText];
  /// [PulseItem.localizedHighlight] marks the number inside it to emphasise.
  Widget _sentence(Color color) {
    final base = AppTextStyles.bodySmall.copyWith(color: AppColors.secondary);
    final text = item.localizedText;
    final highlight = item.localizedHighlight;

    final at = highlight == null || highlight.isEmpty
        ? -1
        : text.indexOf(highlight);
    if (at < 0) return Text(text, style: base);

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: text.substring(0, at)),
          TextSpan(
            text: highlight,
            style: base.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
          TextSpan(text: text.substring(at + highlight!.length)),
        ],
      ),
    );
  }

  Widget _grabButton(BuildContext context, Color color, VoidCallback onTap) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md, vertical: AppSizes.sm),
          child: Text(
            context.tr('اقتنص المباراة'),
            style: AppTextStyles.caption
                .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
