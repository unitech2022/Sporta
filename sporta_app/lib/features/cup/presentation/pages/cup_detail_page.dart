import '../../../memberships/presentation/widgets/member_share.dart';
import '../../../../core/widgets/add_to_calendar_button.dart';
import 'package:flutter/material.dart';
import '../../../reviews/domain/review_models.dart';
import '../../../reviews/presentation/widgets/review_prompt_card.dart';
import '../../../invites/domain/event_invite.dart';
import '../../../invites/presentation/invite_friends.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/widgets/login_required_sheet.dart';
import '../../../friends/presentation/widgets/player_picker_sheet.dart';
import '../../../payment/presentation/widgets/payment_confirm_dialog.dart';
import '../../domain/entities/cup_entity.dart';
import '../cubit/cup_detail_cubit.dart';
import '../widgets/cup_bracket_tab.dart';
import '../widgets/cup_details_tab.dart';
import '../../../event_chat/presentation/widgets/event_chat_fab.dart';
import '../widgets/cup_groups_tab.dart';
import '../widgets/cup_join_card.dart';
import '../widgets/cup_organizer_actions.dart';
import '../widgets/cup_results_tab.dart';
import '../widgets/cup_section_tabs.dart';
import '../widgets/cup_teams_tab.dart';
import '../../../americano/presentation/widgets/join_requests_card.dart';
import '../../../matches/presentation/widgets/withdrawal_widgets.dart';
import '../../../americano/domain/entities/americano_entity.dart';
import 'package:sporta_app/core/utils/server_time.dart';

/// صفحة البطولة الإقصائية: الفرق / المجموعات / الإقصائيات / النتائج.
class CupDetailPage extends StatelessWidget {
  const CupDetailPage({super.key, required this.cupId, required this.onBack});

  final int cupId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CupDetailCubit>(
      create: (_) => getIt<CupDetailCubit>()..load(cupId),
      child: _View(onBack: onBack),
    );
  }
}

class _View extends StatefulWidget {
  const _View({required this.onBack});

  final VoidCallback onBack;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  CupTab _tab = CupTab.details;

  int get _me => int.tryParse(getIt<AuthCubit>().user?.id ?? '') ?? 0;

