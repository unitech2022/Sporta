import '../../../../core/localization/tr_global.dart';
import '../../../../core/utils/server_time.dart';

/// One loyalty-points ledger entry.
class PointsTransactionEntity {
  const PointsTransactionEntity({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
    this.kind = 'reward',
  });

  final int id;

  /// Positive = earned, negative = redeemed/reversed/deducted.
  final int amount;

  /// 'reward' | 'level' — which balance this entry moved.
  final String kind;

  /// BookingConfirmed | MatchCompleted | CoachSessionConfirmed |
  /// SubscriptionBonus | ProfileBonus | Redeemed | AdminAdjustment | Reversal
  final String type;
  final String? description;
  final DateTime? createdAt;

  bool get isEarn => amount > 0;
  bool get isLevel => kind == 'level';

  factory PointsTransactionEntity.fromJson(Map<String, dynamic> json) =>
      PointsTransactionEntity(
        id: (json['id'] as num?)?.toInt() ?? 0,
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        kind: json['kind']?.toString() ?? 'reward',
        type: json['type']?.toString() ?? '',
        description: json['description']?.toString(),
        createdAt: parseServerUtc(json['createdAt']),
      );
}

/// Balance + redemption rules + the user's current multiplier.
class PointsSummaryEntity {
  const PointsSummaryEntity({
    required this.balance,
    required this.redeemPointsPerRiyal,
    required this.minRedeemPoints,
    required this.balanceValueSar,
    required this.earnPer10Sar,
    required this.matchReward,
    required this.multiplier,
    this.levelPoints = 0,
    this.levelCoachVerified = false,
    this.levelPointsRequireCoachVerification = true,
    this.rewardRules = const [],
    this.levelRules = const [],
  });

  /// صافي نقاط المستوى (قد تكون سالبة).
  final int levelPoints;

  /// هل اعتمد مدرب مستوى اللاعب (شرط دخول نظام نقاط المستوى)؟
  final bool levelCoachVerified;
  final bool levelPointsRequireCoachVerification;

  /// نقاط كل نشاط كما يضبطها الأدمن.
  final List<PointsRuleEntity> rewardRules;

  /// قواعد الفوز/الخسارة بحسب فرق المستوى.
  final List<PointsRuleEntity> levelRules;

  /// هل يمكن للاعب كسب نقاط مستوى الآن؟
  bool get levelPointsUnlocked =>
      !levelPointsRequireCoachVerification || levelCoachVerified;

  final int balance;

  /// How many points buy 1 SAR when redeeming.
  final int redeemPointsPerRiyal;
  final int minRedeemPoints;

  /// Cash value of the current balance (SAR).
  final double balanceValueSar;

  /// Points earned per 10 SAR of paid spend.
  final int earnPer10Sar;

  /// Points for completing a match.
  final int matchReward;

  /// Current earn multiplier (>1 for subscribers).
  final double multiplier;

  bool get canRedeem =>
      redeemPointsPerRiyal > 0 && balance >= minRedeemPoints;

  factory PointsSummaryEntity.fromJson(Map<String, dynamic> json) =>
      PointsSummaryEntity(
        balance: (json['balance'] as num?)?.toInt() ?? 0,
        redeemPointsPerRiyal:
            (json['redeemPointsPerRiyal'] as num?)?.toInt() ?? 0,
        minRedeemPoints: (json['minRedeemPoints'] as num?)?.toInt() ?? 0,
        balanceValueSar: (json['balanceValueSar'] as num?)?.toDouble() ?? 0,
        earnPer10Sar: (json['earnPer10Sar'] as num?)?.toInt() ?? 0,
        matchReward: (json['matchReward'] as num?)?.toInt() ?? 0,
        multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1,
        levelPoints: (json['levelPoints'] as num?)?.toInt() ?? 0,
        levelCoachVerified: json['levelCoachVerified'] == true,
        levelPointsRequireCoachVerification:
            json['levelPointsRequireCoachVerification'] != false,
        rewardRules: _rules(json['rewardRules']),
        levelRules: _rules(json['levelRules']),
      );

