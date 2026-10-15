import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/models/api_exception.dart';
import '../../data/coach_repository.dart';
import '../../domain/entities/coach_session_entity.dart';

part 'my_sessions_state.dart';

/// Loads the player's booked coach sessions from the repository.
class MySessionsCubit extends Cubit<MySessionsState> {
  MySessionsCubit(this._repository) : super(const MySessionsState());

  final CoachRepository _repository;

  Future<void> load({bool isArabic = true}) async {
    emit(state.copyWith(status: MySessionsStatus.loading, error: null));
    try {
      final result = await _repository.fetchMySessions();
      emit(
        state.copyWith(
          status: MySessionsStatus.success,
          sessions: result.items,
          page: result.page,
          hasMore: result.hasMore,
          loadingMore: false,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(status: MySessionsStatus.failure, error: e.display));
    }
  }

  /// Submits the player's rating of the coach and updates the session in
  /// place. Returns null on success, or a localized error message.
  Future<String?> rateCoach(
    int sessionId,
    int rating,
    String? review, {
    bool isArabic = true,
  }) async {
    try {
      await _repository.rateCoach(sessionId, rating, review);
      emit(
        state.copyWith(
          sessions: [
            for (final s in state.sessions)
              if (s.id == sessionId)
                s.copyWithPlayerRating(rating, review)
              else
                s,
          ],
        ),
      );
      return null;
    } on ApiException catch (e) {
      return e.display;
    }
  }

  /// Appends the next page when the list scrolls near its end.
  Future<void> loadMore() async {
    if (state.status != MySessionsStatus.success ||
        !state.hasMore ||
        state.loadingMore) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    try {
      final result = await _repository.fetchMySessions(page: state.page + 1);
      emit(
        state.copyWith(
          sessions: [...state.sessions, ...result.items],
          page: result.page,
          hasMore: result.hasMore,
          loadingMore: false,
        ),
      );
    } on ApiException {
      // Keep what's loaded; the user can scroll again to retry.
      emit(state.copyWith(loadingMore: false));
    }
  }
}
