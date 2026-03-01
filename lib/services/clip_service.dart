import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/clip_models.dart';
import '../config/api_config.dart';

String get _baseUrl => ApiConfig.baseUrl;

/// Upload progress callback
typedef UploadProgressCallback = void Function(double progress, int bytesSent, int totalBytes);

class ClipService {
  Future<ClipListResult> getClips({int page = 1, int perPage = 10, int? currentUserId}) async {
    try {
      String url = '$_baseUrl/clips?page=$page&per_page=$perPage';
      if (currentUserId != null) url += '&current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final clips = (data['data'] as List).map((c) => Clip.fromJson(c)).toList();
          return ClipListResult(success: true, clips: clips);
        }
      }
      return ClipListResult(success: false, message: 'Failed to load clips');
    } catch (e) {
      return ClipListResult(success: false, message: 'Error: $e');
    }
  }

  Future<ClipResult> createClip({
    required int userId,
    required File video,
    String? caption,
    int? musicId,
    int? musicStart,
    List<String>? hashtags,
    List<int>? mentions,
    String? locationName,
    double? latitude,
    double? longitude,
    String privacy = 'public',
    bool allowComments = true,
    bool allowDuet = true,
    bool allowStitch = true,
    bool allowDownload = true,
    int? originalClipId,
    String clipType = 'original',
    String? filter,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/clips'));

      request.fields['user_id'] = userId.toString();
      if (caption != null) request.fields['caption'] = caption;
      if (musicId != null) request.fields['music_id'] = musicId.toString();
      if (musicStart != null) request.fields['music_start'] = musicStart.toString();
      if (filter != null && filter.isNotEmpty) request.fields['filter'] = filter;
      if (hashtags != null) request.fields['hashtags'] = jsonEncode(hashtags);
      if (mentions != null) request.fields['mentions'] = jsonEncode(mentions);
      if (locationName != null) request.fields['location_name'] = locationName;
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();
      request.fields['privacy'] = privacy;
      request.fields['allow_comments'] = allowComments.toString();
      request.fields['allow_duet'] = allowDuet.toString();
      request.fields['allow_stitch'] = allowStitch.toString();
      request.fields['allow_download'] = allowDownload.toString();
      if (originalClipId != null) request.fields['original_clip_id'] = originalClipId.toString();
      request.fields['clip_type'] = clipType;

      request.files.add(await http.MultipartFile.fromPath('video', video.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return ClipResult(success: true, clip: Clip.fromJson(data['data']));
      }
      return ClipResult(success: false, message: data['message'] ?? 'Failed');
    } catch (e) {
      return ClipResult(success: false, message: 'Error: $e');
    }
  }

  Future<ClipResult> getClip(int clipId, {int? currentUserId}) async {
    try {
      String url = '$_baseUrl/clips/$clipId';
      if (currentUserId != null) url += '?current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return ClipResult(success: true, clip: Clip.fromJson(data['data']));
        }
      }
      return ClipResult(success: false, message: 'Clip not found');
    } catch (e) {
      return ClipResult(success: false, message: 'Error: $e');
    }
  }

  Future<bool> deleteClip(int clipId) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/clips/$clipId'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<ClipListResult> getUserClips(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/clips/user/$userId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final clips = (data['data'] as List).map((c) => Clip.fromJson(c)).toList();
          return ClipListResult(success: true, clips: clips);
        }
      }
      return ClipListResult(success: false, message: 'Failed');
    } catch (e) {
      return ClipListResult(success: false, message: 'Error: $e');
    }
  }

  /// Track a view on a clip
  Future<bool> viewClip(int clipId, {int? userId}) async {
    try {
      final body = <String, dynamic>{};
      if (userId != null) body['user_id'] = userId;

      final response = await http.post(
        Uri.parse('$_baseUrl/clips/$clipId/view'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> likeClip(int clipId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/clips/$clipId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unlikeClip(int clipId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/clips/$clipId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> saveClip(int clipId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/clips/$clipId/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unsaveClip(int clipId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/clips/$clipId/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> shareClip(int clipId, int userId, {String? platform}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/clips/$clipId/share'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, if (platform != null) 'platform': platform}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Add a clip to user's videos collection (repost/share to profile)
  /// This creates a reference to the original clip in the user's profile
  Future<AddToMyVideosResult> addToMyVideos(int clipId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/clips/$clipId/add-to-collection'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AddToMyVideosResult(
          success: true,
          message: data['message'] ?? 'Imeongezwa kwenye video zako',
        );
      } else if (response.statusCode == 409) {
        // Already in collection
        return AddToMyVideosResult(
          success: false,
          alreadyAdded: true,
          message: data['message'] ?? 'Video hii tayari ipo kwenye mkusanyiko wako',
        );
      }
      return AddToMyVideosResult(
        success: false,
        message: data['message'] ?? 'Imeshindwa kuongeza video',
      );
    } catch (e) {
      return AddToMyVideosResult(
        success: false,
        message: 'Hitilafu: $e',
      );
    }
  }

  /// Remove a clip from user's videos collection
  Future<bool> removeFromMyVideos(int clipId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/clips/$clipId/add-to-collection'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Check if a clip is in user's videos collection
  Future<bool> isInMyVideos(int clipId, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/clips/$clipId/in-collection?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['in_collection'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<CommentsResult> getComments(int clipId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/clips/$clipId/comments'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final comments = (data['data'] as List).map((c) => ClipComment.fromJson(c)).toList();
          return CommentsResult(success: true, comments: comments);
        }
      }
      return CommentsResult(success: false, message: 'Failed');
    } catch (e) {
      return CommentsResult(success: false, message: 'Error: $e');
    }
  }

  Future<CommentResult> addComment(int clipId, int userId, String content, {int? parentId}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/clips/$clipId/comments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'content': content,
          if (parentId != null) 'parent_id': parentId,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return CommentResult(success: true, comment: ClipComment.fromJson(data['data']));
      }
      return CommentResult(success: false, message: data['message'] ?? 'Failed');
    } catch (e) {
      return CommentResult(success: false, message: 'Error: $e');
    }
  }

  Future<bool> likeComment(int clipId, int commentId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/clips/$clipId/comments/$commentId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<HashtagsResult> getTrendingHashtags() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/clips/trending'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final hashtags = (data['data'] as List).map((h) => ClipHashtag.fromJson(h)).toList();
          return HashtagsResult(success: true, hashtags: hashtags);
        }
      }
      return HashtagsResult(success: false, message: 'Failed');
    } catch (e) {
      return HashtagsResult(success: false, message: 'Error: $e');
    }
  }

  Future<ClipListResult> getClipsByHashtag(String tag) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/clips/hashtag/$tag'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final clips = (data['data'] as List).map((c) => Clip.fromJson(c)).toList();
          return ClipListResult(success: true, clips: clips);
        }
      }
      return ClipListResult(success: false, message: 'Failed');
    } catch (e) {
      return ClipListResult(success: false, message: 'Error: $e');
    }
  }

  Future<ClipListResult> getClipsByMusic(int musicId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/clips/music/$musicId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final clips = (data['data'] as List).map((c) => Clip.fromJson(c)).toList();
          return ClipListResult(success: true, clips: clips);
        }
      }
      return ClipListResult(success: false, message: 'Failed');
    } catch (e) {
      return ClipListResult(success: false, message: 'Error: $e');
    }
  }

  // ============================================================================
  // Upload with Progress Tracking
  // ============================================================================

  /// Upload a video clip with progress tracking
  /// Returns a stream of upload progress events
  Stream<UploadProgress> uploadClipWithProgress({
    required int userId,
    required File video,
    File? thumbnail,
    String? caption,
    int? musicId,
    int? musicStart,
    List<String>? hashtags,
    List<int>? mentions,
    String? locationName,
    double? latitude,
    double? longitude,
    String privacy = 'public',
    bool allowComments = true,
    bool allowDuet = true,
    bool allowStitch = true,
    bool allowDownload = true,
    int? originalClipId,
    String clipType = 'original',
  }) async* {
    try {
      // Get file size
      final fileSize = await video.length();
      final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);

      debugPrint('[ClipService] Starting upload: ${video.path} ($fileSizeMB MB)');

      yield UploadProgress(
        state: UploadState.preparing,
        progress: 0.0,
        message: 'Inaandaa video...',
      );

      // Prepare multipart request
      final uri = Uri.parse('$_baseUrl/clips');
      final request = http.MultipartRequest('POST', uri);

      // Add fields
      request.fields['user_id'] = userId.toString();
      if (caption != null) request.fields['caption'] = caption;
      if (musicId != null) request.fields['music_id'] = musicId.toString();
      if (musicStart != null) request.fields['music_start'] = musicStart.toString();
      if (hashtags != null && hashtags.isNotEmpty) {
        request.fields['hashtags'] = jsonEncode(hashtags);
      }
      if (mentions != null && mentions.isNotEmpty) {
        request.fields['mentions'] = jsonEncode(mentions);
      }
      if (locationName != null) request.fields['location_name'] = locationName;
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();
      request.fields['privacy'] = privacy;
      request.fields['allow_comments'] = allowComments.toString();
      request.fields['allow_duet'] = allowDuet.toString();
      request.fields['allow_stitch'] = allowStitch.toString();
      request.fields['allow_download'] = allowDownload.toString();
      if (originalClipId != null) request.fields['original_clip_id'] = originalClipId.toString();
      request.fields['clip_type'] = clipType;

      // Add video file
      final videoFileName = video.path.split('/').last;
      final videoExtension = videoFileName.split('.').last.toLowerCase();
      final videoContentType = _getVideoContentType(videoExtension);

      request.files.add(await http.MultipartFile.fromPath(
        'video',
        video.path,
        contentType: MediaType.parse(videoContentType),
      ));

      // Add thumbnail if provided
      if (thumbnail != null && await thumbnail.exists()) {
        request.files.add(await http.MultipartFile.fromPath(
          'thumbnail',
          thumbnail.path,
          contentType: MediaType.parse('image/jpeg'),
        ));
      }

      yield UploadProgress(
        state: UploadState.uploading,
        progress: 0.0,
        message: 'Inapakia video...',
        bytesSent: 0,
        totalBytes: fileSize,
      );

      // Send request with progress tracking
      final streamedResponse = await request.send();

      // Track upload progress
      int bytesSent = 0;
      final totalBytes = fileSize;

      // Listen to response
      final responseBytes = <int>[];

      await for (final chunk in streamedResponse.stream) {
        responseBytes.addAll(chunk);
        bytesSent += chunk.length;

        final progress = bytesSent / totalBytes;
        yield UploadProgress(
          state: UploadState.uploading,
          progress: progress.clamp(0.0, 1.0),
          message: 'Inapakia... ${(progress * 100).toStringAsFixed(0)}%',
          bytesSent: bytesSent,
          totalBytes: totalBytes,
        );
      }

      yield UploadProgress(
        state: UploadState.processing,
        progress: 1.0,
        message: 'Inachakata video...',
      );

      // Parse response
      final responseBody = String.fromCharCodes(responseBytes);
      final data = jsonDecode(responseBody);

      if (streamedResponse.statusCode == 201 && data['success'] == true) {
        final clip = Clip.fromJson(data['data']);
        debugPrint('[ClipService] Upload successful: Clip ID ${clip.id}');

        yield UploadProgress(
          state: UploadState.completed,
          progress: 1.0,
          message: 'Video imepakiwa!',
          clip: clip,
        );
      } else {
        final errorMessage = data['message'] ?? 'Imeshindwa kupakia video';
        debugPrint('[ClipService] Upload failed: $errorMessage');

        yield UploadProgress(
          state: UploadState.failed,
          progress: 0.0,
          message: errorMessage,
          error: errorMessage,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[ClipService] Upload error: $e');
      debugPrint('[ClipService] Stack: $stackTrace');

      yield UploadProgress(
        state: UploadState.failed,
        progress: 0.0,
        message: 'Hitilafu: ${e.toString()}',
        error: e.toString(),
      );
    }
  }

  String _getVideoContentType(String extension) {
    switch (extension) {
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      case '3gp':
        return 'video/3gpp';
      default:
        return 'video/mp4';
    }
  }

  // ============================================================================
  // Video Search
  // ============================================================================

  /// Search clips by query (caption, hashtags, user)
  Future<ClipSearchResult> searchClips({
    required String query,
    SearchType type = SearchType.all,
    int page = 1,
    int perPage = 20,
    int? currentUserId,
  }) async {
    try {
      debugPrint('[ClipService] Searching clips: "$query" (type: ${type.name})');

      final params = <String, String>{
        'q': query,
        'type': type.name,
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (currentUserId != null) {
        params['current_user_id'] = currentUserId.toString();
      }

      final uri = Uri.parse('$_baseUrl/clips/search').replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final clips = (data['data'] as List)
              .map((c) => Clip.fromJson(c))
              .toList();

          // Parse related data if available
          final users = data['users'] != null
              ? (data['users'] as List).map((u) => ClipUser.fromJson(u)).toList()
              : <ClipUser>[];

          final hashtags = data['hashtags'] != null
              ? (data['hashtags'] as List).map((h) => ClipHashtag.fromJson(h)).toList()
              : <ClipHashtag>[];

          return ClipSearchResult(
            success: true,
            clips: clips,
            users: users,
            hashtags: hashtags,
            query: query,
            meta: data['meta'] != null ? SearchMeta.fromJson(data['meta']) : null,
          );
        }
      }

      return ClipSearchResult(
        success: false,
        message: 'Hakuna matokeo',
        query: query,
      );
    } catch (e) {
      debugPrint('[ClipService] Search error: $e');
      return ClipSearchResult(
        success: false,
        message: 'Error: $e',
        query: query,
      );
    }
  }

  /// Get search suggestions based on partial query
  Future<List<SearchSuggestion>> getSearchSuggestions(String query) async {
    if (query.length < 2) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/clips/search/suggestions?q=$query'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((s) => SearchSuggestion.fromJson(s))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get recent searches for user
  Future<List<String>> getRecentSearches(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId/recent-searches?type=clips'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<String>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Save a search to history
  Future<void> saveSearch(int userId, String query) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/users/$userId/recent-searches'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query, 'type': 'clips'}),
      );
    } catch (e) {
      // Ignore errors
    }
  }

  /// Clear search history
  Future<void> clearSearchHistory(int userId) async {
    try {
      await http.delete(
        Uri.parse('$_baseUrl/users/$userId/recent-searches?type=clips'),
      );
    } catch (e) {
      // Ignore errors
    }
  }
}

