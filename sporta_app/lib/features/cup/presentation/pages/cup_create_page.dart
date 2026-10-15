import 'package:flutter/material.dart';
import 'cup_detail_page.dart';
import '../../../memberships/presentation/widgets/member_share.dart';
import '../../../../core/widgets/success_dialog.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/widgets/directional_icon.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../../courts/data/court_repository.dart';
import '../../../courts/domain/entities/court_entity.dart';
import '../../../friends/domain/entities/player_summary.dart';
import '../../../friends/presentation/widgets/player_picker_sheet.dart';
import '../../../invites/data/event_invite_repository.dart';
import '../../../invites/domain/event_invite.dart';
import '../../../matches/presentation/widgets/create_match_invite_section.dart';
import '../../../payment/presentation/widgets/payment_confirm_dialog.dart';
import '../../data/cup_repository.dart';
import '../../domain/entities/cup_entity.dart';
import '../widgets/cup_create_fields.dart';
import '../widgets/cup_summary_card.dart';
import 'package:sporta_app/core/utils/server_time.dart';

/// إنشاء بطولة إقصائية (نظام كأس العالم): الإعداد كله هنا، والتطبيق يشكّل
/// الفرق والقرعة والمجموعات والمباريات لاحقاً. مع [hostedByVenue] يستضيف
/// صاحب الملعب بلا لعب ولا دفع.
class CupCreatePage extends StatefulWidget {
  const CupCreatePage({
    super.key,
    required this.onBack,
    required this.onCreated,
    this.hostedByVenue = false,
  });

  final VoidCallback onBack;
  final void Function(int cupId) onCreated;
  final bool hostedByVenue;

  @override
  State<CupCreatePage> createState() => _CupCreatePageState();
}

class _CupCreatePageState extends State<CupCreatePage> {
  final _courtRepo = getIt<CourtRepository>();
  final _cupRepo = getIt<CupRepository>();

  final _name = TextEditingController();
  String _format = 'groups';
  int _teamCount = 8;
  List<CourtEntity> _courts = [];
  bool _loadingCourts = true;
  String? _venue;
  final Set<int> _courtIds = {};
  DateTime? _date;
  DateTime? _endDate;
  TimeOfDay _time = const TimeOfDay(hour: 16, minute: 0);
  int _window = 240;

  /// مدة المباراة الواحدة ثابتة (ساعة) — لم تعد خياراً في الشاشة.
  static const int _matchMinutes = 60;
  int _minLevel = 1;
  int _maxLevel = 7;
  PlayerSummary? _partner;
  List<int> _invitedIds = const [];
  int _inviteHours = 24;

  CupQuote? _quote;
  bool _quoting = false;
  int _quoteRequest = 0;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCourts();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _loadCourts() async {
    try {
      final courts = widget.hostedByVenue
          ? await _courtRepo.fetchMyCourts()
          : (await _courtRepo.fetchCourts(pageSize: 100)).items;
      if (!mounted) return;
      setState(() {
        _courts = courts;
        _loadingCourts = false;
        if (courts.isNotEmpty) _venue = courts.first.venueName;
        if (widget.hostedByVenue) {
          _courtIds.addAll(courts.map((c) => c.numericId));
        } else {
          _selectFirstCourt();
        }
      });
      _refreshQuote();
    } catch (_) {
      if (mounted) setState(() => _loadingCourts = false);
    }
  }

  /// اختيار المنشأة يحدّد أول ملعب فيها، فلا يبقى زر الإنشاء معطّلاً حتى
  /// يضغط المستخدم الملعب مرة أخرى؛ ويضيف غيره أو يبدّله بالضغط.
  void _selectFirstCourt() {
    final first = _venueCourts.firstOrNull;
    if (first != null) _courtIds.add(first.numericId);
  }

  List<String> get _venues => _courts.map((c) => c.venueName).toSet().toList();
  List<CourtEntity> get _venueCourts =>
      _courts.where((c) => c.venueName == _venue).toList();

  /// أيام البطولة (يوم البداية حتى يوم النهاية شاملاً).
  int get _days {
    final start = _date, end = _endDate;
    if (start == null || end == null || !end.isAfter(start)) return 1;
    return DateTime(end.year, end.month, end.day)
            .difference(DateTime(start.year, start.month, start.day))
            .inDays +
        1;
  }

  DateTime? get _start => _date == null
      ? null
      : DateTime(
          _date!.year,
          _date!.month,
          _date!.day,
          _time.hour,
          _time.minute,
        );

  bool get _inputsReady =>
      _courtIds.isNotEmpty && _date != null && _teamCount >= 4;

  bool get _isValid =>
      _inputsReady &&
      _name.text.trim().isNotEmpty &&
      _maxLevel >= _minLevel &&
      (_endDate == null || !_endDate!.isBefore(_date!)) &&
      (_quote?.fits ?? false);

