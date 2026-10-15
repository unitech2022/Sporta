part of 'americano_list_cubit.dart';

enum AmericanoListStatus { initial, loading, success, failure }

class AmericanoListState extends Equatable {
  const AmericanoListState({
    this.status = AmericanoListStatus.initial,
    this.items = const [],
    this.mine = const [],
    this.mineTotal = 0,
    this.joiningId,
    this.page = 1,
    this.hasMore = false,
    this.loadingMore = false,
    this.error,
  });

  final AmericanoListStatus status;
  final List<AmericanoEntity> items;

  /// ما أنشأه المستخدم أو هو فيه من الحالية (لا منتهية ولا ملغاة) — أحدث
  /// خمسة؛ [mineTotal] العدد الكلي لإظهار «عرض الكل».
  final List<AmericanoEntity> mine;
  final int mineTotal;

  /// معرّف الحدث الذي يُنضمّ إليه الآن من بطاقته (يعطّل زره).
  final int? joiningId;

  /// Last loaded page number.
  final int page;

  /// Whether the server has more pages to load.
  final bool hasMore;

  /// Whether a next-page request is in flight.
  final bool loadingMore;

  final String? error;

  AmericanoListState copyWith({
    AmericanoListStatus? status,
    List<AmericanoEntity>? items,
    List<AmericanoEntity>? mine,
    int? mineTotal,
    int? joiningId,
    bool clearJoining = false,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    String? error,
  }) {
    return AmericanoListState(
      status: status ?? this.status,
      items: items ?? this.items,
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
    items,
    mine,
    mineTotal,
    joiningId,
    page,
    hasMore,
    loadingMore,
    error,
  ];
}
