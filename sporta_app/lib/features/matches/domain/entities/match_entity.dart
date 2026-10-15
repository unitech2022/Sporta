import '../../../../core/localization/tr_global.dart';
import 'pending_result.dart';
import 'package:sporta_app/core/utils/server_time.dart';

/// A player inside a match (from the backend `MatchDto.players`).
class MatchPlayerEntity {
  const MatchPlayerEntity({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.level,
    this.status = 'approved',
    this.team,
    this.withdrawalRequested = false,
    this.hasPaid = false,
    this.paidAmount,
  });

  final int userId;
  final String name;

  /// الصورة الشخصية للاعب (رابط نسبي من الخادم)، null إن لم يرفع صورة.
  final String? avatarUrl;

  final int? level;

  /// "pending" | "approved".
  final String status;

  /// فريق اللاعب (1 أو 2) بعد إدخال النتيجة؛ null قبلها.
  final int? team;

  /// طلب انسحاب متأخر ينتظر موافقة المنشئ.
  final bool withdrawalRequested;

  /// دفع اللاعب حصته (المدعو الذي لم يردّ بعد لم يدفع).
  final bool hasPaid;
  final double? paidAmount;

  /// Arabic initials derived from the name (e.g. "م.أ").
  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '؟';
    return parts.take(2).map((p) => p.substring(0, 1)).join('.');
  }

  factory MatchPlayerEntity.fromJson(Map<String, dynamic> json) {
    return MatchPlayerEntity(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      level: (json['level'] as num?)?.toInt(),
      status: json['status']?.toString() ?? 'approved',
      team: (json['team'] as num?)?.toInt(),
      withdrawalRequested: json['withdrawalRequested'] == true,
      hasPaid: json['hasPaid'] == true,
      paidAmount: (json['paidAmount'] as num?)?.toDouble(),
    );
  }
}

/// An open match (from the backend `MatchDto`).
class MatchEntity {
  const MatchEntity({
    required this.id,
    required this.creatorId,
    required this.matchType,
    required this.status,
    this.gender = 'male',
    required this.scheduledAt,
    required this.durationMinutes,
    required this.maxPlayers,
    required this.currentPlayers,
    required this.minLevel,
    required this.maxLevel,
    required this.pricePerPlayer,
    required this.team1Score,
    required this.team2Score,
    required this.notes,
    required this.venueName,
    required this.city,
    required this.neighborhood,
    required this.players,
    required this.hasJoined,
    this.isVenueHosted = false,
    this.hasPendingRequest = false,
    this.hasInvite = false,
    this.pendingCount = 0,
    this.paymentMode = 'share',
    this.creatorPaidFull = false,
    this.pendingResult,
    this.canConfirmResult = false,
    this.isResultDisputed = false,
    this.canResolveResult = false,
    this.withdrawalFreeUntil,
    this.canWithdrawDirectly = true,
    this.withdrawalRequested = false,
    this.withdrawalRequestCount = 0,
    this.isPrivate = false,
    this.canMakePublic = false,
    this.invitedPlayers = const [],
  });

  final int id;
  final int creatorId;

  /// Backend enum name, e.g. "social", "competitive", "americanteam".
  final String matchType;

  /// "Open" | "Full" | "InProgress" | "Completed" | "Cancelled".
  final String status;

  /// نوع اللاعبين المنضمين — "male" (رجال) | "female" (نساء).
  final String gender;

  final DateTime scheduledAt;
  final int durationMinutes;
  final int maxPlayers;
  final int currentPlayers;
  final double minLevel;
  final double maxLevel;

  /// حصة اللاعب — كسرية: ملعبٌ بريال واحد يقسَّم على أربعة = 0.26.
  final double pricePerPlayer;
  final int? team1Score;
  final int? team2Score;

  /// نتيجة أدخلها لاعب وتنتظر تأكيد لاعب من الفريق الآخر.
  final PendingResult? pendingResult;

  /// المستخدم الحالي في الفريق المقابل للمقترِح فيستطيع التأكيد/الرفض.
  final bool canConfirmResult;

  /// رُفضت نتيجة مقترحة ولم تُعتمد بعدها نتيجة — خلاف يحسمه المنظّم.
  final bool isResultDisputed;

  /// المستخدم هو المنظّم والنتيجة محل خلاف.
  final bool canResolveResult;

  final String? notes;
  final String? venueName;
  final String? city;
  final String? neighborhood;
  final List<MatchPlayerEntity> players;
  final bool hasJoined;

  /// حدث يستضيفه صاحب الملعب — يظهر له زر الإلغاء، ولا يُحسب لاعباً فيه.
  final bool isVenueHosted;

  /// The current user has a pending (unapproved) join request.
  final bool hasPendingRequest;

  /// The current user has a pending invitation to this match (must accept/decline).
  final bool hasInvite;

  /// Number of pending join requests (populated for the creator).
  final int pendingCount;

  /// "share" | "full".
  final String paymentMode;

  /// True when the creator paid the whole match and players join for free.
  final bool creatorPaidFull;

  /// آخر لحظة للانسحاب بلا موافقة (الموعد ناقص 24 ساعة، بتوقيت التطبيق).
  final DateTime? withdrawalFreeUntil;

