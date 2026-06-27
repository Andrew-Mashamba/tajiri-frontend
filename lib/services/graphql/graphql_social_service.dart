import 'package:flutter/foundation.dart';

import '../../models/friend_models.dart';
import '../../models/post_models.dart';
import 'graphql_post_mapper.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL social graph + post interactions (Phase 1 backend mutations).
class GraphqlSocialService {
  static const _likeMutation = r'''
    mutation LikePost($postId: ID!) {
      likePost(postId: $postId) {
        liked
        saved
        subscribed
      }
    }
  ''';

  static const _unlikeMutation = r'''
    mutation UnlikePost($postId: ID!) {
      unlikePost(postId: $postId) {
        liked
        saved
        subscribed
      }
    }
  ''';

  static const _followMutation = r'''
    mutation FollowUser($userId: ID!) {
      followUser(userId: $userId) {
        following
      }
    }
  ''';

  static const _unfollowMutation = r'''
    mutation UnfollowUser($userId: ID!) {
      unfollowUser(userId: $userId) {
        following
      }
    }
  ''';

  static const _blockMutation = r'''
    mutation BlockUser($userId: ID!) {
      blockUser(userId: $userId)
    }
  ''';

  static const _postQuery = r'''
    query Post($id: ID!) {
      post(id: $id) {
        id
        counts {
          likes
          comments
          saves
          views
        }
        viewerState {
          liked
          saved
        }
      }
    }
  ''';

  static const _saveMutation = r'''
    mutation SavePost($postId: ID!) {
      savePost(postId: $postId) {
        liked
        saved
        subscribed
      }
    }
  ''';

  static const _unsaveMutation = r'''
    mutation UnsavePost($postId: ID!) {
      unsavePost(postId: $postId) {
        liked
        saved
        subscribed
      }
    }
  ''';

  static const _savedPostsQuery = r'''
    query SavedPosts($cursor: String) {
      savedPosts(cursor: $cursor) {
        items {
          id
          caption
          publishedAt
          author {
            id
            username
            displayName
            avatarUrl
          }
          media {
            type
            url
            thumbnailUrl
            blurhash
            width
            height
          }
          counts {
            likes
            comments
            saves
            views
          }
          viewerState {
            liked
            saved
            subscribed
          }
        }
        nextCursor
        hasMore
      }
    }
  ''';

  static final Map<String, String?> _savedCursors = {};
  static final Map<int, String?> _followerCursors = {};
  static final Map<int, String?> _followingCursors = {};
  static String? _friendsCursor;
  static String? _mutualFriendsCursor;
  static String? _searchUsersCursor;
  static String? _managedFriendsCursor;
  static String? _managedFriendsKey;
  static String? _managedFollowersCursor;
  static String? _managedFollowersKey;
  static String? _managedFollowingCursor;
  static String? _managedFollowingKey;

  static String _managedQueryKey({
    String? q,
    String? filter,
    String? sort,
  }) =>
      '${q ?? ''}|${filter ?? ''}|${sort ?? ''}';

  static Map<String, dynamic> _userProfileFromFollowRow(Map<String, dynamic> row) {
    final legacy = _followUserToLegacy(row);
    return {
      'id': legacy['id'],
      'first_name': legacy['first_name'],
      'last_name': legacy['last_name'],
      'username': legacy['username'],
      'profile_photo_path': legacy['profile_photo_url'],
    };
  }

  static Future<
      ({
        bool success,
        List<UserProfile> friends,
        int currentPage,
        int lastPage,
        String? message,
      })> getFriends({int page = 1, int perPage = 20}) async {
    try {
      if (page == 1) _friendsCursor = null;
      final cursor = page > 1 ? _friendsCursor : null;
      if (page > 1 && cursor == null) {
        return (
          success: true,
          friends: <UserProfile>[],
          currentPage: page,
          lastPage: page,
          message: null,
        );
      }
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyFriends(\$cursor: String) {
          myFriends(cursor: \$cursor) {
            items { $_followUserFields }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {if (cursor != null) 'cursor': cursor},
        auth: true,
      );
      final conn = data['myFriends'] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final friends = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => UserProfile.fromJson(_userProfileFromFollowRow(row)))
          .toList();
      final hasMore = conn['hasMore'] == true;
      final nextCursor = conn['nextCursor']?.toString();
      if (hasMore && nextCursor != null) _friendsCursor = nextCursor;
      return (
        success: true,
        friends: friends,
        currentPage: page,
        lastPage: hasMore ? page + 1 : page,
        message: null,
      );
    } catch (e) {
      return (
        success: false,
        friends: <UserProfile>[],
        currentPage: page,
        lastPage: page,
        message: '$e',
      );
    }
  }

