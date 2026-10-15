import '../../../core/localization/app_dates.dart';

/// A padel tournament shown on the player dashboard.
class TournamentEntity {
  const TournamentEntity({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.prizeLabel,
    required this.prizeAmount,
    required this.scope,
  });

  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String prizeLabel;
  final String prizeAmount;

  /// "international" | "local".
  final String scope;

  bool get isLocal => scope == 'local';

  /// Arabic date range, e.g. "15 - 20 يوليو 2026" or
  /// "28 يونيو - 2 يوليو 2026" across months.
  String get datesLabel {
    final s = startDate, e = endDate;
    final sMonth = AppDates.monthName(s.month);
    final eMonth = AppDates.monthName(e.month);
    if (s.month == e.month && s.year == e.year) {
      return '${s.day} - ${e.day} $sMonth ${s.year}';
    }
    return '${s.day} $sMonth - ${e.day} $eMonth ${e.year}';
  }

  factory TournamentEntity.fromJson(Map<String, dynamic> json) =>
      TournamentEntity(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        startDate:
            DateTime.tryParse(json['startDate']?.toString() ?? '') ??
                DateTime.now(),
        endDate: DateTime.tryParse(json['endDate']?.toString() ?? '') ??
            DateTime.now(),
        location: json['location']?.toString() ?? '',
        prizeLabel: json['prizeLabel']?.toString() ?? '',
        prizeAmount: json['prizeAmount']?.toString() ?? '',
        scope: json['scope']?.toString() ?? 'international',
      );
}