// ============================================================================
// Upload Progress Model
// ============================================================================

enum UploadState {
  preparing,
  uploading,
  processing,
  completed,
  failed,
  cancelled,
}

class UploadProgress {
  final UploadState state;
  final double progress; // 0.0 to 1.0
  final String message;
  final int? bytesSent;
  final int? totalBytes;
  final Clip? clip;
  final String? error;

  UploadProgress({
    required this.state,
    required this.progress,
    required this.message,
    this.bytesSent,
    this.totalBytes,
    this.clip,
    this.error,
  });

  bool get isComplete => state == UploadState.completed;
  bool get isFailed => state == UploadState.failed;
  bool get isUploading => state == UploadState.uploading;

  String get progressText {
    if (bytesSent != null && totalBytes != null && totalBytes! > 0) {
      final sentMB = (bytesSent! / (1024 * 1024)).toStringAsFixed(1);
      final totalMB = (totalBytes! / (1024 * 1024)).toStringAsFixed(1);
      return '$sentMB / $totalMB MB';
    }
    return '${(progress * 100).toStringAsFixed(0)}%';
  }
}

// ============================================================================
// Search Models
// ============================================================================

enum SearchType {
  all,
  clips,
  users,
  hashtags,
  sounds,
}

class ClipSearchResult {
  final bool success;
  final List<Clip> clips;
  final List<ClipUser> users;
  final List<ClipHashtag> hashtags;
  final String query;
  final SearchMeta? meta;
  final String? message;

