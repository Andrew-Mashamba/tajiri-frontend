import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'http_retry.dart';
import 'package:path_provider/path_provider.dart';
import '../models/friend_models.dart';
import '../config/api_config.dart';
import 'graphql/graphql_social_service.dart';
import 'local_storage_service.dart';
import 'post_service.dart';

String get _baseUrl => ApiConfig.baseUrl;

class FriendService {
  /// Get user's friends list
  Future<FriendListResult> getFriends({
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      final result = await GraphqlSocialService.getFriends(page: page, perPage: perPage);
      return FriendListResult(
        success: result.success,
        friends: result.friends,
        meta: PaginationMeta(
          currentPage: result.currentPage,
          lastPage: result.lastPage,
          perPage: perPage,
        ),
        message: result.message,
      );
    }
    try {
      final response = await httpGetWithRetry(
        Uri.parse('$_baseUrl/friends?user_id=$userId&page=$page&per_page=$perPage'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final friends = (data['data'] as List)
              .map((f) => UserProfile.fromJson(f))
              .toList();
          return FriendListResult(
            success: true,
            friends: friends,
            meta: PaginationMeta.fromJson(data['meta'] ?? {}),
          );
        }
      }
      return FriendListResult(success: false, message: 'Failed to load friends');
    } catch (e) {
      return FriendListResult(success: false, message: 'Error: $e');
    }
  }

