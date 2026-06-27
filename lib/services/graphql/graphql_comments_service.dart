import 'package:flutter/foundation.dart';

import '../../models/post_models.dart';
import 'graphql_comment_mapper.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL post comments (list, add, delete).
class GraphqlCommentsService {
  static final Map<String, String?> _cursors = {};

  static String _cursorKey(int postId, int? parentId) =>
      '${postId}_${parentId ?? 0}';

  static const _commentsQuery = r'''
    query Comments($postId: ID!, $parentId: ID, $cursor: String) {
      comments(postId: $postId, parentId: $parentId, cursor: $cursor) {
        items {
          id
          postId
          userId
          parentId
          content
          likesCount
          replyCount
          isLiked
          isPinned
          editedAt
          createdAt
          updatedAt
          author {
            id
            username
            displayName
            avatarUrl
          }
        }
        nextCursor
        hasMore
      }
    }
  ''';

  static const _addCommentMutation = r'''
    mutation AddComment($postId: ID!, $content: String!, $parentId: ID) {
      addComment(postId: $postId, content: $content, parentId: $parentId) {
        id
        postId
        userId
        parentId
        content
        likesCount
        replyCount
        isLiked
        createdAt
        updatedAt
        author {
          id
          username
          displayName
          avatarUrl
        }
      }
    }
  ''';

  static const _editCommentMutation = r'''
    mutation EditComment($commentId: ID!, $content: String!) {
      editComment(commentId: $commentId, content: $content) {
        id
        postId
        userId
        parentId
        content
        likesCount
        replyCount
        isLiked
        editedAt
        createdAt
        updatedAt
        author {
          id
          username
          displayName
          avatarUrl
        }
      }
    }
  ''';

  static const _deleteCommentMutation = r'''
    mutation DeleteComment($id: ID!) {
      deleteComment(id: $id)
    }
  ''';

  static const _likeCommentMutation = r'''
    mutation LikeComment($commentId: ID!) {
      likeComment(commentId: $commentId) {
        id
        likesCount
        isLiked
      }
    }
  ''';

  static const _unlikeCommentMutation = r'''
    mutation UnlikeComment($commentId: ID!) {
      unlikeComment(commentId: $commentId) {
        id
        likesCount
        isLiked
      }
    }
  ''';

  static const _pinCommentMutation = r'''
    mutation PinComment($postId: ID!, $commentId: ID!) {
      pinComment(postId: $postId, commentId: $commentId) {
        id
        postId
        userId
        parentId
        content
        likesCount
        replyCount
        isLiked
        isPinned
        editedAt
        createdAt
        updatedAt
        author {
          id
          username
          displayName
          avatarUrl
        }
      }
    }
  ''';

  static const _unpinCommentMutation = r'''
    mutation UnpinComment($postId: ID!) {
      unpinComment(postId: $postId)
    }
  ''';

