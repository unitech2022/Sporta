import '../../../../core/localization/tr_global.dart';
import '../../../americano/domain/entities/americano_entity.dart';
import '../../../matches/domain/entities/pending_result.dart';
import 'package:sporta_app/core/utils/server_time.dart';

/// فريق في بطولة إقصائية: رقمه ولاعباه ومجموعته بعد القرعة.
class CupTeam {
  const CupTeam({
    required this.number,
    required this.letter,
    required this.name,
    this.customName,
    this.playerNames = '',
    required this.players,
    required this.isComplete,
    this.groupIndex,
    this.groupLetter,
  });

  final int number;

  /// حرف الفريق الثابت: A، B، C…
  final String letter;

  /// الاسم المعروض: المخصّص إن وُجد وإلا الحرف.
  final String name;

  /// ما سمّاه به لاعبوه/المنظّم؛ null = الحرف.
  final String? customName;

  /// «فلان و فلان».
  final String playerNames;
  final List<AmericanoPlayer> players;
  final bool isComplete;
  final int? groupIndex;
  final String? groupLetter;

  bool get hasRoom => players.length < 2;

  factory CupTeam.fromJson(Map<String, dynamic> json) => CupTeam(
    number: (json['number'] as num?)?.toInt() ?? 0,
    letter: json['letter']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    customName: json['customName']?.toString(),
    playerNames: json['playerNames']?.toString() ?? '',
    players:
        (json['players'] as List?)
            ?.map((e) => AmericanoPlayer.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    isComplete: json['isComplete'] == true,
    groupIndex: (json['groupIndex'] as num?)?.toInt(),
    groupLetter: json['groupLetter']?.toString(),
  );
}

class CupGroupRow {
  const CupGroupRow({
    required this.position,
    required this.team,
    required this.name,
    this.playerNames = '',
    required this.played,
    required this.wins,
    required this.points,
    required this.diff,
    required this.qualified,
  });

  final int position;
  final int team;
  final String name;
  final String playerNames;
  final int played;
  final int wins;
  final int points;
  final int diff;
  final bool qualified;

  factory CupGroupRow.fromJson(Map<String, dynamic> json) => CupGroupRow(
    position: (json['position'] as num?)?.toInt() ?? 0,
    team: (json['team'] as num?)?.toInt() ?? 0,
    name: json['name']?.toString() ?? '',
    playerNames: json['playerNames']?.toString() ?? '',
    played: (json['played'] as num?)?.toInt() ?? 0,
    wins: (json['wins'] as num?)?.toInt() ?? 0,
    points: (json['points'] as num?)?.toInt() ?? 0,
    diff: (json['diff'] as num?)?.toInt() ?? 0,
    qualified: json['qualified'] == true,
  );
}

class CupGroup {
  const CupGroup({
    required this.index,
    required this.letter,
    required this.title,
    required this.standings,
    required this.played,
    required this.total,
  });

  final int index;
  final String letter;
  final String title;
  final List<CupGroupRow> standings;
  final int played;
  final int total;

  bool get isComplete => played >= total;

  factory CupGroup.fromJson(Map<String, dynamic> json) => CupGroup(
    index: (json['index'] as num?)?.toInt() ?? 0,
    letter: json['letter']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    standings:
        (json['standings'] as List?)
            ?.map((e) => CupGroupRow.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    played: (json['played'] as num?)?.toInt() ?? 0,
    total: (json['total'] as num?)?.toInt() ?? 0,
  );
}

/// مباراة في دور المجموعات أو في شجرة خروج المغلوب.
class CupFixture {
  const CupFixture({
    required this.id,
    required this.stage,
    required this.round,
    required this.roundName,
    required this.index,
    required this.title,
    required this.team1Name,
    required this.team2Name,
    this.team1Players = '',
    this.team2Players = '',
    required this.isCompleted,
    required this.isBye,
    required this.canScore,
    this.groupIndex,
    this.groupLetter,
    this.team1,
    this.team2,
    this.team1Placeholder,
    this.team2Placeholder,
    this.team1Score,
    this.team2Score,
    this.winnerTeam,
    this.courtId,
    this.courtName,
    this.scheduledAt,
    this.pendingResult,
    this.isDisputed = false,
  });

  final int id;

  /// 'group' | 'knockout'.
  final String stage;
  final int? groupIndex;
  final String? groupLetter;
  final int round;
  final String roundName;
  final int index;
  final String title;
  final int? team1;
  final int? team2;
  final String team1Name;
  final String team2Name;
  final String team1Players;
  final String team2Players;
  final String? team1Placeholder;
  final String? team2Placeholder;
  final int? team1Score;
  final int? team2Score;
  final bool isCompleted;
  final bool isBye;
  final int? winnerTeam;
  final bool canScore;
  final int? courtId;
  final String? courtName;
  final DateTime? scheduledAt;

