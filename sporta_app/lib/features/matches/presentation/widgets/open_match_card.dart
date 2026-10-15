import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/state/app_scope.dart';
import '../../domain/entities/match_entity.dart';
import 'matches_colors.dart';
import 'matches_match_card.dart';
import 'matches_pill.dart';
import 'matches_player_avatar.dart';
import 'package:sporta_app/core/utils/server_time.dart';

/// بطاقة مباراة عادية — في قائمة المباريات المفتوحة وفي «مبارياتي». تختار
/// زرّها بحسب حال المستخدم فيها: طلب الانضمام، دعوة لاعب، إدخال/تأكيد
/// النتيجة… والمنتهية والملغاة تعرض حالتها وتفتح التفاصيل.
class OpenMatchCard extends StatelessWidget {
  const OpenMatchCard({
    super.key,
    required this.match,
    required this.onJoin,
    required this.onEnterResult,
    required this.onInvite,
    required this.onOpenDetails,
    this.isJoining = false,
    this.currentUserId = 0,
  });

  final MatchEntity match;

  /// المستخدم الحالي — منشئ المباراة (ولو لم يكن لاعباً فيها، كصاحب الملعب
  /// المستضيف) لا يُعرض له «طلب الانضمام» بل إدارة مباراته.
  final int currentUserId;
  final bool isJoining;
  final void Function(MatchEntity match) onJoin;
  final void Function(MatchEntity match) onEnterResult;
  final void Function(MatchEntity match) onInvite;
  final void Function(MatchEntity match) onOpenDetails;

  static String formatWhen(DateTime d) {
    final weekday = AppDates.weekday(d);
    final month = AppDates.monthName(d.month);
    final period = AppDates.period(d);
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    return '$weekday ${d.day} $month · $h12:$minute $period';
  }

