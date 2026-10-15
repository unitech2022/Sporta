import '../../../memberships/presentation/widgets/member_share.dart';
import '../../../../core/widgets/add_to_calendar_button.dart';
import '../../../../core/widgets/level_avatar.dart';
import 'package:flutter/material.dart';
import '../../../reviews/domain/review_models.dart';
import '../../../reviews/presentation/widgets/review_prompt_card.dart';
import '../../../invites/domain/event_invite.dart';
import '../../../invites/presentation/invite_friends.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../friends/presentation/widgets/player_picker_sheet.dart';
import '../../../payment/presentation/widgets/payment_confirm_dialog.dart';
import '../../domain/entities/americano_entity.dart';
import '../cubit/americano_detail_cubit.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../auth/presentation/widgets/login_required_sheet.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../cup/presentation/pages/cup_detail_page.dart';
import '../../../matches/presentation/widgets/pending_result_banner.dart';
import '../../../matches/presentation/widgets/disputed_result_banner.dart';
import '../widgets/join_requests_card.dart';
import '../../../matches/presentation/widgets/withdrawal_widgets.dart';
import '../../../matches/presentation/widgets/waitlist_bar.dart';
import '../../../event_chat/presentation/widgets/event_chat_fab.dart';
import '../../data/americano_repository.dart';
import '../../../../core/widgets/section_tabs.dart';
import 'package:sporta_app/core/utils/server_time.dart';

/// Americano detail / execution: rounds with score entry and live standings.
class AmericanoDetailPage extends StatelessWidget {
  const AmericanoDetailPage({
    super.key,
    required this.americanoId,
    required this.onBack,
  });

  final int americanoId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AmericanoDetailCubit>(
      create: (_) => getIt<AmericanoDetailCubit>()..load(americanoId),
      child: _DetailView(onBack: onBack),
    );
  }
}

/// أقسام صفحة التفاصيل — كانت تُعرض كلها في قائمة واحدة طويلة، فمع 8 فرق
/// و28 جولة كان الوصول للترتيب يتطلب تمريراً طويلاً. التبويب يُبقي كل قسم
/// في متناول ضغطة واحدة.
enum _DetailTab { roster, rounds, standings }

class _DetailView extends StatefulWidget {
  const _DetailView({required this.onBack});

  final VoidCallback onBack;

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  _DetailTab _tab = _DetailTab.roster;

  VoidCallback get onBack => widget.onBack;