  static Future<
      ({
        bool success,
        List<FriendRequest> received,
        List<FriendRequest> sent,
        String? message,
      })> getFriendRequests() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        r'''
        query FriendRequests {
          friendRequests {
            received {
              id
              requestType
              createdAt
              user { id username displayName avatarUrl isFollowing isFollowedBy }
            }
            sent {
              id
              requestType
              createdAt
              user { id username displayName avatarUrl isFollowing isFollowedBy }
            }
          }
        }
        ''',
        auth: true,
      );
      final bundle = data['friendRequests'] as Map<String, dynamic>? ?? {};
      FriendRequest mapReq(Map<String, dynamic> row) {
        return FriendRequest.fromJson({
          'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
          'type': row['requestType'] ?? 'received',
          'created_at': row['createdAt'],
          'user': _userProfileFromFollowRow(row['user'] as Map<String, dynamic>? ?? {}),
        });
      }

      final received = (bundle['received'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(mapReq)
          .toList();
      final sent = (bundle['sent'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(mapReq)
          .toList();
      return (success: true, received: received, sent: sent, message: null);
    } catch (e) {
      return (
        success: false,
        received: <FriendRequest>[],
        sent: <FriendRequest>[],
        message: '$e',
      );
    }
  }

  static Future<FriendshipStatusResult> checkFriendshipStatus(int otherUserId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        r'''
        query FriendshipStatus($otherUserId: ID!) {
          friendshipStatus(otherUserId: $otherUserId) {
            status
            isRequester
            canSendRequest
            canAccept
            canCancel
          }
        }
        ''',
        variables: {'otherUserId': otherUserId.toString()},
        auth: true,
      );
      final row = data['friendshipStatus'] as Map<String, dynamic>? ?? {};
      return FriendshipStatusResult.fromJson({
        'status': row['status'] ?? 'none',
        'is_requester': row['isRequester'] ?? false,
        'can_send_request': row['canSendRequest'] ?? true,
        'can_accept': row['canAccept'] ?? false,
        'can_cancel': row['canCancel'] ?? false,
      });
    } catch (_) {
      return FriendshipStatusResult(status: 'none');
    }
  }

  static Future<
      ({
        bool success,
        List<UserProfile> friends,
        int currentPage,
        int lastPage,
        String? message,
      })> getMutualFriends({
    required int otherUserId,
    int page = 1,
  }) async {
    try {
      if (page == 1) _mutualFriendsCursor = null;
      final cursor = page > 1 ? _mutualFriendsCursor : null;
      if (page > 1 && cursor == null) {
        return (
          success: true,
          friends: <UserProfile>[],
          currentPage: page,
          lastPage: page,
          message: null,
        );
      }
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MutualFriends(\$otherUserId: ID!, \$cursor: String) {
          mutualFriends(otherUserId: \$otherUserId, cursor: \$cursor) {
            items { $_followUserFields }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          'otherUserId': otherUserId.toString(),
          if (cursor != null) 'cursor': cursor,
        },
        auth: true,
      );
      final conn = data['mutualFriends'] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final friends = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => UserProfile.fromJson(_userProfileFromFollowRow(row)))
          .toList();
      final hasMore = conn['hasMore'] == true;
      final nextCursor = conn['nextCursor']?.toString();
      if (hasMore && nextCursor != null) _mutualFriendsCursor = nextCursor;
      return (
        success: true,
        friends: friends,
        currentPage: page,
        lastPage: hasMore ? page + 1 : page,
        message: null,
      );
    } catch (e) {
      return (
        success: false,
        friends: <UserProfile>[],
        currentPage: page,
        lastPage: page,
        message: '$e',
      );
    }
  }

  static Future<
      ({
        bool success,
        List<UserProfile> users,
        int currentPage,
        int lastPage,
        String? message,
      })> searchUsers({
    required String query,
    int page = 1,
  }) async {
    try {
      if (page == 1) _searchUsersCursor = null;
      final cursor = page > 1 ? _searchUsersCursor : null;
      if (page > 1 && cursor == null) {
        return (
          success: true,
          users: <UserProfile>[],
          currentPage: page,
          lastPage: page,
          message: null,
        );
      }
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query SearchUsers(\$q: String!, \$cursor: String) {
          searchUsers(q: \$q, cursor: \$cursor) {
            items { $_followUserFields }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          'q': query,
          if (cursor != null) 'cursor': cursor,
        },
        auth: true,
      );
      final conn = data['searchUsers'] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final users = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => UserProfile.fromJson(_userProfileFromFollowRow(row)))
          .toList();
      final hasMore = conn['hasMore'] == true;
      final nextCursor = conn['nextCursor']?.toString();
      if (hasMore && nextCursor != null) _searchUsersCursor = nextCursor;
      return (
        success: true,
        users: users,
        currentPage: page,
        lastPage: hasMore ? page + 1 : page,
        message: null,
      );
    } catch (e) {
      return (
        success: false,
        users: <UserProfile>[],
        currentPage: page,
        lastPage: page,
        message: '$e',
      );
    }
  }

  static Future<bool> sendFriendRequest(int targetUserId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        r'''
        mutation SendFriendRequest($userId: ID!) {
          sendFriendRequest(userId: $userId)
        }
        ''',
        variables: {'userId': targetUserId.toString()},
        auth: true,
      );
      return data['sendFriendRequest'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlSocialService] sendFriendRequest: $e');
      return false;
    }
  }

  static Future<bool> acceptFriendRequest(int requesterId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        r'''
        mutation AcceptFriendRequest($userId: ID!) {
          acceptFriendRequest(userId: $userId)
        }
        ''',
        variables: {'userId': requesterId.toString()},
        auth: true,
      );
      return data['acceptFriendRequest'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlSocialService] acceptFriendRequest: $e');
      return false;
    }
  }

  static Future<bool> declineFriendRequest(int requesterId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        r'''
        mutation DeclineFriendRequest($userId: ID!) {
          declineFriendRequest(userId: $userId)
        }
        ''',
        variables: {'userId': requesterId.toString()},
        auth: true,
      );
      return data['declineFriendRequest'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlSocialService] declineFriendRequest: $e');
      return false;
    }
  }

  static Future<bool> cancelFriendRequest(int targetUserId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        r'''
        mutation CancelFriendRequest($userId: ID!) {
          cancelFriendRequest(userId: $userId)
        }
        ''',
        variables: {'userId': targetUserId.toString()},
        auth: true,
      );
      return data['cancelFriendRequest'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlSocialService] cancelFriendRequest: $e');
      return false;
    }
  }

  static Future<bool> removeFriend(int friendId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        r'''
        mutation RemoveFriend($userId: ID!) {
          removeFriend(userId: $userId)
        }
        ''',
        variables: {'userId': friendId.toString()},
        auth: true,
      );
      return data['removeFriend'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlSocialService] removeFriend: $e');
      return false;
    }
  }

  static Future<int> bulkRemoveFriends(List<int> ids) async {
    if (ids.isEmpty) return 0;
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        r'''
        mutation BulkRemoveFriends($userIds: [ID!]!) {
          bulkRemoveFriends(userIds: $userIds)
        }
        ''',
        variables: {
          'userIds': ids.map((id) => id.toString()).toList(),
        },
        auth: true,
      );
      return (data['bulkRemoveFriends'] as num?)?.toInt() ?? 0;
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlSocialService] bulkRemoveFriends: $e');
      return 0;
    }
  }

  static Future<bool> removeFollower(int followerId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        r'''
        mutation RemoveFollower($followerId: ID!) {
          removeFollower(followerId: $followerId)
        }
        ''',
        variables: {'followerId': followerId.toString()},
        auth: true,
      );
      return data['removeFollower'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlSocialService] removeFollower: $e');
      return false;
    }
  }

  static Future<int> bulkRemoveFollowers(List<int> ids) async {
    if (ids.isEmpty) return 0;
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        r'''
        mutation BulkRemoveFollowers($followerIds: [ID!]!) {
          bulkRemoveFollowers(followerIds: $followerIds)
        }
        ''',
        variables: {
          'followerIds': ids.map((id) => id.toString()).toList(),
        },
        auth: true,
      );
      return (data['bulkRemoveFollowers'] as num?)?.toInt() ?? 0;
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlSocialService] bulkRemoveFollowers: $e');
      return 0;
    }
  }

  static Future<int> bulkUnfollow(List<int> ids) async {
    if (ids.isEmpty) return 0;
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        r'''
        mutation BulkUnfollow($userIds: [ID!]!) {
          bulkUnfollow(userIds: $userIds)
        }
        ''',
        variables: {
          'userIds': ids.map((id) => id.toString()).toList(),
        },
        auth: true,
      );
      return (data['bulkUnfollow'] as num?)?.toInt() ?? 0;
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlSocialService] bulkUnfollow: $e');
      return 0;
    }
  }

  static Future<
      ({
        bool success,
        List<UserProfile> friends,
        String? message,
      })> getFriendSuggestions({int limit = 20}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query FriendSuggestions(\$limit: Int!) {
          friendSuggestions(limit: \$limit) {
            items { $_followUserFields }
          }
        }
        ''',
        variables: {'limit': limit},
        auth: true,
      );
      final conn = data['friendSuggestions'] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final friends = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => UserProfile.fromJson(_userProfileFromFollowRow(row)))
          .toList();
      return (success: true, friends: friends, message: null);
    } catch (e) {
      return (
        success: false,
        friends: <UserProfile>[],
        message: '$e',
      );
    }
  }

  static const _followUserFields = r'''
    id
    username
    displayName
    avatarUrl
    isFollowing
    isFollowedBy
    followedAt
  ''';

  static Map<String, dynamic> _followUserToLegacy(Map<String, dynamic> row) {
    final displayName = row['displayName']?.toString() ?? '';
    final parts = displayName.split(' ');
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'first_name': parts.isNotEmpty ? parts.first : displayName,
      'last_name': parts.length > 1 ? parts.sublist(1).join(' ') : '',
      'username': row['username'],
      'profile_photo_url': row['avatarUrl'],
      'is_following': row['isFollowing'] == true,
      'is_followed_by': row['isFollowedBy'] == true,
      'followed_at': row['followedAt'],
    };
  }

  static Map<String, dynamic> _managedFollowUserToLegacy(Map<String, dynamic> row) {
    final legacy = _followUserToLegacy(row);
    legacy['is_mutual'] =
        legacy['is_following'] == true && legacy['is_followed_by'] == true;
    return legacy;
  }

  static Future<
      ({
        bool success,
        List<FollowUser> users,
        int currentPage,
        int lastPage,
        String? message,
      })> _queryManagedList({
    required String fieldName,
    required int page,
    required int perPage,
    required String? q,
    required String? filter,
    required String? sort,
    required String? Function() getCursor,
    required void Function(String?) setCursor,
    required String? Function() getKey,
    required void Function(String?) setKey,
  }) async {
    try {
      final queryKey = _managedQueryKey(q: q, filter: filter, sort: sort);
      if (page == 1 || getKey() != queryKey) {
        setCursor(null);
        setKey(queryKey);
      }
      final cursor = page > 1 ? getCursor() : null;
      if (page > 1 && cursor == null) {
        return (
          success: true,
          users: <FollowUser>[],
          currentPage: page,
          lastPage: page,
          message: null,
        );
      }
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query ManagedList(
          \$q: String
          \$filter: String
          \$sort: String
          \$cursor: String
          \$limit: Int!
        ) {
          $fieldName(q: \$q, filter: \$filter, sort: \$sort, cursor: \$cursor, limit: \$limit) {
            items { $_followUserFields }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          'limit': perPage,
          if (q != null && q.isNotEmpty) 'q': q,
          if (filter != null) 'filter': filter,
          if (sort != null) 'sort': sort,
          if (cursor != null) 'cursor': cursor,
        },
        auth: true,
      );
      final conn = data[fieldName] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final users = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => FollowUser.fromJson(_managedFollowUserToLegacy(row)))
          .toList();
      final hasMore = conn['hasMore'] == true;
      final nextCursor = conn['nextCursor']?.toString();
      if (hasMore && nextCursor != null) setCursor(nextCursor);
      return (
        success: true,
        users: users,
        currentPage: page,
        lastPage: hasMore ? page + 1 : page,
        message: null,
      );
    } catch (e) {
      return (
        success: false,
        users: <FollowUser>[],
        currentPage: page,
        lastPage: page,
        message: '$e',
      );
    }
  }

  static Future<
      ({
        bool success,
        List<FollowUser> users,
        int currentPage,
        int lastPage,
        String? message,
      })> getManagedFriends({
    int page = 1,
    int perPage = 30,
    String? q,
    String? filter,
    String? sort,
  }) =>
      _queryManagedList(
        fieldName: 'managedFriends',
        page: page,
        perPage: perPage,
        q: q,
        filter: filter,
        sort: sort,
        getCursor: () => _managedFriendsCursor,
        setCursor: (v) => _managedFriendsCursor = v,
        getKey: () => _managedFriendsKey,
        setKey: (v) => _managedFriendsKey = v,
      );

  static Future<
      ({
        bool success,
        List<FollowUser> users,
        int currentPage,
        int lastPage,
        String? message,
      })> getManagedFollowers({
    int page = 1,
    int perPage = 30,
    String? q,
    String? filter,
    String? sort,
  }) =>
      _queryManagedList(
        fieldName: 'managedFollowers',
        page: page,
        perPage: perPage,
        q: q,
        filter: filter,
        sort: sort,
        getCursor: () => _managedFollowersCursor,
        setCursor: (v) => _managedFollowersCursor = v,
        getKey: () => _managedFollowersKey,
        setKey: (v) => _managedFollowersKey = v,
      );

  static Future<
      ({
        bool success,
        List<FollowUser> users,
        int currentPage,
        int lastPage,
        String? message,
      })> getManagedFollowing({
    int page = 1,
    int perPage = 30,
    String? q,
    String? filter,
    String? sort,
  }) =>
      _queryManagedList(
        fieldName: 'managedFollowing',
        page: page,
        perPage: perPage,
        q: q,
        filter: filter,
        sort: sort,
        getCursor: () => _managedFollowingCursor,
        setCursor: (v) => _managedFollowingCursor = v,
        getKey: () => _managedFollowingKey,
        setKey: (v) => _managedFollowingKey = v,
      );

  static Future<FollowerInsights?> getFollowListInsights(String listType) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        r'''
        query FollowListInsights($listType: String!) {
          followListInsights(listType: $listType) {
            total
            newThisWeek
            inactive60d
            mutualGap
          }
        }
        ''',
        variables: {'listType': listType},
        auth: true,
      );
      final row = data['followListInsights'] as Map<String, dynamic>?;
      if (row == null) return null;
      return FollowerInsights.fromJson({
        'total': row['total'],
        'new_this_week': row['newThisWeek'],
        'inactive_60d': row['inactive60d'],
        'mutual_gap': row['mutualGap'],
      });
    } catch (_) {
      return null;
    }
  }

  static Future<
      ({
        bool success,
        List<FollowUser> users,
        int currentPage,
        int lastPage,
        String? message,
      })> getFollowers({
    required int userId,
    int page = 1,
  }) async {
    try {
      if (page == 1) _followerCursors.remove(userId);
      final cursor = page > 1 ? _followerCursors[userId] : null;
      if (page > 1 && cursor == null) {
        return (
          success: true,
          users: <FollowUser>[],
          currentPage: page,
          lastPage: page,
          message: null,
        );
      }
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query UserFollowers(\$userId: ID!, \$cursor: String) {
          userFollowers(userId: \$userId, cursor: \$cursor) {
            items { $_followUserFields }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          'userId': userId.toString(),
          if (cursor != null) 'cursor': cursor,
        },
        auth: true,
      );
      final conn = data['userFollowers'] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final users = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => FollowUser.fromJson(_followUserToLegacy(row)))
          .toList();
      final hasMore = conn['hasMore'] == true;
      final nextCursor = conn['nextCursor']?.toString();
      if (hasMore && nextCursor != null) _followerCursors[userId] = nextCursor;
      return (
        success: true,
        users: users,
        currentPage: page,
        lastPage: hasMore ? page + 1 : page,
        message: null,
      );
    } catch (e) {
      return (
        success: false,
        users: <FollowUser>[],
        currentPage: page,
        lastPage: page,
        message: '$e',
      );
    }
  }

  static Future<
      ({
        bool success,
        List<FollowUser> users,
        int currentPage,
        int lastPage,
        String? message,
      })> getFollowing({
    required int userId,
    int page = 1,
  }) async {
    try {
      if (page == 1) _followingCursors.remove(userId);
      final cursor = page > 1 ? _followingCursors[userId] : null;
      if (page > 1 && cursor == null) {
        return (
          success: true,
          users: <FollowUser>[],
          currentPage: page,
          lastPage: page,
          message: null,
        );
      }
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query UserFollowing(\$userId: ID!, \$cursor: String) {
          userFollowing(userId: \$userId, cursor: \$cursor) {
            items { $_followUserFields }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          'userId': userId.toString(),
          if (cursor != null) 'cursor': cursor,
        },
        auth: true,
      );
      final conn = data['userFollowing'] as Map<String, dynamic>? ?? {};
      final rows = conn['items'] as List<dynamic>? ?? [];
      final users = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => FollowUser.fromJson(_followUserToLegacy(row)))
          .toList();
      final hasMore = conn['hasMore'] == true;
      final nextCursor = conn['nextCursor']?.toString();
      if (hasMore && nextCursor != null) _followingCursors[userId] = nextCursor;
      return (
        success: true,
        users: users,
        currentPage: page,
        lastPage: hasMore ? page + 1 : page,
        message: null,
      );
    } catch (e) {
      return (
        success: false,
        users: <FollowUser>[],
        currentPage: page,
        lastPage: page,
        message: '$e',
      );
    }
  }

  static Future<({bool success, int? likesCount})> likePost(int postId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _likeMutation,
        variables: {'postId': postId.toString()},
        auth: true,
      );
      if (data['likePost'] == null) {
        return (success: false, likesCount: null);
      }
      final likesCount = await _fetchLikesCount(postId);
      return (success: true, likesCount: likesCount);
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlSocialService] likePost: $e');
      return (success: false, likesCount: null);
    }
  }

  static Future<({bool success, int? likesCount})> unlikePost(int postId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _unlikeMutation,
        variables: {'postId': postId.toString()},
        auth: true,
      );
      if (data['unlikePost'] == null) {
        return (success: false, likesCount: null);
      }
      final likesCount = await _fetchLikesCount(postId);
      return (success: true, likesCount: likesCount);
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlSocialService] unlikePost: $e');
      return (success: false, likesCount: null);
    }
  }

  static Future<({bool success, int? savesCount, bool isSaved})> savePost(int postId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _saveMutation,
        variables: {'postId': postId.toString()},
        auth: true,
      );
      if (data['savePost'] == null) {
        return (success: false, savesCount: null, isSaved: false);
      }
      final counts = await _fetchPostCounts(postId);
      return (success: true, savesCount: counts.saves, isSaved: true);
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlSocialService] savePost: $e');
      return (success: false, savesCount: null, isSaved: false);
    }
  }

  static Future<({bool success, int? savesCount, bool isSaved})> unsavePost(int postId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _unsaveMutation,
        variables: {'postId': postId.toString()},
        auth: true,
      );
      if (data['unsavePost'] == null) {
        return (success: false, savesCount: null, isSaved: false);
      }
      final counts = await _fetchPostCounts(postId);
      return (success: true, savesCount: counts.saves, isSaved: false);
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlSocialService] unsavePost: $e');
      return (success: false, savesCount: null, isSaved: false);
    }
  }

  static Future<
      ({
        bool success,
        List<Post> posts,
        int currentPage,
        int lastPage,
        String? message,
      })> getSavedPosts({int page = 1, int perPage = 20}) async {
    try {
      final cursorKey = 'saved_page';
      String? cursor;
      if (page > 1) {
        cursor = _savedCursors[cursorKey];
        if (cursor == null) {
          return (success: true, posts: <Post>[], currentPage: page, lastPage: page, message: null);
        }
      }
      final data = await TajiriGraphqlClient.instance.query(
        _savedPostsQuery,
        variables: {if (cursor != null) 'cursor': cursor},
      );
      final conn = data['savedPosts'] as Map<String, dynamic>? ?? {};
      final items = conn['items'] as List? ?? [];
      _savedCursors[cursorKey] = conn['nextCursor']?.toString();
      final hasMore = conn['hasMore'] == true;
      final posts = items
          .whereType<Map<String, dynamic>>()
          .map(GraphqlPostMapper.fromGraphql)
          .toList();
      return (
        success: true,
        posts: posts,
        currentPage: page,
        lastPage: hasMore ? page + 1 : page,
        message: null,
      );
    } catch (e) {
      return (success: false, posts: <Post>[], currentPage: page, lastPage: page, message: e.toString());
    }
  }

  static Future<({int? likes, int? saves})> _fetchPostCounts(int postId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        _postQuery,
        variables: {'id': postId.toString()},
      );
      final post = data['post'] as Map<String, dynamic>?;
      final counts = post?['counts'] as Map<String, dynamic>?;
      return (
        likes: counts?['likes'] as int?,
        saves: counts?['saves'] as int?,
      );
    } catch (_) {
      return (likes: null, saves: null);
    }
  }

  static const _recordViewMutation = r'''
    mutation RecordPostView(
      $postId: ID!
      $watchSeconds: Int
      $watchPercentage: Float
      $via: String
    ) {
      recordPostView(
        postId: $postId
        watchSeconds: $watchSeconds
        watchPercentage: $watchPercentage
        via: $via
      )
    }
  ''';

  static Future<bool> recordPostView({
    required int postId,
    int? watchSeconds,
    double? watchPercentage,
    String? via,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _recordViewMutation,
        variables: {
          'postId': postId.toString(),
          if (watchSeconds != null) 'watchSeconds': watchSeconds,
          if (watchPercentage != null) 'watchPercentage': watchPercentage,
          if (via != null && via.isNotEmpty) 'via': via,
        },
        auth: true,
      );
      return data['recordPostView'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlSocialService] recordPostView: $e');
      return false;
    }
  }

  static Future<int?> _fetchLikesCount(int postId) async {
    final counts = await _fetchPostCounts(postId);
    return counts.likes;
  }

  static Future<bool> followUser(int targetUserId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _followMutation,
        variables: {'userId': targetUserId.toString()},
        auth: true,
      );
      final state = data['followUser'] as Map<String, dynamic>?;
      return state?['following'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlSocialService] followUser: $e');
      return false;
    }
  }

  static Future<bool> unfollowUser(int targetUserId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _unfollowMutation,
        variables: {'userId': targetUserId.toString()},
        auth: true,
      );
      final state = data['unfollowUser'] as Map<String, dynamic>?;
      return state?['following'] == false;
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlSocialService] unfollowUser: $e');
      return false;
    }
  }

  static Future<bool> blockUser(int targetUserId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _blockMutation,
        variables: {'userId': targetUserId.toString()},
        auth: true,
      );
      return data['blockUser'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlSocialService] blockUser: $e');
      return false;
    }
  }
}
