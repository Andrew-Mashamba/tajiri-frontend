import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../models/post_models.dart';
import '../config/api_config.dart';

String get _baseUrl => ApiConfig.baseUrl;

/// Threshold for using chunked upload (10MB)
const int _largeFileThreshold = 10 * 1024 * 1024;

/// Dio instance for large file uploads with proper timeouts
Dio? _dio;

Dio _getDio() {
  _dio ??= Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(minutes: 2),
    receiveTimeout: const Duration(minutes: 10),
    sendTimeout: const Duration(minutes: 10),
    headers: {'Accept': 'application/json'},
  ));
  return _dio!;
}

void _log(String message) {
  debugPrint('[PostService] $message');
}

/// Log detailed server error and return user-friendly message
String _handleServerError(Map<String, dynamic> data, int statusCode) {
  // Log full server response details
  _log('=== SERVER ERROR DETAILS ===');
  _log('Status Code: $statusCode');
  _log('Full Response: $data');

  // Log validation errors in detail
  if (data.containsKey('errors') && data['errors'] is Map) {
    final errors = data['errors'] as Map<String, dynamic>;
    _log('Validation Errors:');
    errors.forEach((field, messages) {
      _log('  - $field: $messages');
    });
  }

  // Log message
  if (data.containsKey('message')) {
    _log('Server Message: ${data['message']}');
  }

  // Log error
  if (data.containsKey('error')) {
    _log('Server Error: ${data['error']}');
  }

  // Log exception if present
  if (data.containsKey('exception')) {
    _log('Exception: ${data['exception']}');
  }

  // Log file if present (Laravel debug)
  if (data.containsKey('file')) {
    _log('File: ${data['file']}');
  }

  // Log line if present (Laravel debug)
  if (data.containsKey('line')) {
    _log('Line: ${data['line']}');
  }

  // Log trace if present
  if (data.containsKey('trace')) {
    _log('Trace: ${data['trace'].toString().substring(0, 500)}...');
  }

  _log('=== END ERROR DETAILS ===');

  // Return user-friendly message for UI
  switch (statusCode) {
    case 400:
      return 'Invalid request. Please try again.';
    case 401:
      return 'Please log in again.';
    case 403:
      return 'You don\'t have permission for this action.';
    case 404:
      return 'Resource not found.';
    case 413:
      return 'File too large. Please use a smaller file.';
    case 422:
      return 'Please check your input and try again.';
    case 500:
      return 'Server error. Please try again later.';
    default:
      return 'Something went wrong. Please try again.';
  }
}

