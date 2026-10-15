part of 'matches_cubit.dart';

enum MatchesStatus { initial, loading, success, failure }

class MatchesState extends Equatable {
  const MatchesState({
    this.status = MatchesStatus.initial,
    this.matches = const [],
    this.mine = const [],
    this.mineTotal = 0,
    this.joiningId,
    this.page = 1,
    this.hasMore = false,
    this.loadingMore = false,
    this.error,
  });

  final MatchesStatus status;
  final List<MatchEntity> matches;

  /// «مبارياتي» الحالية (أنشأتها أو أنا فيها، لا منتهية ولا ملغاة) — أحدث
  /// خمس فقط؛ [mineTotal] العدد الكلي لإظهار «عرض الكل».
  final List<MatchEntity> mine;
  final int mineTotal;

  /// Id of the match currently being joined (drives the per-card spinner).
  final int? joiningId;

  /// Last loaded page number.
  final int page;

  /// Whether the server has more pages to load.
  final bool hasMore;

  /// Whether a next-page request is in flight.
  final bool loadingMore;

  final String? error;

  MatchesState copyWith({
    MatchesStatus? status,
    List<MatchEntity>? matches,
    List<MatchEntity>? mine,
    int? mineTotal,
    int? joiningId,
    bool clearJoining = false,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    String? error,
  }) {
    return MatchesState(
      status: status ?? this.status,
      matches: matches ?? this.matches,
      mine: mine ?? this.mine,
      mineTotal: mineTotal ?? this.mineTotal,
      joiningId: clearJoining ? null : (joiningId ?? this.joiningId),
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    matches,
    mine,
    mineTotal,
    joiningId,
    page,
    hasMore,
    loadingMore,
    error,
  ];
}
