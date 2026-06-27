import 'package:flutter/foundation.dart';

import '../../config/api_config.dart';
import '../../models/content_engine_models.dart';
import '../../models/post_models.dart';
import 'graphql_post_mapper.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL auth against TAJIRI-BACKEND (replaces REST login when enabled).
class GraphqlAuthService {
  static const _loginMutation = r'''
    mutation LoginByPhone($phone: String!, $pin: String!, $deviceId: String!) {
      loginByPhone(phone: $phone, pin: $pin, deviceId: $deviceId) {
        accessToken
        refreshToken
        accessExpiresIn
        refreshExpiresIn
        user {
          id
          username
          displayName
          avatarUrl
          msisdn
        }
      }
    }
  ''';

  static const _refreshMutation = r'''
    mutation RefreshToken($refreshToken: String!, $deviceId: String!) {
      refreshToken(refreshToken: $refreshToken, deviceId: $deviceId) {
        accessToken
        refreshToken
        accessExpiresIn
        refreshExpiresIn
        user {
          id
          username
          displayName
          avatarUrl
          msisdn
        }
      }
    }
  ''';

  static Map<String, dynamic> userToLegacyMap(Map<String, dynamic> user) {
    final displayName = user['displayName']?.toString() ?? '';
    final parts = displayName.split(' ');
    return {
      'id': int.tryParse(user['id']?.toString() ?? ''),
      'phone_number': user['msisdn'],
      'profile_photo_url': user['avatarUrl'],
      'first_name': parts.isNotEmpty ? parts.first : displayName,
      'last_name': parts.length > 1 ? parts.sublist(1).join(' ') : null,
      'username': user['username'],
    };
  }

  static Future<({bool success, Map<String, dynamic>? payload, String? error})>
      login({
    required String phone,
    required String pin,
    required String deviceId,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _loginMutation,
        variables: {'phone': phone, 'pin': pin, 'deviceId': deviceId},
        auth: false,
      );
      final payload = data['loginByPhone'] as Map<String, dynamic>?;
      if (payload == null) {
        return (success: false, payload: null, error: 'Imeshindwa kuingia');
      }
      return (success: true, payload: payload, error: null);
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlAuthService] login: $e');
      return (success: false, payload: null, error: e.toString());
    }
  }

  static Future<({bool success, Map<String, dynamic>? payload, String? error})>
      refresh({
    required String refreshToken,
    required String deviceId,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _refreshMutation,
        variables: {
          'refreshToken': refreshToken,
          'deviceId': deviceId,
        },
        auth: false,
      );
      final payload = data['refreshToken'] as Map<String, dynamic>?;
      if (payload == null) {
        return (success: false, payload: null, error: 'Token refresh failed');
      }
      return (success: true, payload: payload, error: null);
    } catch (e) {
      return (success: false, payload: null, error: e.toString());
    }
  }
}

/// GraphQL feed — cursor pagination mapped to [ContentEngineResult].
class GraphqlFeedService {
  static final Map<String, String?> _cursors = {};

  static const _feedQuery = r'''
    query Feed($cursor: String, $refresh: Boolean) {
      feed(cursor: $cursor, refresh: $refresh) {
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
        feedReset
      }
    }
  ''';

  static Future<ContentEngineResult> feed({
    required String feedType,
    int page = 1,
    int perPage = 20,
  }) async {
    if (!ApiConfig.useGraphqlBackend) {
      throw StateError('GraphQL backend not enabled');
    }

    final cursorKey = feedType;
    String? cursor;
    final refresh = page == 1;
    if (!refresh) {
      cursor = _cursors[cursorKey];
      if (cursor == null) {
        return ContentEngineResult(
          items: const [],
          meta: ContentEngineMeta(
            currentPage: page,
            perPage: perPage,
            totalCandidates: 0,
            servedFromCache: false,
            queryTimeMs: 0,
            feedType: feedType,
          ),
        );
      }
    }

    try {
      final data = await TajiriGraphqlClient.instance.query(
        _feedQuery,
        variables: {
          if (cursor != null) 'cursor': cursor,
          'refresh': refresh,
        },
      );
      final feed = data['feed'] as Map<String, dynamic>? ?? {};
      final itemsRaw = feed['items'] is List ? feed['items'] as List : <dynamic>[];
      final posts = itemsRaw
          .whereType<Map<String, dynamic>>()
          .map(GraphqlPostMapper.fromGraphql)
          .map(ContentDocumentResult.fromLegacyPost)
          .toList();

      final hasMore = feed['hasMore'] == true;
      _cursors[cursorKey] = feed['nextCursor']?.toString();

      return ContentEngineResult(
        items: posts,
        meta: ContentEngineMeta(
          currentPage: page,
          perPage: perPage,
          totalCandidates: hasMore
              ? page * perPage + 1
              : (page - 1) * perPage + posts.length,
          servedFromCache: false,
          queryTimeMs: 0,
          feedType: feedType,
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlFeedService] feed: $e');
      return ContentEngineResult(
        items: const [],
        meta: ContentEngineMeta(
          currentPage: page,
          perPage: perPage,
          totalCandidates: 0,
          servedFromCache: false,
          queryTimeMs: 0,
          feedType: feedType,
        ),
      );
    }
  }
}

/// Single-post fetch for detail screens.
class GraphqlPostService {
  static const _postDetailQuery = r'''
    query Post($id: ID!) {
      post(id: $id) {
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
    }
  ''';

  static Future<Post?> fetchPost(int postId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        _postDetailQuery,
        variables: {'id': postId.toString()},
      );
      final gql = data['post'] as Map<String, dynamic>?;
      if (gql == null) return null;
      return GraphqlPostMapper.fromGraphql(gql);
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlPostService] fetchPost: $e');
      return null;
    }
  }

  static const _userPostsQuery = r'''
    query UserPosts($userId: ID!, $cursor: String) {
      userPosts(userId: $userId, cursor: $cursor) {
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

  static const _deletePostMutation = r'''
    mutation DeletePost($id: ID!) {
      deletePost(id: $id)
    }
  ''';

  static final Map<int, String?> _userPostCursors = {};

  static Future<
      ({
        bool success,
        List<Post> posts,
        int currentPage,
        int lastPage,
        int perPage,
        String? message,
      })> fetchUserPosts({
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      String? cursor;
      if (page > 1) {
        cursor = _userPostCursors[userId];
        if (cursor == null) {
          return (
            success: true,
            posts: <Post>[],
            currentPage: page,
            lastPage: page,
            perPage: perPage,
            message: null,
          );
        }
      }

      final data = await TajiriGraphqlClient.instance.query(
        _userPostsQuery,
        variables: {
          'userId': userId.toString(),
          if (cursor != null) 'cursor': cursor,
        },
      );
      final conn = data['userPosts'] as Map<String, dynamic>? ?? {};
      final posts = (conn['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GraphqlPostMapper.fromGraphql)
          .toList();
      _userPostCursors[userId] = conn['nextCursor']?.toString();
      final hasMore = conn['hasMore'] == true;

      return (
        success: true,
        posts: posts,
        currentPage: page,
        lastPage: hasMore ? page + 1 : page,
        perPage: perPage,
        message: null,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlPostService] fetchUserPosts: $e');
      return (
        success: false,
        posts: <Post>[],
        currentPage: page,
        lastPage: page,
        perPage: perPage,
        message: e.toString(),
      );
    }
  }

  static Future<bool> deletePost(int postId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _deletePostMutation,
        variables: {'id': postId.toString()},
        auth: true,
      );
      return data['deletePost'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlPostService] deletePost: $e');
      return false;
    }
  }
}