  static String _levelText(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final m = match;
    final venueDetail = [
      m.city,
      m.neighborhood,
    ].where((s) => s != null && s.isNotEmpty).join(' • ');
    // مباراة على ملعب لا تُفتح للانضمام قبل موافقة صاحب الملعب؛ تظهر لمنشئها
    // وحده كي يعرف أنها قائمة وأن ماله لم يضِع في الطريق.
    final isPending = m.status == 'PendingApproval';
    final isCancelled = m.status == 'Cancelled';
    final isCompleted = m.status == 'Completed';
    final isInProgress = m.status == 'InProgress';
    final closed = isCancelled || isCompleted || isInProgress;

    final String actionLabel;
    VoidCallback? onAction;
    if (closed) {
      // منتهية أو ملغاة أو جارية: لا انضمام — الزر يفتح التفاصيل (والنتيجة).
      actionLabel = context.tr('عرض التفاصيل');
      onAction = () => onOpenDetails(m);
    } else if (isPending) {
      actionLabel = context.tr('بانتظار موافقة الملعب');
    } else if (!m.hasJoined &&
        currentUserId != 0 &&
        m.creatorId == currentUserId) {
      // المنشئ غير اللاعب (مضيف): يدير المباراة من تفاصيلها.
      actionLabel = context.tr('عرض التفاصيل');
      onAction = () => onOpenDetails(m);
    } else if (isJoining) {
      actionLabel = context.tr('جارٍ الإرسال...');
    } else if (m.hasPendingRequest) {
      // The user already requested to join — awaiting creator approval.
      actionLabel = context.tr('بانتظار الموافقة');
    } else if (m.isFull && m.hasJoined) {
      // Match is ready to play — a participant can record the result, and a
      // player from the other team confirms a result entered by the first.
      actionLabel = m.canConfirmResult
          ? context.tr('تأكيد النتيجة')
          : m.pendingResult != null
          ? context.tr('بانتظار تأكيد النتيجة')
          : context.tr('إدخال النتيجة');
      onAction = () => onEnterResult(m);
    } else if (m.hasJoined) {
      // A participant can invite friends to fill the remaining spots.
      actionLabel = context.tr('دعوة لاعب');
      onAction = () => onInvite(m);
    } else if (m.isFull && m.scheduledAt.isAfter(ksaNow())) {
      // مكتملة لم يحن موعدها: الانتظار على مقعد يفرغ — من صفحة التفاصيل.
      actionLabel = context.tr('قائمة الانتظار');
      onAction = () => onOpenDetails(m);
    } else if (m.isFull) {
      actionLabel = context.tr('مكتملة');
    } else {
      actionLabel = context.tr('طلب الانضمام');
      onAction = () => onJoin(m);
    }

    final MatchesPill statusPill;
    if (isCancelled) {
      statusPill = MatchesPill(
        label: context.tr('ملغاة'),
        background: AppColors.destructive.withValues(alpha: 0.12),
        foreground: AppColors.destructive,
      );
    } else if (isCompleted) {
      statusPill = MatchesPill(
        label: context.tr('منتهية'),
        background: AppColors.muted,
        foreground: AppColors.mutedForeground,
      );
    } else if (isInProgress) {
      statusPill = MatchesPill(
        label: context.tr('جارية'),
        background: MatchesColors.blue100,
        foreground: MatchesColors.blue600,
      );
    } else if (isPending) {
      statusPill = MatchesPill(
        label: context.tr('بانتظار موافقة الملعب'),
        background: MatchesColors.orange100,
        foreground: MatchesColors.orange600,
      );
    } else {
      statusPill = MatchesPill(
        label: m.isFull ? context.tr('مكتملة') : context.tr('متاحة الآن'),
        background: m.isFull ? MatchesColors.green100 : AppColors.primary,
        foreground: m.isFull ? MatchesColors.green600 : AppColors.onPrimary,
      );
    }

    return MatchesMatchCard(
      badges: [
        statusPill,
        MatchesPill(
          label: m.typeLabel,
          background: MatchesColors.blue100,
          foreground: MatchesColors.blue600,
        ),
        if (m.isPrivate)
          MatchesPill(
            label: context.tr('خاصة'),
            background: MatchesColors.orange100,
            foreground: MatchesColors.orange600,
          ),
        // نوع اللاعبين المنضمين: رجال / نساء.
        MatchesPill(
          label: context.tr(m.genderLabel),
          background: m.isWomen ? MatchesColors.pink100 : MatchesColors.teal100,
          foreground: m.isWomen ? MatchesColors.pink600 : MatchesColors.teal700,
        ),
      ],
      level: trgArgs('مستوى: {p0} - {p1}', {
        'p0': _levelText(m.minLevel),
        'p1': _levelText(m.maxLevel),
      }),
      levelTooltip: context.tr('مستوى اللاعبين المطلوب'),
      venue: m.venueName ?? context.tr('بدون ملعب محدد'),
      venueDetail: venueDetail.isEmpty ? null : venueDetail,
      body: _players(context, m),
      time: formatWhen(m.scheduledAt),
      actionLabel: actionLabel,
      onAction: onAction,
      onTap: () => onOpenDetails(m),
    );
  }

  Widget _players(BuildContext context, MatchEntity m) {
    return Row(
      children: [
        MatchesAvatarStack(
          children: [
            for (final p in m.players)
              MatchesPlayerAvatar(
                label: p.initials,
                imageUrl: p.avatarUrl,
                gradient: const [AppColors.primary, MatchesColors.primary80],
                borderColor: Colors.white,
                fontSize: 11,
              ),
            if (!m.isFull)
              const MatchesPlayerAvatar(icon: Icons.group, dashed: true),
          ],
        ),
        const SizedBox(width: AppSizes.md),
        Flexible(
          child: Text(
            // المنتهية والملغاة لا «تحتاج» أحداً — عدد اللاعبين فقط.
            m.status == 'Cancelled' || m.status == 'Completed'
                ? context.trArgs('اللاعبون {p0}/{p1}', {
                    'p0': m.currentPlayers,
                    'p1': m.maxPlayers,
                  })
                : m.isFull
                ? context.trArgs('مكتملة ({p0}/{p1})', {
                    'p0': m.currentPlayers,
                    'p1': m.maxPlayers,
                  })
                : context.trArgs('يحتاج {p0} لاعبين ({p1}/{p2})', {
                    'p0': m.spotsLeft,
                    'p1': m.currentPlayers,
                    'p2': m.maxPlayers,
                  }),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }
}