  static Future<
      ({
        bool success,
        List<Comment> comments,
        int currentPage,
        int lastPage,
        int perPage,
        int total,
        String? message,
      })> getComments({
    required int postId,
    int? parentId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final key = _cursorKey(postId, parentId);
      String? cursor;
      if (page > 1) {
        cursor = _cursors[key];
        if (cursor == null) {
          return (
            success: true,
            comments: <Comment>[],
            currentPage: page,
            lastPage: page,
            perPage: perPage,
            total: 0,
            message: null as String?,
          );
        }
      }

      final data = await TajiriGraphqlClient.instance.query(
        _commentsQuery,
        variables: {
          'postId': postId.toString(),
          if (parentId != null) 'parentId': parentId.toString(),
          if (cursor != null) 'cursor': cursor,
        },
      );
      final conn = data['comments'] as Map<String, dynamic>? ?? {};
      final comments = (conn['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GraphqlCommentMapper.fromGraphql)
          .toList();

      _cursors[key] = conn['nextCursor']?.toString();
      final hasMore = conn['hasMore'] == true;
      final lastPage = hasMore ? page + 1 : page;
      final total = hasMore ? page * perPage + 1 : (page - 1) * perPage + comments.length;

      return (
        success: true,
        comments: comments,
        currentPage: page,
        lastPage: lastPage,
        perPage: perPage,
        total: total,
        message: null,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlCommentsService] getComments: $e');
      return (
        success: false,
        comments: <Comment>[],
        currentPage: page,
        lastPage: page,
        perPage: perPage,
        total: 0,
        message: e.toString(),
      );
    }
  }

  static Future<({bool success, Comment? comment, String? message})> addComment({
    required int postId,
    required String content,
    int? parentId,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _addCommentMutation,
        variables: {
          'postId': postId.toString(),
          'content': content,
          if (parentId != null) 'parentId': parentId.toString(),
        },
        auth: true,
      );
      final gql = data['addComment'] as Map<String, dynamic>?;
      if (gql == null) {
        return (success: false, comment: null, message: 'Failed to add comment');
      }
      return (
        success: true,
        comment: GraphqlCommentMapper.fromGraphql(gql),
        message: null,
      );
    } catch (e) {
      return (success: false, comment: null, message: e.toString());
    }
  }

  static Future<({bool success, Comment? comment, String? message})> editComment({
    required int commentId,
    required String content,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _editCommentMutation,
        variables: {
          'commentId': commentId.toString(),
          'content': content,
        },
        auth: true,
      );
      final gql = data['editComment'] as Map<String, dynamic>?;
      if (gql == null) {
        return (success: false, comment: null, message: 'Failed to update comment');
      }
      return (
        success: true,
        comment: GraphqlCommentMapper.fromGraphql(gql),
        message: null,
      );
    } catch (e) {
      return (success: false, comment: null, message: e.toString());
    }
  }

  static Future<bool> deleteComment(int commentId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _deleteCommentMutation,
        variables: {'id': commentId.toString()},
        auth: true,
      );
      return data['deleteComment'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlCommentsService] deleteComment: $e');
      return false;
    }
  }

  static Future<
      ({
        bool success,
        int? likesCount,
        bool isLiked,
      })> likeComment(int commentId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _likeCommentMutation,
        variables: {'commentId': commentId.toString()},
        auth: true,
      );
      final gql = data['likeComment'] as Map<String, dynamic>?;
      if (gql == null) return (success: false, likesCount: null, isLiked: false);
      return (
        success: true,
        likesCount: gql['likesCount'] as int?,
        isLiked: gql['isLiked'] == true,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlCommentsService] likeComment: $e');
      return (success: false, likesCount: null, isLiked: false);
    }
  }

  static Future<
      ({
        bool success,
        int? likesCount,
        bool isLiked,
      })> unlikeComment(int commentId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _unlikeCommentMutation,
        variables: {'commentId': commentId.toString()},
        auth: true,
      );
      final gql = data['unlikeComment'] as Map<String, dynamic>?;
      if (gql == null) return (success: false, likesCount: null, isLiked: false);
      return (
        success: true,
        likesCount: gql['likesCount'] as int?,
        isLiked: gql['isLiked'] == true,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlCommentsService] unlikeComment: $e');
      return (success: false, likesCount: null, isLiked: false);
    }
  }

  static Future<
      ({
        bool success,
        Comment? comment,
        String? message,
      })> pinComment({
    required int postId,
    required int commentId,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _pinCommentMutation,
        variables: {
          'postId': postId.toString(),
          'commentId': commentId.toString(),
        },
        auth: true,
      );
      final gql = data['pinComment'] as Map<String, dynamic>?;
      if (gql == null) {
        return (success: false, comment: null, message: 'Failed to pin comment');
      }
      return (
        success: true,
        comment: GraphqlCommentMapper.fromGraphql(gql),
        message: null,
      );
    } catch (e) {
      return (success: false, comment: null, message: e.toString());
    }
  }

  static Future<bool> unpinComment(int postId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _unpinCommentMutation,
        variables: {'postId': postId.toString()},
        auth: true,
      );
      return data['unpinComment'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlCommentsService] unpinComment: $e');
      return false;
    }
  }
}
