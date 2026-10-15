import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/tinted_card.dart';
import '../../../americano/domain/entities/americano_entity.dart';
import '../../../matches/presentation/widgets/matches_colors.dart';
import '../../../matches/presentation/widgets/matches_match_card.dart';
import '../../../matches/presentation/widgets/matches_pill.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/localization/tr_global.dart';

const _gold = Color(0xFFEAB308);


/// Playable padel tournaments (`/americano?kind=tournament`) — the same events
/// the "بطولات" tab lists, previewed on the player home page.
///
/// The section header lives with the caller so the dashboard keeps a single
/// title style across all of its sections.
class TournamentsSection extends StatelessWidget {
  const TournamentsSection({
    super.key,
    required this.tournaments,
    required this.loading,
    required this.onOpen,
  });

  final List<AmericanoEntity> tournaments;
  final bool loading;
  final void Function(int americanoId) onOpen;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SkeletonList(
          itemCount: 2,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          showAvatar: false);
    }

    if (tournaments.isEmpty) {
      return TintedCard(
        tint: _gold,
        child: Text(
          context.tr('لا توجد بطولات قادمة حالياً'),
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.mutedForeground),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < tournaments.length; i++) ...[
          _card(context, tournaments[i]),
          if (i != tournaments.length - 1) const SizedBox(height: AppSizes.md),
        ],
      ],
    );
  }

  /// Mirrors the card in `MatchesAmericanoTab` so a tournament looks the same
  /// wherever it appears.
  Widget _card(BuildContext context, AmericanoEntity a) {
    final open = !a.isFull;
    return MatchesMatchCard(
      onTap: () => onOpen(a.id),
      badges: [
        open
            ? MatchesPill(
                label: context.trArgs('مفتوحة · {p0} مقعد', {'p0': a.openSpots}),
                background: MatchesColors.green100,
                foreground: MatchesColors.green600,
              )
            : MatchesPill(
                label: context.tr('مكتملة'),
                background: AppColors.primary,
                foreground: AppColors.onPrimary,
              ),
        MatchesPill(
          label: a.typeLabel,
          background: MatchesColors.purple100,
          foreground: MatchesColors.purple600,
        ),
      ],
      level:
          trgArgs('مستوى: {p0} - {p1}', {'p0': a.minLevel.toStringAsFixed(0), 'p1': a.maxLevel.toStringAsFixed(0)}),
      venue: a.venueName ?? context.tr('بدون ملعب محدد'),
      venueDetail: a.city,
      body: Text(
        context.trArgs('{p0}/{p1} لاعبين • {p2} جولات', {'p0': a.approvedCount, 'p1': a.maxPlayers, 'p2': a.totalRounds}),
        style: AppTextStyles.caption,
      ),
      time: _formatSchedule(a),
      actionLabel: open ? context.tr('انضمام') : context.tr('عرض التفاصيل'),
      onAction: () => onOpen(a.id),
    );
  }

  String _formatWhen(DateTime d) {
    final period = AppDates.period(d);
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    return '${AppDates.weekday(d)} ${d.day} ${AppDates.monthName(d.month)}'
        ' · $h12:$minute $period';
  }

  /// Multi-day tournaments show a start→end range; one-day ones a date + time.
  /// المدة تُذكر دائماً: اللاعب يحتاج طول اللقاء قبل
  /// أن ينضم، وفي البطولة هي مدة كل يوم منها.
  String _formatSchedule(AmericanoEntity a) {
    final duration = trgArgs('{p0} دقيقة', {'p0': a.durationMinutes});
    if (!a.isMultiDay) return '${_formatWhen(a.scheduledAt)} · $duration';
    final s = a.scheduledAt;
    final e = a.endDate!;
    return '${s.day} ${AppDates.monthName(s.month)} - ${e.day} ${AppDates.monthName(e.month)}'
        ' · $duration';
  }
}
