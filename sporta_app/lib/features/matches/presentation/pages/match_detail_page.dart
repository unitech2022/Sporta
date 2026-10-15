import '../../../memberships/presentation/widgets/member_share.dart';
import '../../../../core/widgets/add_to_calendar_button.dart';
import 'package:flutter/material.dart';
import '../../../invites/domain/event_invite.dart';
import '../../../invites/presentation/invite_friends.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../payment/presentation/widgets/payment_confirm_dialog.dart';
import '../match_eligibility.dart';
import '../../data/match_repository.dart';
import '../../domain/entities/match_entity.dart';
import '../../../reviews/domain/review_models.dart';
import '../../../reviews/presentation/widgets/review_prompt_card.dart';
import '../widgets/pending_result_banner.dart';
import '../widgets/disputed_result_banner.dart';
import '../widgets/match_scoreboard.dart';
import '../widgets/match_people_sections.dart';
import '../widgets/withdrawal_widgets.dart';
import '../widgets/waitlist_bar.dart';
import '../../../event_chat/presentation/widgets/event_chat_fab.dart';
import '../../../../core/widgets/section_tabs.dart';
import 'match_result_entry_page.dart';
import '../../../../core/localization/app_dates.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../auth/presentation/widgets/login_required_sheet.dart';
import '../../../../core/utils/system_insets.dart';
import 'package:sporta_app/core/utils/server_time.dart';

/// أقسام صفحة المباراة أمام منشئها: التفاصيل / المشاركون / طلبات الانضمام.
/// غير المنشئ يرى التفاصيل والمشاركين في قائمة واحدة مع زر الانضمام أسفلها.
enum _MatchDetailTab { details, members, requests }

/// Full match details: info, approved members, and — for the creator —
/// pending join requests with approve / reject actions (split into tabs).
class MatchDetailPage extends StatefulWidget {
  const MatchDetailPage({super.key, required this.matchId});

  final int matchId;

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  final _repo = getIt<MatchRepository>();
  late final int _currentUserId =
      int.tryParse(getIt<AuthCubit>().user?.id ?? '') ?? 0;

  MatchEntity? _match;
  List<MatchPlayerEntity> _requests = [];
  bool _loading = true;
  bool _failed = false;
  int? _busyUserId; // request being approved/rejected

  bool _cancelling = false;
  bool _makingPublic = false;
  bool _respondingResult = false;
  bool _withdrawing = false;
  _MatchDetailTab _tab = _MatchDetailTab.details;

