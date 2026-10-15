import 'package:flutter/material.dart';

import '../../../core/localization/tr_global.dart';

/// التجربة التي يجري فيها التقييم — اسمها في المسار `/reviews/{name}/{id}`.
enum ReviewContext {
  match('match'),
  booking('booking'),
  session('session');

  const ReviewContext(this.apiName);
  final String apiName;

  static ReviewContext parse(String? v) => switch (v) {
    'booking' => ReviewContext.booking,
    'session' => ReviewContext.session,
    _ => ReviewContext.match,
  };
}

/// ما يُقيَّم: player | coach | court.
enum ReviewTargetType {
  player('player'),
  coach('coach'),
  court('court');

  const ReviewTargetType(this.apiName);
  final String apiName;

  static ReviewTargetType parse(String? v) => switch (v) {
    'coach' => ReviewTargetType.coach,
    'court' => ReviewTargetType.court,
    _ => ReviewTargetType.player,
  };
}

/// جانب يُختار مع النجوم — معناه يتبع النجوم: ٤ فأكثر ثناء، وما دونها
/// «يحتاج تحسين». المفاتيح نفسها المسموح بها في الخادم لكل نوع هدف.
class ReviewTag {
  const ReviewTag(this.key, this.praise, this.improve, this.icon);

  final String key;
  final String praise;
  final String improve;
  final IconData icon;

  String labelFor(int score) => score >= 4 ? praise : improve;

  static const List<ReviewTag> court = [
    ReviewTag('clean', 'نظيف', 'النظافة', Icons.cleaning_services_outlined),
    ReviewTag('lighting', 'إضاءة ممتازة', 'الإضاءة', Icons.lightbulb_outline),
    ReviewTag('surface', 'أرضية ممتازة', 'الأرضية', Icons.texture),
    ReviewTag('staff', 'تعامل راقٍ', 'تعامل الموظفين', Icons.support_agent),
    ReviewTag('parking', 'مواقف متوفرة', 'المواقف', Icons.local_parking),
    ReviewTag('value', 'سعر مناسب', 'السعر', Icons.sell_outlined),
    ReviewTag('amenities', 'مرافق جيدة', 'المرافق', Icons.wc_outlined),
  ];

  static const List<ReviewTag> player = [
    ReviewTag('punctual', 'ملتزم بالموعد', 'الالتزام بالموعد', Icons.schedule),
    ReviewTag(
      'sportsmanship',
      'روح رياضية',
      'الروح الرياضية',
      Icons.handshake_outlined,
    ),
    ReviewTag(
      'level_accurate',
      'مستواه مطابق',
      'المستوى غير مطابق',
      Icons.equalizer,
    ),
    ReviewTag('respectful', 'محترم', 'الاحترام', Icons.favorite_border),
    ReviewTag(
      'facility_care',
      'يحافظ على الملعب',
      'المحافظة على الملعب',
      Icons.eco_outlined,
    ),
  ];

  static const List<ReviewTag> coach = [
    ReviewTag('punctual', 'ملتزم بالموعد', 'الالتزام بالموعد', Icons.schedule),
    ReviewTag(
      'clear',
      'شرح واضح',
      'وضوح الشرح',
      Icons.record_voice_over_outlined,
    ),
    ReviewTag(
      'professional',
      'احترافي',
      'الاحترافية',
      Icons.workspace_premium_outlined,
    ),
    ReviewTag(
      'motivating',
      'محفّز',
      'التحفيز',
      Icons.local_fire_department_outlined,
    ),
    ReviewTag('value', 'سعر مناسب', 'السعر', Icons.sell_outlined),
  ];

  static List<ReviewTag> forType(ReviewTargetType t) => switch (t) {
    ReviewTargetType.court => court,
    ReviewTargetType.coach => coach,
    ReviewTargetType.player => player,
  };

  static ReviewTag? find(ReviewTargetType t, String key) {
    for (final tag in forType(t)) {
      if (tag.key == key) return tag;
    }
    return null;
  }
}

/// وصف النجوم: 1 سيئ … 5 ممتاز (مفاتيح ترجمة عربية).
String reviewScoreLabel(int score) => switch (score) {
  1 => 'سيئ',
  2 => 'مقبول',
  3 => 'جيد',
  4 => 'جيد جداً',
  5 => 'ممتاز',
  _ => '',
};

DateTime? _date(dynamic v) => DateTime.tryParse(v?.toString() ?? '');

