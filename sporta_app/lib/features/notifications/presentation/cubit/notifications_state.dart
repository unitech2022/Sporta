part of 'notifications_cubit.dart';

enum NotificationsStatus { initial, loading, success, failure }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.items = const [],
    this.unread = 0,
    this.page = 1,
    this.hasMore = false,
    this.loadingMore = false,
    this.error,
  });

  final NotificationsStatus status;
  final List<NotificationEntity> items;
  final int unread;

  /// Last loaded page number.
  final int page;

  /// Whether the server has more (older) pages to load.
  final bool hasMore;

  /// Whether a next-page request is in flight.
  final bool loadingMore;

  final String? error;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationEntity>? items,
    int? unread,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    String? error,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      unread: unread ?? this.unread,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [status, items, unread, page, hasMore, loadingMore, error];
}
