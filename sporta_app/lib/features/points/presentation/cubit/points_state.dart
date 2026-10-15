part of 'points_cubit.dart';

enum PointsStatus { initial, loading, success, failure }

class PointsState extends Equatable {
  const PointsState({
    this.status = PointsStatus.initial,
    this.summary,
    this.transactions = const [],
    this.txPage = 0,
    this.txHasMore = false,
    this.loadingMore = false,
    this.redeeming = false,
    this.levels = const [],
    this.error,
  });

  /// سُلَّم المستويات (يُحمَّل مع الملخّص، best-effort).
  final List<LevelDefinitionEntity> levels;

  final PointsStatus status;
  final PointsSummaryEntity? summary;

  /// Ledger entries accumulated across pages (newest first).
  final List<PointsTransactionEntity> transactions;
  final int txPage;
  final bool txHasMore;
  final bool loadingMore;
  final bool redeeming;
  final String? error;

  PointsState copyWith({
    PointsStatus? status,
    PointsSummaryEntity? summary,
    List<PointsTransactionEntity>? transactions,
    int? txPage,
    bool? txHasMore,
    bool? loadingMore,
    bool? redeeming,
    List<LevelDefinitionEntity>? levels,
    String? error,
  }) {
    return PointsState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      transactions: transactions ?? this.transactions,
      txPage: txPage ?? this.txPage,
      txHasMore: txHasMore ?? this.txHasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      redeeming: redeeming ?? this.redeeming,
      levels: levels ?? this.levels,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        status, summary, transactions, txPage, txHasMore,
        loadingMore, redeeming, levels, error,
      ];
}