  void _snack(String? error, String ok) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? ok)));
  }

  Future<bool> _confirmShare(CupEntity c, String title) async {
    if (c.pricePerPlayer <= 0) return true;
    final share = await eventShareQuote(
      americanoId: c.id,
      price: c.pricePerPlayer,
    );
    if (!mounted) return false;
    final ok = await showPaymentConfirmDialog(
      context,
      title: title,
      amount: share.amount,
      details: [
        PaymentDetail(context.tr('البطولة'), c.name),
        PaymentDetail(context.tr('الملعب'), c.venueName ?? ''),
        ...memberShareDetails(context, share),
      ],
      confirmLabel: context.tr('تأكيد الانضمام'),
    );
    return ok == true;
  }

  /// الانضمام بزر واحد: الخادم يضع اللاعب تلقائياً في أول مقعد شاغر
  /// (وحده يُكمل فريقاً ناقصاً، ومع شريك يأخذان فريقاً فارغاً).
  Future<void> _join(CupEntity c, CupJoinMode mode) async {
    if (await guestBlocked(context)) return;
    if (!mounted) return;
    final cubit = context.read<CupDetailCubit>();
    int? partnerId;
    if (mode == CupJoinMode.withPartner) {
      final picked = await showPlayerPicker(
        context,
        count: 1,
        minCount: 1,
        title: context.tr('اختر شريكك'),
      );
      if (picked == null || picked.isEmpty || !mounted) return;
      partnerId = picked.first.userId;
    }
    if (!await _confirmShare(c, trg('تأكيد الانضمام للبطولة'))) return;
    final error = await cubit.joinTeam(null, partnerId: partnerId);
    if (!mounted) return;
    if (error == null) setState(() => _tab = CupTab.teams);
    _snack(error, _joinOutcome(cubit, _joinedText(cubit)));
  }

  /// «دعوة زميل لفريقك»: للعضو المعتمد الذي ما زال في فريقه مقعد شاغر،
  /// وإلا null فلا يظهر الخيار.
  VoidCallback? _partnerInviter(CupEntity c) {
    if (!c.hasPlayer(_me) || c.isDrawn) return null;
    final number = c.teamOf(_me);
    final team = c.teams.where((t) => t.number == number).firstOrNull;
    if (team == null || !team.hasRoom) return null;
    final cubit = context.read<CupDetailCubit>();
    return () => invitePartnerFlow(context, invite: cubit.invitePartner);
  }

  /// «انضممت للفريق X» باسم الفريق الذي وُضع فيه.
  String _joinedText(CupDetailCubit cubit) {
    final cup = cubit.state.tournament;
    final number = cup?.teamOf(_me);
    final team = cup?.teams.where((t) => t.number == number).firstOrNull;
    return team == null
        ? trg('انضممت للبطولة')
        : trgArgs('انضممت للفريق {n}', {'n': team.name});
  }

  Future<void> _respondInvite(CupEntity c, bool accept) async {
    final cubit = context.read<CupDetailCubit>();
    if (accept && !await _confirmShare(c, trg('تأكيد قبول الدعوة'))) return;
    final error = await cubit.respondToInvite(accept);
    _snack(
      error,
      accept
          ? _joinOutcome(cubit, trg('قبلت الدعوة وانضممت للفريق'))
          : trg('تم رفض الدعوة'),
    );
  }

  /// الانضمام طلب ينتظر موافقة المنظّم، إلا لمن دعاه المنظّم نفسه.
  String _joinOutcome(CupDetailCubit cubit, String joined) =>
      cubit.state.tournament?.hasPendingRequest(_me) == true
      ? trg('أُرسل طلب انضمامك — بانتظار موافقة المنظّم')
      : joined;

  Future<void> _renameTeam(CupTeam team) async {
    final cubit = context.read<CupDetailCubit>();
    final name = await showRenameTeamDialog(context, team);
    if (name == null || !mounted) return;
    // بلا تغيير فعلي لا نطلب شيئاً.
    if (name == (team.customName ?? '')) return;
    _snack(
      await cubit.renameTeam(team.number, name),
      name.isEmpty ? trg('عاد الفريق إلى حرفه') : trg('حُفظ اسم الفريق'),
    );
  }

  Future<void> _submitScore(int fixtureId, int a, int b) async {
    final cubit = context.read<CupDetailCubit>();
    final error = await cubit.submitScore(fixtureId, a, b);
    // إدخال الفريق الآخر للنتيجة نفسها يعتمدها فوراً؛ وإلا تنتظر التأكيد.
    final fixture = cubit.state.tournament?.fixtures
        .where((f) => f.id == fixtureId)
        .firstOrNull;
    _snack(
      error,
      fixture?.pendingResult == null
          ? trg('اعتُمدت نتيجة المباراة')
          : trg('أُرسلت النتيجة — بانتظار تأكيد لاعب من الفريق الآخر'),
    );
  }

  /// انسحاب العضو (مباشر قبل 48 ساعة، وإلا طلب للمنظّم)، أو إلغاء طلب
  /// انضمام معلّق بلا خصم.
  Future<void> _withdraw(CupEntity c, {bool cancelRequest = false}) async {
    if (!cancelRequest) {
      final ok = await confirmWithdrawal(
        context,
        kind: WithdrawalEventKind.tournament,
        direct: c.canWithdrawDirectly,
        refund: c.pricePerPlayer,
      );
      if (!ok || !mounted) return;
    }
    final (outcome, error) = await context.read<CupDetailCubit>().withdraw();
    if (!mounted) return;
    _snack(
      error,
      outcome == null
          ? ''
          : withdrawalOutcomeMessage(
              context,
              outcome,
              WithdrawalEventKind.tournament,
            ),
    );
  }

  Future<void> _respondWithdrawal(WithdrawalRequestItem r, bool approve) async {
    _snack(
      await context.read<CupDetailCubit>().respondToWithdrawal(
        r.userId,
        approve,
      ),
      approve
          ? trgArgs('قُبل انسحاب {p0} وأُعيدت حصته', {'p0': r.name})
          : trgArgs('رُفض طلب انسحاب {p0}', {'p0': r.name}),
    );
  }

  /// شريط العضو أسفل الصفحة: «أنت مشارك» مع الانسحاب، أو طلب معلّق يُلغى.
  /// null لمن ليس فيها، وللمنظّم، وبعد القرعة أو الإلغاء أو الانتهاء.
  Widget? _memberBar(CupEntity c, CupDetailState state) {
    if (_me == 0 || _me == c.creatorId) return null;
    if (c.isCancelled || c.isCompleted || c.isDrawn) return null;
    final mine = c.players.where((p) => p.userId == _me).firstOrNull;
    if (mine == null || mine.isInvited) return null;
    if (mine.isPending) {
      return Row(
        children: [
          Expanded(
            child: Text(
              context.tr('طلب انضمامك بانتظار موافقة المنظّم'),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: state.busy
                ? null
                : () => _withdraw(c, cancelRequest: true),
            style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
            child: Text(context.tr('إلغاء الطلب')),
          ),
        ],
      );
    }
    return MemberWithdrawBar(
      memberLabel: context.tr('أنت مشارك في هذه البطولة'),
      withdrawalRequested: c.hasWithdrawalRequest(_me),
      direct: c.canWithdrawDirectly,
      busy: state.busy,
      onWithdraw: c.canWithdraw(_me) ? () => _withdraw(c) : null,
    );
  }

  Future<void> _respondJoinRequest(AmericanoPlayer p, bool approve) async {
    _snack(
      await context.read<CupDetailCubit>().respondToJoinRequest(
        p.userId,
        approve,
      ),
      approve
          ? trgArgs('قُبل {p0}', {'p0': p.name})
          : trgArgs('رُفض طلب {p0} وأُعيدت حصته', {'p0': p.name}),
    );
  }

  Future<void> _resolveScore(int fixtureId, int a, int b) async {
    _snack(
      await context.read<CupDetailCubit>().resolveScore(fixtureId, a, b),
      trg('حُسمت النتيجة واعتُمدت'),
    );
  }

  /// المنظّم يسجّل نتيجة مباراة مرّ موعدها، أو فوزاً بالانسحاب (6-0).
  Future<void> _recordScore(int fixtureId, int a, int b, bool walkover) async {
    _snack(
      await context.read<CupDetailCubit>().recordScore(
        fixtureId,
        a,
        b,
        walkover: walkover,
      ),
      walkover ? trg('سُجّل الفوز بالانسحاب') : trg('اعتُمدت نتيجة المباراة'),
    );
  }

  Future<void> _respondScore(int fixtureId, bool accept) async {
    _snack(
      await context.read<CupDetailCubit>().respondScore(fixtureId, accept),
      accept
          ? trg('اعتُمدت نتيجة المباراة')
          : trg('رُفضت النتيجة — يمكنكم إدخال النتيجة الصحيحة'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<CupDetailCubit, CupDetailState>(
        builder: (context, state) {
          final c = state.status == CupDetailStatus.success
              ? state.tournament
              : null;
          final memberBar = c == null ? null : _memberBar(c, state);
          return Column(
            children: [
              _header(context, c, state),
              Expanded(
                child: WithEventChatFab(
                  matchId: c?.matchId,
                  membershipKey:
                      '${c?.players.length}-${c?.status}-${c?.hasPlayer(_me)}',
                  child: switch (state.status) {
                    // الملخص في الترويسة؛ المحتوى قائمة الفرق.
                    CupDetailStatus.initial ||
                    CupDetailStatus.loading => const SkeletonList(
                      itemCount: 5,
                      padding: EdgeInsets.fromLTRB(
                        AppSizes.pagePadding,
                        AppSizes.md,
                        AppSizes.pagePadding,
                        AppSizes.pagePadding,
                      ),
                    ),
                    CupDetailStatus.failure => Center(
                      child: Text(
                        state.error ?? context.tr('تعذّر تحميل البطولة'),
                      ),
                    ),
                    CupDetailStatus.success => _body(context, state),
                  },
                ),
              ),
              // أزرار الانضمام ثابتة أسفل الصفحة لا تتحرك مع التمرير.
              if (c != null &&
                  c.pendingInviteFor(_me) == null &&
                  CupJoinCard.actionsVisibleFor(c, _me))
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
                  child: CupJoinActions(
                    cup: c,
                    joining: state.joining,
                    onJoin: (mode) => _join(c, mode),
                  ),
                )
              else if (memberBar != null)
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
                  child: memberBar,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, CupEntity? c, CupDetailState state) {
    final isCreator = c != null && _me != 0 && c.creatorId == _me;
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        // شريط التبويب بعرض الشاشة كاملاً (يمتد تمريره إلى الحافة)، وبقية
        // الترويسة داخل حشوة الصفحة.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: widget.onBack,
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
                            c?.name ?? context.tr('البطولة'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.heading3.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (c != null &&
                            c.isOpen &&
                            !c.isDrawn &&
                            c.scheduledAt.isAfter(ksaNow()))
                          InviteFriendsHeaderButton(
                            onPressed: () => showEventInviteMenu(
                              context,
                              kind: InviteKind.tournament,
                              targetId: c.id,
                              startsAt: c.scheduledAt,
                              maxCount:
                                  c.teamCount * 2 -
                                  c.players.where((p) => p.isApproved).length,
                              onInvitePartner: _partnerInviter(c),
                            ),
                          ),
                        if (c != null) _statusChip(context, c),
                        if (isCreator && !c.isCompleted && !c.isCancelled)
                          CupOrganizerMenu(cup: c, busy: state.busy),
                      ],
                    ),
                    if (c != null) ...[
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        _meta(context, c),
                        maxLines: 2,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      if (c.isDrawn) ...[
                        const SizedBox(height: AppSizes.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusFull,
                          ),
                          child: LinearProgressIndicator(
                            value: c.totalMatches == 0
                                ? 0
                                : c.playedMatches / c.totalMatches,
                            minHeight: 6,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            color: AppColors.brandGold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.trArgs('تم لعب {p0} من {p1} مباراة', {
                            'p0': c.playedMatches,
                            'p1': c.totalMatches,
                          }),
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              if (c != null) ...[
                const SizedBox(height: AppSizes.md),
                CupSectionTabs(
                  active: _tab,
                  onChanged: (t) => setState(() => _tab = t),
                  tabs: [
                    CupTabSpec(
                      tab: CupTab.details,
                      icon: Icons.info_outline,
                      label: context.tr('التفاصيل'),
                    ),
                    CupTabSpec(
                      tab: CupTab.teams,
                      icon: Icons.groups_2_outlined,
                      label: context.tr('الفرق'),
                      badge: '${c.completeTeamCount}/${c.teamCount}',
                    ),
                    if (c.isGroupsFormat)
                      CupTabSpec(
                        tab: CupTab.groups,
                        icon: Icons.table_chart_outlined,
                        label: context.tr('المجموعات'),
                        badge: c.isDrawn ? '${c.groups.length}' : null,
                      ),
                    CupTabSpec(
                      tab: CupTab.bracket,
                      icon: Icons.account_tree_outlined,
                      label: context.tr('الإقصائيات'),
                      badge: c.isDrawn ? '${c.knockoutSize}' : null,
                    ),
                    CupTabSpec(
                      tab: CupTab.results,
                      icon: Icons.emoji_events_outlined,
                      label: context.tr('النتائج'),
                      badge: c.isCompleted ? '✓' : null,
                    ),
                    // طلبات الانضمام للمنظّم وحده، وعدّادها على التبويب.
                    if (isCreator)
                      CupTabSpec(
                        tab: CupTab.requests,
                        icon: Icons.person_add_alt_1_outlined,
                        label: context.tr('الطلبات'),
                        badge: _requestCount(c) == 0
                            ? null
                            : '${_requestCount(c)}',
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

  Widget _statusChip(BuildContext context, CupEntity c) {
    final label = switch (c.status) {
      'pendingApproval' => context.tr('بانتظار موافقة الملعب'),
      'open' => context.tr('التسجيل مفتوح'),
      'full' => context.tr('اكتمل العدد'),
      'inProgress' => context.tr('جارية'),
      'completed' => context.tr('انتهت'),
      _ => context.tr('ملغاة'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _meta(BuildContext context, CupEntity c) {
    final when = c.endDate == null
        ? '${AppDates.dayMonth(c.scheduledAt)} · ${AppDates.time12(c.scheduledAt)}'
        : '${AppDates.dayMonth(c.scheduledAt)} → ${AppDates.dayMonth(c.endDate!)}';
    return [
      c.formatLabel,
      context.trArgs('{p0} فرق', {'p0': c.teamCount}),
      if (c.venueName != null) c.venueName!,
      if (c.courts.length > 1)
        context.trArgs('{p0} ملاعب', {'p0': c.courts.length}),
      when,
    ].join(' · ');
  }

  Widget _body(BuildContext context, CupDetailState state) {
    final c = state.tournament!;
    final isCreator = _me != 0 && c.creatorId == _me;
    final invite = c.pendingInviteFor(_me);
    // فريقي في البطولة (عضو معتمد لا مدعوّ) — لاعبو طرفَي المباراة يُدخلون نتيجتها.
    final myTeam = c.players
        .where((p) => p.userId == _me && !p.isInvited)
        .firstOrNull
        ?.team;
    // التبويب المخفي (المجموعات في خروج المغلوب، أو الطلبات لغير المنظّم)
    // يُعاد إلى الفرق.
    final tab =
        (_tab == CupTab.groups && !c.isGroupsFormat) ||
            (_tab == CupTab.requests && !isCreator)
        ? CupTab.teams
        : _tab;
    return ListView(
      key: ValueKey(tab),
      padding: context.safeBottom(
        const EdgeInsets.fromLTRB(
          AppSizes.pagePadding,
          AppSizes.md,
          AppSizes.pagePadding,
          AppSizes.pagePadding,
        ),
      ),
      children: [
        EventInviteBanner(
          key: ValueKey('invite-${c.players.length}'),
          kind: InviteKind.tournament,
          targetId: c.id,
        ),
        if (invite != null) ...[
          CupInviteBanner(
            cup: c,
            team: invite.team,
            responding: state.busy,
            onAccept: () => _respondInvite(c, true),
            onReject: () => _respondInvite(c, false),
          ),
          const SizedBox(height: AppSizes.md),
        ],
        if (CupJoinCard.visibleFor(c, _me) && invite == null)
          CupJoinCard(cup: c, currentUserId: _me),
        if (tab == CupTab.teams && isCreator && !c.isDrawn && c.isOpen) ...[
          CupIncompleteBanner(cup: c, busy: state.busy),
          const SizedBox(height: AppSizes.md),
        ],
        if (tab == CupTab.details && c.canAddToCalendar(_me)) ...[
          AddToCalendarButton(
            calendarKey: 'match-${c.matchId}',
            title: context.trArgs('بطولة · {p0}', {'p0': c.name}),
            startKsa: c.scheduledAt,
            durationMinutes: c.calendarMinutes,
            location: [
              c.venueName,
              c.city,
            ].whereType<String>().where((e) => e.isNotEmpty).join('، '),
            description: context.tr('بطولة عبر سبورتا'),
          ),
          const SizedBox(height: AppSizes.md),
        ],
        // «كيف كانت تجربتك؟» بعد انتهاء البطولة — في تبويب التفاصيل فقط.
        if (tab == CupTab.details)
          ReviewPromptCard(
            key: ValueKey('review-${c.matchId}-${c.status}'),
            reviewContext: ReviewContext.match,
            contextId: c.matchId,
            padding: const EdgeInsets.only(bottom: AppSizes.md),
          ),
        switch (tab) {
          CupTab.details => CupDetailsTab(cup: c),
          CupTab.requests =>
            _requestCount(c) == 0
                ? _noRequests(context)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // طلبات الانسحاب أولاً: وقتها ضيّق (أقل من 48 ساعة على الموعد).
                      if (c.withdrawalRequests.isNotEmpty) ...[
                        WithdrawalRequestsCard(
                          requests: [
                            for (final p in c.withdrawalRequests)
                              WithdrawalRequestItem(
                                userId: p.userId,
                                name: p.name,
                                subtitle: p.team == null
                                    ? null
                                    : context.trArgs('الفريق {n}', {
                                        'n': p.team!,
                                      }),
                              ),
                          ],
                          busy: state.busy,
                          onRespond: _respondWithdrawal,
                        ),
                        const SizedBox(height: AppSizes.md),
                      ],
                      if (c.joinRequests.isNotEmpty)
                        JoinRequestsCard(
                          requests: c.joinRequests,
                          busy: state.busy,
                          teamLabel: (team) =>
                              context.trArgs('الفريق {n}', {'n': team}),
                          onRespond: _respondJoinRequest,
                        ),
                    ],
                  ),
          CupTab.teams => CupTeamsTab(
            cup: c,
            currentUserId: _me,
            onRename: _renameTeam,
          ),
          CupTab.groups => CupGroupsTab(
            cup: c,
            myTeam: myTeam,
            savingFixtureId: state.savingFixtureId,
            onSubmit: _submitScore,
            onRespond: _respondScore,
            onResolve: isCreator ? _resolveScore : null,
            onRecord: isCreator && !c.isCancelled ? _recordScore : null,
          ),
          CupTab.bracket => CupBracketTab(
            cup: c,
            myTeam: myTeam,
            savingFixtureId: state.savingFixtureId,
            onSubmit: _submitScore,
            onRespond: _respondScore,
            onResolve: isCreator ? _resolveScore : null,
            onRecord: isCreator && !c.isCancelled ? _recordScore : null,
          ),
          CupTab.results => CupResultsTab(cup: c),
        },
      ],
    );
  }

  /// طلبات الانضمام والانسحاب المعلّقة أمام المنظّم.
  int _requestCount(CupEntity c) =>
      c.joinRequests.length + c.withdrawalRequests.length;

  /// تبويب الطلبات بلا طلبات معلّقة.
  Widget _noRequests(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSizes.lg),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.inbox_outlined,
          color: AppColors.mutedForeground,
          size: 40,
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          context.tr('لا توجد طلبات انضمام'),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    ),
  );
}
