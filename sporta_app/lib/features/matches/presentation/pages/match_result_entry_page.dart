import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../data/match_repository.dart';
import '../../domain/entities/match_entity.dart';
import '../widgets/pending_result_banner.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/widgets/network_circle_avatar.dart';

/// إدخال نتيجة مباراة عادية + تقييم اللاعبين. أي لاعب يُدخلها فتبقى مقترحة
/// حتى يؤكدها لاعب من الفريق الآخر — وهنا أيضاً يؤكدها أو يرفضها.
class MatchResultEntryPage extends StatefulWidget {
  const MatchResultEntryPage({
    super.key,
    required this.match,
    required this.currentUserId,
    required this.onBack,
    required this.onCompleted,
  });

  final MatchEntity match;
  final int currentUserId;
  final VoidCallback onBack;
  final VoidCallback onCompleted;

  @override
  State<MatchResultEntryPage> createState() => _MatchResultEntryPageState();
}

class _MatchResultEntryPageState extends State<MatchResultEntryPage> {
  final _repo = getIt<MatchRepository>();
  final _t1 = TextEditingController();
  final _t2 = TextEditingController();

  /// userId -> stars (1..5).
  final Map<int, int> _ratings = {};

  /// لاعبو الفريق الأول (الباقون في الثاني) — الخادم يحتسب بهم نقاط المستوى.
  final Set<int> _team1 = {};

  bool _submitting = false;
  bool _responding = false;
  String? _error;

  List<MatchPlayerEntity> get _approved =>
      widget.match.players.where((p) => p.status == 'approved').toList();

  @override
  void initState() {
    super.initState();
    final pending = widget.match.pendingResult;
    _t1.text =
        (pending?.team1Score ?? widget.match.team1Score)?.toString() ?? '';
    _t2.text =
        (pending?.team2Score ?? widget.match.team2Score)?.toString() ?? '';
    final players = _approved;
    // التوزيع المحفوظ (من نتيجة سابقة أو مقترحة) يُعرض كما هو.
    if (players.isNotEmpty &&
        players.every((p) => p.team == 1 || p.team == 2)) {
      _team1.addAll(players.where((p) => p.team == 1).map((p) => p.userId));
      return;
    }
    // توزيع افتراضي: أنا مع النصف الأول في الفريق 1، والباقون في الفريق 2.
    final half = (players.length / 2).ceil();
    _team1.add(widget.currentUserId);
    for (final p in players) {
      if (_team1.length >= half) break;
      _team1.add(p.userId);
    }
  }

  void _toggleTeam(int userId) {
    setState(() {
      if (!_team1.remove(userId)) _team1.add(userId);
    });
  }

  @override
  void dispose() {
    _t1.dispose();
    _t2.dispose();
    super.dispose();
  }

  List<MatchPlayerEntity> get _others => widget.match.players
      .where((p) => p.userId != widget.currentUserId)
      .toList();

  List<({int ratedUserId, int score})> get _ratingInputs => [
    for (final e in _ratings.entries)
      if (e.value > 0) (ratedUserId: e.key, score: e.value),
  ];

