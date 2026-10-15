part of 'my_sessions_cubit.dart';

enum MySessionsStatus { initial, loading, success, failure }

class MySessionsState extends Equatable {
  const MySessionsState({
    this.status = MySessionsStatus.initial,
    this.sessions = const [],
    this.page = 1,
    this.hasMore = false,
    this.loadingMore = false,
    this.error,
  });

  final MySessionsStatus status;
  final List<CoachSessionEntity> sessions;

  /// Last loaded page number.
  final int page;

  /// Whether the server has more pages to load.
  final bool hasMore;

  /// Whether a next-page request is in flight.
  final bool loadingMore;

  final String? error;

  MySessionsState copyWith({
    MySessionsStatus? status,
    List<CoachSessionEntity>? sessions,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    String? error,
  }) {
    return MySessionsState(
      status: status ?? this.status,
      sessions: sessions ?? this.sessions,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    sessions,
    page,
    hasMore,
    loadingMore,
    error,
  ];
}
