import 'venue_match_request.dart';
import '../../../../core/utils/server_time.dart';

/// One player inside a match request, as the venue owner sees them.
class VenueMatchPlayer {
  const VenueMatchPlayer({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.level,
    required this.hasPaid,
    required this.status,
    required this.isCreator,
    this.joinedAt,
  });

  final int userId;
  final String name;
  final String? avatarUrl;
  final int? level;

  /// Whether the player already paid their share.
  final bool hasPaid;

  /// "approved" | "pending" | "invited".
  final String status;

  final bool isCreator;
  final DateTime? joinedAt;

  bool get isApproved => status == 'approved';

  factory VenueMatchPlayer.fromJson(Map<String, dynamic> json) =>
      VenueMatchPlayer(
        userId: (json['userId'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        avatarUrl: json['avatarUrl']?.toString(),
        level: (json['level'] as num?)?.toInt(),
        hasPaid: json['hasPaid'] == true,
        status: json['status']?.toString() ?? 'approved',
        isCreator: json['isCreator'] == true,
        joinedAt: parseServerUtc(json['joinedAt']),
      );
}

/// The full match request behind a list card: players, creator contact and the
/// owner's payout. Extends [VenueMatchRequest] so the details page can render
/// the card fields before (and after) the detail request lands.
class VenueMatchRequestDetail extends VenueMatchRequest {
  const VenueMatchRequestDetail({
    required super.id,
    required super.courtName,
    required super.venueName,
    required super.creatorName,
    required super.scheduledAt,
    required super.durationMinutes,
    required super.maxPlayers,
    required super.pricePerPlayer,
    required super.paymentMode,
    required super.amountHeld,
    required super.status,
    required this.creatorId,
    required this.creatorPhone,
    this.creatorAvatarUrl,
    required this.matchType,
    required this.gender,
    required this.minLevel,
    required this.maxLevel,
    this.notes,
    this.createdAt,
    required this.players,
    required this.currentPlayers,
    required this.totalPrice,
    required this.sportaCommissionPercent,
    required this.ownerEarning,
  });

  final int creatorId;
  final String creatorPhone;
  final String? creatorAvatarUrl;

  /// "singles" | "doubles" | …
  final String matchType;

  /// نوع اللاعبين المنضمين — "male" | "female".
  final String gender;

  final double minLevel;
  final double maxLevel;
  final String? notes;
  final DateTime? createdAt;

  final List<VenueMatchPlayer> players;

  /// Approved players currently in the match.
  final int currentPlayers;

  /// Per-player share × max players.
  final double totalPrice;

  final double sportaCommissionPercent;

  /// صافي ما يستلمه المالك من المبلغ المحجوز عند القبول.
  final double ownerEarning;

  bool get isWomen => gender == 'female';

  factory VenueMatchRequestDetail.fromJson(Map<String, dynamic> json) =>
      VenueMatchRequestDetail(
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
        creatorId: (json['creatorId'] as num?)?.toInt() ?? 0,
        creatorPhone: json['creatorPhone']?.toString() ?? '',
        creatorAvatarUrl: json['creatorAvatarUrl']?.toString(),
        matchType: json['matchType']?.toString() ?? '',
        gender: json['gender']?.toString() ?? 'male',
        minLevel: (json['minLevel'] as num?)?.toDouble() ?? 0,
        maxLevel: (json['maxLevel'] as num?)?.toDouble() ?? 0,
        notes: json['notes']?.toString(),
        createdAt: parseServerUtc(json['createdAt']),
        players: (json['players'] as List? ?? [])
            .map((e) => VenueMatchPlayer.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentPlayers: (json['currentPlayers'] as num?)?.toInt() ?? 0,
        totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
        sportaCommissionPercent:
            (json['sportaCommissionPercent'] as num?)?.toDouble() ?? 0,
        ownerEarning: (json['ownerEarning'] as num?)?.toDouble() ?? 0,
      );
}
