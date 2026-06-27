import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/post_models.dart';
import 'graphql_media_service.dart';
import 'graphql_post_mapper.dart';
import 'tajiri_graphql_client.dart';

/// Create posts via GraphQL `createPost` (+ `/media/upload` for attachments).
class GraphqlCreatePostService {
  static const _createPostMutation = r'''
    mutation CreatePost($input: CreatePostInput!) {
      createPost(input: $input) {
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

  static Future<Post?> createPost({
    String? content,
    String postType = 'text',
    String privacy = 'public',
    List<File>? mediaFiles,
    String? mediaType,
  }) async {
    try {
      final mediaInputs = <Map<String, dynamic>>[];
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        for (final file in mediaFiles) {
          final uploaded = await GraphqlMediaService.uploadFile(
            file,
            mediaType: mediaType ?? _guessMediaType(postType, file.path),
          );
          if (uploaded == null) return null;
          mediaInputs.add({
            'filePath': uploaded['file_path'],
            if (uploaded['blurhash'] != null) 'blurhash': uploaded['blurhash'],
            if (uploaded['width'] != null) 'width': uploaded['width'],
            if (uploaded['height'] != null) 'height': uploaded['height'],
            'mediaType': uploaded['media_type'] ?? 'image',
          });
        }
      }

      final resolvedType = mediaInputs.isNotEmpty && postType == 'text' ? 'image' : postType;

      final data = await TajiriGraphqlClient.instance.mutate(
        _createPostMutation,
        variables: {
          'input': {
            if (content != null && content.isNotEmpty) 'content': content,
            'privacy': privacy,
            'postType': resolvedType,
            if (mediaInputs.isNotEmpty) 'media': mediaInputs,
          },
        },
        auth: true,
      );
      final gql = data['createPost'] as Map<String, dynamic>?;
      if (gql == null) return null;
      return GraphqlPostMapper.fromGraphql(gql);
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlCreatePostService] createPost: $e');
      return null;
    }
  }

  static String _guessMediaType(String postType, String path) {
    if (postType == 'video' || postType == 'short_video') return 'video';
    final lower = path.toLowerCase();
    if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm')) {
      return 'video';
    }
    return 'image';
  }
}