  /// يعيد التقدير من الخادم كلما تغيّر مدخل يؤثر فيه.
  Future<void> _refreshQuote() async {
    if (!_inputsReady) {
      setState(() => _quote = null);
      return;
    }
    final request = ++_quoteRequest;
    setState(() => _quoting = true);
    try {
      final q = await _cupRepo.quote(
        format: _format,
        teamCount: _teamCount,
        courtIds: _courtIds.toList(),
        scheduledAt: _start!,
        endDate: _endDate,
        durationMinutes: _window,
        matchMinutes: _matchMinutes,
      );
      if (!mounted || request != _quoteRequest) return;
      setState(() {
        _quote = q;
        _quoting = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted || request != _quoteRequest) return;
      setState(() {
        _quote = null;
        _quoting = false;
        _error = e.display;
      });
    }
  }

  void _update(VoidCallback change) {
    setState(change);
    _refreshQuote();
  }

  Future<void> _pickPartner() async {
    final picked = await showPlayerPicker(
      context,
      count: 1,
      minCount: 0,
      title: context.tr('ادعُ شريكك في فريقك (اختياري)'),
    );
    if (picked != null && mounted) {
      setState(() => _partner = picked.isEmpty ? null : picked.first);
    }
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    final q = _quote!;
    if (!widget.hostedByVenue) {
      // عضو نادي الملعب الأساسي يدفع حصته بعد خصم عضويته.
      final share = await courtShareQuote(
        courtId: _courtIds.first,
        price: q.pricePerPlayer,
        minutes: _window * _days,
      );
      if (!mounted) return;
      final ok = await showPaymentConfirmDialog(
        context,
        title: context.tr('تأكيد إنشاء البطولة'),
        amount: share.amount,
        details: [
          ...memberShareDetails(context, share),
          PaymentDetail(context.tr('البطولة'), _name.text.trim()),
          PaymentDetail(context.tr('الملاعب'), '${_courtIds.length}'),
          PaymentDetail(
            context.tr('سعر الملاعب كاملاً'),
            context.trArgs('{p0} ر.س ÷ {p1} لاعبين', {
              'p0': money(q.totalCourtPrice),
              'p1': _teamCount * 2,
            }),
          ),
        ],
        deferredNote: context.tr(
          'تُخصم حصتك أنت فقط، وكل لاعب ينضم يدفع حصته. تبقى البطولة بانتظار موافقة الملعب.',
        ),
        confirmLabel: context.tr('تأكيد الإنشاء'),
      );
      if (ok != true || !mounted) return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final cup = await _cupRepo.create(
        name: _name.text.trim(),
        format: _format,
        teamCount: _teamCount,
        courtIds: _courtIds.toList(),
        scheduledAt: _start!,
        endDate: _endDate,
        durationMinutes: _window,
        matchMinutes: _matchMinutes,
        minLevel: _minLevel.toDouble(),
        maxLevel: _maxLevel.toDouble(),
        partnerId: _partner?.userId,
        hostedByVenue: widget.hostedByVenue,
      );
      await _sendInvites(cup.id);
      if (!mounted) return;
      // تُغلق صفحة الإضافة ثم يظهر حوار النجاح فوق القائمة؛ «متابعة» تفتح
      // البطولة والرجوع منها يعود إلى القائمة لا إلى الحقول.
      final nav = Navigator.of(context);
      final awaitingVenue = cup.isPendingApproval;
      final title = context.tr('تم إنشاء البطولة بنجاح');
      final message = awaitingVenue
          ? context.tr('في انتظار موافقة الملعب')
          : context.tr('التسجيل مفتوح الآن للاعبين');
      final note = awaitingVenue
          ? context.tr('سيصلك إشعار في حال موافقة الملعب')
          : null;
      widget.onCreated(cup.id);
      showSuccessDialog(
        nav,
        title: title,
        message: message,
        note: note,
        onContinue: () => nav.push(
          MaterialPageRoute<void>(
            builder: (_) =>
                CupDetailPage(cupId: cup.id, onBack: () => nav.pop()),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.display;
        _submitting = false;
      });
    }
  }

  /// دعوات الأصدقاء بعد الإنشاء — فشلها لا يُفشل إنشاء البطولة.
  Future<void> _sendInvites(int cupId) async {
    final ids = _invitedIds.where((id) => id != _partner?.userId).toList();
    if (ids.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await getIt<EventInviteRepository>().send(
        kind: InviteKind.tournament,
        targetId: cupId,
        userIds: ids,
        expiresInMinutes: _inviteHours * 60,
      );
      if (result.sent > 0 && mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              context.trArgs('أُرسلت الدعوة إلى {p0}', {'p0': result.sent}),
            ),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              children: [
                CupLabel(context.tr('اسم البطولة')),
                TextField(
                  controller: _name,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: context.tr('مثال: كأس سبورتا الشتوية'),
                  ),
                ),
                const SizedBox(height: AppSizes.xl),
                CupLabel(context.tr('نظام البطولة')),
                CupFormatSelector(
                  value: _format,
                  onChanged: (v) => _update(() => _format = v),
                ),
                const SizedBox(height: AppSizes.xl),
                CupLabel(context.tr('عدد الفرق')),
                CupTeamCountField(
                  value: _teamCount,
                  onChanged: (v) => _update(() => _teamCount = v),
                ),
                const SizedBox(height: AppSizes.xl),
                CupLabel(context.tr('الملاعب')),
                CupCourtsPicker(
                  loading: _loadingCourts,
                  venues: _venues,
                  venue: _venue,
                  courts: _venueCourts,
                  selected: _courtIds,
                  onVenueChanged: (v) => _update(() {
                    if (v == _venue) return;
                    _venue = v;
                    _courtIds.clear();
                    _selectFirstCourt();
                  }),
                  onToggle: (id) => _update(() {
                    if (!_courtIds.remove(id)) _courtIds.add(id);
                  }),
                ),
                const SizedBox(height: AppSizes.xl),
                Row(
                  children: [
                    Expanded(
                      child: CupPickerTile(
                        label: context.tr('التاريخ'),
                        value: _date == null
                            ? context.tr('اختر')
                            : '${_date!.year}-${_date!.month}-${_date!.day}',
                        icon: Icons.calendar_today_outlined,
                        onTap: () async {
                          final now = ksaNow();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date ?? now,
                            firstDate: now,
                            lastDate: now.add(const Duration(days: 365)),
                          );
                          if (picked != null) _update(() => _date = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: CupPickerTile(
                        label: context.tr('بداية اليوم'),
                        value: _time.format(context),
                        icon: Icons.access_time,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _time,
                          );
                          if (picked != null) _update(() => _time = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                CupPickerTile(
                  label: context.tr('آخر يوم (اختياري — لبطولة على عدة أيام)'),
                  value: _endDate == null
                      ? context.tr('يوم واحد')
                      : '${_endDate!.year}-${_endDate!.month}-${_endDate!.day}',
                  icon: Icons.event_available_outlined,
                  onTap: () async {
                    final start = _date ?? ksaNow();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? start,
                      firstDate: start,
                      lastDate: start.add(const Duration(days: 30)),
                    );
                    if (picked != null) _update(() => _endDate = picked);
                  },
                ),
                const SizedBox(height: AppSizes.xl),
                CupLabel(context.tr('نافذة اللعب اليومية')),
                CupMinutesSelector(
                  options: const [120, 180, 240, 360, 480, 600],
                  value: _window,
                  hours: true,
                  onChanged: (v) => _update(() => _window = v),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  context.tr(
                    'تُحجز الملاعب المختارة في هذه النافذة كل يوم، وتُوزَّع المباريات عليها تلقائياً.',
                  ),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: AppSizes.xl),
                CupLabel(context.tr('المستوى')),
                CupLevelRange(
                  min: _minLevel,
                  max: _maxLevel,
                  onChanged: (a, b) => setState(() {
                    _minLevel = a;
                    _maxLevel = b;
                  }),
                ),
                if (!widget.hostedByVenue) ...[
                  const SizedBox(height: AppSizes.xl),
                  CupLabel(context.tr('شريكك في الفريق الأول')),
                  CupPickerTile(
                    label: '',
                    value:
                        _partner?.name ?? context.tr('اختر صديقاً (اختياري)'),
                    icon: Icons.person_add_alt_1_outlined,
                    onTap: _pickPartner,
                  ),
                ],
                const SizedBox(height: AppSizes.xl),
                CreateMatchInviteSection(
                  tooltip: context.tr('دعوة أصدقائك للمشاركة في البطولة'),
                  excludeUserIds: {?_partner?.userId},
                  onInvitedChanged: (ids) => _invitedIds = ids,
                  onDurationChanged: (h) => _inviteHours = h,
                ),
                const SizedBox(height: AppSizes.xl),
                CupSummaryCard(
                  quote: _quote,
                  loading: _quoting,
                  teamCount: _teamCount,
                  hostedByVenue: widget.hostedByVenue,
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSizes.md),
                  Text(
                    _error!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.destructive,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // زر الإنشاء ثابت أسفل الصفحة لا يتحرك مع التمرير.
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
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_isValid && !_submitting) ? _submit : null,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(context.tr('إنشاء البطولة')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() => Container(
    decoration: const BoxDecoration(gradient: AppColors.headerGradient),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.pagePadding,
          AppSizes.xxl,
          AppSizes.pagePadding,
          AppSizes.xl,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('إنشاء بطولة'),
                    style: AppTextStyles.heading2.copyWith(color: Colors.white),
                  ),
                  Text(
                    context.tr(
                      'نظام كأس العالم — فرق من لاعبَين، والتطبيق يشكّل القرعة والمجموعات والمباريات',
                    ),
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