  /// Send a friend request
  Future<bool> sendFriendRequest(int userId, int friendId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlSocialService.sendFriendRequest(friendId);
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/friends/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'friend_id': friendId,
        }),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 201 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Accept a friend request
  Future<bool> acceptFriendRequest(int userId, int requesterId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlSocialService.acceptFriendRequest(requesterId);
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/friends/accept/$requesterId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Decline a friend request
  Future<bool> declineFriendRequest(int userId, int requesterId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlSocialService.declineFriendRequest(requesterId);
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/friends/decline/$requesterId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Cancel a sent friend request
  Future<bool> cancelFriendRequest(int userId, int friendId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlSocialService.cancelFriendRequest(friendId);
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/friends/cancel/$friendId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Remove a friend
  Future<bool> removeFriend(int userId, int friendId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlSocialService.removeFriend(friendId);
    }
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/friends/$friendId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get pending friend requests
  Future<FriendRequestsResult> getFriendRequests(int userId) async {
    if (ApiConfig.useGraphqlBackend) {
      final result = await GraphqlSocialService.getFriendRequests();
      return FriendRequestsResult(
        success: result.success,
        received: result.received,
        sent: result.sent,
        message: result.message,
      );
    }
    try {
      final response = await httpGetWithRetry(
        Uri.parse('$_baseUrl/friends/requests?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final raw = data['data'];
          List<dynamic> receivedList;
          List<dynamic> sentList;
          if (raw is Map<String, dynamic>) {
            receivedList = raw['received'] as List? ?? [];
            sentList = raw['sent'] as List? ?? [];
          } else if (raw is List) {
            receivedList = [
              for (final item in raw)
                if (item is Map<String, dynamic> && item['type'] == 'received')
                  item
            ];
            sentList = [
              for (final item in raw)
                if (item is Map<String, dynamic> && item['type'] == 'sent')
                  item
            ];
          } else {
            receivedList = [];
            sentList = [];
          }
          final received = receivedList
              .map((r) => FriendRequest.fromJson(r as Map<String, dynamic>))
              .toList();
          final sent = sentList
              .map((s) => FriendRequest.fromJson(s as Map<String, dynamic>))
              .toList();
          return FriendRequestsResult(
            success: true,
            received: received,
            sent: sent,
          );
        }
      }
      return FriendRequestsResult(success: false, message: 'Failed to load requests');
    } catch (e) {
      return FriendRequestsResult(success: false, message: 'Error: $e');
    }
  }

  /// Get friend suggestions
  Future<FriendListResult> getFriendSuggestions(int userId, {int limit = 20}) async {
    if (ApiConfig.useGraphqlBackend) {
      final result = await GraphqlSocialService.getFriendSuggestions(limit: limit);
      return FriendListResult(
        success: result.success,
        friends: result.friends,
        message: result.message,
      );
    }
    try {
      final response = await httpGetWithRetry(
        Uri.parse('$_baseUrl/friends/suggestions?user_id=$userId&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final suggestions = (data['data'] as List)
              .map((s) => UserProfile.fromJson(s))
              .toList();
          return FriendListResult(success: true, friends: suggestions);
        }
      }
      return FriendListResult(success: false, message: 'Failed to load suggestions');
    } catch (e) {
      return FriendListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get mutual friends
  Future<FriendListResult> getMutualFriends(int userId, int otherUserId) async {
    if (ApiConfig.useGraphqlBackend) {
      final result = await GraphqlSocialService.getMutualFriends(otherUserId: otherUserId);
      return FriendListResult(
        success: result.success,
        friends: result.friends,
        message: result.message,
      );
    }
    try {
      final response = await httpGetWithRetry(
        Uri.parse('$_baseUrl/friends/mutual/$otherUserId?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final mutual = (data['data'] as List)
              .map((m) => UserProfile.fromJson(m))
              .toList();
          return FriendListResult(success: true, friends: mutual);
        }
      }
      return FriendListResult(success: false, message: 'Failed to load mutual friends');
    } catch (e) {
      return FriendListResult(success: false, message: 'Error: $e');
    }
  }

  /// Check friendship status with another user
  Future<FriendshipStatusResult> checkFriendshipStatus(int userId, int otherUserId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlSocialService.checkFriendshipStatus(otherUserId);
    }
    try {
      final response = await httpGetWithRetry(
        Uri.parse('$_baseUrl/friends/status/$otherUserId?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return FriendshipStatusResult.fromJson(data['data']);
        }
      }
      return FriendshipStatusResult(status: 'none');
    } catch (e) {
      return FriendshipStatusResult(status: 'none');
    }
  }

  /// Search users
  Future<FriendListResult> searchUsers(String query, {int page = 1, int perPage = 20}) async {
    if (ApiConfig.useGraphqlBackend) {
      final result = await GraphqlSocialService.searchUsers(query: query, page: page);
      return FriendListResult(
        success: result.success,
        friends: result.users,
        meta: PaginationMeta(
          currentPage: result.currentPage,
          lastPage: result.lastPage,
          perPage: perPage,
        ),
        message: result.message,
      );
    }
    try {
      final response = await httpGetWithRetry(
        Uri.parse('$_baseUrl/users/search?q=${Uri.encodeComponent(query)}&page=$page&per_page=$perPage'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final users = (data['data'] as List)
              .map((u) => UserProfile.fromJson(u))
              .toList();
          return FriendListResult(
            success: true,
            friends: users,
            meta: PaginationMeta.fromJson(data['meta'] ?? {}),
          );
        }
      }
      return FriendListResult(success: false, message: 'Failed to search users');
    } catch (e) {
      return FriendListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get user's followers list
  Future<FollowListResult> getFollowers({
    required int userId,
    int? currentUserId,
    int page = 1,
    int perPage = 20,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      final result = await GraphqlSocialService.getFollowers(
        userId: userId,
        page: page,
      );
      return FollowListResult(
        success: result.success,
        users: result.users,
        meta: PaginationMeta(
          currentPage: result.currentPage,
          lastPage: result.lastPage,
          perPage: perPage,
        ),
        message: result.message,
      );
    }
    try {
      String url = '$_baseUrl/follows/$userId/followers?page=$page&per_page=$perPage';
      if (currentUserId != null) {
        url += '&current_user_id=$currentUserId';
      }
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final response = await httpGetWithRetry(Uri.parse(url),
          headers: token != null ? ApiConfig.authHeaders(token) : null);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final users = (data['data'] as List)
              .map((u) => FollowUser.fromJson(u))
              .toList();
          return FollowListResult(
            success: true,
            users: users,
            meta: PaginationMeta.fromJson(data['meta'] ?? {}),
          );
        }
      }
      return FollowListResult(success: false, message: 'Failed to load followers');
    } catch (e) {
      return FollowListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get user's following list
  Future<FollowListResult> getFollowing({
    required int userId,
    int? currentUserId,
    int page = 1,
    int perPage = 20,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      final result = await GraphqlSocialService.getFollowing(
        userId: userId,
        page: page,
      );
      return FollowListResult(
        success: result.success,
        users: result.users,
        meta: PaginationMeta(
          currentPage: result.currentPage,
          lastPage: result.lastPage,
          perPage: perPage,
        ),
        message: result.message,
      );
    }
    try {
      String url = '$_baseUrl/follows/$userId/following?page=$page&per_page=$perPage';
      if (currentUserId != null) {
        url += '&current_user_id=$currentUserId';
      }
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final response = await httpGetWithRetry(Uri.parse(url),
          headers: token != null ? ApiConfig.authHeaders(token) : null);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final users = (data['data'] as List)
              .map((u) => FollowUser.fromJson(u))
              .toList();
          return FollowListResult(
            success: true,
            users: users,
            meta: PaginationMeta.fromJson(data['meta'] ?? {}),
          );
        }
      }
      return FollowListResult(success: false, message: 'Failed to load following');
    } catch (e) {
      return FollowListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get user's subscribers list
  Future<FollowListResult> getSubscribers({
    required int userId,
    int? currentUserId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      String url = '$_baseUrl/users/$userId/subscribers?page=$page&per_page=$perPage';
      if (currentUserId != null) {
        url += '&current_user_id=$currentUserId';
      }
      final response = await httpGetWithRetry(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final users = (data['data'] as List)
              .map((u) => FollowUser.fromJson(u))
              .toList();
          return FollowListResult(
            success: true,
            users: users,
            meta: PaginationMeta.fromJson(data['meta'] ?? {}),
          );
        }
      }
      return FollowListResult(success: false, message: 'Failed to load subscribers');
    } catch (e) {
      return FollowListResult(success: false, message: 'Error: $e');
    }
  }

  /// Follow a user
  /// Follow a user.
  ///
  /// UN-004: hits the attribution-aware `/follows/` endpoint and forwards
  /// origin context so the backend can fire the right §III row:
  /// - origin_post_id → follow_from_post·author (row 8)
  /// - origin_clip_id → clip_conversion·clipper (row 50)
  /// - origin_collection_id → collection_conversion·curator (row 62)
  /// - origin_translation_id → translated_conversion·translator (row 56)
  /// - share_uid → follow_from_share·sharer (row 29)
  Future<bool> followUser(
    int userId,
    int targetUserId, {
    int? originPostId,
    int? originClipId,
    int? originCollectionId,
    int? originTranslationId,
    int? originStreamId,
    String? shareUid,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlSocialService.followUser(targetUserId);
    }
    try {
      final body = <String, dynamic>{
        'user_id': userId,
        'follow_id': targetUserId,
      };
      if (originPostId != null) body['origin_post_id'] = originPostId;
      if (originClipId != null) body['origin_clip_id'] = originClipId;
      if (originCollectionId != null) body['origin_collection_id'] = originCollectionId;
      if (originTranslationId != null) body['origin_translation_id'] = originTranslationId;
      if (originStreamId != null) body['origin_stream_id'] = originStreamId;
      if (shareUid != null && shareUid.isNotEmpty) body['share_uid'] = shareUid;

      final response = await http.post(
        Uri.parse('$_baseUrl/follows/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      // Legacy fallback for backwards-compat with older deployments.
      final legacy = await http.post(
        Uri.parse('$_baseUrl/users/$targetUserId/follow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      final data = jsonDecode(legacy.body);
      return legacy.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Unfollow a user. Canonical: DELETE /api/follows with {user_id, follow_id}
  /// — mirrors followUser. Falls back to the legacy POST /users/{id}/unfollow
  /// route for older deployments.
  Future<bool> unfollowUser(int userId, int targetUserId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlSocialService.unfollowUser(targetUserId);
    }
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/follows'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'follow_id': targetUserId,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return true;
      }
      // Legacy fallback for backwards-compat.
      final legacy = await http.post(
        Uri.parse('$_baseUrl/users/$targetUserId/unfollow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      if (legacy.statusCode != 200) return false;
      final data = jsonDecode(legacy.body);
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Block a user. POST /api/users/block
  Future<bool> blockUser(int userId, int blockedUserId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlSocialService.blockUser(blockedUserId);
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/block'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'blocked_user_id': blockedUserId,
        }),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Unblock a user. POST /api/users/unblock
  Future<bool> unblockUser(int userId, int blockedUserId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/unblock'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'blocked_user_id': blockedUserId,
        }),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // ── Subscribers manager (creator-mode) ────────────────────────────────

  Future<SubscriberListResult> getOwnerSubscribers({
    required int creatorId,
    int page = 1,
    int perPage = 30,
    String? q,
    String? filter, // new | expiring | churned | null (active default)
    String? sort,   // newest | oldest | name | expiring | null
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'per_page': '$perPage',
        if (q != null && q.isNotEmpty) 'q': q,
        if (filter != null) 'filter': filter,
        if (sort != null) 'sort': sort,
      };
      final uri = Uri.parse('$_baseUrl/subscriptions/creator/$creatorId/subscribers')
          .replace(queryParameters: params);
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final response = await httpGetWithRetry(uri,
          headers: token != null ? ApiConfig.authHeaders(token) : null);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final entries = (body['data'] as List)
              .map((e) => SubscriberEntry.fromJson(e as Map<String, dynamic>))
              .toList();
          final total =
              (body['meta']?['pagination']?['total'] as num?)?.toInt() ?? 0;
          return SubscriberListResult(
              success: true, entries: entries, totalCount: total);
        }
      }
      return const SubscriberListResult(
          success: false, message: 'Failed to load subscribers');
    } catch (e) {
      return SubscriberListResult(success: false, message: 'Error: $e');
    }
  }

  Future<SubscriberInsights?> getSubscriberInsights({required int creatorId}) async {
    try {
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final response = await httpGetWithRetry(
        Uri.parse(
            '$_baseUrl/subscriptions/creator/$creatorId/subscribers/insights'),
        headers: token != null ? ApiConfig.authHeaders(token) : null,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] is Map<String, dynamic>) {
          return SubscriberInsights.fromJson(body['data']);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<bool> creatorCancelSubscription({
    required int creatorId,
    required int subscriptionId,
  }) async {
    try {
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final response = await http.post(
        Uri.parse(
            '$_baseUrl/subscriptions/creator/$creatorId/subscribers/$subscriptionId/cancel'),
        headers: token != null ? ApiConfig.authHeaders(token) : null,
      );
      return response.statusCode == 200 &&
          (jsonDecode(response.body)['success'] == true);
    } catch (_) {
      return false;
    }
  }

  Future<int> creatorBulkCancelSubscriptions({
    required int creatorId,
    required List<int> subscriptionIds,
  }) async {
    try {
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final response = await http.post(
        Uri.parse(
            '$_baseUrl/subscriptions/creator/$creatorId/subscribers/bulk-cancel'),
        headers: {
          if (token != null) ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'subscription_ids': subscriptionIds}),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          return (body['data']?['cancelled'] as num?)?.toInt() ?? 0;
        }
      }
    } catch (_) {}
    return 0;
  }

  Future<String?> exportSubscribersCsv({required int creatorId}) async {
    try {
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final dir = await getTemporaryDirectory();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final path = '${dir.path}${Platform.pathSeparator}subscribers-$today.csv';
      final dio = Dio();
      final response = await dio.download(
        '$_baseUrl/subscriptions/creator/$creatorId/subscribers/export.csv',
        path,
        options: Options(
          headers: token != null ? ApiConfig.authHeaders(token) : null,
          responseType: ResponseType.bytes,
        ),
      );
      if (response.statusCode == 200) return path;
    } catch (_) {}
    return null;
  }

  // ── Friends manager (owner-mode) ──────────────────────────────────────

  Future<FollowListResult> getOwnerFriends({
    required int userId,
    int page = 1,
    int perPage = 30,
    String? q,
    String? filter,
    String? sort,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      final result = await GraphqlSocialService.getManagedFriends(
        page: page,
        perPage: perPage,
        q: q,
        filter: filter,
        sort: sort,
      );
      return FollowListResult(
        success: result.success,
        users: result.users,
        meta: PaginationMeta(
          currentPage: result.currentPage,
          lastPage: result.lastPage,
          perPage: perPage,
        ),
        message: result.message,
      );
    }
    try {
      final params = <String, String>{
        'user_id': '$userId',
        'page': '$page',
        'per_page': '$perPage',
        if (q != null && q.isNotEmpty) 'q': q,
        if (filter != null) 'filter': filter,
        if (sort != null) 'sort': sort,
      };
      final uri =
          Uri.parse('$_baseUrl/friends').replace(queryParameters: params);
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final response = await httpGetWithRetry(uri,
          headers: token != null ? ApiConfig.authHeaders(token) : null);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final users = (data['data'] as List)
              .map((u) => FollowUser.fromJson(u))
              .toList();
          return FollowListResult(
            success: true,
            users: users,
            meta: PaginationMeta.fromJson(data['meta'] ?? {}),
          );
        }
      }
      return FollowListResult(success: false, message: 'Failed to load friends');
    } catch (e) {
      return FollowListResult(success: false, message: 'Error: $e');
    }
  }

  Future<FollowerInsights?> getFriendsInsights() async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlSocialService.getFollowListInsights('friends');
    }
    try {
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final response = await httpGetWithRetry(
        Uri.parse('$_baseUrl/friends/insights'),
        headers: token != null ? ApiConfig.authHeaders(token) : null,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          return FollowerInsights.fromJson(data['data']);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<int> bulkUnfriend({required List<int> ids}) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlSocialService.bulkRemoveFriends(ids);
    }
    try {
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/friends/bulk-unfriend'),
        headers: {
          if (token != null) ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'ids': ids}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['data']?['unfriended'] as num?)?.toInt() ?? 0;
        }
      }
    } catch (_) {}
    return 0;
  }

  Future<String?> exportFriendsCsv() async {
    try {
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final dir = await getTemporaryDirectory();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final path = '${dir.path}${Platform.pathSeparator}friends-$today.csv';
      final dio = Dio();
      final response = await dio.download(
        '$_baseUrl/friends/export.csv',
        path,
        options: Options(
          headers: token != null ? ApiConfig.authHeaders(token) : null,
          responseType: ResponseType.bytes,
        ),
      );
      if (response.statusCode == 200) return path;
    } catch (_) {}
    return null;
  }

  // ── Following manager (owner-mode) ────────────────────────────────────

  Future<FollowListResult> getOwnerFollowing({
    required int userId,
    int page = 1,
    int perPage = 30,
    String? q,
    String? filter,
    String? sort,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      final result = await GraphqlSocialService.getManagedFollowing(
        page: page,
        perPage: perPage,
        q: q,
        filter: filter,
        sort: sort,
      );
      return FollowListResult(
        success: result.success,
        users: result.users,
        meta: PaginationMeta(
          currentPage: result.currentPage,
          lastPage: result.lastPage,
          perPage: perPage,
        ),
        message: result.message,
      );
    }
    try {
      final params = <String, String>{
        'page': '$page',
        'per_page': '$perPage',
        if (q != null && q.isNotEmpty) 'q': q,
        if (filter != null) 'filter': filter,
        if (sort != null) 'sort': sort,
      };
      final uri = Uri.parse('$_baseUrl/follows/$userId/following')
          .replace(queryParameters: params);
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final response = await httpGetWithRetry(uri,
          headers: token != null ? ApiConfig.authHeaders(token) : null);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final users = (data['data'] as List)
              .map((u) => FollowUser.fromJson(u))
              .toList();
          return FollowListResult(
            success: true,
            users: users,
            meta: PaginationMeta.fromJson(data['meta'] ?? {}),
          );
        }
      }
      return FollowListResult(success: false, message: 'Failed to load following');
    } catch (e) {
      return FollowListResult(success: false, message: 'Error: $e');
    }
  }

  Future<FollowerInsights?> getFollowingInsights({required int userId}) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlSocialService.getFollowListInsights('following');
    }
    try {
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final response = await httpGetWithRetry(
        Uri.parse('$_baseUrl/follows/$userId/following/insights'),
        headers: token != null ? ApiConfig.authHeaders(token) : null,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          return FollowerInsights.fromJson(data['data']);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<bool> unfollow({required int userId, required int targetId}) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlSocialService.unfollowUser(targetId);
    }
    try {
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/follows/$userId/following/$targetId'),
        headers: token != null ? ApiConfig.authHeaders(token) : null,
      );
      return response.statusCode == 200 &&
          (jsonDecode(response.body)['success'] == true);
    } catch (_) {
      return false;
    }
  }

  Future<int> bulkUnfollow({required int userId, required List<int> ids}) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlSocialService.bulkUnfollow(ids);
    }
    try {
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/follows/$userId/following/bulk-unfollow'),
        headers: {
          if (token != null) ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'ids': ids}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['data']?['unfollowed'] as num?)?.toInt() ?? 0;
        }
      }
    } catch (_) {}
    return 0;
  }

  Future<String?> exportFollowingCsv({required int userId}) async {
    try {
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final dir = await getTemporaryDirectory();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final path = '${dir.path}${Platform.pathSeparator}following-$today.csv';
      final dio = Dio();
      final response = await dio.download(
        '$_baseUrl/follows/$userId/following/export.csv',
        path,
        options: Options(
          headers: token != null ? ApiConfig.authHeaders(token) : null,
          responseType: ResponseType.bytes,
        ),
      );
      if (response.statusCode == 200) return path;
    } catch (_) {}
    return null;
  }

  // ── Followers manager (owner-mode) ────────────────────────────────────

  /// Owner-mode followers list with q / filter / sort. Backend returns
  /// 403 if the auth'd user doesn't match `userId` and any management
  /// param is supplied.
  Future<FollowListResult> getOwnerFollowers({
    required int userId,
    int page = 1,
    int perPage = 30,
    String? q,
    String? filter,
    String? sort,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      final result = await GraphqlSocialService.getManagedFollowers(
        page: page,
        perPage: perPage,
        q: q,
        filter: filter,
        sort: sort,
      );
      return FollowListResult(
        success: result.success,
        users: result.users,
        meta: PaginationMeta(
          currentPage: result.currentPage,
          lastPage: result.lastPage,
          perPage: perPage,
        ),
        message: result.message,
      );
    }
    try {
      final params = <String, String>{
        'page': '$page',
        'per_page': '$perPage',
        if (q != null && q.isNotEmpty) 'q': q,
        if (filter != null) 'filter': filter,
        if (sort != null) 'sort': sort,
      };
      final uri = Uri.parse('$_baseUrl/follows/$userId/followers')
          .replace(queryParameters: params);
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final response = await httpGetWithRetry(uri,
          headers: token != null ? ApiConfig.authHeaders(token) : null);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final users = (data['data'] as List)
              .map((u) => FollowUser.fromJson(u))
              .toList();
          return FollowListResult(
            success: true,
            users: users,
            meta: PaginationMeta.fromJson(data['meta'] ?? {}),
          );
        }
      }
      return FollowListResult(success: false, message: 'Failed to load followers');
    } catch (e) {
      return FollowListResult(success: false, message: 'Error: $e');
    }
  }

  Future<FollowerInsights?> getFollowerInsights({required int userId}) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlSocialService.getFollowListInsights('followers');
    }
    try {
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final response = await httpGetWithRetry(
        Uri.parse('$_baseUrl/follows/$userId/followers/insights'),
        headers: token != null ? ApiConfig.authHeaders(token) : null,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          return FollowerInsights.fromJson(data['data']);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<bool> removeFollower({required int userId, required int followerId}) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlSocialService.removeFollower(followerId);
    }
    try {
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/follows/$userId/followers/$followerId'),
        headers: token != null ? ApiConfig.authHeaders(token) : null,
      );
      return response.statusCode == 200 &&
          (jsonDecode(response.body)['success'] == true);
    } catch (_) {
      return false;
    }
  }

  Future<int> bulkRemoveFollowers({required int userId, required List<int> ids}) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlSocialService.bulkRemoveFollowers(ids);
    }
    try {
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/follows/$userId/followers/bulk-remove'),
        headers: {
          if (token != null) ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'ids': ids}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['data']?['removed'] as num?)?.toInt() ?? 0;
        }
      }
    } catch (_) {}
    return 0;
  }

  Future<bool> muteUser({required int userId, required int mutedUserId}) async {
    try {
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/users/$userId/mutes'),
        headers: {
          if (token != null) ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'muted_user_id': mutedUserId}),
      );
      return response.statusCode == 200 &&
          (jsonDecode(response.body)['success'] == true);
    } catch (_) {
      return false;
    }
  }

  Future<bool> unmuteUser({required int userId, required int mutedUserId}) async {
    try {
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/users/$userId/mutes/$mutedUserId'),
        headers: token != null ? ApiConfig.authHeaders(token) : null,
      );
      return response.statusCode == 200 &&
          (jsonDecode(response.body)['success'] == true);
    } catch (_) {
      return false;
    }
  }

  Future<int> bulkMuteUsers({required int userId, required List<int> ids}) async {
    try {
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/users/$userId/mutes/bulk'),
        headers: {
          if (token != null) ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'ids': ids}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['data']?['muted'] as num?)?.toInt() ?? 0;
        }
      }
    } catch (_) {}
    return 0;
  }

  Future<int> bulkBlockUsers({required int userId, required List<int> ids}) async {
    try {
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/users/block-bulk'),
        headers: {
          if (token != null) ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': userId, 'blocked_user_ids': ids}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['data']?['blocked'] as num?)?.toInt() ?? 0;
        }
      }
    } catch (_) {}
    return 0;
  }

  /// Downloads followers CSV to a temp file via Dio. Returns the local
  /// path on success, null on failure.
  Future<String?> exportFollowersCsv({required int userId}) async {
    try {
      final token = (await LocalStorageService.getInstance()).getAuthToken();
      final dir = await getTemporaryDirectory();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final path = '${dir.path}${Platform.pathSeparator}followers-$today.csv';
      final dio = Dio();
      final response = await dio.download(
        '$_baseUrl/follows/$userId/followers/export.csv',
        path,
        options: Options(
          headers: token != null ? ApiConfig.authHeaders(token) : null,
          responseType: ResponseType.bytes,
        ),
      );
      if (response.statusCode == 200) return path;
    } catch (_) {}
    return null;
  }
}

// Result classes
class FriendListResult {
  final bool success;
  final List<UserProfile> friends;
  final PaginationMeta? meta;
  final String? message;

  FriendListResult({
    required this.success,
    this.friends = const [],
    this.meta,
    this.message,
  });
}

class FriendRequestsResult {
  final bool success;
  final List<FriendRequest> received;
  final List<FriendRequest> sent;
  final String? message;

  FriendRequestsResult({
    required this.success,
    this.received = const [],
    this.sent = const [],
    this.message,
  });
}

class FollowListResult {
  final bool success;
  final List<FollowUser> users;
  final PaginationMeta? meta;
  final String? message;

  FollowListResult({
    required this.success,
    this.users = const [],
    this.meta,
    this.message,
  });
}