  bool get _isCreator => _match != null && _match!.creatorId == _currentUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final match = await _repo.fetchMatchById(widget.matchId);
      List<MatchPlayerEntity> requests = [];
      if (match.creatorId == _currentUserId) {
        try {
          requests = await _repo.fetchJoinRequests(widget.matchId);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _match = match;
        _requests = requests;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _respond(MatchPlayerEntity req, bool approve) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busyUserId = req.userId);
    try {
      final updated = await _repo.respondToJoinRequest(
        widget.matchId,
        req.userId,
        approve,
      );
      final requests = await _repo.fetchJoinRequests(widget.matchId);
      if (!mounted) return;
      setState(() {
        _match = updated;
        _requests = requests;
        _busyUserId = null;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            approve ? context.tr('تم قبول الطلب') : context.tr('تم رفض الطلب'),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busyUserId = null);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  Future<void> _respondToInvite(bool accept) async {
    if (await guestBlocked(context)) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    // القبول هو ما يخصم الحصة من المحفظة (الرفض مجاني)، فيُعرض المبلغ أولاً —
    // كانت الدعوة المقبولة تخصم بلا أن يرى اللاعب رقماً.
    final match = _match;
    if (accept && match != null && match.pricePerPlayer > 0) {
      final share = await eventShareQuote(
        matchId: match.id,
        price: match.pricePerPlayer.toDouble(),
      );
      if (!mounted) return;
      final confirmed = await showPaymentConfirmDialog(
        context,
        title: context.tr('تأكيد قبول الدعوة'),
        amount: share.amount,
        details: [
          PaymentDetail(
            context.tr('الملعب'),
            match.venueName ?? context.tr('بدون ملعب محدد'),
          ),
          PaymentDetail(context.tr('الموعد'), _formatWhen(match.scheduledAt)),
          ...memberShareDetails(context, share),
        ],
        confirmLabel: context.tr('قبول الدعوة'),
        autoCancelNote: true,
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _busyUserId = -2);
    try {
      final updated = await _repo.respondToInvite(widget.matchId, accept);
      if (!mounted) return;
      setState(() {
        _match = updated;
        _busyUserId = null;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            accept
                // دعوة من غير المنشئ: القبول طلب ينتظر موافقته لا انضمام.
                ? (updated.hasPendingRequest
                      ? context.tr('أُرسل طلب انضمامك — بانتظار موافقة المنشئ')
                      : context.tr('تم قبول الدعوة والانضمام للمباراة'))
                : context.tr('تم رفض الدعوة'),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busyUserId = null);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  Future<void> _requestJoin() async {
    if (await guestBlocked(context)) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final match = _match;
    if (match == null) return;

    // Check eligibility before the payment dialog — the server rejects an
    // out-of-range level anyway, and confirming a debit first would be cruel.
    final blocked = matchLevelBlockReason(
      match,
      getIt<AuthCubit>().user?.level,
    );
    if (blocked != null) {
      messenger.showSnackBar(SnackBar(content: Text(blocked)));
      return;
    }

    // The share is held when the request is sent (refunded if the creator
    // rejects it), so confirm the debit first.
    final share = await eventShareQuote(
      matchId: match.id,
      price: match.pricePerPlayer.toDouble(),
    );
    if (!mounted) return;
    final confirmed = await showPaymentConfirmDialog(
      context,
      title: context.tr('تأكيد الانضمام للمباراة'),
      amount: share.amount,
      details: [
        PaymentDetail(
          context.tr('الملعب'),
          match.venueName ?? context.tr('بدون ملعب محدد'),
        ),
        PaymentDetail(context.tr('الموعد'), _formatWhen(match.scheduledAt)),
        ...memberShareDetails(context, share),
      ],
      confirmLabel: context.tr('تأكيد الانضمام'),
      autoCancelNote: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyUserId = -1);
    try {
      final updated = await _repo.joinMatch(widget.matchId);
      if (!mounted) return;
      setState(() {
        _match = updated;
        _busyUserId = null;
      });
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('تم إرسال طلب الانضمام'))),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busyUserId = null);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  /// انسحاب العضو: مباشر قبل 24 ساعة، وإلا طلب للمنشئ — أو إلغاء طلب
  /// انضمام معلّق (بلا تأكيد خصم: لم يأخذ مقعداً بعد).
  Future<void> _withdraw(MatchEntity m, {bool cancelRequest = false}) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!cancelRequest) {
      final ok = await confirmWithdrawal(
        context,
        kind: WithdrawalEventKind.match,
        direct: m.canWithdrawDirectly,
        refund: m.pricePerPlayer,
      );
      if (!ok || !mounted) return;
    }
    setState(() => _withdrawing = true);
    try {
      final (outcome, updated) = await _repo.withdraw(widget.matchId);
      if (!mounted) return;
      setState(() {
        _match = updated;
        _withdrawing = false;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            withdrawalOutcomeMessage(
              context,
              outcome,
              WithdrawalEventKind.match,
            ),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _withdrawing = false);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  /// المنشئ يقبل طلب انسحاب متأخراً أو يرفضه.
  Future<void> _respondWithdrawal(WithdrawalRequestItem r, bool approve) async {
    final messenger = ScaffoldMessenger.of(context);
    final done = approve
        ? context.trArgs('قُبل انسحاب {p0} وأُعيدت حصته', {'p0': r.name})
        : context.trArgs('رُفض طلب انسحاب {p0}', {'p0': r.name});
    setState(() => _busyUserId = r.userId);
    try {
      final updated = await _repo.respondToWithdrawal(
        widget.matchId,
        r.userId,
        approve,
      );
      if (!mounted) return;
      setState(() {
        _match = updated;
        _busyUserId = null;
      });
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busyUserId = null);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  String _formatWhen(DateTime d) {
    final weekday = AppDates.weekday(d);
    final month = AppDates.monthName(d.month);
    final period = AppDates.period(d);
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    return '$weekday ${d.day} $month · $h12:$minute $period';
  }

  String _levelText(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _loading
            ? Column(
                children: [
                  _header(null),
                  const Expanded(child: SkeletonDetail(memberRows: 4)),
                ],
              )
            : _failed || _match == null
            ? _errorState()
            : _content(_match!),
      ),
    );
  }

  Widget _errorState() => SafeArea(
    child: Column(
      children: [
        Align(
          alignment: AlignmentDirectional.topStart,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const DirectionalIcon(
              rtl: Icons.arrow_forward,
              ltr: Icons.arrow_back,
            ),
          ),
        ),
        const Spacer(),
        Text(
          context.tr('تعذّر تحميل المباراة'),
          style: AppTextStyles.body.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSizes.md),
        OutlinedButton(
          onPressed: _load,
          child: Text(context.tr('إعادة المحاولة')),
        ),
        const Spacer(flex: 2),
      ],
    ),
  );

  /// لاعب من الفريق الآخر يؤكد النتيجة المقترحة أو يرفضها.
  Future<void> _respondResult(bool accept) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _respondingResult = true);
    try {
      final updated = await _repo.respondResult(
        matchId: widget.matchId,
        accept: accept,
        seen: _match?.pendingResult,
      );
      if (!mounted) return;
      setState(() {
        _match = updated;
        _respondingResult = false;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? context.tr('اعتُمدت نتيجة المباراة')
                : context.tr('رُفضت النتيجة — يمكنكم إدخال النتيجة الصحيحة'),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _respondingResult = false);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  /// المنظّم يحسم الخلاف بإدخال النتيجة نهائيةً.
  Future<void> _resolveResult(int t1, int t2) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _respondingResult = true);
    try {
      final updated = await _repo.resolveResult(
        matchId: widget.matchId,
        team1Score: t1,
        team2Score: t2,
      );
      if (!mounted) return;
      setState(() {
        _match = updated;
        _respondingResult = false;
      });
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('حُسمت النتيجة واعتُمدت'))),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _respondingResult = false);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  Future<void> _openResultEntry(MatchEntity m) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchResultEntryPage(
          match: m,
          currentUserId: _currentUserId,
          onBack: () => Navigator.of(context).pop(),
          onCompleted: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (mounted) _load();
  }

  String _teamNames(MatchEntity m, int team) => m.players
      .where((p) => p.status == 'approved' && p.team == team)
      .map((p) => p.userId == _currentUserId ? context.tr('أنت') : p.name)
      .join(trg(' و '));

  /// النتيجة: المقترحة بانتظار التأكيد، أو المعتمدة، وزر إدخالها للاعبين.
  List<Widget> _resultSection(MatchEntity m) {
    final pending = m.pendingResult;
    final canEnter =
        m.hasJoined &&
        m.isFull &&
        !const ['Cancelled', 'PendingApproval'].contains(m.status);
    if (pending == null &&
        !canEnter &&
        m.team1Score == null &&
        !m.isResultDisputed) {
      return const [];
    }
    return [
      const SizedBox(height: AppSizes.xl),
      if (pending != null)
        PendingResultBanner(
          pending: pending,
          team1Label: _teamNames(m, 1),
          team2Label: _teamNames(m, 2),
          canRespond: m.canConfirmResult,
          busy: _respondingResult,
          onRespond: _respondResult,
          currentUserId: _currentUserId,
        )
      else if (m.isResultDisputed)
        DisputedResultBanner(
          team1Label: _teamNames(m, 1),
          team2Label: _teamNames(m, 2),
          busy: _respondingResult,
          onResolve: m.canResolveResult ? _resolveResult : null,
        )
      else if (m.status == 'Completed' && m.team1Score != null)
        MatchScoreboard(match: m, currentUserId: _currentUserId),
      if (canEnter) ...[
        const SizedBox(height: AppSizes.sm),
        OutlinedButton.icon(
          onPressed: () => _openResultEntry(m),
          icon: const Icon(Icons.scoreboard_outlined, size: 18),
          label: Text(
            pending == null && m.team1Score == null
                ? context.tr('إدخال النتيجة')
                : context.tr('تعديل النتيجة'),
          ),
        ),
      ],
    ];
  }

  /// يُدعى إلى المباراة ما دامت مفتوحة وفيها مكان ولم يحن موعدها.
  bool _canInvite(MatchEntity m) =>
      !m.isFull &&
      m.scheduledAt.isAfter(ksaNow()) &&
      !const ['Cancelled', 'Completed', 'InProgress'].contains(m.status);

  Widget _content(MatchEntity m) {
    return Column(
      children: [
        _header(m),
        Expanded(
          child: WithEventChatFab(
            matchId: m.id,
            membershipKey: '${m.hasJoined}-${m.currentPlayers}-${m.status}',
            child: ListView(
              // يتغيّر المفتاح مع التبويب فتبدأ القائمة من أعلاها عند التبديل.
              key: ValueKey(_isCreator ? _tab : null),
              // مع شريط الانضمام الثابت يتكفّل الشريط بحشوة شريط النظام.
              padding: _isCreator
                  ? context.safeBottom(
                      const EdgeInsets.all(AppSizes.pagePadding),
                    )
                  : const EdgeInsets.all(AppSizes.pagePadding),
              children: _isCreator ? _creatorTabContent(m) : _playerContent(m),
            ),
          ),
        ),
        // زر الانضمام (أو حالته) ثابت أسفل الصفحة لا يتحرك مع التمرير.
        if (!_isCreator) _bottomBar(_joinAction(m)),
      ],
    );
  }

  Widget _calendarButton(MatchEntity m) => AddToCalendarButton(
    calendarKey: 'match-${m.id}',
    title: context.trArgs('مباراة · {p0}', {'p0': m.venueName ?? ''}),
    startKsa: m.scheduledAt,
    durationMinutes: m.durationMinutes,
    location: [
      m.venueName,
      m.city,
    ].whereType<String>().where((e) => e.isNotEmpty).join('، '),
    description: context.tr('مباراة عبر سبورتا'),
  );

  /// غير المنشئ: التفاصيل ثم المشاركون في قائمة واحدة.
  List<Widget> _playerContent(MatchEntity m) => [
    // مفتاحه عدد اللاعبين: بعد الانضمام يُعاد جلبها فتختفي كمقبولة.
    EventInviteBanner(
      key: ValueKey('invite-${m.currentPlayers}'),
      kind: InviteKind.match,
      targetId: m.id,
    ),
    _statsRow(m),
    ..._resultSection(m),
    if (m.canAddToCalendar) ...[
      const SizedBox(height: AppSizes.lg),
      _calendarButton(m),
    ],
    // «كيف كانت تجربتك؟» — تقييم الملعب وبقية اللاعبين بعد الانتهاء.
    ReviewPromptCard(
      key: ValueKey('review-${m.id}-${m.status}'),
      reviewContext: ReviewContext.match,
      contextId: m.id,
      padding: const EdgeInsets.only(top: AppSizes.xl),
    ),
    const SizedBox(height: AppSizes.xl),
    _infoSection(m),
    if (m.isPrivate) ...[
      const SizedBox(height: AppSizes.xl),
      _privateCard(m),
    ],
    const SizedBox(height: AppSizes.xl),
    MatchMembersSection(
      players: m.players,
      creatorId: m.creatorId,
      showPayment: m.pricePerPlayer > 0,
    ),
    MatchInvitedSection(
      invited: m.invitedPlayers,
      showPayment: m.pricePerPlayer > 0,
    ),
    const SizedBox(height: AppSizes.xxl),
  ];

  /// المنشئ: محتوى التبويب النشط وحده — التفاصيل (مع النتيجة وإلغاء الحدث
  /// المستضاف) أو المشاركون أو طلبات الانضمام.
  List<Widget> _creatorTabContent(MatchEntity m) => switch (_tab) {
    _MatchDetailTab.details => [
      _statsRow(m),
      ..._resultSection(m),
      if (m.canAddToCalendar) ...[
        const SizedBox(height: AppSizes.lg),
        _calendarButton(m),
      ],
      // «كيف كانت تجربتك؟» — تقييم الملعب وبقية اللاعبين بعد الانتهاء.
      ReviewPromptCard(
        key: ValueKey('review-${m.id}-${m.status}'),
        reviewContext: ReviewContext.match,
        contextId: m.id,
        padding: const EdgeInsets.only(top: AppSizes.xl),
      ),
      const SizedBox(height: AppSizes.xl),
      _infoSection(m),
      if (m.isPrivate) ...[
        const SizedBox(height: AppSizes.xl),
        _privateCard(m),
      ],
      // المضيف وحده يلغي حدثه، وما دام قابلاً للإلغاء.
      if (m.isVenueHosted &&
          m.status != 'Cancelled' &&
          m.status != 'Completed') ...[
        const SizedBox(height: AppSizes.xl),
        _cancelHostedAction(m),
      ],
      const SizedBox(height: AppSizes.xxl),
    ],
    _MatchDetailTab.members => [
      MatchMembersSection(
      players: m.players,
      creatorId: m.creatorId,
      showPayment: m.pricePerPlayer > 0,
    ),
      MatchInvitedSection(
      invited: m.invitedPlayers,
      showPayment: m.pricePerPlayer > 0,
    ),
      const SizedBox(height: AppSizes.xxl),
    ],
    _MatchDetailTab.requests => [
      // طلبات الانسحاب أولاً: وقتها ضيّق (أقل من 24 ساعة على الموعد).
      if (m.players.any((p) => p.withdrawalRequested)) ...[
        WithdrawalRequestsCard(
          requests: [
            for (final p in m.players.where((p) => p.withdrawalRequested))
              WithdrawalRequestItem(userId: p.userId, name: p.name),
          ],
          busy: _busyUserId != null,
          onRespond: _respondWithdrawal,
        ),
        const SizedBox(height: AppSizes.xl),
      ],
      MatchRequestsSection(
        requests: _requests,
        busyUserId: _busyUserId,
        onRespond: _respond,
      ),
      const SizedBox(height: AppSizes.xxl),
    ],
  };

  /// شريط التبويب في ترويسة المنشئ؛ عدّاد الطلبات على تبويبه كي يراها بلا فتح.
  Widget _creatorTabs(MatchEntity m) => SectionTabs<_MatchDetailTab>(
    active: _tab,
    onChanged: (t) => setState(() => _tab = t),
    tabs: [
      SectionTabSpec(
        tab: _MatchDetailTab.details,
        icon: Icons.info_outline,
        label: context.tr('التفاصيل'),
      ),
      SectionTabSpec(
        tab: _MatchDetailTab.members,
        icon: Icons.people_outline,
        label: context.tr('المشاركون'),
        badge: '${m.currentPlayers}/${m.maxPlayers}',
      ),
      SectionTabSpec(
        tab: _MatchDetailTab.requests,
        icon: Icons.person_add_alt_1_outlined,
        label: context.tr('الطلبات'),
        badge: _requests.length + m.withdrawalRequestCount == 0
            ? null
            : '${_requests.length + m.withdrawalRequestCount}',
      ),
    ],
  );

  Widget _bottomBar(Widget child) => Container(
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
    child: child,
  );

  /// مباراة خاصة: شارة توضيحية، وللمنشئ زر تحويلها إلى عامة.
  Widget _privateCard(MatchEntity m) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline, color: AppColors.primary),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  m.canMakePublic
                      ? context.tr(
                          'مباراة خاصة — لا يراها في البحث إلا من تدعوهم.',
                        )
                      : context.tr('مباراة خاصة — الانضمام بدعوة من المنظّم.'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (m.canMakePublic) ...[
            const SizedBox(height: AppSizes.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _makingPublic ? null : () => _confirmMakePublic(m),
                icon: _makingPublic
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(Icons.public),
                label: Text(context.tr('جعلها مباراة عامة')),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmMakePublic(MatchEntity m) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('جعلها مباراة عامة')),
        content: Text(
          dialogContext.tr(
            'ستظهر المباراة في البحث ويستطيع أي لاعب مناسب طلب الانضمام إليها. لا يمكن إعادتها خاصة.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.tr('تراجع')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.tr('جعلها عامة')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _makingPublic = true);
    try {
      final updated = await _repo.makeMatchPublic(widget.matchId);
      if (!mounted) return;
      setState(() {
        _match = updated;
        _makingPublic = false;
      });
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('أصبحت المباراة عامة'))),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _makingPublic = false);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  /// إلغاء حدث المضيف: يوضّح قبل التنفيذ أن الحصص تُردّ وتُخصم منه.
  Widget _cancelHostedAction(MatchEntity m) {
    final registered = m.players.where((p) => p.status == 'approved').length;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _cancelling ? null : () => _confirmCancelHosted(m),
        icon: _cancelling
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

  Future<void> _confirmCancelHosted(MatchEntity m) async {
    final messenger = ScaffoldMessenger.of(context);
    final registered = m.players.where((p) => p.status == 'approved').length;
    final refund = m.pricePerPlayer * registered;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('إلغاء الحدث')),
        content: Text(
          registered > 0
              ? dialogContext.trArgs(
                  'سيُلغى الحدث، وتُعاد {p0} ر.س إلى {p1} لاعبين مسجّلين وتُخصم من محفظتك.',
                  {'p0': money(refund), 'p1': registered},
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
    if (ok != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      final updated = await _repo.cancelHostedMatch(widget.matchId);
      if (!mounted) return;
      setState(() {
        _match = updated;
        _cancelling = false;
      });
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('أُلغي الحدث وأُعيدت الحصص'))),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  /// [m] = null أثناء التحميل: الترويسة وزر الرجوع ظاهران والتفاصيل هيكل.
  Widget _header(MatchEntity? m) {
    final full = m?.isFull ?? false;
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.md,
            AppSizes.pagePadding,
            _isCreator ? AppSizes.lg : AppSizes.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(AppSizes.sm),
                        child: DirectionalIcon(
                          rtl: Icons.arrow_forward,
                          ltr: Icons.arrow_back,
                          color: Colors.white,
                          size: AppSizes.iconMd,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Text(
                    context.tr('تفاصيل المباراة'),
                    style: AppTextStyles.heading2.copyWith(color: Colors.white),
                  ),
                  const Spacer(),
                  if (m != null && _canInvite(m))
                    InviteFriendsHeaderButton(
                      onPressed: () => inviteFriendsToEvent(
                        context,
                        kind: InviteKind.match,
                        targetId: m.id,
                        startsAt: m.scheduledAt,
                        maxCount: m.spotsLeft,
                      ),
                    ),
                  if (m != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusFull,
                        ),
                      ),
                      child: Text(
                        // حالة المباراة أولاً: الملغاة/المنتهية كانت تظهر
                        // «متاحة الآن» لأن الشارة تنظر للمقاعد وحدها.
                        switch (m.status) {
                          'Cancelled' => context.tr('ملغاة'),
                          'Completed' => context.tr('منتهية'),
                          'InProgress' => context.tr('جارية'),
                          'PendingApproval' => context.tr(
                            'بانتظار موافقة الملعب',
                          ),
                          _ =>
                            full
                                ? context.tr('مكتملة')
                                : context.tr('متاحة الآن'),
                        },
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              if (m == null) ...[
                _headerPlaceholder(160, 22),
                const SizedBox(height: AppSizes.sm),
                _headerPlaceholder(120, 14),
              ] else ...[
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        m.typeLabel,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.heading2.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    _visibilityBadge(m.isPrivate),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: AppSizes.iconSm,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: AppSizes.xs),
                    Expanded(
                      child: Text(
                        m.venueName ?? context.tr('بدون ملعب محدد'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
                // المنشئ: التفاصيل / المشاركون / الطلبات.
                if (_isCreator) ...[
                  const SizedBox(height: AppSizes.lg),
                  _creatorTabs(m),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// نوع المباراة: خاصة (بدعوة) أو عامة (تظهر في البحث).
  Widget _visibilityBadge(bool isPrivate) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 3),
    decoration: BoxDecoration(
      color: isPrivate
          ? AppColors.warning.withValues(alpha: 0.9)
          : Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPrivate ? Icons.lock_outline : Icons.public,
          size: 14,
          color: Colors.white,
        ),
        const SizedBox(width: 4),
        Text(
          isPrivate ? context.tr('خاصة') : context.tr('عامة'),
          style: AppTextStyles.caption.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _headerPlaceholder(double width, double height) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
    ),
  );

  Widget _statsRow(MatchEntity m) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            Icons.people_outline,
            AppColors.primary,
            '${m.currentPlayers}/${m.maxPlayers}',
            context.tr('اللاعبون'),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: _statCard(
            Icons.bar_chart,
            const Color(0xFF2563EB),
            '${_levelText(m.minLevel)}-${_levelText(m.maxLevel)}',
            context.tr('المستوى'),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: _statCard(
            Icons.payments_outlined,
            AppColors.success,
            trgArgs('{p0} ر.س', {'p0': money(m.pricePerPlayer)}),
            context.tr('لكل لاعب'),
          ),
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, Color color, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.lg,
        horizontal: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppSizes.iconMd),
          const SizedBox(height: AppSizes.sm),
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _infoSection(MatchEntity m) {
    final detail = [
      m.city,
      m.neighborhood,
    ].where((s) => s != null && s.isNotEmpty).join(' • ');
    final end = m.scheduledAt.add(Duration(minutes: m.durationMinutes));
    final rows = <Widget>[
      _infoRow(
        Icons.confirmation_number_outlined,
        context.tr('رقم المباراة'),
        '#${m.id}',
      ),
      _infoRow(Icons.sports_tennis, context.tr('النوع'), m.typeLabel),
      _infoRow(
        Icons.wc,
        context.tr('اللاعبون المنضمون'),
        context.tr(m.genderLabel),
      ),
      _infoRow(
        Icons.event_outlined,
        context.tr('التاريخ'),
        _formatDate(m.scheduledAt),
      ),
      _infoRow(
        Icons.access_time,
        context.tr('الوقت'),
        '${_time(m.scheduledAt)} — ${_time(end)}',
      ),
      _infoRow(
        Icons.timelapse,
        context.tr('المدة'),
        '${m.durationMinutes} ${context.tr('دقيقة')}',
      ),
      if (m.venueName != null && m.venueName!.isNotEmpty)
        _infoRow(Icons.stadium_outlined, context.tr('الملعب'), m.venueName!),
      if (detail.isNotEmpty)
        _infoRow(Icons.map_outlined, context.tr('الموقع'), detail),
      _infoRow(
        Icons.bar_chart,
        context.tr('المستوى'),
        '${_levelText(m.minLevel)} - ${_levelText(m.maxLevel)}',
      ),
      _infoRow(
        Icons.people_outline,
        context.tr('اللاعبون'),
        '${m.currentPlayers}/${m.maxPlayers}'
        '${m.spotsLeft > 0 ? ' (${m.spotsLeft} ${context.tr('مقاعد متاحة')})' : ''}',
      ),
      _infoRow(
        Icons.payments_outlined,
        context.tr('السعر للاعب'),
        '${money(m.pricePerPlayer)} ${context.tr('ر.س')}',
      ),
      _infoRow(
        Icons.info_outline,
        context.tr('الحالة'),
        _matchStatusLabel(m.status),
      ),
      if (m.notes != null && m.notes!.isNotEmpty)
        _infoRow(Icons.notes, context.tr('ملاحظات'), m.notes!),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: AppSizes.xl),
            rows[i],
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => _formatWhen(d).split(' · ').first;

  String _time(DateTime d) {
    final period = AppDates.periodShort(d);
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$h12:${d.minute.toString().padLeft(2, '0')} $period';
  }

  String _matchStatusLabel(String s) => switch (s) {
    'Open' => context.tr('مفتوحة'),
    'Full' => context.tr('مكتملة'),
    'InProgress' => context.tr('جارية'),
    'Completed' => context.tr('منتهية'),
    'Cancelled' => context.tr('ملغاة'),
    _ => s,
  };

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSizes.iconSm, color: AppColors.mutedForeground),
        const SizedBox(width: AppSizes.md),
        Text(label, style: AppTextStyles.caption),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _joinAction(MatchEntity m) {
    // ملغاة أو منتهية أو جارية: لا انضمام — نقول السبب بدل زر يرفضه الخادم.
    if (!m.hasJoined && m.status == 'Cancelled') {
      return _tag(
        context.tr('أُلغيت المباراة — لا يمكن الانضمام إليها'),
        AppColors.destructive,
        fullWidth: true,
      );
    }
    if (!m.hasJoined && const ['Completed', 'InProgress'].contains(m.status)) {
      return _tag(
        context.tr('انتهى التسجيل — لا يمكن الانضمام'),
        AppColors.mutedForeground,
        fullWidth: true,
      );
    }
    if (m.hasJoined) {
      return MemberWithdrawBar(
        memberLabel: context.tr('أنت عضو في هذه المباراة'),
        withdrawalRequested: m.withdrawalRequested,
        direct: m.canWithdrawDirectly,
        busy: _withdrawing,
        onWithdraw: m.canWithdraw(_currentUserId) ? () => _withdraw(m) : null,
      );
    }
    if (m.hasInvite) {
      return _inviteActions(m);
    }
    if (m.hasPendingRequest) {
      // الطلب المعلّق يُلغى بلا خصم نقاط ولا مهلة، وتُعاد الحصة المحجوزة.
      return Row(
        children: [
          Expanded(
            child: _tag(
              context.tr('بانتظار موافقة المنشئ'),
              AppColors.warning,
              fullWidth: true,
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          TextButton(
            onPressed: _withdrawing
                ? null
                : () => _withdraw(m, cancelRequest: true),
            style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
            child: Text(context.tr('إلغاء الطلب')),
          ),
        ],
      );
    }
    final disabled = m.isFull || _busyUserId == -1;
    // مكتملة أو مقعدها الشاغر محجوز: قائمة الانتظار بدل زر معطّل. المفتاح
    // يتغيّر مع العدد والحالة فيُعاد جلب حالة القائمة.
    return WaitlistBar(
      key: ValueKey('waitlist-${m.id}-${m.currentPlayers}-${m.status}'),
      fetch: () => _repo.fetchWaitlist(m.id),
      join: () => _repo.joinWaitlist(m.id),
      leave: () => _repo.leaveWaitlist(m.id),
      onRequestJoin: _requestJoin,
      requesting: _busyUserId == -1,
      fallback: _joinButton(m, disabled),
    );
  }

  /// زر «طلب الانضمام» العادي (ومعه تنبيه دفع المنشئ كاملاً إن وُجد).
  Widget _joinButton(MatchEntity m, bool disabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (m.creatorPaidFull && !m.isFull) ...[
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_outlined,
                  color: AppColors.success,
                  size: AppSizes.iconMd,
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    context.tr(
                      'دفع المنشئ سعر المباراة كاملاً — حصتك تُرد له عند انضمامك',
                    ),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),
        ],
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: disabled ? null : _requestJoin,
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(
              m.isFull ? context.tr('مكتملة') : context.tr('طلب الانضمام'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _inviteActions(MatchEntity m) {
    final busy = _busyUserId == -2;
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.mail_outline,
                color: AppColors.primary,
                size: AppSizes.iconMd,
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  context.tr('لديك دعوة للانضمام إلى هذه المباراة'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          if (busy)
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: m.isFull ? null : () => _respondToInvite(true),
                      icon: const Icon(Icons.check),
                      label: Text(
                        m.isFull ? context.tr('مكتملة') : context.tr('قبول'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusLg,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _respondToInvite(false),
                      icon: const Icon(Icons.close),
                      label: Text(context.tr('رفض')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.destructive,
                        side: const BorderSide(color: AppColors.destructive),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusLg,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
