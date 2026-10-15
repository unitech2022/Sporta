part of 'feed_cubit.dart';

enum FeedStatus { initial, loading, success, failure }

class FeedState extends Equatable {
  const FeedState({
    this.status = FeedStatus.initial,
    this.items = const [],
    this.error,
  });

  final FeedStatus status;
  final List<FeedItem> items;
  final String? error;

  FeedState copyWith({
    FeedStatus? status,
    List<FeedItem>? items,
    String? error,
  }) {
    return FeedState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, items, error];
}
