import 'package:sporta_app/core/state/app_scope.dart';
import 'package:flutter/material.dart';
import 'match_detail_page.dart';
import '../../../memberships/presentation/widgets/member_share.dart';
import '../../../../core/widgets/success_dialog.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/system_insets.dart';
import '../../../../core/di/service_locator.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../../auth/presentation/widgets/circle_back_button.dart';
import '../../../courts/data/court_repository.dart';
import '../../../courts/data/models/court_slot.dart';
import '../../../courts/domain/entities/court_entity.dart';
import '../../../courts/presentation/widgets/book_court/time_slots_grid.dart';
import '../../../invites/data/event_invite_repository.dart';
import '../../../invites/domain/event_invite.dart';
import '../../../payment/presentation/widgets/payment_confirm_dialog.dart';
import '../../data/match_repository.dart';
import '../widgets/create_match_choice_button.dart';
import '../widgets/create_match_cost_summary.dart';
import '../widgets/create_match_court_number_field.dart';
import '../widgets/create_match_field_label.dart';
import '../widgets/create_match_invite_section.dart';
import '../widgets/create_match_picker_field.dart';
import '../widgets/create_match_preview_card.dart';
import '../widgets/create_match_select_field.dart';
import '../../../../core/localization/tr_global.dart';
import 'package:sporta_app/core/utils/server_time.dart';

List<CreateMatchSelectOption> get _levelOptions => [
  CreateMatchSelectOption('3.0', trg('3.0 - مبتدئ')),
  CreateMatchSelectOption('3.5', trg('3.5 - مبتدئ متقدم')),
  CreateMatchSelectOption('4.0', trg('4.0 - متوسط')),
  CreateMatchSelectOption('4.5', trg('4.5 - متوسط متقدم')),
  CreateMatchSelectOption('5.0', trg('5.0 - متقدم')),
  CreateMatchSelectOption('5.5', trg('5.5 - متقدم جداً')),
  CreateMatchSelectOption('6.0', trg('6.0 - محترف')),
  CreateMatchSelectOption('6.5', trg('6.5 - محترف متقدم')),
  CreateMatchSelectOption('7.0', trg('7.0 - نخبة')),
];

/// "إنشاء مباراة جديدة" — full-screen form to create an open match,
/// converted from CreateMatchPage.tsx.
class CreateMatchPage extends StatefulWidget {
  const CreateMatchPage({
    super.key,
    required this.onBack,
    required this.onComplete,
    this.hostedByVenue = false,
  });

  final VoidCallback onBack;
  final VoidCallback onComplete;

  /// صاحب الملعب يستضيف المباراة على ملعبه: ليس لاعباً فيها، ولا يدفع شيئاً —
  /// المقاعد الأربعة كلها معروضة، وكل لاعب يدفع حصته وتصل المالك مباشرة.
  final bool hostedByVenue;