class ReviewItem {
  const ReviewItem({
    required this.id,
    required this.raterId,
    required this.raterName,
    required this.raterRole,
    required this.score,
    required this.tags,
    required this.createdAt,
    this.raterAvatarUrl,
    this.comment,
    this.updatedAt,
  });

  final int id;
  final int raterId;
  final String raterName;
  final String? raterAvatarUrl;

  /// player | coach | venue
  final String raterRole;
  final int score;
  final List<String> tags;
  final String? comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory ReviewItem.fromJson(Map<String, dynamic> j) => ReviewItem(
    id: (j['id'] as num).toInt(),
    raterId: (j['raterId'] as num?)?.toInt() ?? 0,
    raterName: j['raterName']?.toString() ?? '',
    raterAvatarUrl: j['raterAvatarUrl']?.toString(),
    raterRole: j['raterRole']?.toString() ?? 'player',
    score: (j['score'] as num?)?.toInt() ?? 0,
    tags: [for (final t in (j['tags'] as List? ?? const [])) t.toString()],
    comment: (j['comment']?.toString().trim().isEmpty ?? true)
        ? null
        : j['comment'].toString(),
    createdAt: _date(j['createdAt'])?.toLocal() ?? DateTime.now(),
    updatedAt: _date(j['updatedAt'])?.toLocal(),
  );
}

/// طرف يمكن تقييمه في التجربة.
class ReviewTarget {
  const ReviewTarget({
    required this.type,
    required this.id,
    required this.name,
    required this.role,
    this.imageUrl,
    this.myReview,
  });

  final ReviewTargetType type;
  final int id;
  final String name;
  final String? imageUrl;

  /// player | coach | court
  final String role;
  final ReviewItem? myReview;

  String get key => '${type.apiName}-$id';

  factory ReviewTarget.fromJson(Map<String, dynamic> j) => ReviewTarget(
    type: ReviewTargetType.parse(j['type']?.toString()),
    id: (j['id'] as num).toInt(),
    name: localizedServerName(j['name'], j['nameEn']),
    imageUrl: j['imageUrl']?.toString(),
    role: j['role']?.toString() ?? 'player',
    myReview: j['myReview'] is Map<String, dynamic>
        ? ReviewItem.fromJson(j['myReview'] as Map<String, dynamic>)
        : null,
  );
}

/// تجربة واحدة كما يراها المستخدم: ما يحقّ له تقييمه ومن قيّم.
class ReviewSession {
  const ReviewSession({
    required this.context,
    required this.contextId,
    required this.kind,
    required this.title,
    required this.canReview,
    required this.targets,
    required this.ratedCount,
    this.subtitle,
    this.imageUrl,
    this.startsAt,
    this.myRole,
    this.reason,
  });

  final ReviewContext context;
  final int contextId;

  /// match | americano | tournament | booking | session
  final String kind;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final DateTime? startsAt;

  /// player | coach | venue
  final String? myRole;
  final bool canReview;

  /// not_member | not_ended | cancelled | not_paid | not_confirmed | nothing
  final String? reason;
  final List<ReviewTarget> targets;
  final int ratedCount;

  bool get allRated => targets.isNotEmpty && ratedCount >= targets.length;

  factory ReviewSession.fromJson(Map<String, dynamic> j) => ReviewSession(
    context: ReviewContext.parse(j['context']?.toString()),
    contextId: (j['contextId'] as num).toInt(),
    kind: j['kind']?.toString() ?? 'match',
    title: localizedServerName(j['title'], j['titleEn']),
    subtitle: j['subtitle'] == null
        ? null
        : localizedServerName(j['subtitle'], j['subtitleEn']),
    imageUrl: j['imageUrl']?.toString(),
    startsAt: _date(j['startsAt']),
    myRole: j['myRole']?.toString(),
    canReview: j['canReview'] == true,
    reason: j['reason']?.toString(),
    targets: [
      for (final t in (j['targets'] as List? ?? const []))
        ReviewTarget.fromJson(t as Map<String, dynamic>),
    ],
    ratedCount: (j['ratedCount'] as num?)?.toInt() ?? 0,
  );
}

/// تجربة انتهت وفيها أطراف لم تُقيَّم بعد.
class PendingReview {
  const PendingReview({
    required this.context,
    required this.contextId,
    required this.kind,
    required this.title,
    required this.startsAt,
    required this.myRole,
    required this.pendingCount,
    this.subtitle,
    this.imageUrl,
  });