  /// نتيجة أدخلها لاعب وتنتظر تأكيد لاعب من الفريق الآخر.
  final PendingResult? pendingResult;

  /// رُفضت نتيجة مقترحة — خلاف يحسمه المنظّم.
  final bool isDisputed;

  bool get isGroup => stage == 'group';
  bool get isReady => team1 != null && team2 != null;

  /// طرف فريق اللاعب في هذه المباراة (1 أو 2)، أو null إن لم يكن طرفاً فيها.
  int? sideOf(int? myTeam) => myTeam == null
      ? null
      : myTeam == team1
      ? 1
      : myTeam == team2
      ? 2
      : null;

  factory CupFixture.fromJson(Map<String, dynamic> json) => CupFixture(
    id: (json['id'] as num?)?.toInt() ?? 0,
    stage: json['stage']?.toString() ?? 'group',
    groupIndex: (json['groupIndex'] as num?)?.toInt(),
    groupLetter: json['groupLetter']?.toString(),
    round: (json['round'] as num?)?.toInt() ?? 1,
    roundName: json['roundName']?.toString() ?? '',
    index: (json['index'] as num?)?.toInt() ?? 0,
    title: json['title']?.toString() ?? '',
    team1: (json['team1'] as num?)?.toInt(),
    team2: (json['team2'] as num?)?.toInt(),
    team1Name: json['team1Name']?.toString() ?? '',
    team2Name: json['team2Name']?.toString() ?? '',
    team1Players: json['team1Players']?.toString() ?? '',
    team2Players: json['team2Players']?.toString() ?? '',
    team1Placeholder: json['team1Placeholder']?.toString(),
    team2Placeholder: json['team2Placeholder']?.toString(),
    team1Score: (json['team1Score'] as num?)?.toInt(),
    team2Score: (json['team2Score'] as num?)?.toInt(),
    isCompleted: json['isCompleted'] == true,
    isBye: json['isBye'] == true,
    winnerTeam: (json['winnerTeam'] as num?)?.toInt(),
    canScore: json['canScore'] == true,
    courtId: (json['courtId'] as num?)?.toInt(),
    courtName: json['courtName']?.toString(),
    scheduledAt: DateTime.tryParse(json['scheduledAt']?.toString() ?? ''),
    pendingResult: PendingResult.fromJson(json['pendingResult']),
    isDisputed: json['isDisputed'] == true,
  );
}

class CupRankingRow {
  const CupRankingRow({
    required this.rank,
    required this.team,
    required this.name,
    this.playerNames = '',
    required this.note,
  });

  final int rank;
  final int team;
  final String name;
  final String playerNames;
  final String note;

  factory CupRankingRow.fromJson(Map<String, dynamic> json) => CupRankingRow(
    rank: (json['rank'] as num?)?.toInt() ?? 0,
    team: (json['team'] as num?)?.toInt() ?? 0,
    name: json['name']?.toString() ?? '',
    playerNames: json['playerNames']?.toString() ?? '',
    note: json['note']?.toString() ?? '',
  );
}

class CupCourt {
  const CupCourt({required this.id, required this.name});

  final int id;
  final String name;

  factory CupCourt.fromJson(Map<String, dynamic> json) => CupCourt(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: localizedServerName(json['name'], json['nameEn']),
  );
}

/// تقدير قبل الإنشاء: المجموعات وعدد المباريات وسعة الجدول والسعر.
class CupQuote {
  const CupQuote({
    required this.teamCount,
    required this.groupCount,
    required this.knockoutSize,
    required this.bestThirds,
    required this.groupMatches,
    required this.knockoutMatches,
    required this.totalMatches,
    required this.slotCapacity,
    required this.fits,
    required this.pathText,
    required this.totalCourtPrice,
    required this.pricePerPlayer,
  });

  final int teamCount;
  final int groupCount;
  final int knockoutSize;
  final int bestThirds;
  final int groupMatches;
  final int knockoutMatches;
  final int totalMatches;
  final int slotCapacity;
  final bool fits;
  final String pathText;
  final double totalCourtPrice;
  final double pricePerPlayer;

