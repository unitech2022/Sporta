import 'package:sporta_app/core/widgets/directional_icon.dart';
import 'package:flutter/material.dart';
import 'americano_detail_page.dart';

import '../../../memberships/presentation/widgets/member_share.dart';
import '../../../../core/widgets/success_dialog.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/app_scope.dart';
import '../../../auth/data/models/api_exception.dart';
import '../../../courts/data/court_repository.dart';
import '../../../courts/data/models/court_slot.dart';
import '../../../courts/domain/entities/court_entity.dart';
import '../../../courts/presentation/widgets/book_court/time_slots_grid.dart';
import '../../../friends/domain/entities/player_summary.dart';
import '../../../matches/presentation/widgets/create_match_choice_button.dart';
import '../../../friends/presentation/widgets/player_picker_sheet.dart';
import '../../../payment/presentation/widgets/payment_confirm_dialog.dart';
import '../../data/americano_repository.dart';
import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/system_insets.dart';
import 'package:sporta_app/core/utils/server_time.dart';

/// مدد الأمريكانو/البطولة بالدقائق. الأمريكانو أطول من المباراة العادية وقد
/// يستغرق اليوم كله، فالخيارات مفتوحة ولا تقتصر على مدد الملعب المسعّرة —
/// سقفها 240 دقيقة لأنه سقف `CreateAmericanoDto.DurationMinutes` في الخادم.
const List<int> kAmericanoDurations = [60, 90, 120, 150, 180, 210, 240];

/// المدة المختارة عند فتح الصفحة. تُرسل صراحةً كي يطابق السعر المعروض في
/// نافذة التأكيد ما يخصمه الخادم.
const int _kDefaultDurationMinutes = 90;

/// سياسة التسعير التي يجب أن يقرّها المنشئ قبل إنشاء أي أمريكانو/بطولة.
const String kAmericanoPricePolicy =
    'يجب أن يكون سعر الحجز في مباراة الأمريكانو مطابقًا لسعر الحجز العادي '
    'للملعب، ولا يجوز إضافة أي رسوم إضافية على سعر الحجز.';

/// أقل عدد لاعبين في الأمريكانو/البطولة الفردية — مباراة واحدة كاملة. لا سقف
/// أعلى: البطولة قد تضم 20 أو 50 لاعباً. يطابق `AmericanoService.MinSinglesPlayers`.
const int kMinSinglesPlayers = 4;

/// أقصى فارق بالأيام بين بداية البطولة ونهايتها — يطابق
/// `CourtSchedule.MaxMultiDayRangeDays` في الخادم، وهو نفسه سقف فحص المواعيد
/// وتسعيرها، فلا يختار المنشئ مدى لا يستطيع الخادم فحصه كاملاً.
const int kMaxTournamentSpanDays = 30;

/// أقل عدد فرق في أمريكانو/بطولة الفرق — لاعبان لكل فريق. لا سقف أعلى:
/// البطولة قد تضم 10 أو 30 فريقاً. يطابق `AmericanoService.MinTeams`.
const int kMinTeams = 2;
const int kPlayersPerTeam = 2;

/// عدد مباريات الدوري (كل فريق يلاقي البقية مرة واحدة).
int americanoRoundRobinGames(int teamCount) => teamCount * (teamCount - 1) ~/ 2;

/// حالة الموعد المختار في الملعب المختار، كما يراها الخادم.
enum _SlotStatus {
  /// لا ملعب أو لا وقت مختار بعد — لا شيء يُعرض.
  none,

  /// أوقات اليوم قيد الجلب.
  checking,

  /// الموعد فارغ ويقبله الملعب (وكل أيام البطولة).
  available,

  /// الموعد مشغول بحجز أو مباراة أو جلسة تدريب.
  booked,

  /// الموعد خارج أوقات الملعب المتاحة بهذه المدة.
  outside,

  /// الملعب مغلق في اليوم المختار (أو في أحد أيام البطولة).
  closed,
}

/// Clean "create americano/tournament" flow: pick court/date/level + 3 players.
/// With [isTournament] the same flow creates a بطولة — identical system, but it
/// may span one day or several (optional end date).
class AmericanoCreatePage extends StatefulWidget {
  const AmericanoCreatePage({
    super.key,
    required this.onBack,
    required this.onCreated,
    this.isTournament = false,
    this.hostedByVenue = false,
  });

  final VoidCallback onBack;
  final void Function(int americanoId) onCreated;
  final bool isTournament;

  /// صاحب الملعب يستضيف الحدث على ملعبه: منظّمٌ لا لاعب — لا فريق له ولا
  /// شريك، ولا يُخصم منه شيء؛ كل لاعب يدفع حصته وتصل إليه.
  final bool hostedByVenue;

