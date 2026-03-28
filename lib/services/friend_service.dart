import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/friend_models.dart';
import '../config/api_config.dart';
import 'post_service.dart';

String get _baseUrl => ApiConfig.baseUrl;

class FriendService {
  /// Get user's friends list
  Future<FriendListResult> getFriends({
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await http.get(
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
    try {
      final response = await http.get(
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
    try {
      final response = await http.get(
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
    try {
      final response = await http.get(
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
    try {
      final response = await http.get(
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
    try {
      final response = await http.get(
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
    try {
      String url = '$_baseUrl/users/$userId/followers?page=$page&per_page=$perPage';
      if (currentUserId != null) {
        url += '&current_user_id=$currentUserId';
      }
      final response = await http.get(Uri.parse(url));

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
    try {
      String url = '$_baseUrl/users/$userId/following?page=$page&per_page=$perPage';
      if (currentUserId != null) {
        url += '&current_user_id=$currentUserId';
      }
      final response = await http.get(Uri.parse(url));

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
      final response = await http.get(Uri.parse(url));

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
  Future<bool> followUser(int userId, int targetUserId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/$targetUserId/follow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser(int userId, int targetUserId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/$targetUserId/unfollow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Block a user. POST /api/users/block
  Future<bool> blockUser(int userId, int blockedUserId) async {
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
