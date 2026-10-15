import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../americano/presentation/pages/americano_detail_page.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../../matches/data/match_repository.dart';
import '../../data/venue_repository.dart';
import '../../domain/entities/venue_match_request.dart';
import '../widgets/venue_event_kind_tabs.dart';
import '../widgets/venue_match_request_card.dart';
import '../widgets/venue_status_filter_bar.dart';
import 'match_request_detail_page.dart';

/// صفحة «المباريات» لصاحب الملعب: كل ما يُقام على ملاعبه — طلبات اللاعبين
/// وما استضافه بنفسه — في قائمة واحدة، مقسومة بتبويب النوع (مباريات /
/// أمريكانو / بطولات) ومصفّاة بالحالة. ما ينتظر قراره يتصدّر القائمة.
class ManageMatchRequestsPage extends StatefulWidget {
  const ManageMatchRequestsPage({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<ManageMatchRequestsPage> createState() =>
      _ManageMatchRequestsPageState();
}

class _ManageMatchRequestsPageState extends State<ManageMatchRequestsPage> {
  final _repo = getIt<VenueRepository>();
  final _scroll = ScrollController();

  final List<VenueMatchRequest> _items = [];
  VenueEventKind _kind = VenueEventKind.match;

  /// قيمة وسيط status (قد تحمل أكثر من حالة بفاصلة)؛ null = الكل.
  String? _status;
  int _page = 1;
  bool _hasMore = true;
  bool _loading = false;
  bool _initialLoading = true;
  int? _busyId;

  // «الكل» أولاً — يظهر في بداية الشريط (يمين الشاشة بالعربي).
  // «مقبولة» = Open + Full: ما وافق عليه الملعب سواء اكتمل عدده أم لا.
  late final List<(String, String?)> _filters = [
    (context.tr('الكل'), null),
    (context.tr('تنتظر قرارك'), 'PendingApproval'),
    (context.tr('مقبولة'), 'Open,Full'),
    (context.tr('ملغاة'), 'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_loading) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _items.clear();
        _initialLoading = true;
      }
    });
    try {
      final res = await _repo.fetchMatchRequests(
        page: _page,
        status: _status,
        kind: _kind.wire,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(res.items);
        _hasMore = res.hasMore;
        _page += 1;
        _loading = false;
        _initialLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _initialLoading = false;
      });
    }
  }

  void _selectKind(VenueEventKind kind) {
    if (_kind == kind) return;
    setState(() => _kind = kind);
    _load(reset: true);
  }

  void _selectFilter(String? value) {
    if (_status == value) return;
    setState(() => _status = value);
    _load(reset: true);
  }

  Future<void> _respond(VenueMatchRequest m, bool approve) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busyId = m.id);
    try {
      await _repo.respondToMatchRequest(m.id, approve);
      if (!mounted) return;
      setState(() => _busyId = null);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? context.tr('تم قبول المباراة')
                : context.tr('تم رفض المباراة'),
          ),
        ),
      );
      _load(reset: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busyId = null);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  /// إلغاء الحدث المستضاف: يوضّح ما سيُردّ قبل التنفيذ.
  Future<void> _confirmCancelHosted(VenueMatchRequest m) async {
    final messenger = ScaffoldMessenger.of(context);
    final refund = m.pricePerPlayer * m.registeredPlayers;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('إلغاء الحدث')),
        content: Text(
          m.registeredPlayers > 0
              ? dialogContext.trArgs(
                  'سيُلغى الحدث، وتُعاد {p0} ر.س إلى {p1} لاعبين مسجّلين وتُخصم من محفظتك.',
                  {'p0': money(refund), 'p1': m.registeredPlayers},
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

    setState(() => _busyId = m.id);
    try {
      await getIt<MatchRepository>().cancelHostedMatch(m.id);
      if (!mounted) return;
      setState(() => _busyId = null);
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('أُلغي الحدث وأُعيدت الحصص'))),
      );
      _load(reset: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busyId = null);
      messenger.showSnackBar(SnackBar(content: Text(e.display)));
    }
  }

  /// الأمريكانو والبطولة تُفتح صفحتهما الكاملة (الفرق/الجولات/النتائج)؛
  /// المباراة العادية تُفتح صفحة الطلب التي تُبلغ إن تغيّر شيء.
  Future<void> _openDetail(VenueMatchRequest m) async {
    if (m.americanoId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AmericanoDetailPage(
            americanoId: m.americanoId!,
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
      );
      if (mounted) _load(reset: true);
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MatchRequestDetailPage(requestId: m.id, initial: m),
      ),
    );
    if (changed == true && mounted) _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(context.tr('المباريات')),
        leading: widget.onBack != null
            ? IconButton(
                onPressed: widget.onBack,
                icon: const DirectionalIcon(
                  rtl: Icons.arrow_forward,
                  ltr: Icons.arrow_back,
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          VenueEventKindTabs(selected: _kind, onChanged: _selectKind),
          VenueStatusFilterBar(
            options: _filters,
            selected: _status,
            onSelected: _selectFilter,
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  String get _emptyLabel => switch (_kind) {
    VenueEventKind.match => context.tr('لا توجد مباريات على ملاعبك بعد'),
    VenueEventKind.americano => context.tr('لا توجد أمريكانو على ملاعبك بعد'),
    VenueEventKind.tournament => context.tr('لا توجد بطولات على ملاعبك بعد'),
  };

  Widget _body() {
    if (_initialLoading) {
      return const SkeletonList(showAvatar: false);
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
          child: Text(
            _emptyLabel,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        controller: _scroll,
        padding: context.safeBottom(const EdgeInsets.all(AppSizes.pagePadding)),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSizes.lg),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final m = _items[i];
          return VenueMatchRequestCard(
            request: m,
            busy: _busyId == m.id,
            onTap: () => _openDetail(m),
            onApprove: () => _respond(m, true),
            onReject: () => _respond(m, false),
            onCancelHosted: () => _confirmCancelHosted(m),
          );
        },
      ),
    );
  }
}
