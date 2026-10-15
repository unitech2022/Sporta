part of 'friends_cubit.dart';

enum FriendsStatus { initial, loading, success, failure }

class FriendsState extends Equatable {
  const FriendsState({
    this.status = FriendsStatus.initial,
    this.friends = const [],
    this.requests = const [],
    this.following = const [],
    this.searchResults = const [],
    this.query = '',
    this.searching = false,
    this.error,
  });

  final FriendsStatus status;
  final List<PlayerSummary> friends;
  final List<FriendRequest> requests;
  final List<PlayerSummary> following;
  final List<PlayerSummary> searchResults;
  final String query;
  final bool searching;
  final String? error;

  FriendsState copyWith({
    FriendsStatus? status,
    List<PlayerSummary>? friends,
    List<FriendRequest>? requests,
    List<PlayerSummary>? following,
    List<PlayerSummary>? searchResults,
    String? query,
    bool? searching,
    String? error,
  }) {
    return FriendsState(
      status: status ?? this.status,
      friends: friends ?? this.friends,
      requests: requests ?? this.requests,
      following: following ?? this.following,
      searchResults: searchResults ?? this.searchResults,
      query: query ?? this.query,
      searching: searching ?? this.searching,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [status, friends, requests, following, searchResults, query, searching, error];
}