  factory CupQuote.fromJson(Map<String, dynamic> json) => CupQuote(
    teamCount: (json['teamCount'] as num?)?.toInt() ?? 0,
    groupCount: (json['groupCount'] as num?)?.toInt() ?? 0,
    knockoutSize: (json['knockoutSize'] as num?)?.toInt() ?? 0,
    bestThirds: (json['bestThirds'] as num?)?.toInt() ?? 0,
    groupMatches: (json['groupMatches'] as num?)?.toInt() ?? 0,
    knockoutMatches: (json['knockoutMatches'] as num?)?.toInt() ?? 0,
    totalMatches: (json['totalMatches'] as num?)?.toInt() ?? 0,
    slotCapacity: (json['slotCapacity'] as num?)?.toInt() ?? 0,
    fits: json['fits'] == true,
    pathText: json['pathText']?.toString() ?? '',
    totalCourtPrice: (json['totalCourtPrice'] as num?)?.toDouble() ?? 0,
    pricePerPlayer: (json['pricePerPlayer'] as num?)?.toDouble() ?? 0,
  );
}

/// بطولة إقصائية كاملة: الفرق والمجموعات والشجرة والترتيب النهائي.
class CupEntity {
  const CupEntity({
    required this.id,
    required this.matchId,
    required this.creatorId,
    required this.name,
    required this.format,
    required this.status,
    required this.isVenueHosted,
    required this.isCompleted,
    required this.isDrawn,
    required this.scheduledAt,
    this.endDate,
    required this.durationMinutes,
    required this.matchMinutes,
    required this.teamCount,
    required this.completeTeamCount,
    required this.maxPlayers,
    required this.minLevel,
    required this.maxLevel,
    required this.pricePerPlayer,
    this.venueName,
    this.city,
    required this.courts,
    required this.groupCount,
    required this.knockoutSize,
    required this.bestThirds,
    required this.totalMatches,
    required this.playedMatches,
    required this.pathText,
    required this.players,
    required this.teams,
    required this.groups,
    required this.fixtures,
    required this.ranking,
    this.championTeam,
    this.championName,
    this.championPlayers,
    this.withdrawalFreeUntil,
    this.canWithdrawDirectly = true,
  });

  final int id;
  final int matchId;
  final int creatorId;
  final String name;

  /// آخر لحظة للانسحاب بلا موافقة (الموعد ناقص 48 ساعة، بتوقيت التطبيق).
  final DateTime? withdrawalFreeUntil;

  /// الانسحاب الآن مباشر؛ وإلا يصير طلباً ينتظر المنظّم.
  final bool canWithdrawDirectly;

  /// طلبات انسحاب تنتظر موافقة المنظّم.
  List<AmericanoPlayer> get withdrawalRequests =>
      players.where((p) => p.isApproved && p.withdrawalRequested).toList();

  bool hasWithdrawalRequest(int userId) => players.any(
    (p) => p.userId == userId && p.isApproved && p.withdrawalRequested,
  );

  /// يملك المستخدم الانسحاب: عضو معتمد ليس المنظّم، قبل القرعة والموعد.
  bool canWithdraw(int userId) =>
      userId != 0 &&
      userId != creatorId &&
      players.any((p) => p.userId == userId && p.isApproved) &&
      !hasWithdrawalRequest(userId) &&
      !isDrawn &&
      !isCancelled &&
      !isCompleted &&
      scheduledAt.isAfter(ksaNow());

  /// 'groups' | 'knockout'.
  final String format;

  /// pendingApproval | open | full | inProgress | completed | cancelled.
  final String status;
  final bool isVenueHosted;
  final bool isCompleted;
  final bool isDrawn;
  final DateTime scheduledAt;
  final DateTime? endDate;
  final int durationMinutes;
  final int matchMinutes;
  final int teamCount;
  final int completeTeamCount;
  final int maxPlayers;
  final double minLevel;
  final double maxLevel;
  final double pricePerPlayer;
  final String? venueName;
  final String? city;
  final List<CupCourt> courts;
  final int groupCount;
  final int knockoutSize;
  final int bestThirds;
  final int totalMatches;
  final int playedMatches;
  final String pathText;
  final List<AmericanoPlayer> players;
  final List<CupTeam> teams;
  final List<CupGroup> groups;
  final List<CupFixture> fixtures;
  final List<CupRankingRow> ranking;
  final int? championTeam;
  final String? championName;
  final String? championPlayers;

  /// يسمّي الفريقَ لاعبوه المعتمدون أو المنظّم، ما لم تُلغَ البطولة.
  bool canRename(CupTeam team, int userId) =>
      !isCancelled &&
      userId != 0 &&
      (creatorId == userId ||
          team.players.any((p) => p.userId == userId && !p.isInvited));

  bool get isGroupsFormat => format == 'groups';
  bool get isCancelled => status == 'cancelled';
  bool get isPendingApproval => status == 'pendingApproval';
  bool get isOpen => status == 'open' || status == 'full';
  String get formatLabel => isGroupsFormat
      ? trg('مجموعات + خروج المغلوب')
      : trg('خروج المغلوب مباشرة');

