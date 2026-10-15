import '../../../../core/localization/tr_global.dart';

/// A booking row shown on the venue dashboard.
class VenueBooking {
  const VenueBooking({
    required this.id,
    required this.courtName,
    required this.venueName,
    required this.playerName,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    this.courtType = 'indoor',
  });

  final int id;
  final String courtName;
  final String venueName;
  final String playerName;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;

  /// "indoor" | "outdoor".
  final String courtType;

  /// "Pending" | "Confirmed" | "Cancelled" | "Completed".
  final String status;

  String get courtTypeLabel =>
      courtType == 'outdoor' ? trg('خارجي') : trg('داخلي');

  factory VenueBooking.fromJson(Map<String, dynamic> json) => VenueBooking(
    id: (json['id'] as num?)?.toInt() ?? 0,
    courtName: json['courtName']?.toString() ?? '',
    venueName: json['venueName']?.toString() ?? '',
    playerName: json['playerName']?.toString() ?? '',
    startTime:
        DateTime.tryParse(json['startTime']?.toString() ?? '') ??
        DateTime.now(),
    endTime:
        DateTime.tryParse(json['endTime']?.toString() ?? '') ?? DateTime.now(),
    totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
    courtType: json['courtType']?.toString() ?? 'indoor',
    status: json['status']?.toString() ?? '',
  );
}

/// A court's live status right now, for the owner's home dashboard.
class CourtLiveStatus {
  const CourtLiveStatus({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.timeRangeLabel,
  });

  final int id;
  final String name;

  /// "indoor" | "outdoor".
  final String type;

  /// "booked" | "available" | "maintenance".
  final String status;

  /// e.g. "4:00 - 5:30 م" — set only when [status] is "booked".
  final String? timeRangeLabel;

  factory CourtLiveStatus.fromJson(Map<String, dynamic> json) =>
      CourtLiveStatus(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        type: json['type']?.toString() ?? 'indoor',
        status: json['status']?.toString() ?? 'available',
        timeRangeLabel: json['timeRangeLabel']?.toString(),
      );
}

/// Venue-owner home dashboard stats.
class VenueDashboard {
  const VenueDashboard({
    required this.venuesCount,
    required this.courtsCount,
    required this.todayBookings,
    required this.monthRevenue,
    required this.recentBookings,
    this.weekRevenue = 0,
    this.bookingRatePercent = 0,
    this.liveCourtStatuses = const [],
    this.upcomingBookings = const [],
    this.weekBookingsCount = 0,
    this.weekPlayHours = 0,
    this.weekAvgHourlyPrice = 0,
  });

  final int venuesCount;
  final int courtsCount;
  final int todayBookings;
  final double monthRevenue;
  final double weekRevenue;

  /// Today's booked hours ÷ total bookable hours across all owned courts, 0–100.
  final double bookingRatePercent;
  final List<VenueBooking> recentBookings;
  final List<CourtLiveStatus> liveCourtStatuses;

  /// Future confirmed bookings, nearest first.
  final List<VenueBooking> upcomingBookings;

  final int weekBookingsCount;
  final double weekPlayHours;
  final double weekAvgHourlyPrice;

  factory VenueDashboard.fromJson(Map<String, dynamic> json) => VenueDashboard(
    venuesCount: (json['venuesCount'] as num?)?.toInt() ?? 0,
    courtsCount: (json['courtsCount'] as num?)?.toInt() ?? 0,
    todayBookings: (json['todayBookings'] as num?)?.toInt() ?? 0,
    monthRevenue: (json['monthRevenue'] as num?)?.toDouble() ?? 0,
    weekRevenue: (json['weekRevenue'] as num?)?.toDouble() ?? 0,
    bookingRatePercent: (json['bookingRatePercent'] as num?)?.toDouble() ?? 0,
    recentBookings:
        (json['recentBookings'] as List?)
            ?.map((e) => VenueBooking.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    liveCourtStatuses:
        (json['liveCourtStatuses'] as List?)
            ?.map((e) => CourtLiveStatus.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    upcomingBookings:
        (json['upcomingBookings'] as List?)
            ?.map((e) => VenueBooking.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    weekBookingsCount: (json['weekBookingsCount'] as num?)?.toInt() ?? 0,
    weekPlayHours: (json['weekPlayHours'] as num?)?.toDouble() ?? 0,
    weekAvgHourlyPrice: (json['weekAvgHourlyPrice'] as num?)?.toDouble() ?? 0,
  );
}

/// One bar in the revenue report's chart (a day of the week, or a week of the month).
class RevenueBar {
  const RevenueBar({required this.label, required this.amount});

  final String label;
  final double amount;

  factory RevenueBar.fromJson(Map<String, dynamic> json) => RevenueBar(
    label: json['label']?.toString() ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
  );
}

/// A single court's share of a revenue report period.
class CourtRevenue {
  const CourtRevenue({
    required this.courtName,
    required this.total,
    required this.percent,
    required this.bookingsCount,
  });

  final String courtName;
  final double total;

  /// Share of the period's total revenue, 0–100.
  final double percent;
  final int bookingsCount;

  factory CourtRevenue.fromJson(Map<String, dynamic> json) => CourtRevenue(
    courtName: json['courtName']?.toString() ?? '',
    total: (json['total'] as num?)?.toDouble() ?? 0,
    percent: (json['percent'] as num?)?.toDouble() ?? 0,
    bookingsCount: (json['bookingsCount'] as num?)?.toInt() ?? 0,
  );
}

/// A single earning entry in a revenue report period.
class RevenueTransaction {
  const RevenueTransaction({
    required this.courtName,
    required this.timeRangeLabel,
    required this.playerName,
    required this.amount,
    required this.date,
  });

  final String courtName;
  final String timeRangeLabel;
  final String playerName;
  final double amount;
  final DateTime date;

  factory RevenueTransaction.fromJson(Map<String, dynamic> json) =>
      RevenueTransaction(
        courtName: json['courtName']?.toString() ?? '',
        timeRangeLabel: json['timeRangeLabel']?.toString() ?? '',
        playerName: json['playerName']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        date:
            DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      );
}

/// A venue owner's financial report for one period (month or week).
class VenueRevenueReport {
  const VenueRevenueReport({
    required this.periodType,
    required this.periodLabel,
    required this.total,
    required this.changePercent,
    required this.bars,
    required this.courtBreakdown,
    required this.transactions,
  });

  /// "month" | "week".
  final String periodType;
  final String periodLabel;
  final double total;

  /// % change vs. the preceding period (null if no data to compare against).
  final double? changePercent;
  final List<RevenueBar> bars;
  final List<CourtRevenue> courtBreakdown;
  final List<RevenueTransaction> transactions;

  factory VenueRevenueReport.fromJson(Map<String, dynamic> json) =>
      VenueRevenueReport(
        periodType: json['periodType']?.toString() ?? 'month',
        periodLabel: json['periodLabel']?.toString() ?? '',
        total: (json['total'] as num?)?.toDouble() ?? 0,
        changePercent: (json['changePercent'] as num?)?.toDouble(),
        bars:
            (json['bars'] as List?)
                ?.map((e) => RevenueBar.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        courtBreakdown:
            (json['courtBreakdown'] as List?)
                ?.map((e) => CourtRevenue.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        transactions:
            (json['transactions'] as List?)
                ?.map(
                  (e) => RevenueTransaction.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            const [],
      );
}
