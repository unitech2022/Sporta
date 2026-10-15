/// حالة قائمة انتظار حدث كما يراها المستخدم الحالي (`WaitlistStatusDto`).
class WaitlistStatus {
  const WaitlistStatus({
    this.supported = false,
    this.isOpen = false,
    this.count = 0,
    this.position,
    this.offerActive = false,
    this.offerMinutesLeft,
    this.seatReservedForOthers = false,
    this.canJoin = false,
    this.offerWindowMinutes = 30,
  });

  /// للحدث قائمة انتظار (لا لأمريكانو الفرق ولا للبطولة).
  final bool supported;
  final bool isOpen;

  /// عدد المنتظرين.
  final int count;

  /// ترتيب المستخدم (1 = الأول)؛ null إن لم يكن في القائمة.
  final int? position;

  /// للمستخدم مقعد محجوز الآن ينتظر أن يطلب الانضمام.
  final bool offerActive;
  final int? offerMinutesLeft;

  /// مقعد شاغر لكنه محجوز لمن قبله في القائمة.
  final bool seatReservedForOthers;

  /// يستطيع التسجيل في القائمة الآن.
  final bool canJoin;

  /// مدة حجز المقعد لمن يأتي دوره (دقائق).
  final int offerWindowMinutes;

  bool get isWaiting => position != null;

  factory WaitlistStatus.fromJson(Map<String, dynamic> json) => WaitlistStatus(
    supported: json['supported'] == true,
    isOpen: json['isOpen'] == true,
    count: (json['count'] as num?)?.toInt() ?? 0,
    position: (json['position'] as num?)?.toInt(),
    offerActive: json['offerActive'] == true,
    offerMinutesLeft: (json['offerMinutesLeft'] as num?)?.toInt(),
    seatReservedForOthers: json['seatReservedForOthers'] == true,
    canJoin: json['canJoin'] == true,
    offerWindowMinutes: (json['offerWindowMinutes'] as num?)?.toInt() ?? 30,
  );
}