  bool hasPlayer(int userId) =>
      players.any((p) => p.userId == userId && !p.isInvited);

  /// لاعب معتمد في بطولة قادمة لم تُلغَ — يظهر له «أضف إلى التقويم».
  bool canAddToCalendar(int userId) =>
      players.any((p) => p.userId == userId && p.isApproved) &&
      !isCancelled &&
      !isCompleted &&
      scheduledAt.isAfter(ksaNow());

  /// مدة البطولة كاملة بالدقائق (حتى تاريخ نهايتها إن وُجد).
  int get calendarMinutes {
    final end = endDate;
    if (end != null && end.isAfter(scheduledAt)) {
      return end.difference(scheduledAt).inMinutes;
    }
    return durationMinutes;
  }

  /// طلبات انضمام تنتظر موافقة المنظّم.
  List<AmericanoPlayer> get joinRequests =>
      players.where((p) => p.isPending).toList();
  bool hasPendingRequest(int userId) =>
      players.any((p) => p.userId == userId && p.isPending);

  AmericanoPlayer? pendingInviteFor(int userId) {
    for (final p in players) {
      if (p.userId == userId && p.isInvited) return p;
    }
    return null;
  }

  /// فريق اللاعب إن كان مشاركاً.
  int? teamOf(int userId) {
    for (final p in players) {
      if (p.userId == userId) return p.team;
    }
    return null;
  }

  List<CupFixture> get groupFixtures =>
      fixtures.where((f) => f.isGroup).toList();
  List<CupFixture> get knockoutFixtures =>
      fixtures.where((f) => !f.isGroup).toList();

  /// أدوار الإقصائيات مرتّبة (1 = الأول).
  List<int> get knockoutRounds =>
      knockoutFixtures.map((f) => f.round).toSet().toList()..sort();

  /// المباريات المكتملة (بلا الإعفاءات) — تبويب النتائج.
  List<CupFixture> get completedFixtures =>
      fixtures.where((f) => f.isCompleted && !f.isBye).toList();

  factory CupEntity.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) =>
        (json[key] as List?)
            ?.map((e) => f(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return CupEntity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      matchId: (json['matchId'] as num?)?.toInt() ?? 0,
      creatorId: (json['creatorId'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      format: json['format']?.toString() ?? 'groups',
      status: json['status']?.toString() ?? 'open',
      isVenueHosted: json['isVenueHosted'] == true,
      isCompleted: json['isCompleted'] == true,
      isDrawn: json['isDrawn'] == true,
      scheduledAt:
          DateTime.tryParse(json['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? ''),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      matchMinutes: (json['matchMinutes'] as num?)?.toInt() ?? 60,
      teamCount: (json['teamCount'] as num?)?.toInt() ?? 0,
      completeTeamCount: (json['completeTeamCount'] as num?)?.toInt() ?? 0,
      maxPlayers: (json['maxPlayers'] as num?)?.toInt() ?? 0,
      minLevel: (json['minLevel'] as num?)?.toDouble() ?? 1,
      maxLevel: (json['maxLevel'] as num?)?.toDouble() ?? 7,
      pricePerPlayer: (json['pricePerPlayer'] as num?)?.toDouble() ?? 0,
      venueName: json['venueName'] == null
          ? null
          : localizedServerName(json['venueName'], json['venueNameEn']),
      city: json['city'] == null
          ? null
          : localizedServerName(json['city'], json['cityEn']),
      courts: list('courts', CupCourt.fromJson),
      groupCount: (json['groupCount'] as num?)?.toInt() ?? 0,
      knockoutSize: (json['knockoutSize'] as num?)?.toInt() ?? 0,
      bestThirds: (json['bestThirds'] as num?)?.toInt() ?? 0,
      totalMatches: (json['totalMatches'] as num?)?.toInt() ?? 0,
      playedMatches: (json['playedMatches'] as num?)?.toInt() ?? 0,
      pathText: json['pathText']?.toString() ?? '',
      players: list('players', AmericanoPlayer.fromJson),
      teams: list('teams', CupTeam.fromJson),
      groups: list('groups', CupGroup.fromJson),
      fixtures: list('fixtures', CupFixture.fromJson),
      ranking: list('ranking', CupRankingRow.fromJson),
      championTeam: (json['championTeam'] as num?)?.toInt(),
      championName: json['championName']?.toString(),
      championPlayers: json['championPlayers']?.toString(),
      withdrawalFreeUntil: DateTime.tryParse(
        json['withdrawalFreeUntil']?.toString() ?? '',
      ),
      canWithdrawDirectly: json['canWithdrawDirectly'] != false,
    );
  }
}