  final ReviewContext context;
  final int contextId;
  final String kind;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final DateTime startsAt;
  final String myRole;
  final int pendingCount;

  factory PendingReview.fromJson(Map<String, dynamic> j) => PendingReview(
    context: ReviewContext.parse(j['context']?.toString()),
    contextId: (j['contextId'] as num).toInt(),
    kind: j['kind']?.toString() ?? 'match',
    title: localizedServerName(j['title'], j['titleEn']),
    subtitle: j['subtitle'] == null
        ? null
        : localizedServerName(j['subtitle'], j['subtitleEn']),
    imageUrl: j['imageUrl']?.toString(),
    startsAt: _date(j['startsAt']) ?? DateTime.now(),
    myRole: j['myRole']?.toString() ?? 'player',
    pendingCount: (j['pendingCount'] as num?)?.toInt() ?? 0,
  );
}

class TagCount {
  const TagCount(this.tag, this.count);
  final String tag;
  final int count;

  static List<TagCount> listFrom(dynamic raw) => [
    for (final t in (raw as List? ?? const []))
      TagCount(
        (t as Map)['tag'].toString(),
        (t['count'] as num?)?.toInt() ?? 0,
      ),
  ];
}

Map<int, int> _distribution(dynamic raw) {
  final dist = <int, int>{};
  if (raw is Map) {
    raw.forEach((k, v) {
      final key = int.tryParse(k.toString());
      if (key != null) dist[key] = (v as num?)?.toInt() ?? 0;
    });
  }
  return dist;
}

/// ملخّص تقييمات ملعب + صفحة مراجعات.
class CourtRatingsSummary {
  const CourtRatingsSummary({
    required this.average,
    required this.count,
    required this.distribution,
    required this.topPraised,
    required this.reviews,
    required this.page,
    required this.hasMore,
  });

  final double average;
  final int count;
  final Map<int, int> distribution;
  final List<TagCount> topPraised;
  final List<ReviewItem> reviews;
  final int page;
  final bool hasMore;

  factory CourtRatingsSummary.fromJson(Map<String, dynamic> j) {
    final rev = j['reviews'] as Map<String, dynamic>? ?? const {};
    return CourtRatingsSummary(
      average: (j['average'] as num?)?.toDouble() ?? 0,
      count: (j['count'] as num?)?.toInt() ?? 0,
      distribution: _distribution(j['distribution']),
      topPraised: TagCount.listFrom(j['topPraised']),
      reviews: [
        for (final r in (rev['items'] as List? ?? const []))
          ReviewItem.fromJson(r as Map<String, dynamic>),
      ],
      page: (rev['page'] as num?)?.toInt() ?? 1,
      hasMore: rev['hasMore'] == true,
    );
  }
}

/// سمعة لاعب: متوسط ما منحه إياه اللاعبون والمدربون وأصحاب الملاعب.
class PlayerReputation {
  const PlayerReputation({
    required this.average,
    required this.count,
    required this.distribution,
    required this.topPraised,
    required this.byRole,
  });

  final double average;
  final int count;
  final Map<int, int> distribution;
  final List<TagCount> topPraised;

  /// player | coach | venue → العدد
  final Map<String, int> byRole;

  factory PlayerReputation.fromJson(Map<String, dynamic> j) => PlayerReputation(
    average: (j['average'] as num?)?.toDouble() ?? 0,
    count: (j['count'] as num?)?.toInt() ?? 0,
    distribution: _distribution(j['distribution']),
    topPraised: TagCount.listFrom(j['topPraised']),
    byRole: {
      for (final e in ((j['byRole'] as Map?) ?? const {}).entries)
        e.key.toString(): (e.value as num?)?.toInt() ?? 0,
    },
  );
}

/// تقييم واحد يُرسل ضمن دفعة.
class ReviewDraft {
  const ReviewDraft({
    required this.type,
    required this.id,
    required this.score,
    this.tags = const [],
    this.comment,
  });

  final ReviewTargetType type;
  final int id;
  final int score;
  final List<String> tags;
  final String? comment;

  Map<String, dynamic> toJson() => {
    'type': type.apiName,
    'id': id,
    'score': score,
    'tags': tags,
    if (comment != null && comment!.trim().isNotEmpty)
      'comment': comment!.trim(),
  };
}
