part of 'my_events_cubit.dart';

enum MyEventsStatus { initial, loading, success, failure }

class MyEventsState extends Equatable {
  const MyEventsState({
    this.status = MyEventsStatus.initial,
    this.matches = const [],
    this.events = const [],
    this.page = 1,
    this.hasMore = false,
    this.loadingMore = false,
    this.error,
  });

  final MyEventsStatus status;

  /// مبارياتي (حين [MyEventsCubit.kind] = match).
  final List<MatchEntity> matches;

  /// أمريكانو/بطولاتي (لبقية الأنواع).
  final List<AmericanoEntity> events;

  /// Last loaded page number.
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final String? error;

  bool get isEmpty => matches.isEmpty && events.isEmpty;

  MyEventsState copyWith({
    MyEventsStatus? status,
    List<MatchEntity>? matches,
    List<AmericanoEntity>? events,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    String? error,
  }) {
    return MyEventsState(
      status: status ?? this.status,
      matches: matches ?? this.matches,
      events: events ?? this.events,
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
    events,
    page,
    hasMore,
    loadingMore,
    error,
  ];
}
