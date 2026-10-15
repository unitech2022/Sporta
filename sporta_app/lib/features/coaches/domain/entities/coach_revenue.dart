/// One bar in the revenue report's chart (a day of the week, or a week of the month).
class CoachRevenueBar {
  const CoachRevenueBar({required this.label, required this.amount});

  final String label;
  final double amount;

  factory CoachRevenueBar.fromJson(Map<String, dynamic> json) =>
      CoachRevenueBar(
        label: json['label']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );
}

/// One training-level's share of a revenue report period.
class CoachRevenueBreakdown {
  const CoachRevenueBreakdown({
    required this.label,
    required this.total,
    required this.percent,
    required this.sessionsCount,
  });

  final String label;
  final double total;

  /// Share of the period's total revenue, 0–100.
  final double percent;
  final int sessionsCount;

  factory CoachRevenueBreakdown.fromJson(Map<String, dynamic> json) =>
      CoachRevenueBreakdown(
        label: json['label']?.toString() ?? '',
        total: (json['total'] as num?)?.toDouble() ?? 0,
        percent: (json['percent'] as num?)?.toDouble() ?? 0,
        sessionsCount: (json['sessionsCount'] as num?)?.toInt() ?? 0,
      );
}

/// A single earning entry in a revenue report period.
class CoachRevenueTransaction {
  const CoachRevenueTransaction({
    required this.playerName,
    required this.targetLevel,
    required this.amount,
    required this.date,
  });

  final String playerName;
  final String targetLevel;
  final double amount;
  final DateTime date;

  factory CoachRevenueTransaction.fromJson(Map<String, dynamic> json) =>
      CoachRevenueTransaction(
        playerName: json['playerName']?.toString() ?? '',
        targetLevel: json['targetLevel']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        date:
            DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      );
}

/// A coach's earnings report for one period (month or week).
class CoachRevenueReport {
  const CoachRevenueReport({
    required this.periodType,
    required this.periodLabel,
    required this.total,
    required this.changePercent,
    required this.bars,
    required this.levelBreakdown,
    required this.transactions,
  });

  /// "month" | "week".
  final String periodType;
  final String periodLabel;
  final double total;

  /// % change vs. the preceding period (null if no data to compare against).
  final double? changePercent;
  final List<CoachRevenueBar> bars;
  final List<CoachRevenueBreakdown> levelBreakdown;
  final List<CoachRevenueTransaction> transactions;

  factory CoachRevenueReport.fromJson(
    Map<String, dynamic> json,
  ) => CoachRevenueReport(
    periodType: json['periodType']?.toString() ?? 'month',
    periodLabel: json['periodLabel']?.toString() ?? '',
    total: (json['total'] as num?)?.toDouble() ?? 0,
    changePercent: (json['changePercent'] as num?)?.toDouble(),
    bars:
        (json['bars'] as List?)
            ?.map((e) => CoachRevenueBar.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    levelBreakdown:
        (json['levelBreakdown'] as List?)
            ?.map(
              (e) => CoachRevenueBreakdown.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        const [],
    transactions:
        (json['transactions'] as List?)
            ?.map(
              (e) =>
                  CoachRevenueTransaction.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        const [],
  );
}
