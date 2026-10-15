import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/models/api_exception.dart';
import '../../data/friend_repository.dart';
import '../../domain/entities/player_summary.dart';

part 'friends_state.dart';

/// Drives the friends screen: friends list, incoming requests, and search/add.
class FriendsCubit extends Cubit<FriendsState> {
  FriendsCubit(this._repository) : super(const FriendsState());

  final FriendRepository _repository;

  Future<void> load({bool isArabic = true}) async {
    emit(state.copyWith(status: FriendsStatus.loading, error: null));
    try {
      final friends = await _repository.fetchFriends();
      final requests = await _repository.fetchRequests();
      final following = await _repository.fetchFollowing();
      emit(state.copyWith(
        status: FriendsStatus.success,
        friends: friends,
        requests: requests,
        following: following,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: FriendsStatus.failure,
        error: e.display,
      ));
    }
  }

  Future<void> toggleFollow(int userId, bool follow) async {
    try {
      if (follow) {
        await _repository.follow(userId);
      } else {
        await _repository.unfollow(userId);
      }
      // Refresh search results (relation/follow flags) + the following list.
      if (state.query.trim().isNotEmpty) await search(state.query);
      final following = await _repository.fetchFollowing();
      emit(state.copyWith(following: following));
    } on ApiException {
      // ignore; UI stays as-is
    }
  }

  Future<void> search(String query) async {
    emit(state.copyWith(query: query, searching: true));
    try {
      final results = await _repository.searchPlayers(query);
      emit(state.copyWith(searchResults: results, searching: false));
    } on ApiException {
      emit(state.copyWith(searching: false));
    }
  }

  Future<String?> sendRequest(int userId, {bool isArabic = true}) async {
    try {
      await _repository.sendRequest(userId);
      // Refresh search results so the relation flips to pending.
      if (state.query.isNotEmpty) await search(state.query);
      return null;
    } on ApiException catch (e) {
      return e.display;
    }
  }

  Future<void> respond(int requestId, bool accept) async {
    try {
      await _repository.respond(requestId, accept);
      await load();
    } on ApiException {
      // ignore; the list stays as-is
    }
  }
}
