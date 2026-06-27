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