  Future<void> _submit(
    BuildContext context,
    int roundId,
    int t1,
    int t2,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<AmericanoDetailCubit>();
    final error = await cubit.submitScore(
      roundId: roundId,
      team1Score: t1,
      team2Score: t2,
    );
    if (!context.mounted) return;
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    // إدخال الفريق الآخر للنتيجة نفسها يعتمدها فوراً؛ وإلا تنتظر التأكيد.
    final round = cubit.state.americano?.rounds
        .where((r) => r.id == roundId)
        .firstOrNull;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          round?.pendingResult == null
              ? context.tr('اعتُمدت نتيجة الجولة')
              : context.tr(
                  'أُرسلت النتيجة — بانتظار تأكيد لاعب من الفريق الآخر',
                ),
        ),
      ),
    );
  }

  Future<void> _resolve(
    BuildContext context,
    int roundId,
    int t1,
    int t2,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<AmericanoDetailCubit>().resolveScore(
      roundId: roundId,
      team1Score: t1,
      team2Score: t2,
    );
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? context.tr('حُسمت النتيجة واعتُمدت'))),
    );
  }

  Future<void> _respond(BuildContext context, int roundId, bool accept) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<AmericanoDetailCubit>().respondScore(
      roundId: roundId,
      accept: accept,
    );
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error ??
              (accept
                  ? context.tr('اعتُمدت نتيجة الجولة')
                  : context.tr('رُفضت النتيجة — يمكنكم إدخال النتيجة الصحيحة')),
        ),
      ),
    );
  }

  /// Confirms the share debit before joining. A court-less americano is free,
  /// so it skips straight through.
  Future<bool> _confirmShare(
    BuildContext context,
    AmericanoEntity a,
    String title,
  ) async {
    if (a.pricePerPlayer <= 0) return true;
    final share = await eventShareQuote(
      americanoId: a.id,
      price: a.pricePerPlayer,
    );
    if (!context.mounted) return false;
    final confirmed = await showPaymentConfirmDialog(
      context,
      title: title,
      amount: share.amount,
      details: [
        PaymentDetail(
          context.tr('الملعب'),
          a.venueName ?? context.tr('بدون ملعب محدد'),
        ),
        PaymentDetail(context.tr('النوع'), a.typeLabel),
        ...memberShareDetails(context, share),
      ],
      confirmLabel: context.tr('تأكيد الانضمام'),
      autoCancelNote: true,
    );
    return confirmed == true;
  }

  Future<void> _join(BuildContext context, AmericanoEntity a) async {
    if (await guestBlocked(context)) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<AmericanoDetailCubit>();
    final joined = a.isTournament
        ? context.tr('تم انضمامك للبطولة')
        : context.tr('تم انضمامك للأمريكانو');

    if (!await _confirmShare(
      context,
      a,
      a.isTournament
          ? trg('تأكيد الانضمام للبطولة')
          : trg('تأكيد الانضمام للأمريكانو'),
    )) {
      return;
    }

    final error = await cubit.join(a.id);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? _joinOutcome(context, cubit, joined))),
    );
  }

  /// الانضمام طلب ينتظر موافقة المنظّم، إلا لمن دعاه المنظّم نفسه فيُقبل فوراً.
  String _joinOutcome(
    BuildContext context,
    AmericanoDetailCubit cubit,
    String joined,
  ) {
    final me = int.tryParse(getIt<AuthCubit>().user?.id ?? '') ?? 0;
    return cubit.state.americano?.hasPendingRequest(me) == true
        ? context.tr('أُرسل طلب انضمامك — بانتظار موافقة المنظّم')
        : joined;
  }

  Future<void> _respondJoinRequest(
    BuildContext context,
    AmericanoEntity a,
    AmericanoPlayer p,
    bool approve,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context
        .read<AmericanoDetailCubit>()
        .respondToJoinRequest(a.id, p.userId, approve);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error ??
              (approve
                  ? context.trArgs('قُبل {p0}', {'p0': p.name})
                  : context.trArgs('رُفض طلب {p0} وأُعيدت حصته', {
                      'p0': p.name,
                    })),
        ),
      ),
    );
  }

  WithdrawalEventKind _kindOf(AmericanoEntity a) => a.isTournament
      ? WithdrawalEventKind.tournament
      : WithdrawalEventKind.americano;

  /// انسحاب العضو (مباشر قبل 48 ساعة، وإلا طلب للمنظّم)، أو إلغاء طلب
  /// انضمام معلّق بلا خصم.
  Future<void> _withdraw(
    BuildContext context,
    AmericanoEntity a, {
    bool cancelRequest = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<AmericanoDetailCubit>();
    final kind = _kindOf(a);
    if (!cancelRequest) {
      final ok = await confirmWithdrawal(
        context,
        kind: kind,
        direct: a.canWithdrawDirectly,
        refund: a.pricePerPlayer,
      );
      if (!ok || !context.mounted) return;
    }
    final (outcome, error) = await cubit.withdraw(a.id);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error ?? withdrawalOutcomeMessage(context, outcome!, kind),
        ),
      ),
    );
  }

  Future<void> _respondWithdrawal(
    BuildContext context,
    AmericanoEntity a,
    WithdrawalRequestItem r,
    bool approve,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final done = approve
        ? context.trArgs('قُبل انسحاب {p0} وأُعيدت حصته', {'p0': r.name})
        : context.trArgs('رُفض طلب انسحاب {p0}', {'p0': r.name});
    final error = await context
        .read<AmericanoDetailCubit>()
        .respondToWithdrawal(a.id, r.userId, approve);
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(error ?? done)));
  }

  /// شريط أسفل الصفحة لمن هو فيها أصلاً: المشارك المعتمد يرى «أنت مشارك» مع
  /// زر الانسحاب، وصاحب الطلب المعلّق يرى حالته مع «إلغاء الطلب».
  Widget? _memberBar(
    BuildContext context,
    AmericanoEntity a,
    AmericanoDetailState state,
    int me,
  ) {
    if (me == 0 || me == a.creatorId || a.isClosed) return null;
    final mine = a.players.where((p) => p.userId == me).firstOrNull;
    if (mine == null || mine.isInvited) return null;
    if (mine.isPending) {
      return Row(
        children: [
          Expanded(
            child: Text(
              context.tr('طلبك بانتظار موافقة المنظّم'),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: state.responding
                ? null
                : () => _withdraw(context, a, cancelRequest: true),
            style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
            child: Text(context.tr('إلغاء الطلب')),
          ),
        ],
      );
    }
    return MemberWithdrawBar(
      memberLabel: a.isTournament
          ? context.tr('أنت مشارك في هذه البطولة')
          : context.tr('أنت مشارك في هذا الأمريكانو'),
      withdrawalRequested: a.hasWithdrawalRequest(me),
      direct: a.canWithdrawDirectly,
      busy: state.responding,
      onWithdraw: a.canWithdraw(me) ? () => _withdraw(context, a) : null,
    );
  }

  /// Teams: join a chosen team, optionally inviting a friend as partner.
  Future<void> _joinTeam(
    BuildContext context,
    AmericanoEntity a,
    int team,
  ) async {
    final cubit = context.read<AmericanoDetailCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final joined = context.trArgs('انضممت للفريق {n}', {'n': team});

    final picked = await showPlayerPicker(
      context,
      count: 1,
      minCount: 0,
      title: context.tr('ادعُ شريكك (اختياري)'),
    );
    if (!context.mounted) return;
    final partnerId = (picked != null && picked.isNotEmpty)
        ? picked.first.userId
        : null;

    // Confirm after the partner picker so the dialog is the last step before
    // the money actually moves.
    if (!await _confirmShare(context, a, trg('تأكيد الانضمام للفريق'))) return;

    final error = await cubit.join(a.id, team: team, partnerId: partnerId);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? _joinOutcome(context, cubit, joined))),
    );
  }

  /// The invited partner accepts or declines their team invitation.
  Future<void> _respondInvite(
    BuildContext context,
    AmericanoEntity a,
    bool accept,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<AmericanoDetailCubit>();
    final done = context.tr(
      accept ? trg('قبلت الدعوة وانضممت للفريق') : trg('تم رفض الدعوة'),
    );

    // Accepting is what triggers the share debit; declining costs nothing.
    if (accept && !await _confirmShare(context, a, trg('تأكيد قبول الدعوة')))
      return;

    final error = await cubit.respondToInvite(a.id, accept);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error ?? (accept ? _joinOutcome(context, cubit, done) : done),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // البطولة الإقصائية لها صفحتها (مجموعات/إقصائيات/نتائج)؛ كل من يفتح
    // «أمريكانو» بمعرّفها — إشعار أو قائمة — يصل إليها من هنا.
    final loaded = context.watch<AmericanoDetailCubit>().state.americano;
    if (loaded != null && loaded.isKnockoutTournament) {
      return CupDetailPage(cupId: loaded.id, onBack: onBack);
    }
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<AmericanoDetailCubit, AmericanoDetailState>(
          builder: (context, state) {
            final a = state.status == AmericanoDetailStatus.success
                ? state.americano
                : null;
            return Column(
              children: [
                _header(context, a),
                Expanded(
                  child: switch (state.status) {
                    AmericanoDetailStatus.initial ||
                    AmericanoDetailStatus.loading =>
                      // الملخص في الترويسة؛ المحتوى قائمة المشاركين.
                      const SkeletonList(
                        itemCount: 5,
                        padding: EdgeInsets.fromLTRB(
                          AppSizes.pagePadding,
                          AppSizes.md,
                          AppSizes.pagePadding,
                          AppSizes.pagePadding,
                        ),
                      ),
                    AmericanoDetailStatus.failure => _error(
                      context,
                      state.error,
                    ),
                    AmericanoDetailStatus.success => _body(context, state),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// الـ app bar يحمل كل ما هو ثابت: اسم اللقاء وحالته وتفاصيله والتبويبات —
  /// فلا تُهدر الشاشة على بطاقة منفصلة، ويبقى محتوى التبويب وحده يتحرك.
  Widget _header(BuildContext context, AmericanoEntity? a) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.md,
            AppSizes.pagePadding,
            AppSizes.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const DirectionalIcon(
                      rtl: Icons.arrow_forward,
                      ltr: Icons.arrow_back,
                      color: Colors.white,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Text(
                      a?.typeLabel ??
                          context.tr('americano.americano_detail_page.title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (a != null &&
                      !a.isFull &&
                      !a.isClosed &&
                      a.scheduledAt.isAfter(ksaNow()))
                    InviteFriendsHeaderButton(
                      onPressed: () => showEventInviteMenu(
                        context,
                        kind: a.isTournament
                            ? InviteKind.tournament
                            : InviteKind.americano,
                        targetId: a.id,
                        startsAt: a.scheduledAt,
                        maxCount: a.openSpots,
                        onInvitePartner: _americanoPartnerInviter(context, a),
                      ),
                    ),
                  if (a != null) ...[
                    const SizedBox(width: AppSizes.sm),
                    _statusChip(context, a),
                  ],
                ],
              ),
              if (a != null) ...[
                const SizedBox(height: AppSizes.xs),
                Text(
                  _detailsLine(context, a),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                SectionTabs<_DetailTab>(
                  active: _tab,
                  onChanged: (t) => setState(() => _tab = t),
                  tabs: [
                    SectionTabSpec(
                      tab: _DetailTab.roster,
                      icon: a.isTeams
                          ? Icons.groups_2_outlined
                          : Icons.people_outline,
                      label: a.isTeams
                          ? (a.teamCount > 2
                                ? context.tr('الفرق')
                                : context.tr('الفريقان'))
                          : context.tr('المشاركون'),
                      badge: '${a.approvedCount}/${a.maxPlayers}',
                    ),
                    SectionTabSpec(
                      tab: _DetailTab.rounds,
                      icon: Icons.sports_tennis_outlined,
                      label: context.tr(
                        'americano.americano_detail_page.rounds',
                      ),
                      badge: a.rounds.isEmpty
                          ? null
                          : '${a.rounds.where((r) => r.isCompleted).length}/${a.rounds.length}',
                    ),
                    SectionTabSpec(
                      tab: _DetailTab.standings,
                      icon: Icons.emoji_events_outlined,
                      label: context.tr(
                        'americano.americano_detail_page.standings',
                      ),
                      badge: a.isCompleted ? '✓' : null,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// إلغاء الحدث المستضاف: يوضّح ما سيُردّ قبل التنفيذ.
  Widget _cancelHostedAction(
    BuildContext context,
    AmericanoEntity a,
    bool busy,
  ) {
    final registered = a.approvedCount;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: busy ? null : () => _confirmCancelHosted(context, a),
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Icon(Icons.cancel_outlined),
        label: Text(
          registered > 0
              ? context.trArgs('إلغاء الحدث وردّ حصص {p0} لاعبين', {
                  'p0': registered,
                })
              : context.tr('إلغاء الحدث'),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.destructive,
          side: const BorderSide(color: AppColors.destructive),
          minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
        ),
      ),
    );
  }

  Future<void> _confirmCancelHosted(
    BuildContext context,
    AmericanoEntity a,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<AmericanoDetailCubit>();
    final registered = a.approvedCount;
    final refund = a.pricePerPlayer * registered;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('إلغاء الحدث')),
        content: Text(
          registered > 0
              ? dialogContext.trArgs(
                  'سيُلغى الحدث، وتُعاد {p0} ر.س إلى {p1} لاعبين مسجّلين وتُخصم من محفظتك.',
                  {'p0': refund.toStringAsFixed(2), 'p1': registered},
                )
              : dialogContext.tr('سيُلغى الحدث ولن يعود متاحاً للتسجيل.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.tr('تراجع')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
            child: Text(dialogContext.tr('إلغاء الحدث')),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final error = await cubit.cancelHosted(a.id, a.matchId);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? context.tr('أُلغي الحدث وأُعيدت الحصص'))),
    );
  }

  /// حالة اللقاء كشارة صغيرة — أيقونة بدل الإيموجي: خط التطبيق لا يحوي
  /// رموز الإيموجي فكان يظهر مربّعاً على جهاز بلا احتياطي.
  Widget _statusChip(BuildContext context, AmericanoEntity a) {
    final status = a.isCancelled
        ? (a.isTournament
              ? context.tr('أُلغيت البطولة')
              : context.tr('أُلغي الأمريكانو'))
        : !a.isFull
        ? context.tr('بانتظار اكتمال اللاعبين')
        : a.isCompleted
        ? context.tr('اكتملت كل الجولات')
        : context.trArgs('الجولات المكتملة: {done} / {total}', {
            'done': a.completedRounds,
            'total': a.totalRounds,
          });
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (a.isFull && a.isCompleted) ...[
            const Icon(
              Icons.emoji_events,
              size: 14,
              color: AppColors.brandGold,
            ),
            const SizedBox(width: AppSizes.xs),
          ],
          Text(
            status,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _detailsLine(BuildContext context, AmericanoEntity a) {
    final parts = [
      a.venueName ?? context.tr('بدون ملعب'),
      context.trArgs('{p0} / {p1} لاعبين', {
        'p0': a.approvedCount,
        'p1': a.maxPlayers,
      }),
      a.isMultiDay
          ? context.trArgs('{p0} دقيقة في كل يوم', {'p0': a.durationMinutes})
          : context.trArgs('{p0} دقيقة', {'p0': a.durationMinutes}),
      if (a.isMultiDay)
        context.trArgs('{from} إلى {to}', {
          'from':
              '${a.scheduledAt.year}-${a.scheduledAt.month}-${a.scheduledAt.day}',
          'to': '${a.endDate!.year}-${a.endDate!.month}-${a.endDate!.day}',
        }),
    ];
    return parts.join(' • ');
  }

  Widget _error(BuildContext context, String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.destructive,
              size: 48,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              error ?? context.tr('americano.americano_detail_page.loadError'),
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AmericanoDetailState state) {
    final a = state.americano!;
    final currentUserId = int.tryParse(getIt<AuthCubit>().user?.id ?? '') ?? 0;
    final isCreator = currentUserId != 0 && currentUserId == a.creatorId;
    final myInvite = a.pendingInviteFor(currentUserId);
    final rosterLabel = a.isTeams
        ? (a.teamCount > 2 ? context.tr('الفرق') : context.tr('الفريقان'))
        : context.tr('المشاركون');
    // زر الانضمام ثابت أسفل الصفحة لا يتحرك مع التمرير. في الفرق يبقى زر كل
    // فريق على بطاقته، ويضاف أسفل الصفحة زر «انضم» يضعه الخادم في أول فريق
    // ناقص — فلا يُضطر إلى التمرير بين الفرق ليجد مقعداً.
    final Widget? joinBar = (isCreator || a.hasPlayer(currentUserId))
        ? _memberBar(context, a, state, currentUserId)
        : a.isClosed
        ? _closedNotice(context, a)
        : a.isTeams
        ? _joinButton(context, a, state)
        // الفردي: مكتمل ← قائمة الانتظار بدل زر «مكتمل» المعطّل.
        : WaitlistBar(
            key: ValueKey(
              'waitlist-${a.id}-${a.approvedCount}-${a.players.length}-${a.matchStatus}',
            ),
            fetch: () => getIt<AmericanoRepository>().fetchWaitlist(a.id),
            join: () => getIt<AmericanoRepository>().joinWaitlist(a.id),
            leave: () => getIt<AmericanoRepository>().leaveWaitlist(a.id),
            onRequestJoin: () => _join(context, a),
            requesting: state.joining,
            fallback: _joinButton(context, a, state),
          );
    // الملخص والتبويبات في الـ app bar؛ هنا تبقى دعوة الشريك مثبّتة (إن
    // وُجدت) ثم محتوى التبويب وهو وحده ما يتحرك.
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.md,
            AppSizes.pagePadding,
            0,
          ),
          child: EventInviteBanner(
            key: ValueKey('invite-${a.players.length}'),
            kind: a.isTournament ? InviteKind.tournament : InviteKind.americano,
            targetId: a.id,
          ),
        ),
        if (myInvite != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.pagePadding,
              AppSizes.md,
              AppSizes.pagePadding,
              0,
            ),
            child: _InviteBanner(
              americano: a,
              team: myInvite.team,
              responding: state.responding,
              onAccept: () => _respondInvite(context, a, true),
              onReject: () => _respondInvite(context, a, false),
            ),
          ),
        Expanded(
          child: WithEventChatFab(
            matchId: a.matchId,
            membershipKey:
                '${a.approvedCount}-${a.players.length}-${a.matchStatus}',
            child: ListView(
              key: ValueKey(_tab),
              // مع شريط الانضمام الثابت يتكفّل الشريط بحشوة شريط النظام.
              padding: joinBar != null
                  ? const EdgeInsets.fromLTRB(
                      AppSizes.pagePadding,
                      AppSizes.md,
                      AppSizes.pagePadding,
                      AppSizes.pagePadding,
                    )
                  : context.safeBottom(
                      const EdgeInsets.fromLTRB(
                        AppSizes.pagePadding,
                        AppSizes.md,
                        AppSizes.pagePadding,
                        AppSizes.pagePadding,
                      ),
                    ),
              children: [
                if (a.canAddToCalendar(currentUserId)) ...[
                  AddToCalendarButton(
                    calendarKey: 'match-${a.matchId}',
                    title: context.trArgs('أمريكانو · {p0}', {'p0': a.name}),
                    startKsa: a.scheduledAt,
                    durationMinutes: a.durationMinutes,
                    location: [
                      a.venueName,
                      a.city,
                    ].whereType<String>().where((e) => e.isNotEmpty).join('، '),
                    description: context.tr('أمريكانو عبر سبورتا'),
                  ),
                  const SizedBox(height: AppSizes.lg),
                ],
                // «كيف كانت تجربتك؟» بعد انتهاء الأمريكانو — تقييم الملعب
                // وبقية اللاعبين، وتختفي ما لم يكن التقييم متاحاً.
                ReviewPromptCard(
                  key: ValueKey(
                    'review-${a.matchId}-${a.matchStatus}-${a.isCompleted}',
                  ),
                  reviewContext: ReviewContext.match,
                  contextId: a.matchId,
                  padding: const EdgeInsets.only(bottom: AppSizes.lg),
                ),
                // المضيف وحده يلغي حدثه — يظهر مع قائمة المسجّلين.
                if (_tab == _DetailTab.roster &&
                    isCreator &&
                    a.isVenueHosted &&
                    !a.isCompleted) ...[
                  _cancelHostedAction(context, a, state.responding),
                  const SizedBox(height: AppSizes.lg),
                ],
                // طلبات الانسحاب أولاً: وقتها ضيّق (أقل من 48 ساعة على الموعد).
                if (_tab == _DetailTab.roster &&
                    isCreator &&
                    a.withdrawalRequests.isNotEmpty) ...[
                  WithdrawalRequestsCard(
                    requests: [
                      for (final p in a.withdrawalRequests)
                        WithdrawalRequestItem(
                          userId: p.userId,
                          name: p.name,
                          subtitle: a.isTeams && p.team != null
                              ? context.trArgs('الفريق {n}', {'n': p.team!})
                              : null,
                        ),
                    ],
                    busy: state.responding,
                    onRespond: (r, approve) =>
                        _respondWithdrawal(context, a, r, approve),
                  ),
                  const SizedBox(height: AppSizes.lg),
                ],
                if (_tab == _DetailTab.roster &&
                    isCreator &&
                    a.joinRequests.isNotEmpty) ...[
                  JoinRequestsCard(
                    requests: a.joinRequests,
                    busy: state.responding,
                    teamLabel: a.isTeams
                        ? (team) => context.trArgs('الفريق {n}', {'n': team})
                        : null,
                    onRespond: (p, approve) =>
                        _respondJoinRequest(context, a, p, approve),
                  ),
                  const SizedBox(height: AppSizes.lg),
                ],
                if (_tab == _DetailTab.roster) ...[
                  Row(
                    children: [
                      Text(
                        rosterLabel,
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${a.approvedCount} / ${a.maxPlayers}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  if (a.isTeams)
                    _TeamsView(
                      americano: a,
                      currentUserId: currentUserId,
                      joining: state.joining,
                      onJoinTeam: (team) => _joinTeam(context, a, team),
                    )
                  else ...[
                    _ParticipantsCard(
                      players: a.players,
                      creatorId: a.creatorId,
                    ),
                    // مشارك أصلاً: لا زر انضمام — نوضّح السبب بدل تركه فارغاً.
                    if (a.hasPlayer(currentUserId))
                      Padding(
                        padding: const EdgeInsets.only(top: AppSizes.md),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: AppSizes.iconSm,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: AppSizes.xs),
                            Expanded(
                              child: Text(
                                a.hasPendingRequest(currentUserId)
                                    ? context.tr('طلبك بانتظار موافقة المنظّم')
                                    : a.isFull
                                    ? context.tr('أنت مشارك في هذا الأمريكانو')
                                    : context.tr(
                                        'أنت مشارك — بانتظار اكتمال بقية اللاعبين',
                                      ),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // ملغى أو منتهٍ: لا انضمام — نقول السبب بدل زر يرفضه الخادم.
                  ],
                ],
                if (_tab == _DetailTab.standings) ...[
                  if (a.isCompleted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.md),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            size: AppSizes.iconSm,
                            color: AppColors.brandGold,
                          ),
                          const SizedBox(width: AppSizes.xs),
                          Text(
                            context.tr('الترتيب النهائي'),
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  _StandingsCard(standings: a.standings),
                ],
                if (_tab == _DetailTab.rounds) ...[
                  if (a.rounds.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSizes.lg),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        context.tr(
                          'ستُنشأ الجولات تلقائياً عند اكتمال اللاعبين',
                        ),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    )
                  else
                    ...(() {
                      // الجولة الواحدة قد تضم عدة مباريات متوازية (مجموعات من 4 لاعبين)،
                      // فتُرقَّم المباريات داخلها حتى لا تتشابه عناوين البطاقات.
                      final gamesInRound = <int, int>{};
                      for (final r in a.rounds) {
                        gamesInRound[r.roundNumber] =
                            (gamesInRound[r.roundNumber] ?? 0) + 1;
                      }
                      final seen = <int, int>{};
                      return [
                        for (final r in a.rounds) ...[
                          _RoundCard(
                            round: r,
                            gameNumber: (gamesInRound[r.roundNumber] ?? 1) > 1
                                ? (seen[r.roundNumber] =
                                      (seen[r.roundNumber] ?? 0) + 1)
                                : null,
                            saving: state.savingRoundId == r.id,
                            // أي لاعب من لاعبي الجولة الأربعة يُدخل النتيجة ويؤكدها الفريق الآخر.
                            currentUserId: currentUserId,
                            canEdit: r.sideOf(currentUserId) != null,
                            onSubmit: (t1, t2) =>
                                _submit(context, r.id, t1, t2),
                            onRespond: (accept) =>
                                _respond(context, r.id, accept),
                            onResolve: isCreator
                                ? (t1, t2) => _resolve(context, r.id, t1, t2)
                                : null,
                          ),
                          const SizedBox(height: AppSizes.md),
                        ],
                      ];
                    })(),
                ],
              ],
            ),
          ),
        ),
        if (joinBar != null)
          Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            padding: context.safeBottom(
              const EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                AppSizes.md,
                AppSizes.pagePadding,
                AppSizes.md,
              ),
            ),
            child: joinBar,
          ),
      ],
    );
  }

  /// زر «انضم» أسفل الصفحة — معطّل ومكتوب عليه «مكتمل» حين يكتمل العدد.
  /// في الفردي ينضم مباشرة؛ في الفرق يضعه الخادم في أول فريق ناقص.
  Widget _joinButton(
    BuildContext context,
    AmericanoEntity a,
    AmericanoDetailState state,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (a.isFull || state.joining) ? null : () => _join(context, a),
        icon: state.joining
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Icon(a.isFull ? Icons.lock_outline : Icons.person_add_alt_1),
        label: Text(
          a.isFull
              ? context.tr('مكتمل')
              : a.isTournament
              ? context.tr('انضم للبطولة')
              : a.isTeams
              ? context.tr('انضم لأول فريق شاغر')
              : context.tr('انضم للأمريكانو'),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

// ── Standings ────────────────────────────────────────────────────────────────

class _StandingsCard extends StatelessWidget {
  const _StandingsCard({required this.standings});

  final List<AmericanoStanding> standings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < standings.length; i++) ...[
            if (i != 0) const Divider(height: 1),
            _row(context, standings[i]),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, AmericanoStanding s) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.md,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: s.rank == 1
                ? AppColors.brandGold
                : AppColors.muted,
            child: Text(
              '${s.rank}',
              style: AppTextStyles.caption.copyWith(
                color: s.rank == 1 ? Colors.white : AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(
              s.name,
              style: AppTextStyles.body.copyWith(color: AppColors.secondary),
            ),
          ),
          Text(
            context.trArgs('{p0} فوز', {'p0': s.wins}),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Text(
            context.trArgs('{p0} نقطة', {'p0': s.points}),
            style: AppTextStyles.body.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Round ────────────────────────────────────────────────────────────────────

class _RoundCard extends StatefulWidget {
  const _RoundCard({
    required this.round,
    required this.saving,
    required this.canEdit,
    required this.onSubmit,
    required this.onRespond,
    required this.currentUserId,
    this.onResolve,
    this.gameNumber,
  });

  final AmericanoRoundEntity round;

  /// ترتيب المباراة داخل جولتها حين تُلعب عدة مباريات معاً؛ null لجولة بمباراة واحدة.
  final int? gameNumber;
  final bool saving;

  /// لاعبو الجولة الأربعة فقط يُدخلون النتيجة.
  final bool canEdit;
  final void Function(int team1Score, int team2Score) onSubmit;
  final void Function(bool accept) onRespond;
  final int currentUserId;

  /// للمنظّم فقط: حسم خلاف على نتيجة الجولة.
  final void Function(int team1Score, int team2Score)? onResolve;

  @override
  State<_RoundCard> createState() => _RoundCardState();
}

class _RoundCardState extends State<_RoundCard> {
  late final TextEditingController _t1 = TextEditingController(
    text:
        (widget.round.pendingResult?.team1Score ?? widget.round.team1Score)
            ?.toString() ??
        '',
  );
  late final TextEditingController _t2 = TextEditingController(
    text:
        (widget.round.pendingResult?.team2Score ?? widget.round.team2Score)
            ?.toString() ??
        '',
  );

  @override
  void dispose() {
    _t1.dispose();
    _t2.dispose();
    super.dispose();
  }

  void _save() {
    final t1 = int.tryParse(_t1.text.trim());
    final t2 = int.tryParse(_t2.text.trim());
    if (t1 == null || t2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('americano.americano_detail_page.enterBothScores'),
          ),
        ),
      );
      return;
    }
    widget.onSubmit(t1, t2);
  }

  String _names(List<AmericanoPlayer> team) =>
      team.map((p) => p.name).join(trg(' و '));

  @override
  Widget build(BuildContext context) {
    final r = widget.round;
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: r.isCompleted
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${context.tr('americano.americano_detail_page.round')} '
                '${r.roundNumber}'
                '${widget.gameNumber == null ? '' : ' · ${context.tr('مباراة')} ${widget.gameNumber}'}',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (r.isCompleted)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: AppSizes.iconSm,
                ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          _teamRow(_names(r.team1), _t1, r.team1Score),
          const SizedBox(height: AppSizes.sm),
          Center(
            child: Text(
              context.tr('americano.americano_detail_page.versus'),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          _teamRow(_names(r.team2), _t2, r.team2Score),
          if (r.pendingResult == null && r.isDisputed) ...[
            const SizedBox(height: AppSizes.md),
            DisputedResultBanner(
              team1Label: _names(r.team1),
              team2Label: _names(r.team2),
              busy: widget.saving,
              onResolve: widget.onResolve,
            ),
          ],
          if (r.pendingResult != null) ...[
            const SizedBox(height: AppSizes.md),
            PendingResultBanner(
              pending: r.pendingResult!,
              team1Label: _names(r.team1),
              team2Label: _names(r.team2),
              canRespond: r.pendingResult!.canRespond(
                r.sideOf(widget.currentUserId),
              ),
              busy: widget.saving,
              onRespond: widget.onRespond,
              currentUserId: widget.currentUserId,
            ),
          ],
          if (widget.canEdit) ...[
            const SizedBox(height: AppSizes.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.saving ? null : _save,
                child: widget.saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        r.isCompleted || r.pendingResult != null
                            ? context.tr(
                                'americano.americano_detail_page.editScore',
                              )
                            : context.tr(
                                'americano.americano_detail_page.saveScore',
                              ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _teamRow(String names, TextEditingController controller, int? score) {
    return Row(
      children: [
        Expanded(
          child: Text(
            names,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        if (widget.canEdit)
          SizedBox(
            width: 64,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: '0'),
            ),
          )
        else
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Text(
              score?.toString() ?? '-',
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Pending partner invite banner ────────────────────────────────────────────

class _InviteBanner extends StatelessWidget {
  const _InviteBanner({
    required this.americano,
    required this.team,
    required this.responding,
    required this.onAccept,
    required this.onReject,
  });

  final AmericanoEntity americano;
  final int? team;
  final bool responding;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final a = americano;
    final where = a.venueName ?? context.tr('بدون ملعب محدد');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.primary, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.mail_outline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  context.trArgs('دعوة للانضمام إلى الفريق {p0}', {
                    'p0': team ?? '',
                  }),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            context.tr(
              context.trArgs(
                'دعاك صديقك للعب أمريكانو فرق في {p0}. راجع التفاصيل بالأسفل ثم اقبل أو ارفض.',
                {'p0': where},
              ),
            ),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: responding ? null : onAccept,
                  icon: responding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(context.tr('قبول')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: responding ? null : onReject,
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(context.tr('رفض')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.destructive,
                    side: const BorderSide(color: AppColors.destructive),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Teams view (fixed teams: two or more) ────────────────────────────────────

class _TeamsView extends StatelessWidget {
  const _TeamsView({
    required this.americano,
    required this.currentUserId,
    required this.joining,
    required this.onJoinTeam,
  });

  final AmericanoEntity americano;
  final int currentUserId;
  final bool joining;
  final void Function(int team) onJoinTeam;

  @override
  Widget build(BuildContext context) {
    final a = americano;
    final alreadyIn = a.players.any((p) => p.userId == currentUserId);
    return Column(
      children: [
        if (alreadyIn)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.md),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: AppSizes.iconSm,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSizes.xs),
                Expanded(
                  child: Text(
                    a.hasPendingRequest(currentUserId)
                        ? context.tr('طلبك بانتظار موافقة المنظّم')
                        : a.isFull
                        ? context.tr('أنت مشارك في هذا الأمريكانو')
                        : context.tr('أنت مشارك — بانتظار اكتمال بقية الفرق'),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        for (final team in a.teams) ...[
          _TeamCard(
            team: team,
            players: a.teamPlayers(team),
            creatorId: a.creatorId,
            // Can join a team that has room, when not already in the americano.
            canJoin:
                !alreadyIn && !a.isClosed && a.teamHasRoom(team) && !a.isFull,
            // فريق ممتلئ ولستَ مشاركاً: زر معطّل مكتوب عليه "مكتمل".
            showFull:
                !alreadyIn && !a.isClosed && (!a.teamHasRoom(team) || a.isFull),
            joining: joining,
            onJoin: () => onJoinTeam(team),
          ),
          if (team != a.teams.last) const SizedBox(height: AppSizes.md),
        ],
      ],
    );
  }
}

/// Every fixed team seats exactly two players (mirrors the API).
const int _playersPerTeam = 2;

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.team,
    required this.players,
    required this.creatorId,
    required this.canJoin,
    required this.showFull,
    required this.joining,
    required this.onJoin,
  });

  final int team;
  final List<AmericanoPlayer> players;
  final int creatorId;
  final bool canJoin;

  /// الفريق ممتلئ: يُعرض زر معطّل مكتوب عليه "مكتمل".
  final bool showFull;
  final bool joining;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    // Alternating accents so a long list of teams stays readable.
    final color = team.isOdd ? AppColors.primary : AppColors.brandGold;
    final slots = <Widget>[];
    for (var i = 0; i < _playersPerTeam; i++) {
      slots.add(
        i < players.length
            ? _playerRow(context, players[i], color)
            : _emptySlot(context),
      );
      if (i == 0) slots.add(const Divider(height: 1));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.lg,
              AppSizes.md,
              AppSizes.lg,
              AppSizes.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  context.trArgs('الفريق {n}', {'n': team}),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...slots,
          if (canJoin || showFull)
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (showFull || joining) ? null : onJoin,
                  icon: Icon(
                    showFull ? Icons.lock_outline : Icons.person_add_alt_1,
                    size: 18,
                  ),
                  label: Text(
                    context.tr(
                      showFull
                          ? context.tr('مكتمل')
                          : context.tr('انضم لهذا الفريق'),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _playerRow(BuildContext context, AmericanoPlayer p, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.md,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Text(
              p.name.isNotEmpty ? p.name.characters.first : context.tr('؟'),
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(
              p.name,
              style: AppTextStyles.body.copyWith(color: AppColors.secondary),
            ),
          ),
          if (p.userId == creatorId)
            _tag(context, context.tr('المنظّم'), AppColors.brandGold),
          if (p.isInvited)
            _tag(
              context,
              context.tr('بانتظار القبول'),
              AppColors.mutedForeground,
            ),
          if (p.isPending)
            _tag(
              context,
              context.tr('بانتظار موافقة المنظّم'),
              AppColors.warning,
            ),
        ],
      ),
    );
  }

  Widget _emptySlot(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.md,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.muted,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              size: 18,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Text(
            context.tr('مقعد شاغر'),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: color)),
    );
  }
}

// ── Participants ─────────────────────────────────────────────────────────────

class _ParticipantsCard extends StatelessWidget {
  const _ParticipantsCard({required this.players, required this.creatorId});

  final List<AmericanoPlayer> players;
  final int creatorId;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          context.tr('لا يوجد مشاركون'),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.mutedForeground,
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < players.length; i++) ...[
            if (i != 0) const Divider(height: 1),
            _row(context, players[i]),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, AmericanoPlayer p) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.md,
      ),
      child: Row(
        children: [
          LevelAvatar(
            name: p.name,
            imageUrl: p.avatarUrl,
            level: p.level,
            radius: 18,
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(
              p.name,
              style: AppTextStyles.body.copyWith(color: AppColors.secondary),
            ),
          ),
          if (p.userId == creatorId)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: 2,
              ),
              margin: const EdgeInsets.only(
                left: AppSizes.sm,
                right: AppSizes.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.brandGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Text(
                context.tr('المنظّم'),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.brandGold,
                ),
              ),
            ),
          if (p.isPending)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
              child: Text(
                context.tr('بانتظار موافقة المنظّم'),
                style: AppTextStyles.caption.copyWith(color: AppColors.warning),
              ),
            ),
          if (p.level != null)
            Text(
              PlayerLevelStyle.name(p.level!),
              style: AppTextStyles.caption.copyWith(
                color: PlayerLevelStyle.color(p.level!),
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

/// «دعوة زميل لفريقك» في أمريكانو الفرق: للعضو المعتمد الذي ما زال في فريقه
/// مقعد شاغر. null = الخيار لا ينطبق (فردي، أو ليس عضواً، أو فريقه مكتمل).
VoidCallback? _americanoPartnerInviter(
  BuildContext context,
  AmericanoEntity a,
) {
  if (!a.isTeams || a.isCompleted) return null;
  final me = int.tryParse(getIt<AuthCubit>().user?.id ?? '') ?? 0;
  final mine = a.players
      .where((p) => p.userId == me && p.isApproved)
      .firstOrNull;
  if (mine == null) return null;
  final teamSize = a.players.where((p) => p.team == mine.team).length;
  if (teamSize >= 2) return null;
  final cubit = context.read<AmericanoDetailCubit>();
  return () => invitePartnerFlow(
    context,
    invite: (userId) => cubit.invitePartner(a.id, userId),
  );
}

/// سطر «لا يمكن الانضمام» لحدث ملغى أو منتهٍ، مكان زر الانضمام.
Widget _closedNotice(BuildContext context, AmericanoEntity a) {
  final text = a.isCancelled
      ? (a.isTournament
            ? context.tr('أُلغيت البطولة — لا يمكن الانضمام إليها')
            : context.tr('أُلغي الأمريكانو — لا يمكن الانضمام إليه'))
      : context.tr('انتهى التسجيل — لا يمكن الانضمام');
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSizes.md),
    decoration: BoxDecoration(
      color: AppColors.destructive.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      border: Border.all(color: AppColors.destructive.withValues(alpha: 0.4)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.cancel_outlined,
          color: AppColors.destructive,
          size: AppSizes.iconMd,
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.destructive,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