  @override
  State<AmericanoCreatePage> createState() => _AmericanoCreatePageState();
}

class _AmericanoCreatePageState extends State<AmericanoCreatePage> {
  final _courtRepo = getIt<CourtRepository>();
  final _americanoRepo = getIt<AmericanoRepository>();

  List<CourtEntity> _courts = [];
  CourtEntity? _court;
  DateTime? _date;
  TimeOfDay? _time;

  /// مدة الحجز بالدقائق — تحدد طول كل موعد في شبكة الأوقات المتاحة.
  int _duration = _kDefaultDurationMinutes;

  /// Tournament only: optional last day (null or same day = one-day event).
  DateTime? _endDate;
  int _minLevel = 3;
  int _maxLevel = 6;
  final List<PlayerSummary> _players = [];

  /// عدد لاعبي النمط الفردي شاملاً المنشئ — يختاره المنشئ بلا سقف.
  int _playerCount = kMinSinglesPlayers;
  final _playerCountCtrl = TextEditingController(text: '$kMinSinglesPlayers');

  /// 'singles' (partner rotation) | 'teams' (fixed 2v2).
  String _type = 'singles';

  /// Teams mode: how many fixed teams take part (2 players each).
  int _teamCount = kMinTeams;
  final _teamCountCtrl = TextEditingController(text: '$kMinTeams');
  int _creatorTeam = 1;
  PlayerSummary? _partner;

  /// أوقات الملعب المختار في اليوم المختار — تُجلب من الخادم بدل اختيار وقت حر.
  CourtDayAvailability _availability = CourtDayAvailability.empty;
  bool _loadingSlots = false;

  /// يبطل ردّ طلب أوقات قديم إذا غيّر المستخدم الملعب/التاريخ قبل وصوله.
  int _slotsRequest = 0;

  bool _loadingCourts = true;
  bool _submitting = false;
  String? _error;

  /// إقرار المنشئ بسياسة التسعير — لا إنشاء بدونه.
  bool _acceptedPricePolicy = false;

  bool get _isTeams => _type == 'teams';

  @override
  void initState() {
    super.initState();
    _loadCourts();
  }

