/// نتيجة طلب الانسحاب من مباراة/أمريكانو/بطولة كما يعيدها الخادم.
enum WithdrawalOutcome {
  /// خرج اللاعب فعلاً: أُعيدت حصته وخُصمت نقاطه.
  withdrawn,

  /// بعد مهلة الانسحاب الحرّ: طلب ينتظر موافقة المنشئ.
  requested,

  /// كان طلب انضمام معلّقاً فأُلغي وأُعيدت حصته بلا خصم.
  requestCancelled;

  static WithdrawalOutcome parse(Object? raw) => switch (raw?.toString()) {
    'requested' => WithdrawalOutcome.requested,
    'requestCancelled' => WithdrawalOutcome.requestCancelled,
    _ => WithdrawalOutcome.withdrawn,
  };
}