  Future<void> _submit() async {
    if (_submitting) return;
    final messenger = ScaffoldMessenger.of(context);
    final s1 = int.tryParse(_t1.text.trim());
    final s2 = int.tryParse(_t2.text.trim());
    final players = _approved.map((p) => p.userId).toSet();
    final team1 = _team1.where(players.contains).toList();
    if (s1 == null || s2 == null) {
      setState(() => _error = context.tr('أدخل نتيجة الفريقين'));
      return;
    }
    // يلزم فريقان غير فارغين كي يُعرف «الفريق الآخر» الذي يؤكد النتيجة.
    if (team1.isEmpty || team1.length == players.length) {
      setState(() => _error = context.tr('حدّد لاعبي كل فريق'));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final updated = await _repo.submitResult(
        matchId: widget.match.id,
        team1Score: s1,
        team2Score: s2,
        team1PlayerIds: team1,
        ratings: _ratingInputs,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            updated.status == 'Completed'
                ? context.tr('اعتُمدت نتيجة المباراة')
                : context.tr(
                    'أُرسلت النتيجة — بانتظار تأكيد لاعب من الفريق الآخر',
                  ),
          ),
        ),
      );
      widget.onCompleted();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.display;
      });
    }
  }

  Future<void> _respond(bool accept) async {
    if (_responding) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _responding = true;
      _error = null;
    });
    try {
      await _repo.respondResult(
        matchId: widget.match.id,
        accept: accept,
        ratings: _ratingInputs,
        seen: widget.match.pendingResult,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? context.tr('اعتُمدت نتيجة المباراة')
                : context.tr('رُفضت النتيجة — يمكنكم إدخال النتيجة الصحيحة'),
          ),
        ),
      );
      widget.onCompleted();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _responding = false;
        _error = e.display;
      });
    }
  }

  /// أسماء لاعبي الفريق كما حُفظت مع النتيجة المقترحة.
  String _teamNames(int team) => widget.match.players
      .where((p) => p.status == 'approved' && p.team == team)
      .map((p) => p.userId == widget.currentUserId ? context.tr('أنت') : p.name)
      .join(trg(' و '));

  @override
  Widget build(BuildContext context) {
    final pending = widget.match.pendingResult;
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _header(),
            Expanded(
              child: ListView(
                padding: context.safeBottom(
                  const EdgeInsets.all(AppSizes.pagePadding),
                ),
                children: [
                  if (pending != null) ...[
                    PendingResultBanner(
                      pending: pending,
                      team1Label: _teamNames(1),
                      team2Label: _teamNames(2),
                      canRespond: widget.match.canConfirmResult,
                      busy: _responding,
                      onRespond: _respond,
                      currentUserId: widget.currentUserId,
                    ),
                    if (widget.match.canConfirmResult) ...[
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        context.tr(
                          'النتيجة غير صحيحة؟ عدّلها أدناه وأرسلها ليؤكدها الفريق الآخر',
                        ),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSizes.xl),
                  ],
                  _teamsCard(),
                  const SizedBox(height: AppSizes.xl),
                  _scoreCard(),
                  const SizedBox(height: AppSizes.xl),
                  Text(
                    context.tr('قيّم اللاعبين'),
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  for (final p in _others) ...[
                    _ratingTile(p),
                    const SizedBox(height: AppSizes.sm),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: AppSizes.lg),
                    Text(
                      _error!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.destructive,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSizes.xxl),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(context.tr('إرسال النتيجة للتأكيد')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.xxxl,
            AppSizes.pagePadding,
            AppSizes.xxl,
          ),
          child: Row(
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
              Text(
                context.tr('نتيجة المباراة'),
                style: AppTextStyles.heading2.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// توزيع اللاعبين على الفريقين: اضغط لاعباً لنقله للفريق الآخر.
  Widget _teamsCard() {
    final players = _approved;
    final team1 = players.where((p) => _team1.contains(p.userId)).toList();
    final team2 = players.where((p) => !_team1.contains(p.userId)).toList();

    Widget column(String title, List<MatchPlayerEntity> members, Color tint) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(AppSizes.sm),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: tint.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: tint,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              if (members.isEmpty)
                Text(
                  context.tr('لا أحد'),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
              for (final p in members)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.xs),
                  child: _playerChip(p, tint),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('الفرق'),
            style: AppTextStyles.body.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            context.tr(
              'اضغط على لاعب لنقله إلى الفريق الآخر — التوزيع يحدد نقاط المستوى',
            ),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              column(trg('الفريق 1'), team1, AppColors.primary),
              const SizedBox(width: AppSizes.sm),
              column(trg('الفريق 2'), team2, const Color(0xFFF97316)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _playerChip(MatchPlayerEntity p, Color tint) {
    final isMe = p.userId == widget.currentUserId;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: InkWell(
        onTap: () => _toggleTeam(p.userId),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: AppSizes.xs,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: tint,
                child: Text(
                  p.initials,
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
              ),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: Text(
                  isMe ? context.tr('أنت') : p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const Icon(
                Icons.swap_horiz_rounded,
                size: 14,
                color: AppColors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            context.tr('النتيجة النهائية'),
            style: AppTextStyles.body.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSizes.lg),
          Row(
            children: [
              Expanded(child: _scoreField(trg('الفريق 1'), _t1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: Text(
                  '-',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
              Expanded(child: _scoreField(trg('الفريق 2'), _t2)),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            context.tr('تُعتمد النتيجة بعد تأكيد لاعب من الفريق الآخر'),
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreField(String label, TextEditingController controller) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: AppSizes.sm),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTextStyles.heading2.copyWith(color: AppColors.secondary),
          decoration: const InputDecoration(hintText: '0'),
        ),
      ],
    );
  }

  Widget _ratingTile(MatchPlayerEntity player) {
    final stars = _ratings[player.userId] ?? 0;
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          NetworkCircleAvatar(
            imageUrl: player.avatarUrl,
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Text(
                    player.initials,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(
              player.name,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => setState(() => _ratings[player.userId] = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Icon(
                      i <= stars ? Icons.star : Icons.star_border,
                      color: AppColors.brandGold,
                      size: AppSizes.iconMd,
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
