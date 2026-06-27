import '../../config/api_config.dart';
import '../../models/post_models.dart';

/// Maps greenfield GraphQL Post shape → legacy [Post] model for existing UI.
class GraphqlPostMapper {
  static Post fromGraphql(Map<String, dynamic> gql) {
    final author = gql['author'] as Map<String, dynamic>? ?? {};
    final counts = gql['counts'] as Map<String, dynamic>? ?? {};
    final viewer = gql['viewerState'] as Map<String, dynamic>? ?? {};
    final publishedAt = gql['publishedAt']?.toString() ?? DateTime.now().toIso8601String();
    final displayName = author['displayName']?.toString() ?? '';
    final nameParts = displayName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final mediaList = gql['media'] is List ? gql['media'] as List : <dynamic>[];
    final media = mediaList.map((m) {
      final map = m as Map<String, dynamic>;
      return PostMedia.fromJson({
        'id': 0,
        'post_id': int.tryParse(gql['id']?.toString() ?? '') ?? 0,
        'file_path': map['url'],
        'thumbnail_path': map['thumbnailUrl'],
        'blurhash': map['blurhash'],
        'media_type': map['type'] ?? 'image',
        'width': map['width'],
        'height': map['height'],
      });
    }).toList();

    return Post.fromJson({
      'id': int.tryParse(gql['id']?.toString() ?? '') ?? 0,
      'user_id': int.tryParse(author['id']?.toString() ?? '') ?? 0,
      'content': gql['caption'],
      'post_type': media.isNotEmpty ? 'image' : 'text',
      'privacy': 'public',
      'likes_count': counts['likes'] ?? 0,
      'comments_count': counts['comments'] ?? 0,
      'saves_count': counts['saves'] ?? 0,
      'views_count': counts['views'] ?? 0,
      'created_at': publishedAt,
      'updated_at': publishedAt,
      'is_liked': viewer['liked'] == true,
      'is_saved': viewer['saved'] == true,
      'user': {
        'id': int.tryParse(author['id']?.toString() ?? '') ?? 0,
        'first_name': firstName,
        'last_name': lastName,
        'username': author['username'],
        'profile_photo_url': _sanitizeUrl(author['avatarUrl']?.toString()),
      },
      'media': media.map((m) => m.toJson()).toList(),
    });
  }

  static String? _sanitizeUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://127.0.0.1:9000') ||
        url.startsWith('http://localhost:9000')) {
      final path = Uri.parse(url).path.replaceFirst(RegExp(r'^/'), '');
      return '${ApiConfig.graphqlStorageUrl}/$path';
    }
    if (url.startsWith('http://127.0.0.1:8000/media/files') ||
        url.startsWith('http://localhost:8000/media/files')) {
      final path = Uri.parse(url).path.replaceFirst('/media/files/', '');
      return '${ApiConfig.graphqlStorageUrl}/$path';
    }
    return ApiConfig.sanitizeUrl(url);
  }
}