  static List<PointsRuleEntity> _rules(dynamic raw) => [
        for (final e in (raw as List? ?? const []))
          PointsRuleEntity.fromJson(e as Map<String, dynamic>),
      ];
}

/// قاعدة نقاط واحدة (مفتاح الإعداد + تسميتها + قيمتها).
class PointsRuleEntity {
  const PointsRuleEntity({
    required this.key,
    required this.labelAr,
    required this.labelEn,
    required this.points,
  });

  final String key;
  final String labelAr;
  final String labelEn;
  final int points;

  String get label => localizedServerName(labelAr, labelEn);

  factory PointsRuleEntity.fromJson(Map<String, dynamic> json) =>
      PointsRuleEntity(
        key: json['key']?.toString() ?? '',
        labelAr: json['labelAr']?.toString() ?? '',
        labelEn: json['labelEn']?.toString() ?? '',
        points: (json['points'] as num?)?.toInt() ?? 0,
      );
}

/// صف في لوحة المتصدرين.
class LeaderboardEntryEntity {
  const LeaderboardEntryEntity({
    required this.rank,
    required this.userId,
    required this.name,
    required this.points,
    this.avatarUrl,
    this.level,
    this.isMe = false,
  });

  final int rank;
  final int userId;
  final String name;
  final String? avatarUrl;
  final int? level;
  final int points;
  final bool isMe;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join('.');
  }

  factory LeaderboardEntryEntity.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntryEntity(
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        userId: (json['userId'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        avatarUrl: json['avatarUrl']?.toString(),
        level: (json['level'] as num?)?.toInt(),
        points: (json['points'] as num?)?.toInt() ?? 0,
        isMe: json['isMe'] == true,
      );
}

/// أعلى الحاصلين على النقاط لنوع وفترة، مع موقع المستخدم الحالي.
class LeaderboardEntity {
  const LeaderboardEntity({
    required this.kind,
    required this.period,
    required this.entries,
    this.me,
  });

  final String kind;
  final String period;
  final List<LeaderboardEntryEntity> entries;
  final LeaderboardEntryEntity? me;

  factory LeaderboardEntity.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntity(
        kind: json['kind']?.toString() ?? 'reward',
        period: json['period']?.toString() ?? 'all',
        entries: [
          for (final e in (json['entries'] as List? ?? const []))
            LeaderboardEntryEntity.fromJson(e as Map<String, dynamic>),
        ],
        me: json['me'] is Map<String, dynamic>
            ? LeaderboardEntryEntity.fromJson(json['me'] as Map<String, dynamic>)
            : null,
      );
}

/// مستوى من سُلَّم المستويات (3.0 مبتدئ … 7.0 محترف — نخبة).
class LevelDefinitionEntity {
  const LevelDefinitionEntity({
    required this.id,
    required this.value,
    required this.titleAr,
    required this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
  });

  final int id;
  final double value;
  final String titleAr;
  final String titleEn;
  final String? descriptionAr;
  final String? descriptionEn;

  String get title => localizedServerName(titleAr, titleEn);
  String get description =>
      localizedServerName(descriptionAr ?? '', descriptionEn ?? '');

  /// "3.0" / "4.5" — كما في الوثيقة.
  String get valueLabel => value.toStringAsFixed(1);

  factory LevelDefinitionEntity.fromJson(Map<String, dynamic> json) =>
      LevelDefinitionEntity(
        id: (json['id'] as num?)?.toInt() ?? 0,
        value: (json['value'] as num?)?.toDouble() ?? 0,
        titleAr: json['titleAr']?.toString() ?? '',
        titleEn: json['titleEn']?.toString() ?? '',
        descriptionAr: json['descriptionAr']?.toString(),
        descriptionEn: json['descriptionEn']?.toString(),
      );
}
