import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/models/api_exception.dart';
import '../../data/friend_repository.dart';
import '../../domain/entities/feed_item.dart';

part 'feed_state.dart';

/// Loads the followed-players activity feed.
class FeedCubit extends Cubit<FeedState> {
  FeedCubit(this._repository) : super(const FeedState());

  final FriendRepository _repository;

  Future<void> load({bool isArabic = true}) async {
    emit(state.copyWith(status: FeedStatus.loading, error: null));
    try {
      final items = await _repository.fetchFeed();
      emit(state.copyWith(status: FeedStatus.success, items: items));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: FeedStatus.failure,
        error: e.display,
      ));
    }
  }
}
