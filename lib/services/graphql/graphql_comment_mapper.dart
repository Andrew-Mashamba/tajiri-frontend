import '../../models/post_models.dart';

/// Maps GraphQL Comment → legacy REST JSON for [Comment.fromJson].
class GraphqlCommentMapper {
  static int _int(dynamic v) =>
      v is int ? v : (v != null ? int.tryParse(v.toString()) ?? 0 : 0);

  static Map<String, dynamic> toLegacy(Map<String, dynamic> gql) {
    final author = gql['author'] as Map<String, dynamic>?;
    final displayName = author?['displayName']?.toString() ?? '';
    final parts = displayName.split(' ');
    return {
      'id': _int(gql['id']),
      'post_id': _int(gql['postId']),
      'user_id': _int(gql['userId']),
      'parent_id': gql['parentId'] != null ? _int(gql['parentId']) : null,
      'content': gql['content'] ?? '',
      'likes_count': gql['likesCount'] ?? 0,
      'reply_count': gql['replyCount'] ?? 0,
      'is_liked': gql['isLiked'] == true,
      'is_pinned': gql['isPinned'] == true,
      if (gql['editedAt'] != null) 'edited_at': gql['editedAt'].toString(),
      'created_at': gql['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      'updated_at': gql['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
      if (author != null)
        'user': {
          'id': _int(author['id']),
          'first_name': parts.isNotEmpty ? parts.first : displayName,
          'last_name': parts.length > 1 ? parts.sublist(1).join(' ') : '',
          'username': author['username'],
          'profile_photo_url': author['avatarUrl'],
        },
    };
  }

  static Comment fromGraphql(Map<String, dynamic> gql) {
    return Comment.fromJson(toLegacy(gql));
  }
}