  ClipSearchResult({
    required this.success,
    this.clips = const [],
    this.users = const [],
    this.hashtags = const [],
    required this.query,
    this.meta,
    this.message,
  });

  bool get hasResults => clips.isNotEmpty || users.isNotEmpty || hashtags.isNotEmpty;
}

class SearchMeta {
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  SearchMeta({
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });

  factory SearchMeta.fromJson(Map<String, dynamic> json) {
    return SearchMeta(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      total: json['total'] ?? 0,
      perPage: json['per_page'] ?? 20,
    );
  }

  bool get hasMore => currentPage < lastPage;
}

class SearchSuggestion {
  final String text;
  final SearchSuggestionType type;
  final int? id;
  final String? imageUrl;
  final int? count;

  SearchSuggestion({
    required this.text,
    required this.type,
    this.id,
    this.imageUrl,
    this.count,
  });

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      text: json['text'] ?? '',
      type: SearchSuggestionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => SearchSuggestionType.query,
      ),
      id: json['id'],
      imageUrl: json['image_url'],
      count: json['count'],
    );
  }
}

enum SearchSuggestionType {
  query,
  user,
  hashtag,
  sound,
}

// Result classes
class ClipListResult {
  final bool success;
  final List<Clip> clips;
  final String? message;

  ClipListResult({required this.success, this.clips = const [], this.message});
}

class ClipResult {
  final bool success;
  final Clip? clip;
  final String? message;

  ClipResult({required this.success, this.clip, this.message});
}

class CommentsResult {
  final bool success;
  final List<ClipComment> comments;
  final String? message;

  CommentsResult({required this.success, this.comments = const [], this.message});
}

class CommentResult {
  final bool success;
  final ClipComment? comment;
  final String? message;

  CommentResult({required this.success, this.comment, this.message});
}

class HashtagsResult {
  final bool success;
  final List<ClipHashtag> hashtags;
  final String? message;

  HashtagsResult({required this.success, this.hashtags = const [], this.message});
}

class AddToMyVideosResult {
  final bool success;
  final bool alreadyAdded;
  final String? message;

  AddToMyVideosResult({
    required this.success,
    this.alreadyAdded = false,
    this.message,
  });
}