  @override
  State<CreateMatchPage> createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends State<CreateMatchPage> {
  String _courtId = ''; // selected court id (as string)
  /// رقم الملعب الداخلي داخل النادي المختار (1..courtCount).
  int? _courtNumber;
  String _date = '';
  String _time = '';
  String _duration = '90';
  String _matchType = '';
  String _gender = ''; // 'maletrg(' (رجال) أو ')female' (نساء) — إلزامي
  String _minLevel = '';
  String _maxLevel = '';

  /// المباراة العادية دائماً 4 أشخاص (بادل): أنت + 3 ينضمون أو يُدعون.
  /// وفي استضافة صاحب الملعب: أربعة مقاعد كلها للاعبين.
  static const String _playersNeeded = '3';
  final String _costPerPlayer = '';
  final TextEditingController _notesController = TextEditingController();

  final _courtRepo = getIt<CourtRepository>();
  final _matchRepo = getIt<MatchRepository>();

  List<CourtEntity> _courts = [];
  List<int> _invitedPlayerIds = const [];
  int _inviteHours = 24;
  bool _isPrivate = false;
  bool _loadingCourts = true;
  bool _submitting = false;
  String? _error;

  // مواعيد الملعب في اليوم المختار — تُجلب من الخادم بعد اختيار الملعب
  // والتاريخ والمدة، فلا يختار اللاعب وقتاً مغلقاً أو محجوزاً.
  List<CourtSlot> _slots = const [];
  bool _loadingSlots = false;
  bool _dayClosed = false;
  String _dayRangeLabel = '';

  @override
  void initState() {
    super.initState();
    _loadCourts();
  }

  Future<void> _loadCourts() async {
    try {
      // Court picker: fetch one large page (max the API allows). The server
      // scopes the list to the player's saved city, nearest court first.
      // وحين يستضيف صاحب الملعب: ملاعبه وحدها — اختياره ملعب غيره يجعلها
      // مباراة لاعب عادية بلا أن يقصد ذلك.
      final courts = widget.hostedByVenue
          ? await _courtRepo.fetchMyCourts()
          : (await _courtRepo.fetchCourts(pageSize: 100)).items;
      if (!mounted) return;
      setState(() {
        _courts = courts;
        _loadingCourts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCourts = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  CourtEntity? get _selectedCourt {
    for (final c in _courts) {
      if (c.id == _courtId) return c;
    }
    return null;
  }

  /// اسم النادي مع رقم الملعب الداخلي كما يُعرض في الملخّص والتأكيد.
  String get _courtLabel {
    final name = _selectedCourt?.name ?? '';
    if (name.isEmpty || _courtNumber == null) return name;
    return '$name - ${trgArgs('ملعب {p0}', {'p0': _courtNumber})}';
  }

  List<CreateMatchSelectOption> get _courtOptions => [
    for (final c in _courts)
      CreateMatchSelectOption(c.id, '${c.name} - ${c.city}'),
  ];

  /// Durations the selected court offers a booking price for (else the defaults).
  List<String> get _durationOptions {
    final court = _selectedCourt;
    if (court != null && court.bookingPrices.isNotEmpty) {
      final ds = court.bookingPrices.map((t) => t.durationMinutes).toList()
        ..sort();
      return ds.map((d) => d.toString()).toList();
    }
    return const ['60', '90', '120'];
  }

  // العدد الكلي للاعبين (+1 لأن منشئ المباراة يُحسب — إلا حين يستضيف صاحب
  // الملعب، فهو منظّم لا لاعب).
  int get _totalPlayers =>
      widget.hostedByVenue ? 4 : int.parse(_playersNeeded) + 1;

  /// سعر الموعد المختار كما حسبه الخادم (يشمل ساعات الذروة والخصم) — وهو
  /// نفسه ما ستحسبه المباراة عند الإنشاء.
  double? get _selectedSlotPrice {
    if (_time.isEmpty) return null;
    for (final s in _slots) {
      if (s.time == _time && !s.isBooked) return s.price;
    }
    return null;
  }

  // حصة اللاعب الواحد: سعر حجز الملعب لهذه المدة مقسوماً على عدد اللاعبين
  // (نفس سعر حجز الملعب العادي)، وإلا تقسيم تكلفة الساعة كاحتياطي.
  // كسريةٌ عمداً: التقريب إلى عدد صحيح كان يعرض ملعباً بريال واحد على أنه
  // «0 ر.س» للاعب — والخادم يخصم 0.26 فعلاً.
  double get _playerShare {
    final court = _selectedCourt;
    if (court == null || _duration.isEmpty) return 0;
    final slotPrice = _selectedSlotPrice;
    final total =
        slotPrice ??
        (court.bookingPriceFor(int.parse(_duration)) ??
            court.totalPrice * int.parse(_duration) / 60);
    // نفس تقريب الخادم (منزلتان) حتى لا يختلف المعروض عمّا يُخصم.
    return (total / _totalPlayers * 100).round() / 100;
  }

  // التكلفة الإجمالية = حصة اللاعب × عدد اللاعبين
  double get _totalCost => _playerShare * _totalPlayers;

  bool get _isFormValid {
    return _courtId.isNotEmpty &&
        _courtNumber != null &&
        _date.isNotEmpty &&
        _time.isNotEmpty &&
        _matchType.isNotEmpty &&
        _gender.isNotEmpty &&
        _minLevel.isNotEmpty &&
        _maxLevel.isNotEmpty;
  }

  String get _matchTypeLabel {
    switch (_matchType) {
      case 'challenge-team':
        return trg('تحدي فرق');
      case 'friendly-individual':
        return trg('ودية فردي');
      default:
        return '';
    }
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  Future<void> _pickDate() async {
    final now = ksaNow();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _date = '${picked.year}-${_two(picked.month)}-${_two(picked.day)}';
        _time = '';
      });
      await _loadSlots();
    }
  }

  /// مواعيد الملعب المتاحة في اليوم والمدة المختارين. الخادم يُرجع بدايات
  /// المواعيد مقسّمة على المدة، ويعلّم المحجوز منها، فلا حاجة لمنتقي وقت حر.
  Future<void> _loadSlots() async {
    final court = _selectedCourt;
    if (court == null || _date.isEmpty || _duration.isEmpty) {
      setState(() {
        _slots = const [];
        _dayClosed = false;
        _dayRangeLabel = '';
        _loadingSlots = false;
      });
      return;
    }

    final courtId = int.tryParse(_courtId);
    final day = DateTime.tryParse(_date);
    if (courtId == null || day == null) return;

    setState(() => _loadingSlots = true);
    // يحمي من سباق الطلبات: نتجاهل ردّ اختيار قديم بعد تغيير المستخدم لاختياره.
    final requestKey = '$_courtId|$_date|$_duration';
    try {
      final availability = await _courtRepo.fetchAvailability(
        courtId,
        day,
        durationMinutes: int.parse(_duration),
      );
      if (!mounted || requestKey != '$_courtId|$_date|$_duration') return;
      setState(() {
        _slots = availability.slots;
        _dayClosed = availability.isClosed;
        _dayRangeLabel = availability.rangeLabel;
        _loadingSlots = false;
        // الوقت المختار سابقاً قد لا يكون ضمن مواعيد اليوم/المدة الجديدة.
        if (_selectedSlotPrice == null) _time = '';
      });
    } catch (_) {
      if (!mounted || requestKey != '$_courtId|$_date|$_duration') return;
      setState(() {
        _slots = const [];
        _dayClosed = false;
        _dayRangeLabel = '';
        _loadingSlots = false;
        _time = '';
      });
    }
  }

  String _mapMatchType() => switch (_matchType) {
    'challenge-team' => 'competitive',
    'friendly-individual' => 'social',
    _ => 'social',
  };

  Future<void> _handleSubmit() async {
    if (!_isFormValid || _submitting) return;

    final scheduledAt = DateTime.tryParse('${_date}T$_time:00');
    if (scheduledAt == null) {
      setState(() => _error = trg('التاريخ أو الوقت غير صحيح'));
      return;
    }

    // Mirrors Match.CreatorCharge() on the server: paying in full covers every
    // player, otherwise the creator only pays their own share. Court-less
    // matches cost the creator nothing.
    // صاحب الملعب المستضيف لا يُخصم منه شيء — اللاعبون يدفعون له.
    final creatorCharge = (_courtId.isEmpty || widget.hostedByVenue)
        ? 0.0
        : _playerShare; // الدفع فرديّ: حصتك وحدها

    if (creatorCharge > 0) {
      // عضو نادي الملعب يدفع حصته بعد خصم عضويته.
      final share = await courtShareQuote(
        courtId: int.tryParse(_courtId) ?? 0,
        price: creatorCharge,
        minutes: int.tryParse(_duration) ?? 0,
      );
      if (!mounted) return;
      final confirmed = await showPaymentConfirmDialog(
        context,
        title: context.tr('تأكيد إنشاء المباراة'),
        amount: share.amount,
        details: [
          ...memberShareDetails(context, share),
          PaymentDetail(
            context.tr('الملعب'),
            _selectedCourt == null ? context.tr('بدون ملعب محدد') : _courtLabel,
          ),
          PaymentDetail(
            context.tr('طريقة الدفع'),
            context.tr('كل لاعب يدفع حصته'),
          ),
        ],
        confirmLabel: context.tr('تأكيد الإنشاء'),
        autoCancelNote: true,
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final match = await _matchRepo.createMatch(
        courtId: int.tryParse(_courtId),
        matchType: _mapMatchType(),
        gender: _gender,
        scheduledAt: scheduledAt,
        durationMinutes: int.parse(_duration),
        maxPlayers: _totalPlayers,
        minLevel: double.tryParse(_minLevel) ?? 1,
        maxLevel: double.tryParse(_maxLevel) ?? 7,
        pricePerPlayer: _playerShare,
        paymentMode: 'share',
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        hostedByVenue: widget.hostedByVenue,
        isPrivate: _isPrivate,
      );
      // الدعوات بمدة صلاحيتها عبر نظام الدعوات — فشلها لا يُفشل الإنشاء.
      // المدعو ينضم بزر الانضمام (ولو قبل موافقة الملعب) فيُقبل فوراً.
      // ما لم يُرسل يُذكر في حوار النجاح — كان الفشل يُبتلع بصمت فتُنشأ
      // المباراة الخاصة ولا أحد يستطيع الانضمام إليها.
      String? inviteNote;
      if (_invitedPlayerIds.isNotEmpty) {
        try {
          final sent = await getIt<EventInviteRepository>().send(
            kind: InviteKind.match,
            targetId: match.id,
            userIds: _invitedPlayerIds,
            expiresInMinutes: _inviteHours * 60,
          );
          if (sent.skipped.isNotEmpty && mounted) {
            inviteNote = context.trArgs('لم تُرسل الدعوة إلى: {p0}', {
              'p0': sent.skipped.map((s) => s.$1).join('، '),
            });
          }
        } on ApiException catch (e) {
          if (mounted) {
            inviteNote = context.trArgs(
              'تعذّر إرسال الدعوات ({p0}) — أرسلها من صفحة المباراة',
              {'p0': e.display},
            );
          }
        }
      }
      if (!mounted) return;
      // تُغلق صفحة الإضافة ثم يظهر حوار النجاح فوق القائمة؛ «متابعة» تفتح
      // المباراة والرجوع منها يعود إلى القائمة لا إلى الحقول.
      final nav = Navigator.of(context);
      final awaitingVenue = match.status == 'PendingApproval';
      final message = awaitingVenue
          ? context.tr('في انتظار موافقة الملعب')
          : context.tr('المباراة مفتوحة الآن للاعبين');
      final note = [
        if (awaitingVenue) context.tr('سيصلك إشعار في حال موافقة الملعب'),
        ?inviteNote,
      ].join('\n');
      final title = context.tr('تم إنشاء المباراة بنجاح');
      widget.onComplete();
      showSuccessDialog(
        nav,
        title: title,
        message: message,
        note: note.isEmpty ? null : note,
        onContinue: () => nav.push(
          MaterialPageRoute<void>(
            builder: (_) => MatchDetailPage(matchId: match.id),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.display;
      });
      // الموعد اختُطف بين عرض القائمة والإرسال — نُحدّث الأوقات المتاحة.
      if (e.code == 'SLOT_TAKEN' || e.code == 'SLOT_UNAVAILABLE') {
        await _loadSlots();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.pagePadding,
                  vertical: AppSizes.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCourtField(),
                    if (_selectedCourt != null) ...[
                      const SizedBox(height: AppSizes.xl),
                      _buildCourtNumberField(),
                    ],
                    const SizedBox(height: AppSizes.xl),
                    _buildDateField(),
                    const SizedBox(height: AppSizes.xl),
                    _buildDurationField(),
                    const SizedBox(height: AppSizes.xl),
                    _buildTimeSlotsField(),
                    const SizedBox(height: AppSizes.xl),
                    _buildMatchTypeField(),
                    const SizedBox(height: AppSizes.xl),
                    _buildGenderField(),
                    const SizedBox(height: AppSizes.xl),
                    _buildLevelFields(),
                    const SizedBox(height: AppSizes.xl),
                    _buildPlayersNeededField(),
                    const SizedBox(height: AppSizes.xl),
                    if (_courtId.isNotEmpty && _duration.isNotEmpty) ...[
                      CreateMatchCostSummary(
                        totalCost: _totalCost,
                        playerShare: _playerShare,
                        totalPlayers: _totalPlayers,
                        hostedByVenue: widget.hostedByVenue,
                      ),
                      const SizedBox(height: AppSizes.xl),
                    ],
                    _buildNotesField(),
                    const SizedBox(height: AppSizes.xl),
                    _buildPrivateSwitch(),
                    const SizedBox(height: AppSizes.xl),
                    CreateMatchInviteSection(
                      onInvitedChanged: (ids) => _invitedPlayerIds = ids,
                      onDurationChanged: (h) => _inviteHours = h,
                    ),
                    const SizedBox(height: AppSizes.xl),
                    if (_isFormValid) ...[
                      CreateMatchPreviewCard(
                        courtName: _courtLabel,
                        date: _date,
                        time: _time,
                        typeLabel: _matchTypeLabel,
                        minLevel: _minLevel,
                        maxLevel: _maxLevel,
                        costPerPlayer: _costPerPlayer,
                      ),
                      const SizedBox(height: AppSizes.xl),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // زرّا الإنشاء والإلغاء ثابتان أسفل الصفحة لا يتحركان مع التمرير.
          Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            padding: context.safeBottom(
              const EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                0,
                AppSizes.pagePadding,
                AppSizes.md,
              ),
            ),
            child: _buildActions(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleBackButton(onTap: widget.onBack),
                  SizedBox(width: AppSizes.md),
                  Text(
                    context.tr('إنشاء مباراة جديدة'),
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.onSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.lg),
              Text(
                context.tr('املأ التفاصيل لإنشاء مباراة مفتوحة'),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.onSecondary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourtField() {
    return CreateMatchSelectField(
      label: context.tr('اسم الملعب *'),
      icon: Icons.location_on_outlined,
      hint: _loadingCourts
          ? context.tr('جاري تحميل الملاعب...')
          : context.tr('اختر الملعب'),
      options: _courtOptions,
      value: _courtId,
      onChanged: (value) {
        setState(() {
          _courtId = value;
          // رقم الملعب يخص النادي المختار، فيُعاد اختياره مع كل تغيير.
          _courtNumber = null;
          // Drop a duration the newly-selected court doesn't price.
          if (!_durationOptions.contains(_duration)) _duration = '';
          _time = '';
        });
        _loadSlots();
      },
    );
  }

  /// الملاعب الداخلية للنادي المختار (1، 2، 3...) — يختار المنشئ أيّها.
  Widget _buildCourtNumberField() {
    return CreateMatchCourtNumberField(
      label: context.tr('رقم الملعب *'),
      count: _selectedCourt?.courtCount ?? 1,
      selected: _courtNumber,
      onSelect: (number) => setState(() => _courtNumber = number),
    );
  }

  Widget _buildDateField() {
    return CreateMatchPickerField(
      label: context.tr('التاريخ *'),
      icon: Icons.calendar_today_outlined,
      value: _date,
      hint: context.tr('يوم/شهر/سنة'),
      onTap: _pickDate,
    );
  }

  /// مواعيد الملعب المتاحة في اليوم المختار بدل منتقي وقت حر — تظهر بعد
  /// اختيار الملعب والتاريخ والمدة.
  Widget _buildTimeSlotsField() {
    if (_courtId.isEmpty || _date.isEmpty || _duration.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CreateMatchFieldLabel(
            text: context.tr('الوقت *'),
            icon: Icons.access_time,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            context.tr(
              _courtId.isEmpty
                  ? context.tr('اختر الملعب أولاً لعرض الأوقات المتاحة')
                  : _date.isEmpty
                  ? context.tr('اختر التاريخ لعرض الأوقات المتاحة')
                  : context.tr('اختر مدة المباراة لعرض الأوقات المتاحة'),
            ),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      );
    }

    return TimeSlotsGrid(
      slots: _slots,
      selectedTime: _time.isEmpty ? null : _time,
      loading: _loadingSlots,
      dayClosed: _dayClosed,
      dayRangeLabel: _dayRangeLabel,
      day: DateTime.tryParse(_date),
      onSelect: (time) => setState(() => _time = time),
    );
  }

  Widget _buildDurationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CreateMatchFieldLabel(text: context.tr('مدة المباراة')),
        const SizedBox(height: AppSizes.sm),
        Builder(
          builder: (context) {
            final options = _durationOptions;
            return Row(
              children: [
                for (var i = 0; i < options.length; i++) ...[
                  Expanded(
                    child: CreateMatchChoiceButton(
                      label: context.trArgs('{p0} دقيقة', {'p0': options[i]}),
                      selected: _duration == options[i],
                      onTap: () {
                        if (_duration == options[i]) return;
                        setState(() {
                          _duration = options[i];
                          _time = '';
                        });
                        _loadSlots();
                      },
                    ),
                  ),
                  if (i != options.length - 1)
                    const SizedBox(width: AppSizes.md),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMatchTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CreateMatchFieldLabel(text: context.tr('نوع المباراة *')),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            Expanded(
              child: CreateMatchChoiceButton(
                label: context.tr('تحدي فرق'),
                selected: _matchType == 'challenge-team',
                onTap: () => setState(() => _matchType = 'challenge-team'),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: CreateMatchChoiceButton(
                label: context.tr('ودية فردي'),
                selected: _matchType == 'friendly-individual',
                onTap: () => setState(() => _matchType = 'friendly-individual'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CreateMatchFieldLabel(
          text: context.tr('نوع اللاعبين المنضمين *'),
          icon: Icons.wc,
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            Expanded(
              child: CreateMatchChoiceButton(
                label: context.tr('رجال'),
                selected: _gender == 'male',
                onTap: () => setState(() => _gender = 'male'),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: CreateMatchChoiceButton(
                label: context.tr('نساء'),
                selected: _gender == 'female',
                onTap: () => setState(() => _gender = 'female'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLevelFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CreateMatchFieldLabel(
          text: context.tr('المستوى المطلوب *'),
          icon: Icons.trending_up,
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CreateMatchSelectField(
                label: context.tr('الحد الأدنى'),
                hint: context.tr('اختر'),
                dense: true,
                options: _levelOptions,
                value: _minLevel,
                onChanged: (value) => setState(() => _minLevel = value),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: CreateMatchSelectField(
                label: context.tr('الحد الأقصى'),
                hint: context.tr('اختر'),
                dense: true,
                options: _levelOptions,
                value: _maxLevel,
                onChanged: (value) => setState(() => _maxLevel = value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// المباراة ثابتة على 4 أشخاص، فلا اختيار للعدد — سطر توضيحي فقط.
  Widget _buildPlayersNeededField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CreateMatchFieldLabel(
          text: context.tr('عدد اللاعبين'),
          icon: Icons.people_outline,
        ),
        const SizedBox(height: AppSizes.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            widget.hostedByVenue
                ? context.tr(
                    '4 لاعبين — المقاعد الأربعة مفتوحة للتسجيل، ولست أحدهم',
                  )
                : context.tr('4 لاعبين — أنت و3 ينضمون أو تدعوهم'),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
          ),
        ),
      ],
    );
  }

  /// مباراة خاصة: لا تظهر في البحث، وينضم إليها المدعوون فقط؛ يحوّلها المنشئ
  /// لعامة لاحقاً من تفاصيل المباراة.
  Widget _buildPrivateSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        value: _isPrivate,
        onChanged: (v) => setState(() => _isPrivate = v),
        activeThumbColor: AppColors.primary,
        secondary: const Icon(Icons.lock_outline),
        title: Text(
          context.tr('مباراة خاصة'),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          context.tr(
            'لا تظهر في البحث، وينضم إليها اللاعبون الذين تدعوهم فقط. يمكنك جعلها عامة لاحقاً.',
          ),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CreateMatchFieldLabel(text: context.tr('ملاحظات إضافية')),
        SizedBox(height: AppSizes.sm),
        TextField(
          controller: _notesController,
          maxLines: 3,
          style: AppTextStyles.body.copyWith(color: AppColors.secondary),
          decoration: createMatchInputDecoration(
            hint: context.tr('أي تفاصيل إضافية تريد إضافتها...'),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    const gray100 = Color(0xFFF3F4F6);
    const gray300 = Color(0xFFD1D5DB);
    final valid = _isFormValid && !_submitting;

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            Text(
              _error!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.destructive,
              ),
            ),
            const SizedBox(height: AppSizes.md),
          ],
          Row(
            children: [
              // إلغاء
              Material(
                color: gray100,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                child: InkWell(
                  onTap: widget.onBack,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSizes.pagePadding,
                      vertical: AppSizes.md,
                    ),
                    child: Text(
                      context.tr('إلغاء'),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              // إنشاء المباراة
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: valid ? AppColors.primaryGradient : null,
                    color: valid ? null : gray300,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    boxShadow: valid
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    child: InkWell(
                      onTap: valid ? _handleSubmit : null,
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.md,
                        ),
                        child: _submitting
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                context.tr('إنشاء المباراة'),
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body.copyWith(
                                  color: valid
                                      ? Colors.white
                                      : AppColors.mutedForeground,
                                ),
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
}