class PostService {
  /// Get posts for a user's wall
  Future<PostListResult> getUserPosts({
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    _log('=== GET USER POSTS ===');
    _log('userId: $userId, page: $page, perPage: $perPage');

    try {
      final url = '$_baseUrl/users/$userId/posts?page=$page&per_page=$perPage';
      _log('Request URL: $url');

      final response = await http.get(Uri.parse(url));

      _log('Response status: ${response.statusCode}');
      _log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final posts = (data['data'] as List)
              .map((p) => Post.fromJson(p))
              .toList();
          _log('Loaded ${posts.length} posts');
          return PostListResult(
            success: true,
            posts: posts,
            meta: PaginationMeta.fromJson(data['meta'] ?? {}),
          );
        }
      }
      _log('Failed to load posts');
      return PostListResult(success: false, message: 'Failed to load posts');
    } catch (e, stackTrace) {
      _log('EXCEPTION: $e');
      _log('Stack trace: $stackTrace');
      return PostListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get posts by query parameters.
  /// - [userId] Required: requesting user (for auth/context).
  /// - [profileUserId] Optional: when set, returns only that user's posts (profile timeline).
  ///   When omitted, returns global timeline (all public posts from everyone).
  Future<PostListResult> getPosts({
    int? userId,
    int? profileUserId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      String url = '$_baseUrl/posts?page=$page&per_page=$perPage';
      if (userId != null) url += '&user_id=$userId';
      if (profileUserId != null) url += '&profile_user_id=$profileUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final rawList = data['data'] as List;
          final posts = <Post>[];
          for (var i = 0; i < rawList.length; i++) {
            try {
              posts.add(Post.fromJson(rawList[i] as Map<String, dynamic>));
            } catch (e) {
              _log('Skip post index $i: $e');
            }
          }
          return PostListResult(
            success: true,
            posts: posts,
            meta: PaginationMeta.fromJson(data['meta'] ?? {}),
          );
        }
        _log('getPosts: success!=true or data null. keys=${data is Map ? (data as Map).keys.toList() : []}');
      } else {
        _log('getPosts: status=${response.statusCode} body=${response.body.length} chars');
      }
      return PostListResult(success: false, message: 'Failed to load posts');
    } catch (e) {
      return PostListResult(success: false, message: 'Error: $e');
    }
  }

  /// Create a new post
  ///
  /// For large video files (>10MB), uses Dio with proper chunked streaming
  /// and longer timeouts to prevent connection resets.
  ///
  /// [onProgress] callback reports upload progress (0.0 to 1.0)
  Future<PostResult> createPost({
    required int userId,
    String? content,
    String postType = 'text',
    String privacy = 'public',
    String? locationName,
    List<int>? taggedUsers,
    List<File>? media,
    // New fields for enhanced post types
    String? backgroundColor,
    File? audioFile,
    int? audioDuration,
    File? coverImage,
    int? musicTrackId,
    int? musicStartTime,
    double? originalAudioVolume,
    double? musicVolume,
    double? videoSpeed,
    String? videoFilter,
    List<Map<String, dynamic>>? textOverlays,
    // Progress callback for large uploads
    void Function(double progress)? onProgress,
    bool allowComments = true,
  }) async {
    _log('=== CREATE POST START ===');
    _log('userId: $userId');
    _log('content: ${content ?? "(empty)"}');
    _log('postType: $postType');
    _log('privacy: $privacy');
    _log('locationName: $locationName');
    _log('taggedUsers: $taggedUsers');
    _log('media count: ${media?.length ?? 0}');
    _log('audioFile: ${audioFile?.path ?? "(none)"}');
    _log('coverImage: ${coverImage?.path ?? "(none)"}');

    try {
      // Use multipart request if there are any files to upload (media, audio, or cover image)
      final hasFilesToUpload = (media != null && media.isNotEmpty) ||
          (audioFile != null && audioFile.existsSync()) ||
          (coverImage != null && coverImage.existsSync());

      if (hasFilesToUpload) {
        // Check total file size to determine upload method
        int totalFileSize = 0;
        if (media != null) {
          for (var file in media) {
            if (file.existsSync()) {
              totalFileSize += file.lengthSync();
            }
          }
        }
        if (audioFile != null && audioFile.existsSync()) {
          totalFileSize += audioFile.lengthSync();
        }
        if (coverImage != null && coverImage.existsSync()) {
          totalFileSize += coverImage.lengthSync();
        }

        final useDio = totalFileSize > _largeFileThreshold;
        _log('Total file size: ${(totalFileSize / (1024 * 1024)).toStringAsFixed(2)} MB');
        _log('Using ${useDio ? 'Dio (large file)' : 'http (small file)'} for upload');

        // Log media files
        if (media != null) {
          for (int i = 0; i < media.length; i++) {
            final file = media[i];
            _log('Media[$i]: ${file.path}');
            _log('  exists: ${file.existsSync()}');
            if (file.existsSync()) {
              _log('  size: ${file.lengthSync()} bytes');
            }
          }
        }

        if (useDio) {
          // Use Dio for large file uploads with proper chunked streaming
          return await _createPostWithDio(
            userId: userId,
            content: content,
            postType: postType,
            privacy: privacy,
            locationName: locationName,
            taggedUsers: taggedUsers,
            media: media,
            backgroundColor: backgroundColor,
            audioFile: audioFile,
            audioDuration: audioDuration,
            coverImage: coverImage,
            musicTrackId: musicTrackId,
            musicStartTime: musicStartTime,
            originalAudioVolume: originalAudioVolume,
            musicVolume: musicVolume,
            videoSpeed: videoSpeed,
            videoFilter: videoFilter,
            textOverlays: textOverlays,
            onProgress: onProgress,
            allowComments: allowComments,
          );
        }

        // Use standard http multipart for smaller files
        _log('Using multipart request for file upload');

        // Use multipart request for media uploads
        var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/posts'));

        // Add headers to ensure JSON response (even for errors)
        request.headers['Accept'] = 'application/json';

        request.fields['user_id'] = userId.toString();
        if (content != null) request.fields['content'] = content;
        request.fields['post_type'] = postType;
        request.fields['privacy'] = privacy;
        if (postType == 'short_video') request.fields['is_short_video'] = 'true';
        if (locationName != null) request.fields['location_name'] = locationName;

        // New fields for enhanced post types
        if (backgroundColor != null) request.fields['background_color'] = backgroundColor;
        if (musicTrackId != null) request.fields['music_track_id'] = musicTrackId.toString();
        if (musicStartTime != null) request.fields['music_start_time'] = musicStartTime.toString();
        if (originalAudioVolume != null) request.fields['original_audio_volume'] = originalAudioVolume.toString();
        if (musicVolume != null) request.fields['music_volume'] = musicVolume.toString();
        if (videoSpeed != null) request.fields['video_speed'] = videoSpeed.toString();
        if (videoFilter != null) request.fields['video_filter'] = videoFilter;
        if (textOverlays != null) request.fields['text_overlays'] = jsonEncode(textOverlays);
        // Multipart form sends strings; backend expects boolean-like value (accept '1'/'0' or 'true'/'false')
        request.fields['allow_comments'] = allowComments ? '1' : '0';

        // Add audio file if present
        if (audioFile != null && audioFile.existsSync()) {
          final audioMultipart = await http.MultipartFile.fromPath('audio', audioFile.path);
          request.files.add(audioMultipart);
          _log('Added audio file: ${audioMultipart.filename}');
        }
        if (audioDuration != null) {
          request.fields['audio_duration'] = audioDuration.toString();
          _log('audio_duration: $audioDuration');
        }

        // Add cover image if present
        if (coverImage != null && coverImage.existsSync()) {
          final coverMultipart = await http.MultipartFile.fromPath('cover_image', coverImage.path);
          request.files.add(coverMultipart);
          _log('Added cover image: ${coverMultipart.filename}');
        }

        _log('Request fields: ${request.fields}');

        // Add media files if present
        if (media != null) {
          for (var file in media) {
            if (file.existsSync()) {
              final multipartFile = await http.MultipartFile.fromPath('media[]', file.path);
              request.files.add(multipartFile);
              _log('Added file: ${multipartFile.filename}, size: ${multipartFile.length}');
            } else {
              _log('WARNING: File does not exist: ${file.path}');
            }
          }
        }

        _log('Sending multipart request to: ${request.url}');
        _log('Files count: ${request.files.length}');

        final streamedResponse = await request.send();
        _log('Response status: ${streamedResponse.statusCode}');

        final response = await http.Response.fromStream(streamedResponse);
        _log('Response body: ${response.body}');

        try {
          final data = jsonDecode(response.body);
          _log('Parsed response: $data');

          if (response.statusCode == 201 && data['success'] == true) {
            _log('Post created successfully!');
            return PostResult(
              success: true,
              post: Post.fromJson(data['data']),
              message: data['message'],
            );
          }

          // Handle validation errors (422) and other errors
          String errorMessage = _handleServerError(data, response.statusCode);
          _log('Post creation failed: $errorMessage');
          return PostResult(success: false, message: errorMessage);
        } catch (parseError) {
          _log('=== SERVER RETURNED NON-JSON RESPONSE ===');
          _log('Status Code: ${response.statusCode}');
          _log('Parse Error: $parseError');

          // Check if it's an HTML error page
          if (response.body.contains('<!DOCTYPE html>') || response.body.contains('<html')) {
            _log('Server returned HTML error page (Laravel exception)');
            // Try to extract error message from HTML
            final titleMatch = RegExp(r'<title>(.*?)</title>').firstMatch(response.body);
            if (titleMatch != null) {
              _log('Page Title: ${titleMatch.group(1)}');
            }
            // Look for exception message in Ignition page
            final messageMatch = RegExp(r'message&quot;:&quot;(.*?)&quot;').firstMatch(response.body);
            if (messageMatch != null) {
              _log('Exception Message: ${messageMatch.group(1)}');
            }
          } else {
            _log('Raw response (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
          }
          _log('=== END NON-JSON RESPONSE ===');

          return PostResult(
            success: false,
            message: 'Server error. Please try again later.',
          );
        }
      } else {
        _log('Using JSON request for text-only post');

        final requestBody = jsonEncode({
          'user_id': userId,
          'content': content,
          'post_type': postType,
          'privacy': privacy,
          'location_name': locationName,
          'tagged_users': taggedUsers,
          if (postType == 'short_video') 'is_short_video': true,
          // New fields for enhanced post types
          if (backgroundColor != null) 'background_color': backgroundColor,
          if (musicTrackId != null) 'music_track_id': musicTrackId,
          if (musicStartTime != null) 'music_start_time': musicStartTime,
          if (originalAudioVolume != null) 'original_audio_volume': originalAudioVolume,
          if (musicVolume != null) 'music_volume': musicVolume,
          if (videoSpeed != null) 'video_speed': videoSpeed,
          if (videoFilter != null) 'video_filter': videoFilter,
          if (textOverlays != null) 'text_overlays': textOverlays,
          'allow_comments': allowComments,
        });

        _log('Request URL: $_baseUrl/posts');
        _log('Request body: $requestBody');

        final response = await http.post(
          Uri.parse('$_baseUrl/posts'),
          headers: {'Content-Type': 'application/json'},
          body: requestBody,
        );

        _log('Response status: ${response.statusCode}');
        _log('Response body: ${response.body}');

        try {
          final data = jsonDecode(response.body);
          _log('Parsed response: $data');

          if (response.statusCode == 201 && data['success'] == true) {
            _log('Post created successfully!');
            return PostResult(
              success: true,
              post: Post.fromJson(data['data']),
              message: data['message'],
            );
          }

          // Handle validation errors (422) and other errors
          String errorMessage = _handleServerError(data, response.statusCode);
          _log('Post creation failed: $errorMessage');
          return PostResult(success: false, message: errorMessage);
        } catch (parseError) {
          _log('=== SERVER RETURNED NON-JSON RESPONSE ===');
          _log('Status Code: ${response.statusCode}');
          _log('Parse Error: $parseError');

          if (response.body.contains('<!DOCTYPE html>') || response.body.contains('<html')) {
            _log('Server returned HTML error page (Laravel exception)');
            final titleMatch = RegExp(r'<title>(.*?)</title>').firstMatch(response.body);
            if (titleMatch != null) {
              _log('Page Title: ${titleMatch.group(1)}');
            }
            final messageMatch = RegExp(r'message&quot;:&quot;(.*?)&quot;').firstMatch(response.body);
            if (messageMatch != null) {
              _log('Exception Message: ${messageMatch.group(1)}');
            }
          } else {
            _log('Raw response (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
          }
          _log('=== END NON-JSON RESPONSE ===');

          return PostResult(
            success: false,
            message: 'Server error. Please try again later.',
          );
        }
      }
    } catch (e, stackTrace) {
      _log('EXCEPTION: $e');
      _log('Stack trace: $stackTrace');
      return PostResult(success: false, message: 'Error: $e');
    } finally {
      _log('=== CREATE POST END ===');
    }
  }

  /// Internal method to create post using Dio for large file uploads
  /// Provides proper chunked streaming, longer timeouts, and progress tracking
  Future<PostResult> _createPostWithDio({
    required int userId,
    String? content,
    String postType = 'text',
    String privacy = 'public',
    String? locationName,
    List<int>? taggedUsers,
    List<File>? media,
    String? backgroundColor,
    File? audioFile,
    int? audioDuration,
    File? coverImage,
    int? musicTrackId,
    int? musicStartTime,
    double? originalAudioVolume,
    double? musicVolume,
    double? videoSpeed,
    String? videoFilter,
    List<Map<String, dynamic>>? textOverlays,
    void Function(double progress)? onProgress,
    bool allowComments = true,
  }) async {
    _log('=== DIO UPLOAD START ===');

    try {
      final dio = _getDio();

      // Build form data
      final formData = FormData.fromMap({
        'user_id': userId.toString(),
        if (content != null) 'content': content,
        'post_type': postType,
        'privacy': privacy,
        if (postType == 'short_video') 'is_short_video': 'true',
        if (locationName != null) 'location_name': locationName,
        if (backgroundColor != null) 'background_color': backgroundColor,
        if (musicTrackId != null) 'music_track_id': musicTrackId.toString(),
        if (musicStartTime != null) 'music_start_time': musicStartTime.toString(),
        if (originalAudioVolume != null) 'original_audio_volume': originalAudioVolume.toString(),
        if (musicVolume != null) 'music_volume': musicVolume.toString(),
        if (videoSpeed != null) 'video_speed': videoSpeed.toString(),
        if (videoFilter != null) 'video_filter': videoFilter,
        if (textOverlays != null) 'text_overlays': jsonEncode(textOverlays),
        if (audioDuration != null) 'audio_duration': audioDuration.toString(),
        'allow_comments': allowComments ? '1' : '0',
      });

      // Add audio file if present
      if (audioFile != null && audioFile.existsSync()) {
        formData.files.add(MapEntry(
          'audio',
          await MultipartFile.fromFile(audioFile.path, filename: audioFile.path.split('/').last),
        ));
        _log('Added audio file: ${audioFile.path}');
      }

      // Add cover image if present
      if (coverImage != null && coverImage.existsSync()) {
        formData.files.add(MapEntry(
          'cover_image',
          await MultipartFile.fromFile(coverImage.path, filename: coverImage.path.split('/').last),
        ));
        _log('Added cover image: ${coverImage.path}');
      }

      // Add media files if present
      if (media != null) {
        for (var file in media) {
          if (file.existsSync()) {
            formData.files.add(MapEntry(
              'media[]',
              await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
            ));
            _log('Added media file: ${file.path} (${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB)');
          }
        }
      }

      _log('Sending Dio request to: /posts');
      _log('Files count: ${formData.files.length}');

      final response = await dio.post(
        '/posts',
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            final progress = sent / total;
            _log('Upload progress: ${(progress * 100).toStringAsFixed(1)}% ($sent / $total bytes)');
            onProgress?.call(progress);
          }
        },
      );

      _log('Response status: ${response.statusCode}');
      _log('Response data: ${response.data}');

      final data = response.data;

      if (response.statusCode == 201 && data['success'] == true) {
        _log('Post created successfully via Dio!');
        return PostResult(
          success: true,
          post: Post.fromJson(data['data']),
          message: data['message'],
        );
      }

      // Handle error
      String errorMessage = _handleServerError(data is Map<String, dynamic> ? data : {}, response.statusCode ?? 500);
      _log('Post creation failed: $errorMessage');
      return PostResult(success: false, message: errorMessage);

    } on DioException catch (e) {
      _log('=== DIO EXCEPTION ===');
      _log('Type: ${e.type}');
      _log('Message: ${e.message}');
      _log('Error: ${e.error}');

      String errorMessage;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage = 'Connection timeout. Check your internet connection.';
          break;
        case DioExceptionType.sendTimeout:
          errorMessage = 'Upload taking too long. Try again with a smaller file or better connection.';
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Server not responding. Please try again.';
          break;
        case DioExceptionType.badResponse:
          // Try to parse error from response
          if (e.response?.data is Map<String, dynamic>) {
            errorMessage = _handleServerError(e.response!.data, e.response!.statusCode ?? 500);
          } else {
            errorMessage = 'Server error: ${e.response?.statusCode}';
          }
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Upload cancelled.';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'No internet connection. Please check your network.';
          break;
        default:
          errorMessage = 'Upload failed: ${e.message}';
      }

      return PostResult(success: false, message: errorMessage);
    } catch (e, stackTrace) {
      _log('=== UNEXPECTED ERROR ===');
      _log('Error: $e');
      _log('Stack trace: $stackTrace');
      return PostResult(success: false, message: 'Unexpected error: $e');
    } finally {
      _log('=== DIO UPLOAD END ===');
    }
  }

  /// Get a single post
  Future<PostResult> getPost(int postId, {int? currentUserId}) async {
    try {
      String url = '$_baseUrl/posts/$postId';
      if (currentUserId != null) url += '?current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return PostResult(success: true, post: Post.fromJson(data['data']));
        }
      }
      return PostResult(success: false, message: 'Post not found');
    } catch (e) {
      return PostResult(success: false, message: 'Error: $e');
    }
  }

  /// Update a post
  Future<PostResult> updatePost(
    int postId, {
    String? content,
    String? privacy,
    String? locationName,
    bool? isPinned,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/posts/$postId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (content != null) 'content': content,
          if (privacy != null) 'privacy': privacy,
          if (locationName != null) 'location_name': locationName,
          if (isPinned != null) 'is_pinned': isPinned,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return PostResult(
          success: true,
          post: Post.fromJson(data['data']),
          message: data['message'],
        );
      }
      return PostResult(success: false, message: data['message'] ?? 'Failed to update post');
    } catch (e) {
      return PostResult(success: false, message: 'Error: $e');
    }
  }

  /// Delete a post
  Future<bool> deletePost(int postId) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/posts/$postId'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Like a post
  Future<LikeResult> likePost(int postId, int userId, {String reactionType = 'like'}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/posts/$postId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'reaction_type': reactionType,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return LikeResult(
          success: true,
          likesCount: data['data']['likes_count'],
        );
      }
      return LikeResult(success: false);
    } catch (e) {
      return LikeResult(success: false);
    }
  }

  /// Unlike a post
  Future<LikeResult> unlikePost(int postId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/posts/$postId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return LikeResult(
          success: true,
          likesCount: data['data']['likes_count'],
        );
      }
      return LikeResult(success: false);
    } catch (e) {
      return LikeResult(success: false);
    }
  }

  /// Get comments for a post
  Future<CommentListResult> getComments(int postId, {int page = 1, int perPage = 20}) async {
    final url = '$_baseUrl/posts/$postId/comments?page=$page&per_page=$perPage';
    _log('getComments: request postId=$postId page=$page url=$url');
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8), onTimeout: () {
        _log('getComments: timeout after 8s');
        throw Exception('Connection timed out');
      });

      _log('getComments: response statusCode=${response.statusCode} bodyLength=${response.body.length}');
      final body = response.body;
      Map<String, dynamic>? data;
      try {
        data = body.isNotEmpty ? jsonDecode(body) as Map<String, dynamic>? : null;
      } catch (_) {
        _log('getComments: invalid JSON (status ${response.statusCode})');
        return CommentListResult(
          success: false,
          message: response.statusCode >= 400
              ? 'Server error. Try again.'
              : 'Failed to load comments',
        );
      }

      if (response.statusCode == 200 && data != null && data['success'] == true) {
        final rawList = data['data'];
        if (rawList == null || rawList is! List) {
          return CommentListResult(
            success: true,
            comments: [],
            meta: PaginationMeta.fromJson(data['meta'] ?? {}),
          );
        }
        final comments = <Comment>[];
        for (final item in rawList) {
          if (item is! Map<String, dynamic>) continue;
          try {
            comments.add(Comment.fromJson(item));
          } catch (e) {
            _log('getComments: skip invalid comment item: $e');
          }
        }
        final meta = PaginationMeta.fromJson(data['meta'] ?? {});
        _log('getComments: returning success count=${comments.length} hasMore=${meta.hasMore} total=${meta.total}');
        return CommentListResult(
          success: true,
          comments: comments,
          meta: meta,
        );
      }

      final message = data?['message'] ?? (response.statusCode >= 400 ? 'Server error. Try again.' : 'Failed to load comments');
      _log('getComments: returning failure message=$message');
      return CommentListResult(success: false, message: message is String ? message : 'Failed to load comments');
    } catch (e) {
      _log('getComments error: $e');
      return CommentListResult(success: false, message: e.toString());
    }
  }

  /// Add a comment to a post (optional mentions for @tagging).
  Future<CommentResult> addComment(
    int postId,
    int userId,
    String content, {
    int? parentId,
    List<int>? mentionIds,
  }) async {
    try {
      final body = <String, dynamic>{
        'user_id': userId,
        'content': content,
        if (parentId != null) 'parent_id': parentId,
        if (mentionIds != null && mentionIds.isNotEmpty) 'mention_ids': mentionIds,
      };
      final response = await http.post(
        Uri.parse('$_baseUrl/posts/$postId/comments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return CommentResult(
          success: true,
          comment: Comment.fromJson(data['data']),
        );
      }
      return CommentResult(success: false, message: data['message'] ?? 'Failed to add comment');
    } catch (e) {
      return CommentResult(success: false, message: 'Error: $e');
    }
  }

  /// Delete a comment
  Future<bool> deleteComment(int commentId) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/comments/$commentId'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Like a comment
  Future<CommentLikeResult> likeComment(int commentId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/comments/$commentId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final likesCount = data['data'] != null && data['data'] is Map
            ? (data['data'] as Map)['likes_count'] as int? ?? 0
            : 0;
        return CommentLikeResult(success: true, likesCount: likesCount, isLiked: true);
      }
      return CommentLikeResult(success: false);
    } catch (e) {
      return CommentLikeResult(success: false);
    }
  }

  /// Unlike a comment
  Future<CommentLikeResult> unlikeComment(int commentId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/comments/$commentId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final likesCount = data['data'] != null && data['data'] is Map
            ? (data['data'] as Map)['likes_count'] as int? ?? 0
            : 0;
        return CommentLikeResult(success: true, likesCount: likesCount, isLiked: false);
      }
      return CommentLikeResult(success: false);
    } catch (e) {
      return CommentLikeResult(success: false);
    }
  }

  /// Update (edit) a comment
  Future<CommentResult> updateComment(int commentId, String content, {List<int>? mentionIds}) async {
    try {
      final body = <String, dynamic>{
        'content': content,
        if (mentionIds != null && mentionIds.isNotEmpty) 'mention_ids': mentionIds,
      };
      final response = await http.patch(
        Uri.parse('$_baseUrl/comments/$commentId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return CommentResult(success: true, comment: Comment.fromJson(data['data']));
      }
      return CommentResult(success: false, message: data['message'] ?? 'Failed to update comment');
    } catch (e) {
      return CommentResult(success: false, message: 'Error: $e');
    }
  }

  /// Pin a comment (post author only). Only one comment per post can be pinned.
  Future<CommentResult> pinComment(int postId, int commentId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/posts/$postId/comments/$commentId/pin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return CommentResult(success: true, comment: Comment.fromJson(data['data']));
      }
      return CommentResult(success: false, message: data['message'] ?? 'Failed to pin comment');
    } catch (e) {
      return CommentResult(success: false, message: 'Error: $e');
    }
  }

  /// Unpin the pinned comment for a post
  Future<bool> unpinComment(int postId) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/posts/$postId/comments/pin'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Report a comment (reason optional)
  Future<bool> reportComment(int commentId, {String? reason, String? category}) async {
    try {
      final body = <String, dynamic>{
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (category != null && category.isNotEmpty) 'category': category,
      };
      final response = await http.post(
        Uri.parse('$_baseUrl/comments/$commentId/report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : <String, dynamic>{};
      return response.statusCode == 200 && (data['success'] != false);
    } catch (e) {
      return false;
    }
  }

  /// Get replies for a comment (paginated). Backend may support ?parent_id= or /comments/{id}/replies.
  Future<CommentListResult> getReplies(int postId, int parentCommentId, {int page = 1, int perPage = 20}) async {
    try {
      final url = '$_baseUrl/posts/$postId/comments?parent_id=$parentCommentId&page=$page&per_page=$perPage';
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw Exception('Connection timed out'),
      );
      final body = response.body;
      Map<String, dynamic>? data;
      try {
        data = body.isNotEmpty ? jsonDecode(body) as Map<String, dynamic>? : null;
      } catch (_) {
        return CommentListResult(success: false, message: 'Failed to load replies');
      }
      if (response.statusCode == 200 && data != null && data['success'] == true) {
        final rawList = data['data'];
        if (rawList == null || rawList is! List) {
          return CommentListResult(
            success: true,
            comments: [],
            meta: PaginationMeta.fromJson(data['meta'] ?? {}),
          );
        }
        final comments = <Comment>[];
        for (final item in rawList) {
          if (item is! Map<String, dynamic>) continue;
          try {
            comments.add(Comment.fromJson(item));
          } catch (_) {}
        }
        return CommentListResult(
          success: true,
          comments: comments,
          meta: PaginationMeta.fromJson(data['meta'] ?? {}),
        );
      }
      return CommentListResult(
        success: false,
        message: data?['message'] ?? 'Failed to load replies',
      );
    } catch (e) {
      return CommentListResult(success: false, message: e.toString());
    }
  }

  /// Search posts by hashtag
  Future<PostListResult> searchByHashtag({
    required String hashtag,
    int? currentUserId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      String url = '$_baseUrl/posts/hashtag/$hashtag?page=$page&per_page=$perPage';
      if (currentUserId != null) url += '&current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final posts = (data['data'] as List)
              .map((p) => Post.fromJson(p))
              .toList();
          return PostListResult(
            success: true,
            posts: posts,
            meta: PaginationMeta.fromJson(data['meta'] ?? {}),
          );
        }
      }
      return PostListResult(success: false, message: 'Failed to search posts');
    } catch (e) {
      return PostListResult(success: false, message: 'Error: $e');
    }
  }

  /// Share a post
  Future<PostResult> sharePost(int postId, int userId, {String? content, String privacy = 'public'}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/posts/$postId/share'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'content': content,
          'privacy': privacy,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return PostResult(
          success: true,
          post: Post.fromJson(data['data']),
          message: data['message'],
        );
      }
      return PostResult(success: false, message: data['message'] ?? 'Failed to share post');
    } catch (e) {
      return PostResult(success: false, message: 'Error: $e');
    }
  }

  /// Save (bookmark) a post for the user. Story 25.
  Future<SavePostResult> savePost(int postId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/posts/$postId/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return SavePostResult(
          success: true,
          isSaved: true,
          savesCount: data['data']?['saves_count'] ?? 0,
        );
      }
      return SavePostResult(
        success: false,
        message: data['message'] ?? 'Failed to save post',
      );
    } catch (e) {
      return SavePostResult(success: false, message: 'Error: $e');
    }
  }

  /// Remove a saved (bookmarked) post for the user. Story 25.
  Future<SavePostResult> unsavePost(int postId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/posts/$postId/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return SavePostResult(
          success: true,
          isSaved: false,
          savesCount: data['data']?['saves_count'] ?? 0,
        );
      }
      return SavePostResult(
        success: false,
        message: data['message'] ?? 'Failed to unsave post',
      );
    } catch (e) {
      return SavePostResult(success: false, message: 'Error: $e');
    }
  }

  /// Get saved (bookmarked) posts for the user. Story 25.
  Future<PostListResult> getSavedPosts({
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final url = '$_baseUrl/posts/saved?user_id=$userId&page=$page&per_page=$perPage';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final posts = (data['data'] as List)
              .map((p) => Post.fromJson(p))
              .toList();
          return PostListResult(
            success: true,
            posts: posts,
            meta: PaginationMeta.fromJson(data['meta'] ?? {}),
          );
        }
      }
      return PostListResult(
        success: false,
        message: 'Failed to load saved posts',
      );
    } catch (e) {
      return PostListResult(success: false, message: 'Error: $e');
    }
  }
}

