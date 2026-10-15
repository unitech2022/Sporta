/// نتيجة أدخلها لاعب وتنتظر تأكيد لاعب من الفريق الآخر (الخادم `PendingResultDto`).
/// تشترك فيها المباراة العادية وجولة الأمريكانو ومباراة البطولة.
class PendingResult {
  const PendingResult({
    required this.team1Score,
    required this.team2Score,
    required this.proposedById,
    required this.proposedByName,
    this.proposedBySide,
  });

  final int team1Score;
  final int team2Score;
  final int proposedById;
  final String proposedByName;

  /// طرف المقترِح في المباراة (1 أو 2) — يؤكد لاعب من الطرف الآخر.
  final int? proposedBySide;

  /// لاعب في [mySide] يستطيع التأكيد/الرفض إن كان في الطرف المقابل للمقترِح.
  bool canRespond(int? mySide) =>
      mySide != null && proposedBySide != null && mySide != proposedBySide;

  static PendingResult? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return PendingResult(
      team1Score: (json['team1Score'] as num?)?.toInt() ?? 0,
      team2Score: (json['team2Score'] as num?)?.toInt() ?? 0,
      proposedById: (json['proposedById'] as num?)?.toInt() ?? 0,
      proposedByName: json['proposedByName']?.toString() ?? '',
      proposedBySide: (json['proposedBySide'] as num?)?.toInt(),
    );
  }
}
