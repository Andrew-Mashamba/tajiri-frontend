import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/photo_models.dart';
import '../config/api_config.dart';
import 'post_service.dart';

String get _baseUrl => ApiConfig.baseUrl;

class PhotoService {
  /// Get user's photos
  Future<PhotoListResult> getPhotos({
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId/photos?page=$page&per_page=$perPage'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final photos = (data['data'] as List)
              .map((p) => Photo.fromJson(p))
              .toList();
          return PhotoListResult(
            success: true,
            photos: photos,
            meta: PaginationMeta.fromJson(data['meta'] ?? {}),
          );
        }
      }
      return PhotoListResult(success: false, message: 'Failed to load photos');
    } catch (e) {
      return PhotoListResult(success: false, message: 'Error: $e');
    }
  }

  /// Upload a photo
  Future<PhotoResult> uploadPhoto({
    required int userId,
    required File file,
    int? albumId,
    String? caption,
    String? locationName,
  }) async {
    final String requestUrl = '$_baseUrl/photos';

    debugPrint('╔══════════════════════════════════════════════════════════════');
    debugPrint('║ [PhotoService] UPLOAD PHOTO REQUEST');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ URL: $requestUrl');
    debugPrint('║ Method: POST (Multipart)');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ REQUEST FIELDS:');
    debugPrint('║   user_id: $userId');
    debugPrint('║   album_id: ${albumId ?? 'null'}');
    debugPrint('║   caption: ${caption ?? 'null'}');
    debugPrint('║   location_name: ${locationName ?? 'null'}');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ FILE DETAILS:');
    debugPrint('║   path: ${file.path}');
    debugPrint('║   exists: ${file.existsSync()}');

    try {
      final fileSize = await file.length();
      final fileSizeKB = (fileSize / 1024).toStringAsFixed(2);
      final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
      debugPrint('║   size: $fileSize bytes ($fileSizeKB KB / $fileSizeMB MB)');

      final fileName = file.path.split('/').last;
      final fileExtension = fileName.contains('.') ? fileName.split('.').last : 'unknown';
      debugPrint('║   filename: $fileName');
      debugPrint('║   extension: $fileExtension');
      debugPrint('╠══════════════════════════════════════════════════════════════');

      var request = http.MultipartRequest('POST', Uri.parse(requestUrl));

      // Add fields
      request.fields['user_id'] = userId.toString();
      if (albumId != null) request.fields['album_id'] = albumId.toString();
      if (caption != null) request.fields['caption'] = caption;
      if (locationName != null) request.fields['location_name'] = locationName;

      // Add file
      final multipartFile = await http.MultipartFile.fromPath('photo', file.path);
      request.files.add(multipartFile);

      debugPrint('║ MULTIPART FILE:');
      debugPrint('║   field: photo');
      debugPrint('║   filename: ${multipartFile.filename}');
      debugPrint('║   contentType: ${multipartFile.contentType}');
      debugPrint('║   length: ${multipartFile.length}');
      debugPrint('╠══════════════════════════════════════════════════════════════');
      debugPrint('║ Sending request...');

      final stopwatch = Stopwatch()..start();
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      stopwatch.stop();

      debugPrint('╠══════════════════════════════════════════════════════════════');
      debugPrint('║ RESPONSE RECEIVED (${stopwatch.elapsedMilliseconds}ms)');
      debugPrint('╠══════════════════════════════════════════════════════════════');
      debugPrint('║ Status Code: ${response.statusCode}');
      debugPrint('║ Reason Phrase: ${response.reasonPhrase}');
      debugPrint('╠══════════════════════════════════════════════════════════════');
      debugPrint('║ RESPONSE HEADERS:');
      response.headers.forEach((key, value) {
        debugPrint('║   $key: $value');
      });
      debugPrint('╠══════════════════════════════════════════════════════════════');
      debugPrint('║ RESPONSE BODY (${response.body.length} chars):');

      // Check if response is HTML (error page) instead of JSON
      final contentType = response.headers['content-type'] ?? '';
      final isHtmlResponse = contentType.contains('text/html') ||
          response.body.trimLeft().startsWith('<!DOCTYPE') ||
          response.body.trimLeft().startsWith('<html');

      if (isHtmlResponse) {
        debugPrint('║ ⚠️  SERVER RETURNED HTML ERROR PAGE (not JSON)');
        debugPrint('╠══════════════════════════════════════════════════════════════');

        // Try to extract error message from HTML
        String extractedError = 'Unknown server error';

        // Extract <title> tag
        final titleMatch = RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false)
            .firstMatch(response.body);
        if (titleMatch != null) {
          extractedError = titleMatch.group(1)?.trim() ?? extractedError;
          debugPrint('║ HTML Title: $extractedError');
        }

        // Extract Laravel/PHP error message if present
        final laravelErrorMatch = RegExp(r'<div class="message[^"]*"[^>]*>([^<]+)</div>', caseSensitive: false)
            .firstMatch(response.body);
        if (laravelErrorMatch != null) {
          final msg = laravelErrorMatch.group(1)?.trim();
          if (msg != null && msg.isNotEmpty) {
            debugPrint('║ Laravel Error: $msg');
            extractedError = msg;
          }
        }

        // Extract exception message
        final exceptionMatch = RegExp(r'exception["\s:]+([^<"]+)', caseSensitive: false)
            .firstMatch(response.body);
        if (exceptionMatch != null) {
          final msg = exceptionMatch.group(1)?.trim();
          if (msg != null && msg.isNotEmpty) {
            debugPrint('║ Exception: $msg');
          }
        }

        // Extract "message" from error page
        final msgMatch = RegExp(r'"message"\s*:\s*"([^"]+)"', caseSensitive: false)
            .firstMatch(response.body);
        if (msgMatch != null) {
          final msg = msgMatch.group(1)?.trim();
          if (msg != null && msg.isNotEmpty) {
            debugPrint('║ Message: $msg');
            extractedError = msg;
          }
        }

        // Show first 500 chars of body for debugging
        debugPrint('╠══════════════════════════════════════════════════════════════');
        debugPrint('║ FIRST 500 CHARS OF HTML:');
        final preview = response.body.length > 500
            ? response.body.substring(0, 500)
            : response.body;
        for (final line in preview.split('\n').take(20)) {
          debugPrint('║   ${line.trim()}');
        }

        debugPrint('╚══════════════════════════════════════════════════════════════');

        return PhotoResult(
          success: false,
          message: 'Server Error (${response.statusCode}): $extractedError',
        );
      }

      // Print JSON response body
      final bodyLines = response.body.split('\n');
      for (final line in bodyLines) {
        if (line.length > 100) {
          // Split long lines
          for (var i = 0; i < line.length; i += 100) {
            final end = (i + 100 < line.length) ? i + 100 : line.length;
            debugPrint('║   ${line.substring(i, end)}');
          }
        } else {
          debugPrint('║   $line');
        }
      }
      debugPrint('╚══════════════════════════════════════════════════════════════');

      // Try to parse response
      dynamic data;
      try {
        data = jsonDecode(response.body);
        debugPrint('[PhotoService] Parsed JSON successfully');
      } catch (jsonError) {
        debugPrint('[PhotoService] ERROR: Failed to parse JSON response: $jsonError');
        debugPrint('[PhotoService] First 200 chars: ${response.body.substring(0, response.body.length.clamp(0, 200))}');
        return PhotoResult(
          success: false,
          message: 'Server returned invalid response. Status: ${response.statusCode}',
        );
      }

      if (response.statusCode == 201 && data['success'] == true) {
        debugPrint('[PhotoService] SUCCESS: Photo uploaded successfully');
        return PhotoResult(
          success: true,
          photo: Photo.fromJson(data['data']),
          message: data['message'],
        );
      }

      final errorMessage = data['message'] ?? 'Failed to upload photo';
      debugPrint('[PhotoService] FAILED: $errorMessage');
      debugPrint('[PhotoService] Full error data: $data');
      return PhotoResult(success: false, message: errorMessage);
    } catch (e, stackTrace) {
      debugPrint('╠══════════════════════════════════════════════════════════════');
      debugPrint('║ EXCEPTION OCCURRED');
      debugPrint('╠══════════════════════════════════════════════════════════════');
      debugPrint('║ Error Type: ${e.runtimeType}');
      debugPrint('║ Error Message: $e');
      debugPrint('╠══════════════════════════════════════════════════════════════');
      debugPrint('║ STACK TRACE:');
      final stackLines = stackTrace.toString().split('\n');
      for (final line in stackLines.take(10)) {
        debugPrint('║   $line');
      }
      debugPrint('╚══════════════════════════════════════════════════════════════');
      return PhotoResult(success: false, message: 'Error: $e');
    }
  }

  /// Get a single photo
  Future<PhotoResult> getPhoto(int photoId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/photos/$photoId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return PhotoResult(success: true, photo: Photo.fromJson(data['data']));
        }
      }
      return PhotoResult(success: false, message: 'Photo not found');
    } catch (e) {
      return PhotoResult(success: false, message: 'Error: $e');
    }
  }

  /// Update photo details
  Future<PhotoResult> updatePhoto(
    int photoId, {
    String? caption,
    String? locationName,
    int? albumId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/photos/$photoId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (caption != null) 'caption': caption,
          if (locationName != null) 'location_name': locationName,
          if (albumId != null) 'album_id': albumId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return PhotoResult(
          success: true,
          photo: Photo.fromJson(data['data']),
          message: data['message'],
        );
      }
      return PhotoResult(success: false, message: data['message'] ?? 'Failed to update photo');
    } catch (e) {
      return PhotoResult(success: false, message: 'Error: $e');
    }
  }

  /// Delete a photo
  Future<bool> deletePhoto(int photoId) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/photos/$photoId'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get user's albums
  Future<AlbumListResult> getAlbums(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId/albums'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final albums = (data['data'] as List)
              .map((a) => PhotoAlbum.fromJson(a))
              .toList();
          return AlbumListResult(success: true, albums: albums);
        }
      }
      return AlbumListResult(success: false, message: 'Failed to load albums');
    } catch (e) {
      return AlbumListResult(success: false, message: 'Error: $e');
    }
  }

  /// Create a new album
  Future<AlbumResult> createAlbum({
    required int userId,
    required String name,
    String? description,
    String privacy = 'public',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/albums'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'name': name,
          'description': description,
          'privacy': privacy,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return AlbumResult(
          success: true,
          album: PhotoAlbum.fromJson(data['data']),
          message: data['message'],
        );
      }
      return AlbumResult(success: false, message: data['message'] ?? 'Failed to create album');
    } catch (e) {
      return AlbumResult(success: false, message: 'Error: $e');
    }
  }

  /// Get a single album with photos
  Future<AlbumDetailResult> getAlbum(int albumId, {int page = 1, int perPage = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/albums/$albumId?page=$page&per_page=$perPage'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final album = PhotoAlbum.fromJson(data['data']['album']);
          final photos = (data['data']['photos'] as List)
              .map((p) => Photo.fromJson(p))
              .toList();
          return AlbumDetailResult(
            success: true,
            album: album,
            photos: photos,
            meta: PaginationMeta.fromJson(data['meta'] ?? {}),
          );
        }
      }
      return AlbumDetailResult(success: false, message: 'Album not found');
    } catch (e) {
      return AlbumDetailResult(success: false, message: 'Error: $e');
    }
  }

  /// Update an album
  Future<AlbumResult> updateAlbum(
    int albumId, {
    String? name,
    String? description,
    String? privacy,
    int? coverPhotoId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/albums/$albumId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (privacy != null) 'privacy': privacy,
          if (coverPhotoId != null) 'cover_photo_id': coverPhotoId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return AlbumResult(
          success: true,
          album: PhotoAlbum.fromJson(data['data']),
          message: data['message'],
        );
      }
      return AlbumResult(success: false, message: data['message'] ?? 'Failed to update album');
    } catch (e) {
      return AlbumResult(success: false, message: 'Error: $e');
    }
  }

  /// Delete an album
  Future<bool> deleteAlbum(int albumId) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/albums/$albumId'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// Result classes
class PhotoListResult {
  final bool success;
  final List<Photo> photos;
  final PaginationMeta? meta;
  final String? message;

  PhotoListResult({
    required this.success,
    this.photos = const [],
    this.meta,
    this.message,
  });
}

class PhotoResult {
  final bool success;
  final Photo? photo;
  final String? message;

  PhotoResult({required this.success, this.photo, this.message});
}

class AlbumListResult {
  final bool success;
  final List<PhotoAlbum> albums;
  final String? message;

  AlbumListResult({required this.success, this.albums = const [], this.message});
}

class AlbumResult {
  final bool success;
  final PhotoAlbum? album;
  final String? message;

  AlbumResult({required this.success, this.album, this.message});
}

class AlbumDetailResult {
  final bool success;
  final PhotoAlbum? album;
  final List<Photo> photos;
  final PaginationMeta? meta;
  final String? message;

  AlbumDetailResult({
    required this.success,
    this.album,
    this.photos = const [],
    this.meta,
    this.message,
  });
}