// Result classes
class PostListResult {
  final bool success;
  final List<Post> posts;
  final PaginationMeta? meta;
  final String? message;

  PostListResult({
    required this.success,
    this.posts = const [],
    this.meta,
    this.message,
  });
}

class PostResult {
  final bool success;
  final Post? post;
  final String? message;

  PostResult({required this.success, this.post, this.message});
}

class LikeResult {
  final bool success;
  final int? likesCount;

  LikeResult({required this.success, this.likesCount});
}

/// Result for save/unsave post (Story 25).
class SavePostResult {
  final bool success;
  final bool isSaved;
  final int? savesCount;
  final String? message;

  SavePostResult({
    required this.success,
    this.isSaved = false,
    this.savesCount,
    this.message,
  });
}

class CommentListResult {
  final bool success;
  final List<Comment> comments;
  final PaginationMeta? meta;
  final String? message;

  CommentListResult({
    required this.success,
    this.comments = const [],
    this.meta,
    this.message,
  });
}

class CommentResult {
  final bool success;
  final Comment? comment;
  final String? message;

  CommentResult({required this.success, this.comment, this.message});
}

class CommentLikeResult {
  final bool success;
  final int likesCount;
  final bool isLiked;

  CommentLikeResult({required this.success, this.likesCount = 0, this.isLiked = false});
}

class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginationMeta({
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 20,
    this.total = 0,
  });

  static int _int(dynamic v, [int def = 0]) {
    if (v == null) return def;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? def;
    return def;
  }

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: _int(json['current_page'], 1),
      lastPage: _int(json['last_page'], 1),
      perPage: _int(json['per_page'], 20),
      total: _int(json['total']),
    );
  }

  bool get hasMore => currentPage < lastPage;
}
