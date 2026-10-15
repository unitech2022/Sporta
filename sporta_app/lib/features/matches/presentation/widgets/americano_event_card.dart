import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/state/app_scope.dart';
import '../../../americano/domain/entities/americano_entity.dart';
import 'matches_colors.dart';
import 'matches_match_card.dart';
import 'matches_pill.dart';
import 'package:sporta_app/core/utils/server_time.dart';

/// بطاقة أمريكانو/بطولة — في تبويبَي الأمريكانو والبطولات وفي «ما يخصّني».
/// زر «انضمام» ينضم فعلاً من البطاقة (طلب ينتظر المنظّم)؛ المشارك والمنظّم
/// يفتحان التفاصيل؛ والمنتهي والملغى يعرضان حالتهما.
class AmericanoEventCard extends StatelessWidget {
  const AmericanoEventCard({
    super.key,
    required this.event,
    required this.currentUserId,
    required this.onOpen,
    required this.onJoin,
    this.isJoining = false,
  });

  final AmericanoEntity event;
  final int currentUserId;
  final bool isJoining;
  final void Function(AmericanoEntity event) onOpen;
  final void Function(AmericanoEntity event) onJoin;

  static String _formatWhen(DateTime d) {
    final weekday = AppDates.weekday(d);
    final month = AppDates.monthName(d.month);
    final period = AppDates.period(d);
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    return '$weekday ${d.day} $month · $h12:$minute $period';
  }

  /// Multi-day tournaments show a start→end date range; everything else the
  /// usual single date+time. المدة تُذكر دائماً: اللاعب يحتاج طول اللقاء قبل
  /// أن ينضم، وفي البطولة هي مدة كل يوم منها.
  static String formatSchedule(AmericanoEntity a) {
    final duration = trgArgs('{p0} دقيقة', {'p0': a.durationMinutes});
    if (!a.isMultiDay) return '${_formatWhen(a.scheduledAt)} · $duration';
    final s = a.scheduledAt;
    final e = a.endDate!;
    return '${s.day} ${AppDates.monthName(s.month)} - ${e.day} ${AppDates.monthName(e.month)}'
        ' · $duration';
  }

  @override
  Widget build(BuildContext context) {
    final a = event;
    final done = a.isCompleted || a.matchStatus == 'completed';
    final open = !a.isFull;
    // مشارك أصلاً (أو المنظّم): الزر يفتح التفاصيل، فلا يُعرض كدعوة للانضمام.
    final mine =
        currentUserId != 0 &&
        (a.creatorId == currentUserId || a.hasPlayer(currentUserId));
    final pendingVenue = a.matchStatus == 'pendingApproval';

    final MatchesPill statusPill;
    if (a.isCancelled) {
      statusPill = MatchesPill(
        label: context.tr('ملغاة'),
        background: AppColors.destructive.withValues(alpha: 0.12),
        foreground: AppColors.destructive,
      );
    } else if (done) {
      statusPill = MatchesPill(
        label: context.tr('مكتملة'),
        background: MatchesColors.green100,
        foreground: MatchesColors.green600,
      );
    } else if (pendingVenue) {
      statusPill = MatchesPill(
        label: context.tr('بانتظار موافقة الملعب'),
        background: MatchesColors.orange100,
        foreground: MatchesColors.orange600,
      );
    } else if (open) {
      statusPill = MatchesPill(
        label: context.trArgs('مفتوحة · {p0} مقعد', {'p0': a.openSpots}),
        background: MatchesColors.green100,
        foreground: MatchesColors.green600,
      );
    } else {
      statusPill = MatchesPill(
        label: context.trArgs('الجولات {p0}/{p1}', {
          'p0': a.completedRounds,
          'p1': a.totalRounds,
        }),
        background: AppColors.primary,
        foreground: AppColors.onPrimary,
      );
    }

    final String actionLabel;
    VoidCallback? onAction = () => onOpen(a);
    if (a.isCancelled) {
      actionLabel = context.tr('عرض التفاصيل');
    } else if (done) {
      actionLabel = context.tr('عرض النتائج');
    } else if (mine) {
      actionLabel = context.tr('عرض التفاصيل');
    } else if (pendingVenue || a.isClosed) {
      actionLabel = context.tr('عرض التفاصيل');
    } else if (isJoining) {
      actionLabel = context.tr('جارٍ الإرسال...');
      onAction = null;
    } else if (open) {
      actionLabel = context.tr('انضمام');
      onAction = () => onJoin(a);
    } else if (!a.isTeams &&
        !a.isKnockoutTournament &&
        a.scheduledAt.isAfter(ksaNow()) &&
        !a.rounds.any((r) => r.isCompleted || r.pendingResult != null)) {
      // الفردي المكتمل الذي لم يبدأ: قائمة الانتظار من صفحة التفاصيل.
      actionLabel = context.tr('قائمة الانتظار');
    } else {
      // مكتمل ولستَ مشاركاً: زر معطّل مكتوب عليه "مكتمل" بدل دعوة للانضمام.
      actionLabel = context.tr('مكتمل');
      onAction = null;
    }

    return MatchesMatchCard(
      onTap: () => onOpen(a),
      badges: [
        statusPill,
        MatchesPill(
          label: a.typeLabel,
          background: MatchesColors.purple100,
          foreground: MatchesColors.purple600,
        ),
      ],
      level: trgArgs('مستوى: {p0} - {p1}', {
        'p0': a.minLevel.toStringAsFixed(0),
        'p1': a.maxLevel.toStringAsFixed(0),
      }),
      venue: a.venueName ?? context.tr('بدون ملعب محدد'),
      venueDetail: a.city,
      body: Text(
        context.trArgs('{p0}/{p1} لاعبين • {p2} جولات', {
          'p0': a.approvedCount,
          'p1': a.maxPlayers,
          'p2': a.totalRounds,
        }),
        style: AppTextStyles.caption,
      ),
      time: formatSchedule(a),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
