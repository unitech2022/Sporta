import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../auth/data/models/api_exception.dart';
import '../domain/entities/feed_item.dart';
import '../domain/entities/player_summary.dart';

/// Talks to the friends REST endpoints.
class FriendRepository {
  FriendRepository(this._dio);

  final Dio _dio;

  Future<List<PlayerSummary>> fetchFriends() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.friends);
      return _asPlayers(res.data);
    });
  }

  Future<List<PlayerSummary>> searchPlayers(String query) async {
    return _guard(() async {
      final res = await _dio.get(
        ApiEndpoints.friendsSearch,
        queryParameters: {if (query.isNotEmpty) 'q': query},
      );
      return _asPlayers(res.data);
    });
  }

  /// Suggested players to connect with (not self/friends/already-followed).
  Future<List<PlayerSummary>> fetchSuggestions() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.friendsSuggestions);
      return _asPlayers(res.data);
    });
  }

  Future<List<FriendRequest>> fetchRequests() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.friendRequests);
      final data = _unwrap(res.data) as List;
      return data
          .map((e) => FriendRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> sendRequest(int userId) async {
    return _guard(() async {
      await _dio.post(ApiEndpoints.friendRequests, data: {'userId': userId});
    });
  }

  Future<void> respond(int requestId, bool accept) async {
    return _guard(() async {
      await _dio.put(
        ApiEndpoints.respondFriendRequest(requestId),
        data: {'accept': accept},
      );
    });
  }

  /// Marks/unmarks a friend as a favorite partner.
  Future<void> toggleFavorite(int userId, bool favorite) async {
    return _guard(() async {
      await _dio.put(
        ApiEndpoints.friendFavorite(userId),
        data: {'favorite': favorite},
      );
    });
  }

  // ── follow ──────────────────────────────────────────────────────────────────

  Future<List<PlayerSummary>> fetchFollowing() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.following);
      return _asPlayers(res.data);
    });
  }

  Future<void> follow(int userId) async {
    return _guard(() async => _dio.post(ApiEndpoints.follow(userId)));
  }

  Future<void> unfollow(int userId) async {
    return _guard(() async => _dio.delete(ApiEndpoints.follow(userId)));
  }

  /// Activity feed of the players the current user follows.
  Future<List<FeedItem>> fetchFeed() async {
    return _guard(() async {
      final res = await _dio.get(ApiEndpoints.feed);
      final data = _unwrap(res.data) as List;
      return data
          .map((e) => FeedItem.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  List<PlayerSummary> _asPlayers(dynamic body) {
    final data = _unwrap(body) as List;
    return data
        .map((e) => PlayerSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  dynamic _unwrap(dynamic body) =>
      body is Map<String, dynamic> ? (body['data'] ?? body) : body;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw e.response != null
          ? ApiException.fromResponse(e.response!)
          : ApiException.network;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException.unexpected;
    }
  }
}