  /// الانسحاب الآن مباشر؛ وإلا يصير طلباً ينتظر المنشئ.
  final bool canWithdrawDirectly;

  /// للمستخدم الحالي طلب انسحاب ينتظر المنشئ.
  final bool withdrawalRequested;

  /// عدد طلبات الانسحاب المعلّقة (للمنشئ).
  final int withdrawalRequestCount;

  /// مباراة خاصة: بدعوة المنظّم فقط ولا تظهر في البحث العام.
  final bool isPrivate;

  /// المنشئ يستطيع تحويل المباراة الخاصة إلى عامة.
  final bool canMakePublic;

  /// المدعوون الذين لم يردّوا بعد (لم يدفعوا) — للمنشئ وللأعضاء.
  final List<MatchPlayerEntity> invitedPlayers;

  /// هل يملك المستخدم الحالي الانسحاب: عضو معتمد ليس المنشئ، والمباراة لم
  /// تبدأ ولم تُدخل نتيجتها. (الخادم يتحقق من جديد.)
  bool canWithdraw(int currentUserId) =>
      hasJoined &&
      creatorId != currentUserId &&
      !withdrawalRequested &&
      const ['Open', 'Full', 'PendingApproval'].contains(status) &&
      team1Score == null &&
      pendingResult == null &&
      scheduledAt.isAfter(ksaNow());

  /// عضو معتمد في مباراة قادمة لم تُلغَ — يظهر له «أضف إلى التقويم».
  bool get canAddToCalendar =>
      hasJoined &&
      const ['Open', 'Full', 'InProgress'].contains(status) &&
      scheduledAt.isAfter(ksaNow());

  bool get isFull => currentPlayers >= maxPlayers;
  int get spotsLeft => (maxPlayers - currentPlayers).clamp(0, maxPlayers);

  bool get isWomen => gender == 'female';

  /// Arabic display label for the joiners' gender.
  String get genderLabel => isWomen ? trg('نساء') : trg('رجال');

  /// Arabic display label for the match type.
  String get typeLabel {
    switch (matchType) {
      case 'social':
        return trg('ودية فردي');
      case 'competitive':
        return trg('تحدي فرق');
      case 'training':
        return trg('تدريبية');
      case 'american':
        return trg('أمريكانو فردي');
      case 'americanteam':
        return trg('أمريكانو فرق');
      case 'event':
        return trg('حدث');
      case 'lesson':
        return trg('درس');
      default:
        return trg('مباراة مفتوحة');
    }
  }

  factory MatchEntity.fromJson(Map<String, dynamic> json) {
    return MatchEntity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      creatorId: (json['creatorId'] as num?)?.toInt() ?? 0,
      matchType: json['matchType']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Open',
      gender: json['gender']?.toString() ?? 'male',
      scheduledAt:
          DateTime.tryParse(json['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 90,
      maxPlayers: (json['maxPlayers'] as num?)?.toInt() ?? 4,
      currentPlayers: (json['currentPlayers'] as num?)?.toInt() ?? 0,
      minLevel: (json['minLevel'] as num?)?.toDouble() ?? 1,
      maxLevel: (json['maxLevel'] as num?)?.toDouble() ?? 7,
      pricePerPlayer: (json['pricePerPlayer'] as num?)?.toDouble() ?? 0,
      team1Score: (json['team1Score'] as num?)?.toInt(),
      team2Score: (json['team2Score'] as num?)?.toInt(),
      notes: json['notes']?.toString(),
      venueName: json['venueName'] == null
          ? null
          : localizedServerName(json['venueName'], json['venueNameEn']),
      city: json['city'] == null
          ? null
          : localizedServerName(json['city'], json['cityEn']),
      // الحي المختار من القائمة له اسم إنجليزي؛ وإلا يُعرض العنوان النصي.
      neighborhood: json['district'] != null
          ? localizedServerName(json['district'], json['districtEn'])
          : json['neighborhood']?.toString(),
      players:
          (json['players'] as List?)
              ?.map(
                (e) => MatchPlayerEntity.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      hasJoined: json['hasJoined'] == true,
      isVenueHosted: json['isVenueHosted'] == true,
      hasPendingRequest: json['hasPendingRequest'] == true,
      hasInvite: json['hasInvite'] == true,
      pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
      paymentMode: json['paymentMode']?.toString() ?? 'share',
      creatorPaidFull: json['creatorPaidFull'] == true,
      pendingResult: PendingResult.fromJson(json['pendingResult']),
      canConfirmResult: json['canConfirmResult'] == true,
      isResultDisputed: json['isResultDisputed'] == true,
      canResolveResult: json['canResolveResult'] == true,
      withdrawalFreeUntil: DateTime.tryParse(
        json['withdrawalFreeUntil']?.toString() ?? '',
      ),
      canWithdrawDirectly: json['canWithdrawDirectly'] != false,
      withdrawalRequested: json['withdrawalRequested'] == true,
      withdrawalRequestCount:
          (json['withdrawalRequestCount'] as num?)?.toInt() ?? 0,
      isPrivate: json['isPrivate'] == true,
      canMakePublic: json['canMakePublic'] == true,
      invitedPlayers:
          (json['invitedPlayers'] as List?)
              ?.map(
                (e) => MatchPlayerEntity.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }
}