  @override
  void dispose() {
    _playerCountCtrl.dispose();
    _teamCountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCourts() async {
    try {
      // Court picker: fetch one large page (max the API allows). The server
      // scopes the list to the player's saved city, nearest court first.
      // وحين يستضيف صاحب الملعب: ملاعبه وحدها.
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

  /// يعيد جلب أوقات اليوم للملعب المختار. بلا ملعب (أمريكانو بدون حجز) لا توجد
  /// أوقات تُجلب، فيبقى اختيار الوقت يدوياً.
  Future<void> _loadSlots() async {
    final court = _court;
    final date = _date;
    final request = ++_slotsRequest;
    if (court == null || date == null) {
      setState(() {
        _availability = CourtDayAvailability.empty;
        _loadingSlots = false;
      });
      return;
    }
    setState(() => _loadingSlots = true);
    try {
      final availability = await _courtRepo.fetchAvailability(
        court.numericId,
        date,
        durationMinutes: _duration,
        // البطولة تشغل نفس الموعد من كل يوم، فالمواعيد المعروضة يجب أن تكون
        // فارغة في أيامها كلها لا في يوم البداية وحده.
        endDate: _rangeEndDate,
      );
      if (!mounted || request != _slotsRequest) return;
      setState(() {
        _availability = availability;
        _loadingSlots = false;
      });
    } on ApiException {
      if (!mounted || request != _slotsRequest) return;
      setState(() {
        _availability = CourtDayAvailability.empty;
        _loadingSlots = false;
      });
    }
  }

  /// "20:00" كما يعيدها الخادم → وقت المباراة.
  void _selectSlot(String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts.first);
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : 0;
    if (hour == null) return;
    setState(() => _time = TimeOfDay(hour: hour, minute: minute ?? 0));
  }

  /// الوقت المختار بصيغة الخادم ("20:00")، لمطابقته بأوقات الشبكة.
  String? get _selectedSlotTime => _time == null
      ? null
      : '${_time!.hour.toString().padLeft(2, '0')}:'
            '${_time!.minute.toString().padLeft(2, '0')}';

  /// آخر يوم يشغله الحجز: تاريخ نهاية البطولة حين يتجاوز يوم البداية،
  /// وإلا null (يوم واحد) فلا يتغير سلوك الأمريكانو العادي.
  DateTime? get _rangeEndDate {
    final start = _date;
    final end = _endDate;
    if (!widget.isTournament || start == null || end == null) return null;
    return end.isAfter(start) ? end : null;
  }

  /// عدد أيام البطولة (1 لليوم الواحد).
  int get _rangeDays {
    final end = _rangeEndDate;
    if (end == null || _date == null) return 1;
    return DateTime(
          end.year,
          end.month,
          end.day,
        ).difference(DateTime(_date!.year, _date!.month, _date!.day)).inDays +
        1;
  }

  /// حالة الموعد المختار في الملعب المختار — تُعرض للمنشئ صراحةً بدل أن
  /// يكتشف عند الإنشاء أن الموعد محجوز أو خارج الدوام.
  _SlotStatus get _slotStatus {
    if (_court == null || _time == null) return _SlotStatus.none;
    if (_loadingSlots) return _SlotStatus.checking;
    if (_availability.isClosed) return _SlotStatus.closed;
    final time = _selectedSlotTime;
    final matches = _availability.slots.where((s) => s.time == time);
    if (matches.isEmpty) return _SlotStatus.outside;
    return matches.first.isBooked ? _SlotStatus.booked : _SlotStatus.available;
  }

  /// مع ملعب لا يُسمح بالإنشاء إلا على موعد أكّد الخادم أنه متاح.
  bool get _slotUsable =>
      _court == null || _slotStatus == _SlotStatus.available;

  bool get _isValid =>
      _date != null &&
      _time != null &&
      _slotUsable &&
      // تنبيه سعر الحجز خاص بالأمريكانو وحده، فلا تُطلب موافقته في البطولة،
      // ولا من صاحب الملعب المستضيف (لا يدفع أصلاً).
      (widget.isTournament || widget.hostedByVenue || _acceptedPricePolicy) &&
      _maxLevel >= _minLevel &&
      (_endDate == null || !_endDate!.isBefore(_date!)) &&
      (_isTeams
          ? (_teamCount >= kMinTeams && _creatorTeam <= _teamCount)
          : (_playerCount >= kMinSinglesPlayers &&
                _players.length <= _playerCount - 1));

  Future<void> _pickPlayers() async {
    final picked = await showPlayerPicker(
      context,
      count: _playerCount - 1,
      minCount: 0,
      title: context.trArgs('اختر حتى {n} لاعباً', {'n': _playerCount - 1}),
    );
    if (picked != null) {
      setState(() {
        _players
          ..clear()
          ..addAll(picked);
      });
    }
  }

  Future<void> _pickPartner() async {
    final picked = await showPlayerPicker(
      context,
      count: 1,
      minCount: 0,
      title: context.tr('اختر شريكك في الفريق'),
    );
    if (picked != null) {
      setState(() => _partner = picked.isEmpty ? null : picked.first);
    }
  }

  /// سعر حجز الملعب العادي لنفس الموعد كما يسعّره الخادم — قبل خصم باقة اللاعب،
  /// لأن الأمريكانو يُحجز بالسعر الأساسي نفسه. مع [endDate] يعود مجموع أيام
  /// المدى (البطولة تحجز الملعب في كل يوم منها). null حين يتعذّر الوصول للخادم.
  Future<double?> _fetchNormalBookingPrice(
    CourtEntity court,
    DateTime scheduledAt, {
    DateTime? endDate,
  }) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final quote = await _courtRepo.quoteBooking(
        courtId: court.numericId,
        startTime: scheduledAt,
        durationMinutes: _duration,
        endDate: endDate,
      );
      // basePrice بلا عمولة سبورتا (حصة المالك)، أمّا سعر الأمريكانو المعروض
      // للاعبين فشامل العمولة؛ فنقارن بالسعر الإجمالي قبل الخصم.
      return quote.total + quote.discountAmount;
    } on ApiException {
      return null;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    final scheduledAt = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );

    // A court americano is booked FullByCreator: the creator pays the whole
    // court up-front (players' shares are paid back as they join). Court-less
    // americanos are free. Duration matches the repository default.
    final court = _court;
    // صاحب الملعب المستضيف لا يحجز ولا يدفع: الخادم يفتح الحدث فوراً ويجمع
    // حصص اللاعبين له، فلا تسعير مسبق ولا حوار خصم.
    if (court != null && !widget.hostedByVenue) {
      final timeLabel =
          '${_time!.hour.toString().padLeft(2, '0')}:'
          '${_time!.minute.toString().padLeft(2, '0')}';
      // سعر الحجز العادي للملعب لنفس الموعد والمدة كما يحسبه الخادم — وهو
      // نفسه ما يسعّر به الخادم الأمريكانو (CourtSchedule.BookingPrice)، فلا
      // تُقارَن به أي حسبة محلية: التقدير المحلي يقرّب الهللات ويجهل قواعد
      // تسعير المالك فيُخطئ مع أسعار مثل 3.30 ويمنع حجزاً صحيحاً.
      final normalPrice = await _fetchNormalBookingPrice(court, scheduledAt);
      if (!mounted) return;
      if (normalPrice == null) {
        setState(
          () => _error = context.tr(
            trg('تعذّر التحقق من سعر حجز الملعب. حاول مرة أخرى قبل الإنشاء.'),
          ),
        );
        return;
      }

      // البطولة تحجز الملعب في كل يوم من أيامها، فالمخصوم مجموع أسعار تلك
      // الأيام (قد تختلف بينها بقواعد تسعير المالك) لا سعر يوم البداية.
      final rangeEnd = _rangeEndDate;
      // الدفع فرديّ: المنشئ يدفع حصته وحدها، وكل منضمّ يدفع حصته.
      final capacity = _isTeams ? _teamCount * kPlayersPerTeam : _playerCount;
      var chargeTotal = normalPrice;
      if (rangeEnd != null) {
        final rangePrice = await _fetchNormalBookingPrice(
          court,
          scheduledAt,
          endDate: rangeEnd,
        );
        if (!mounted) return;
        if (rangePrice == null) {
          setState(
            () => _error = context.tr(
              trg('تعذّر التحقق من سعر حجز الملعب. حاول مرة أخرى قبل الإنشاء.'),
            ),
          );
          return;
        }
        chargeTotal = rangePrice;
      }
      final creatorShare =
          (chargeTotal / capacity * 100).round() / 100; // نفس تقريب الخادم
      // عضو نادي الملعب يدفع حصته بعد خصم عضويته (المدة × أيام الحدث).
      final share = await courtShareQuote(
        courtId: court.numericId,
        price: creatorShare,
        minutes: _duration * (rangeEnd != null ? _rangeDays : 1),
      );
      if (!mounted) return;

      final confirmed = await showPaymentConfirmDialog(
        context,
        title: widget.isTournament
            ? context.tr('تأكيد إنشاء البطولة')
            : context.tr('تأكيد إنشاء الأمريكانو'),
        amount: share.amount,
        details: [
          ...memberShareDetails(context, share),
          PaymentDetail(context.tr('الملعب'), court.name),
          PaymentDetail(context.tr('الموعد'), timeLabel),
          PaymentDetail(
            context.tr('سعر الملعب كاملاً'),
            context.trArgs('{p0} ر.س ÷ {p1} لاعبين', {
              'p0': chargeTotal.toStringAsFixed(2),
              'p1': capacity,
            }),
          ),
          PaymentDetail(
            context.tr('المدة'),
            context.trArgs('{p0} دقيقة', {'p0': _duration}),
          ),
          if (rangeEnd != null) ...[
            PaymentDetail(
              context.tr('عدد الأيام'),
              context.trArgs('{p0} أيام', {'p0': _rangeDays}),
            ),
            PaymentDetail(
              context.tr('سعر اليوم الأول'),
              context.trArgs('{p0} ر.س', {
                'p0': normalPrice.toStringAsFixed(2),
              }),
            ),
          ],
        ],
        deferredNote: context.tr(
          'تُخصم حصتك أنت فقط، وكل لاعب ينضم يدفع حصته. يبقى الحدث بانتظار موافقة الملعب.',
        ),
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
      final americano = await _americanoRepo.create(
        courtId: _court?.numericId,
        type: _type,
        scheduledAt: scheduledAt,
        durationMinutes: _duration,
        minLevel: _minLevel.toDouble(),
        maxLevel: _maxLevel.toDouble(),
        playerIds: _isTeams ? const [] : _players.map((p) => p.userId).toList(),
        playerCount: _playerCount,
        teamCount: _teamCount,
        creatorTeam: widget.hostedByVenue ? 1 : _creatorTeam,
        partnerId: (_isTeams && !widget.hostedByVenue)
            ? _partner?.userId
            : null,
        isTournament: widget.isTournament,
        endDate: widget.isTournament ? _endDate : null,
        hostedByVenue: widget.hostedByVenue,
      );
      if (!mounted) return;
      // تُغلق صفحة الإضافة ثم يظهر حوار النجاح فوق القائمة؛ «متابعة» تفتح
      // التفاصيل والرجوع منها يعود إلى القائمة لا إلى الحقول.
      final nav = Navigator.of(context);
      final awaitingVenue = _court != null && !widget.hostedByVenue;
      final title = widget.isTournament
          ? context.tr('تم إنشاء البطولة بنجاح')
          : context.tr('تم إنشاء الأمريكانو بنجاح');
      final message = awaitingVenue
          ? context.tr('في انتظار موافقة الملعب')
          : context.tr('التسجيل مفتوح الآن للاعبين');
      final note = awaitingVenue
          ? context.tr('سيصلك إشعار في حال موافقة الملعب')
          : null;
      widget.onCreated(americano.id);
      showSuccessDialog(
        nav,
        title: title,
        message: message,
        note: note,
        onContinue: () => nav.push(
          MaterialPageRoute<void>(
            builder: (_) => AmericanoDetailPage(
              americanoId: americano.id,
              onBack: () => nav.pop(),
            ),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.display;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                children: [
                  _label(
                    context.tr(
                      widget.isTournament
                          ? context.tr('نوع البطولة')
                          : context.tr('نوع الأمريكانو'),
                    ),
                  ),
                  _typeSelector(),
                  const SizedBox(height: AppSizes.xl),
                  _label(
                    context.tr('americano.americano_create_page.courtLabel'),
                  ),
                  _courtDropdown(),
                  const SizedBox(height: AppSizes.xl),
                  // مع ملعب: التاريخ ثم شبكة الأوقات المتاحة من الخادم.
                  // بدون ملعب (بلا حجز): يبقى اختيار الوقت يدوياً.
                  if (_court != null)
                    _dateField()
                  else
                    Row(
                      children: [
                        Expanded(child: _dateField()),
                        const SizedBox(width: AppSizes.md),
                        Expanded(child: _timeField()),
                      ],
                    ),
                  if (widget.isTournament) ...[
                    const SizedBox(height: AppSizes.xl),
                    _endDateField(),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      context.trArgs(
                        'البطولة بنفس نظام الأمريكانو — اتركه فارغاً ليوم واحد أو اختر تاريخاً لاحقاً لبطولة على عدة أيام (حتى {p0} يوماً)، ويُحجز الملعب في كل يوم منها.',
                        {'p0': kMaxTournamentSpanDays},
                      ),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSizes.xl),
                  _label(
                    context.tr(
                      widget.isTournament ? 'مدة البطولة' : 'مدة الأمريكانو',
                    ),
                  ),
                  _durationSelector(),
                  if (_court != null) ...[
                    const SizedBox(height: AppSizes.xl),
                    if (_date == null)
                      Text(
                        context.tr('اختر التاريخ لعرض الأوقات المتاحة'),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      )
                    else
                      TimeSlotsGrid(
                        slots: _availability.slots,
                        selectedTime: _selectedSlotTime,
                        loading: _loadingSlots,
                        onSelect: _selectSlot,
                        dayClosed: _availability.isClosed,
                        dayRangeLabel: _availability.rangeLabel,
                        day: _date,
                      ),
                    if (_rangeDays > 1) ...[
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        context.trArgs(
                          'تُعرض المواعيد الفارغة في كل أيام البطولة ({p0} أيام) فقط',
                          {'p0': _rangeDays},
                        ),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                    if (_time != null) ...[
                      const SizedBox(height: AppSizes.lg),
                      _slotStatusNote(),
                    ],
                  ],
                  const SizedBox(height: AppSizes.xl),
                  _label(
                    context.tr(
                      'americano.americano_create_page.levelRangeLabel',
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _levelDropdown(
                          _minLevel,
                          (v) => setState(() => _minLevel = v),
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: _levelDropdown(
                          _maxLevel,
                          (v) => setState(() => _maxLevel = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xl),
                  if (_isTeams) ...[
                    _label(context.tr('عدد الفرق')),
                    _teamCountField(),
                    if (_teamCount >= kMinTeams) ...[
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        context.tr(
                          context.trArgs(
                            '{p0} فرق × {p1} لاعب = {p2} لاعباً، و{p3} مباراة (كل فريق يلاقي بقية الفرق مرة واحدة) على الملعب نفسه، وسعر الحجز يُقسم على جميع اللاعبين.',
                            {
                              'p0': _teamCount,
                              'p1': kPlayersPerTeam,
                              'p2': _teamCount * kPlayersPerTeam,
                              'p3': americanoRoundRobinGames(_teamCount),
                            },
                          ),
                        ),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                    // المستضيف ليس لاعباً: لا فريق له ولا شريك — الفرق كلها
                    // تنضم بلاعبيها بعد الإنشاء.
                    if (!widget.hostedByVenue) ...[
                      const SizedBox(height: AppSizes.xl),
                      _label(context.tr('فريقك')),
                      _teamSelector(),
                      const SizedBox(height: AppSizes.xl),
                      _label(context.tr('شريكك في الفريق (اختياري)')),
                      _partnerField(),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        context.tr(
                          context.tr(
                            'سيصل شريكك إشعار دعوة، ولن يُضاف حتى يقبل. بقية الفرق تنضم بلاعبيها بعد الإنشاء.',
                          ),
                        ),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ] else ...[
                    _label(
                      widget.hostedByVenue
                          ? context.tr('عدد اللاعبين')
                          : context.tr('عدد اللاعبين (شاملك)'),
                    ),
                    _playerCountField(),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      context.tr(
                        context.tr(
                          'في كل جولة يُقسم اللاعبون إلى مجموعات من 4 يلعبون معاً، ويتبدّل الشركاء كل جولة، وسعر الحجز يُقسم على الجميع.',
                        ),
                      ),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    // دعوة لاعبين مسبقاً تخصّ من يلعب؛ المستضيف يترك المقاعد
                    // كلها مفتوحة للتسجيل.
                    if (!widget.hostedByVenue) ...[
                      const SizedBox(height: AppSizes.xl),
                      _label(
                        context.tr(
                          'americano.americano_create_page.playersLabel',
                        ),
                      ),
                      _playersField(),
                    ],
                  ],
                  if (!widget.isTournament && !widget.hostedByVenue) ...[
                    const SizedBox(height: AppSizes.xl),
                    _pricePolicyNotice(),
                  ],
                  if (widget.hostedByVenue) ...[
                    const SizedBox(height: AppSizes.xl),
                    _hostNotice(),
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
                      : Text(
                          context.tr(
                            'americano.americano_create_page.submitButton',
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// تنبيه سياسة التسعير مع خانة الموافقة — خاص بالأمريكانو (فردي وفرق) ولا
  /// يظهر في البطولة، وزر الإنشاء يبقى معطّلاً حتى يوافق المنشئ.
  Widget _pricePolicyNotice() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: AppSizes.iconMd,
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                context.tr('تنبيه'),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            context.tr(kAmericanoPricePolicy),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          InkWell(
            onTap: () =>
                setState(() => _acceptedPricePolicy = !_acceptedPricePolicy),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            child: Row(
              children: [
                Checkbox(
                  value: _acceptedPricePolicy,
                  activeColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (v) =>
                      setState(() => _acceptedPricePolicy = v ?? false),
                ),
                const SizedBox(width: AppSizes.xs),
                Expanded(
                  child: Text(
                    context.tr('أوافق على هذا الشرط'),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
              // Expanded: the longest title ("إنشاء أمريكانو فردي") overflows a
              // narrow screen otherwise.
              Expanded(
                child: Text(
                  context.tr(
                    widget.isTournament
                        ? (_isTeams
                              ? context.tr('إنشاء بطولة فرق')
                              : context.tr('إنشاء بطولة فردي'))
                        : (_isTeams
                              ? context.tr('إنشاء أمريكانو فرق')
                              : context.tr('إنشاء أمريكانو فردي')),
                  ),
                  style: AppTextStyles.heading2.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.sm),
    child: Text(
      text,
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
    ),
  );

  Widget _typeSelector() {
    Widget option(String value, String label, IconData icon, String hint) {
      final selected = _type == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _type = value),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSizes.md,
              horizontal: AppSizes.sm,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? AppColors.primary
                      : AppColors.mutedForeground,
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: selected ? AppColors.primary : AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        option(
          'singles',
          context.tr('فردي'),
          Icons.sync_alt,
          context.tr('تبديل الشركاء'),
        ),
        const SizedBox(width: AppSizes.md),
        option(
          'teams',
          context.tr('فرق'),
          Icons.groups,
          context.tr('فرق ثابتة'),
        ),
      ],
    );
  }

  Widget _teamSelector() {
    Widget chip(int team) {
      final selected = _creatorTeam == team;
      // Fixed-width chips wrap onto several rows once there are many teams.
      return SizedBox(
        width: 104,
        child: GestureDetector(
          onTap: () => setState(() => _creatorTeam = team),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              context.trArgs('الفريق {n}', {'n': team}),
              style: AppTextStyles.bodySmall.copyWith(
                color: selected ? AppColors.primary : AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: AppSizes.md,
      runSpacing: AppSizes.md,
      children: [
        if (_teamCount >= kMinTeams)
          for (var team = 1; team <= _teamCount; team++) chip(team),
      ],
    );
  }

  /// عدد الفرق المشاركة (لاعبان لكل فريق) — إدخال حر (2 فأكثر بلا سقف).
  /// تقليصه يعيد المنشئ لفريق موجود.
  Widget _teamCountField() {
    return TextField(
      controller: _teamCountCtrl,
      keyboardType: TextInputType.number,
      style: AppTextStyles.body.copyWith(color: AppColors.secondary),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.groups_outlined, color: AppColors.primary),
        hintText: context.tr('2 فأكثر'),
        errorText: _teamCount < kMinTeams
            ? context.trArgs('أقل عدد الفرق هو {n}', {'n': kMinTeams})
            : null,
      ),
      onChanged: (value) {
        final count = int.tryParse(value.trim()) ?? 0;
        setState(() {
          _teamCount = count;
          if (_creatorTeam > _teamCount && _teamCount >= 1) {
            _creatorTeam = _teamCount;
          }
        });
      },
    );
  }

  /// ما يهمّ صاحب الملعب معرفته قبل الإنشاء: لا خصم عليه، والحصص تصله.
  Widget _hostNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: AppSizes.iconSm,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              context.tr(
                'لا يُخصم منك شيء — كل لاعب يدفع حصته وتصلك مباشرةً بعد خصم نسبة سبورتا.',
              ),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _partnerField() {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: _pickPartner,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              const Icon(
                Icons.person_add_alt_1_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Text(
                  _partner?.name ??
                      context.tr('اختر صديقاً لدعوته (يمكنك تخطّيه)'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _partner == null
                        ? AppColors.mutedForeground
                        : AppColors.secondary,
                  ),
                ),
              ),
              if (_partner != null)
                GestureDetector(
                  onTap: () => setState(() => _partner = null),
                  child: const Icon(
                    Icons.close,
                    size: AppSizes.iconSm,
                    color: AppColors.mutedForeground,
                  ),
                )
              else
                DirectionalIcon(
                  rtl: Icons.chevron_left,
                  ltr: Icons.chevron_right,
                  color: AppColors.mutedForeground,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _courtDropdown() {
    return DropdownButtonFormField<CourtEntity>(
      initialValue: _court,
      isExpanded: true,
      hint: Text(
        _loadingCourts
            ? context.tr('جاري التحميل...')
            : context.tr('اختر الملعب'),
      ),
      items: [
        for (final c in _courts)
          DropdownMenuItem(value: c, child: Text('${c.name} - ${c.city}')),
      ],
      onChanged: (v) {
        setState(() {
          _court = v;
          _time = null;
        });
        _loadSlots();
      },
    );
  }

  /// اختيار المدة: شبكة مفتوحة من المدد لا تقتصر على مدد الملعب المسعّرة.
  /// تغييرها يعيد جلب الأوقات، فتظهر مواعيد الملعب بهذه المدة كاملة.
  Widget _durationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // ثلاثة خيارات في السطر مهما اتسعت الشاشة.
            final width = (constraints.maxWidth - AppSizes.md * 2) / 3;
            return Wrap(
              spacing: AppSizes.md,
              runSpacing: AppSizes.md,
              children: [
                for (final minutes in kAmericanoDurations)
                  SizedBox(
                    width: width,
                    child: CreateMatchChoiceButton(
                      label: context.trArgs('{p0} دقيقة', {'p0': minutes}),
                      selected: _duration == minutes,
                      onTap: () {
                        if (_duration == minutes) return;
                        setState(() {
                          _duration = minutes;
                          // الوقت المختار قد لا يبقى متاحاً بالمدة الجديدة.
                          _time = null;
                        });
                        _loadSlots();
                      },
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          context.tr('تظهر أوقات الملعب المتاحة بهذه المدة كاملة'),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }

  /// سطر صريح تحت شبكة الأوقات: هل الموعد المختار متاح في هذا الملعب أم لا،
  /// ولماذا. مع البطولة متعددة الأيام يشمل الحكم أيامها كلها.
  Widget _slotStatusNote() {
    final status = _slotStatus;
    if (status == _SlotStatus.none) return const SizedBox.shrink();

    final time = _selectedSlotTime ?? '';
    final days = _rangeDays;
    final multiDay = days > 1;

    late final IconData icon;
    late final Color color;
    late final String text;

    switch (status) {
      case _SlotStatus.checking:
        icon = Icons.hourglass_empty;
        color = AppColors.mutedForeground;
        text = context.tr('جارٍ التحقق من توفّر الموعد في الملعب…');
      case _SlotStatus.available:
        icon = Icons.check_circle_outline;
        color = AppColors.success;
        text = multiDay
            ? context.trArgs(
                'الموعد {p0} متاح في {p1} في كل أيام البطولة ({p2} أيام)',
                {'p0': time, 'p1': _court?.name ?? '', 'p2': days},
              )
            : context.trArgs('الموعد {p0} متاح في {p1}', {
                'p0': time,
                'p1': _court?.name ?? '',
              });
      case _SlotStatus.booked:
        icon = Icons.cancel_outlined;
        color = AppColors.destructive;
        text = multiDay
            ? context.trArgs(
                'الموعد {p0} محجوز في يوم أو أكثر من أيام البطولة — اختر موعداً آخر',
                {'p0': time},
              )
            : context.trArgs(
                'الموعد {p0} محجوز في هذا الملعب — اختر موعداً آخر',
                {'p0': time},
              );
      case _SlotStatus.outside:
        icon = Icons.error_outline;
        color = AppColors.destructive;
        text = multiDay
            ? context.trArgs(
                'الموعد {p0} خارج دوام الملعب في يوم أو أكثر من أيام البطولة',
                {'p0': time},
              )
            : context.trArgs(
                'الموعد {p0} خارج أوقات الملعب المتاحة لهذه المدة',
                {'p0': time},
              );
      case _SlotStatus.closed:
        icon = Icons.event_busy_outlined;
        color = AppColors.destructive;
        text = multiDay
            ? context.tr('الملعب مغلق في أحد أيام البطولة — اختر مدى آخر')
            : context.tr('الملعب مغلق في هذا اليوم — اختر يوماً آخر');
      case _SlotStatus.none:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: AppSizes.iconMd),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField() {
    return _PickerTile(
      label: context.tr('التاريخ'),
      value: _date == null
          ? trg('اختر')
          : '${_date!.year}-${_date!.month}-${_date!.day}',
      icon: Icons.calendar_today_outlined,
      onTap: () async {
        final now = ksaNow();
        final picked = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: now,
          lastDate: now.add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() {
            _date = picked;
            _time = null;
          });
          _loadSlots();
        }
      },
    );
  }

  Widget _endDateField() {
    return _PickerTile(
      label: context.tr('تاريخ الانتهاء (اختياري — لبطولة عدة أيام)'),
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
          lastDate: start.add(const Duration(days: kMaxTournamentSpanDays)),
        );
        if (picked != null) {
          // المدى يحدد المواعيد المتاحة: الموعد يجب أن يكون فارغاً في كل
          // أيام البطولة، فتُعاد الأوقات بعد تغييره.
          setState(() => _endDate = picked);
          _loadSlots();
        }
      },
    );
  }

  Widget _timeField() {
    return _PickerTile(
      label: context.tr('الوقت'),
      value: _time == null ? context.tr('اختر') : _time!.format(context),
      icon: Icons.access_time,
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(ksaNow()),
        );
        if (picked != null) setState(() => _time = picked);
      },
    );
  }

  Widget _levelDropdown(int value, ValueChanged<int> onChanged) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      items: [
        for (var i = 1; i <= 7; i++)
          DropdownMenuItem(
            value: i,
            child: Text(context.trArgs('مستوى {p0}', {'p0': i})),
          ),
      ],
      onChanged: (v) => onChanged(v ?? value),
    );
  }

  /// عدد اللاعبين في النمط الفردي — إدخال حر (4 فأكثر بلا سقف). تقليصه يقصّ
  /// اللاعبين المختارين مسبقاً حتى لا يتجاوزوا المقاعد المتاحة.
  Widget _playerCountField() {
    return TextField(
      controller: _playerCountCtrl,
      keyboardType: TextInputType.number,
      style: AppTextStyles.body.copyWith(color: AppColors.secondary),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.groups_outlined, color: AppColors.primary),
        hintText: context.tr('4 فأكثر'),
        errorText: _playerCount < kMinSinglesPlayers
            ? context.trArgs('أقل عدد هو {n} لاعبين', {'n': kMinSinglesPlayers})
            : null,
      ),
      onChanged: (value) {
        final count = int.tryParse(value.trim()) ?? 0;
        setState(() {
          _playerCount = count;
          final seats = count - 1;
          if (seats >= 0 && _players.length > seats) {
            _players.removeRange(seats, _players.length);
          }
        });
      },
    );
  }

  Widget _playersField() {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: _pickPlayers,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              const Icon(Icons.group_add_outlined, color: AppColors.primary),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Text(
                  _players.isEmpty
                      ? context.trArgs(
                          'اختر حتى {p0} لاعباً (يمكن للآخرين الانضمام لاحقاً)',
                          {'p0': _playerCount - 1},
                        )
                      : _players.map((p) => p.name).join(context.tr('، ')),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _players.isEmpty
                        ? AppColors.mutedForeground
                        : AppColors.secondary,
                  ),
                ),
              ),
              DirectionalIcon(
                rtl: Icons.chevron_left,
                ltr: Icons.chevron_right,
                color: AppColors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSizes.sm),
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Row(
                children: [
                  Icon(icon, size: AppSizes.iconSm, color: AppColors.primary),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    value,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
