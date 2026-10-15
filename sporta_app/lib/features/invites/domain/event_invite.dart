/// ما يُدعى إليه الصديق.
enum InviteKind {
  match('match'),
  americano('americano'),
  tournament('tournament');

  const InviteKind(this.wire);
  final String wire;
}

/// دعوة صديق إلى مباراة/أمريكانو/بطولة (لا تحجز مقعداً — المدعو ينضم بنفسه).
class EventInvite {
  const EventInvite({
    required this.id,
    required this.kind,
    required this.targetId,
    required this.senderName,
    required this.targetTitle,
    required this.expiresAt,
    required this.status,
    this.targetStartsAt,
  });

  final int id;
  final String kind;
  final int targetId;
  final String senderName;
  final String targetTitle;
  final DateTime expiresAt;
  final DateTime? targetStartsAt;

  /// pending | accepted | declined | expired.
  final String status;

  bool get isPending => status == 'pending';
  bool get isExpired => status == 'expired';
  bool get isDeclined => status == 'declined';

  factory EventInvite.fromJson(Map<String, dynamic> json) => EventInvite(
        id: (json['id'] as num?)?.toInt() ?? 0,
        kind: json['kind']?.toString() ?? 'match',
        targetId: (json['targetId'] as num?)?.toInt() ?? 0,
        senderName: json['senderName']?.toString() ?? '',
        targetTitle: json['targetTitle']?.toString() ?? '',
        expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '') ?? DateTime.now(),
        targetStartsAt: DateTime.tryParse(json['targetStartsAt']?.toString() ?? ''),
        status: json['status']?.toString() ?? 'pending',
      );
}

/// نتيجة الإرسال: كم أُرسل، ومن تُخطّي ولماذا.
class SendInviteResult {
  const SendInviteResult({required this.sent, required this.skipped});

  final int sent;

  /// (الاسم، السبب).
  final List<(String, String)> skipped;

  factory SendInviteResult.fromJson(Map<String, dynamic> json) => SendInviteResult(
        sent: (json['sent'] as num?)?.toInt() ?? 0,
        skipped: [
          for (final s in (json['skipped'] as List? ?? const []))
            ((s as Map)['name']?.toString() ?? '', s['reasonAr']?.toString() ?? ''),
        ],
      );
}
