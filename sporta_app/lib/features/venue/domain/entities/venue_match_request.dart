import '../../../../core/localization/tr_global.dart';

/// A match-hosting request on one of the owner's courts, awaiting approval.
class VenueMatchRequest {
  const VenueMatchRequest({
    required this.id,
    required this.courtName,
    required this.venueName,
    required this.creatorName,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.maxPlayers,
    required this.pricePerPlayer,
    required this.paymentMode,
    required this.amountHeld,
    required this.status,
    this.isVenueHosted = false,
    this.registeredPlayers = 0,
    this.kind = 'match',
    this.americanoId,
    this.title,
  });

  final int id;
  final String courtName;
  final String venueName;
  final String creatorName;
  final DateTime scheduledAt;
  final int durationMinutes;
  final int maxPlayers;

  /// Per-player share for this match.
  final double pricePerPlayer;

  /// "share" | "full" — whether the creator paid in full.
  final String paymentMode;

  /// Amount the creator paid up-front and is held until the owner responds.
  final double amountHeld;

  /// "Open" | "PendingApproval" | "Cancelled" | …
  final String status;

  /// حدث أنشأه صاحب الملعب على ملعبه — لا موافقة له، وله وحده إلغاؤه.
  final bool isVenueHosted;

  /// المسجّلون المعتمدون — تُردّ حصصهم عند الإلغاء.
  final int registeredPlayers;

  /// 'match' | 'americano' | 'tournament'.
  final String kind;

  /// معرّف الأمريكانو/البطولة لفتح صفحتها؛ null للمباراة العادية.
  final int? americanoId;

  /// اسم البطولة الإقصائية إن وُجد.
  final String? title;

  String get kindLabel => switch (kind) {
    'americano' => trg('أمريكانو'),
    'tournament' => trg('بطولة'),
    _ => trg('مباراة'),
  };

  bool get isFullPayment => paymentMode == 'full';

  String get paymentLabel => isFullPayment
      ? trg('دفع المنشئ كامل المباراة')
      : trg('كل لاعب يدفع حصته');

  factory VenueMatchRequest.fromJson(Map<String, dynamic> json) =>
      VenueMatchRequest(
        id: (json['id'] as num?)?.toInt() ?? 0,
        courtName: json['courtName']?.toString() ?? '',
        venueName: json['venueName']?.toString() ?? '',
        creatorName: json['creatorName']?.toString() ?? '',
        scheduledAt:
            DateTime.tryParse(json['scheduledAt']?.toString() ?? '') ??
            DateTime.now(),
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
        maxPlayers: (json['maxPlayers'] as num?)?.toInt() ?? 0,
        pricePerPlayer: (json['pricePerPlayer'] as num?)?.toDouble() ?? 0,
        paymentMode: json['paymentMode']?.toString() ?? 'share',
        amountHeld: (json['amountHeld'] as num?)?.toDouble() ?? 0,
        status: json['status']?.toString() ?? '',
        isVenueHosted: json['isVenueHosted'] == true,
        registeredPlayers: (json['registeredPlayers'] as num?)?.toInt() ?? 0,
        kind: json['kind']?.toString() ?? 'match',
        americanoId: (json['americanoId'] as num?)?.toInt(),
        title: json['title']?.toString(),
      );
}
