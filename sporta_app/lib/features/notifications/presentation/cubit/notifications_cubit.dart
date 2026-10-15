import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/models/api_exception.dart';
import '../../data/notification_repository.dart';
import '../../domain/entities/notification_entity.dart';

part 'notifications_state.dart';

/// Loads notifications and the unread badge count, and marks items read.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsState());

  final NotificationRepository _repository;

  Future<void> loadUnreadCount() async {
    try {
      final count = await _repository.fetchUnreadCount();
      emit(state.copyWith(unread: count));
    } on ApiException {
      // ignore — badge stays as-is
    }
  }

  Future<void> load({bool isArabic = true}) async {
    emit(state.copyWith(status: NotificationsStatus.loading, error: null));
    try {
      final page = await _repository.fetchAll();
      // Unread comes from the server: loaded pages may not cover all unread.
      final unread = await _repository.fetchUnreadCount();
      emit(state.copyWith(
        status: NotificationsStatus.success,
        items: page.items,
        unread: unread,
        page: page.page,
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: NotificationsStatus.failure,
        error: e.display,
      ));
    }
  }

  /// Appends the next (older) page when the list scrolls near its end.
  Future<void> loadMore() async {
    if (state.status != NotificationsStatus.success ||
        !state.hasMore ||
        state.loadingMore) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _repository.fetchAll(page: state.page + 1);
      emit(state.copyWith(
        items: [...state.items, ...page.items],
        page: page.page,
        hasMore: page.hasMore,
        loadingMore: false,
      ));
    } on ApiException {
      // Keep what's loaded; the user can scroll again to retry.
      emit(state.copyWith(loadingMore: false));
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _repository.markRead(id);
      // Update in place so already-loaded pages are kept.
      final items = state.items
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList();
      final wasUnread = state.items.any((n) => n.id == id && !n.isRead);
      emit(state.copyWith(
        items: items,
        unread: wasUnread && state.unread > 0 ? state.unread - 1 : state.unread,
      ));
    } on ApiException {
      // ignore
    }
  }

  Future<void> markAllRead() async {
    try {
      await _repository.markAllRead();
      emit(state.copyWith(
        items: state.items.map((n) => n.copyWith(isRead: true)).toList(),
        unread: 0,
      ));
    } on ApiException {
      // ignore
    }
  }
}
