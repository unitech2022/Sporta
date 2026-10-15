import '../../../../core/localization/tr_global.dart';
import '../../../matches/domain/entities/pending_result.dart';
import 'package:sporta_app/core/utils/server_time.dart';

/// A player inside an americano event/round.
class AmericanoPlayer {
  const AmericanoPlayer({
    required this.userId,
    required this.name,
    this.level,
    this.avatarUrl,
    this.team,
    this.status = 'approved',
    this.withdrawalRequested = false,
  });

  final int userId;
  final String name;
  final int? level;

  /// الصورة الشخصية (رابط نسبي) أو null.
  final String? avatarUrl;

  /// Fixed team number (1..teamCount) in a teams americano; null for singles.
  final int? team;

  /// "approved" (confirmed) | "pending" (join request awaiting the organizer)
  /// | "invited" (partner awaiting reply).
  final String status;

  /// طلب انسحاب متأخر ينتظر موافقة المنظّم (اللاعب ما زال عضواً).
  final bool withdrawalRequested;

  bool get isInvited => status == 'invited';

  /// طلب انضمام ينتظر موافقة المنظّم.
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';

  factory AmericanoPlayer.fromJson(Map<String, dynamic> json) =>
      AmericanoPlayer(
        userId: (json['userId'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        level: (json['level'] as num?)?.toInt(),
        avatarUrl: (json['avatarUrl']?.toString().isEmpty ?? true)
            ? null
            : json['avatarUrl'].toString(),
        team: (json['team'] as num?)?.toInt(),
        status: json['status']?.toString() ?? 'approved',
        withdrawalRequested: json['withdrawalRequested'] == true,
      );
}

/// One americano round (2 vs 2) with optional scores.
class AmericanoRoundEntity {
  const AmericanoRoundEntity({
    required this.id,
    required this.roundNumber,
    required this.team1,
    required this.team2,
    required this.team1Score,
    required this.team2Score,
    required this.isCompleted,
    this.pendingResult,
    this.isDisputed = false,
  });

  final int id;
  final int roundNumber;
  final List<AmericanoPlayer> team1;
  final List<AmericanoPlayer> team2;
  final int? team1Score;
  final int? team2Score;
  final bool isCompleted;

  /// نتيجة أدخلها أحد لاعبي الجولة وتنتظر تأكيد الفريق الآخر.
  final PendingResult? pendingResult;

  /// رُفضت نتيجة مقترحة — خلاف يحسمه المنظّم.
  final bool isDisputed;

  /// طرف اللاعب في الجولة (1 أو 2)، أو null إن لم يلعبها.
  int? sideOf(int userId) => team1.any((p) => p.userId == userId)
      ? 1
      : team2.any((p) => p.userId == userId)
      ? 2
      : null;

  factory AmericanoRoundEntity.fromJson(Map<String, dynamic> json) {
    List<AmericanoPlayer> team(String key) =>
        (json[key] as List?)
            ?.map((e) => AmericanoPlayer.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return AmericanoRoundEntity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      roundNumber: (json['roundNumber'] as num?)?.toInt() ?? 0,
      team1: team('team1'),
      team2: team('team2'),
      team1Score: (json['team1Score'] as num?)?.toInt(),
      team2Score: (json['team2Score'] as num?)?.toInt(),
      isCompleted: json['isCompleted'] == true,
      pendingResult: PendingResult.fromJson(json['pendingResult']),
      isDisputed: json['isDisputed'] == true,
    );
  }
}

/// One row of the americano standings.
class AmericanoStanding {
  const AmericanoStanding({
    required this.rank,
    required this.userId,
    required this.name,
    required this.points,
    required this.wins,
    required this.played,
  });

  final int rank;
  final int userId;
  final String name;
  final int points;
  final int wins;
  final int played;

  factory AmericanoStanding.fromJson(Map<String, dynamic> json) =>
      AmericanoStanding(
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        userId: (json['userId'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        points: (json['points'] as num?)?.toInt() ?? 0,
        wins: (json['wins'] as num?)?.toInt() ?? 0,
        played: (json['played'] as num?)?.toInt() ?? 0,
      );
}

/// An americano event with its rounds and standings.
class AmericanoEntity {
  const AmericanoEntity({
    required this.id,
    required this.matchId,
    this.isVenueHosted = false,
    this.matchStatus = 'open',
    required this.creatorId,
    required this.type,
    this.isTournament = false,
    this.endDate,
    this.name,
    this.format,
    required this.scheduledAt,
    this.durationMinutes = 90,
    required this.totalRounds,
    required this.maxPlayers,
    this.teamCount = 2,
    required this.isCompleted,
    required this.minLevel,
    required this.maxLevel,
    required this.venueName,
    required this.city,
    this.pricePerPlayer = 0,
    this.withdrawalFreeUntil,
    this.canWithdrawDirectly = true,
    required this.players,
    required this.rounds,
    required this.standings,
  });

  final int id;
  final int matchId;

  /// حدث يستضيفه صاحب الملعب — منظّمٌ لا لاعب، وله وحده زر الإلغاء.
  final bool isVenueHosted;

  /// pendingApproval | open | full | inProgress | completed | cancelled.
  final String matchStatus;
  bool get isCancelled => matchStatus == 'cancelled';

  /// الملغى والمنتهي والجاري لا يُنضمّ إليها ولا يُدعى.
  bool get isClosed =>
      isCancelled ||
      isCompleted ||
      matchStatus == 'completed' ||
      matchStatus == 'inProgress';

  /// The user who created the americano — only they may enter scores.
  final int creatorId;

  /// "singles" | "teams".
  final String type;

  /// بطولة — same americano system, but may span one or more days.
  final bool isTournament;

  /// Tournament last day; null for americano / one-day tournaments.
  final DateTime? endDate;

  /// اسم البطولة الإقصائية؛ null للأمريكانو.
  final String? name;

  /// 'groups' | 'knockout' للبطولة الإقصائية؛ null للأمريكانو والبطولة القديمة.
  final String? format;

  /// بطولة إقصائية (كأس العالم) — تُفتح صفحتها الخاصة لا صفحة الأمريكانو.
  bool get isKnockoutTournament => format != null;
  final DateTime scheduledAt;

  /// مدة اللقاء بالدقائق — نفسها في كل يوم من أيام البطولة.
  final int durationMinutes;
  final int totalRounds;
  final int maxPlayers;

  /// Number of fixed teams (2 players each) in a teams americano.
  final int teamCount;
  final bool isCompleted;
  final double minLevel;
  final double maxLevel;
  final String? venueName;
  final String? city;

  /// Share debited from the wallet on join; 0 for a court-less americano.
  final double pricePerPlayer;

  /// آخر لحظة للانسحاب بلا موافقة (الموعد ناقص 48 ساعة، بتوقيت التطبيق).
  final DateTime? withdrawalFreeUntil;

  /// الانسحاب الآن مباشر؛ وإلا يصير طلباً ينتظر المنظّم.
  final bool canWithdrawDirectly;

  /// طلبات انسحاب تنتظر موافقة المنظّم.
  List<AmericanoPlayer> get withdrawalRequests =>
      players.where((p) => p.isApproved && p.withdrawalRequested).toList();

  /// للمستخدم طلب انسحاب ينتظر المنظّم.
  bool hasWithdrawalRequest(int userId) => players.any(
    (p) => p.userId == userId && p.isApproved && p.withdrawalRequested,
  );

  /// يملك المستخدم الانسحاب: عضو معتمد ليس المنظّم، ولم يبدأ تسجيل الجولات
  /// والموعد لم يحن. (الخادم يتحقق من جديد.)
  bool canWithdraw(int userId) =>
      userId != 0 &&
      userId != creatorId &&
      players.any((p) => p.userId == userId && p.isApproved) &&
      !hasWithdrawalRequest(userId) &&
      !isClosed &&
      !rounds.any((r) => r.isCompleted || r.pendingResult != null) &&
      scheduledAt.isAfter(ksaNow());

  final List<AmericanoPlayer> players;
  final List<AmericanoRoundEntity> rounds;
  final List<AmericanoStanding> standings;

  String get typeLabel => isKnockoutTournament
      ? (name?.isNotEmpty == true ? name! : trg('بطولة'))
      : isTournament
      ? (type == 'teams' ? trg('بطولة فرق') : trg('بطولة فردي'))
      : (type == 'teams' ? trg('أمريكانو فرق') : trg('أمريكانو فردي'));
  bool get isTeams => type == 'teams';

  /// Tournament spanning more than one day.
  bool get isMultiDay =>
      isTournament && endDate != null && !_sameDay(endDate!, scheduledAt);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  int get completedRounds => rounds.where((r) => r.isCompleted).length;

  /// Confirmed members only (invited partners and pending requests don't count).
  List<AmericanoPlayer> get approvedPlayers =>
      players.where((p) => p.isApproved).toList();

  /// طلبات انضمام تنتظر موافقة المنظّم.
  List<AmericanoPlayer> get joinRequests =>
      players.where((p) => p.isPending).toList();

  /// للمستخدم طلب انضمام لم يُبتّ فيه.
  bool hasPendingRequest(int userId) =>
      players.any((p) => p.userId == userId && p.isPending);
  int get approvedCount => approvedPlayers.length;
  bool get isFull => approvedCount >= maxPlayers;
  int get openSpots => (maxPlayers - approvedCount).clamp(0, maxPlayers);
  bool hasPlayer(int userId) =>
      players.any((p) => p.userId == userId && !p.isInvited);

  /// لاعب معتمد في حدث قادم لم يُلغَ — يظهر له «أضف إلى التقويم».
  bool canAddToCalendar(int userId) =>
      players.any((p) => p.userId == userId && p.isApproved) &&
      !isCancelled &&
      !isCompleted &&
      scheduledAt.isAfter(ksaNow());

  /// Team numbers of a teams americano, in display order.
  List<int> get teams => [for (var i = 1; i <= teamCount; i++) i];

  /// All players (approved + invited) on a given fixed team.
  List<AmericanoPlayer> teamPlayers(int team) =>
      players.where((p) => p.team == team).toList();

  /// A team has room when fewer than 2 players (approved or invited) hold it.
  bool teamHasRoom(int team) => teamPlayers(team).length < 2;

  /// The pending partner invite addressed to [userId], if any.
  AmericanoPlayer? pendingInviteFor(int userId) {
    for (final p in players) {
      if (p.userId == userId && p.isInvited) return p;
    }
    return null;
  }

  factory AmericanoEntity.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) =>
        (json[key] as List?)
            ?.map((e) => f(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return AmericanoEntity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      matchId: (json['matchId'] as num?)?.toInt() ?? 0,
      isVenueHosted: json['isVenueHosted'] == true,
      creatorId: (json['creatorId'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? 'singles',
      isTournament: json['isTournament'] == true,
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? ''),
      name: json['name']?.toString(),
      format: json['format']?.toString(),
      scheduledAt:
          DateTime.tryParse(json['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 90,
      totalRounds: (json['totalRounds'] as num?)?.toInt() ?? 0,
      maxPlayers: (json['maxPlayers'] as num?)?.toInt() ?? 4,
      // Older responses have no teamCount — derive it from the roster size.
      teamCount:
          (json['teamCount'] as num?)?.toInt() ??
          (((json['maxPlayers'] as num?)?.toInt() ?? 4) ~/ 2),
      isCompleted: json['isCompleted'] == true,
      matchStatus: json['matchStatus']?.toString() ?? 'open',
      minLevel: (json['minLevel'] as num?)?.toDouble() ?? 1,
      maxLevel: (json['maxLevel'] as num?)?.toDouble() ?? 7,
      venueName: json['venueName'] == null
          ? null
          : localizedServerName(json['venueName'], json['venueNameEn']),
      city: json['city'] == null
          ? null
          : localizedServerName(json['city'], json['cityEn']),
      pricePerPlayer: (json['pricePerPlayer'] as num?)?.toDouble() ?? 0,
      withdrawalFreeUntil: DateTime.tryParse(
        json['withdrawalFreeUntil']?.toString() ?? '',
      ),
      canWithdrawDirectly: json['canWithdrawDirectly'] != false,
      players: list('players', AmericanoPlayer.fromJson),
      rounds: list('rounds', AmericanoRoundEntity.fromJson),
      standings: list('standings', AmericanoStanding.fromJson),
    );
  }
}
