import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'http_retry.dart';
import '../models/profile_models.dart';
import '../config/api_config.dart';
import 'perf_logger.dart';

String get _baseUrl => ApiConfig.baseUrl;

class _CachedProfile {
  final FullProfile profile;
  final DateTime fetchedAt;
  _CachedProfile(this.profile) : fetchedAt = DateTime.now();
  bool get isExpired => DateTime.now().difference(fetchedAt) > ProfileService._cacheTtl;
}

class ProfileService {
  // In-memory profile cache: 5-min TTL, max 50 entries
  // (Per docs/SQLITE_ADOPTION_ROADMAP.md the user profile is explicitly
  //  not worth SQLite — small payload, 5 min TTL is enough.)
  static final Map<int, _CachedProfile> _cache = {};
  static const int _maxCacheSize = 50;
  static const Duration _cacheTtl = Duration(minutes: 5);

  /// Drop the cached profile for [userId] so the next [getProfile] call
  /// hits the network. Call this from any screen that mutates the profile
  /// (edit profile, edit email, edit location, etc.) so the change is
  /// visible immediately instead of after the 5-min TTL expires.
  static void invalidate(int userId) {
    _cache.remove(userId);
  }

  /// Drop the entire cache (called on logout).
  static void clearCache() {
    _cache.clear();
  }

  /// UN-002 / posts.md row 10 — profile_visit_from_post·author.
  /// Fire when a user opens a creator's profile from a post / share.
  /// Backend also derives row 31 (profile_visit_from_share·sharer) when
  /// share_uid maps to an active sharer attribution.
  Future<bool> recordProfileVisit({
    required int targetUserId,
    required int viewerUserId,
    int? originPostId,
    int? originStreamId,
    String? shareUid,
  }) async {
    try {
      final body = <String, dynamic>{'user_id': viewerUserId};
      if (originPostId != null) body['origin_post_id'] = originPostId;
      if (originStreamId != null) body['origin_stream_id'] = originStreamId;
      if (shareUid != null && shareUid.isNotEmpty) body['share_uid'] = shareUid;
      final response = await http.post(
        Uri.parse('$_baseUrl/users/$targetUserId/profile-visit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Get full profile for a user
  Future<ProfileResult> getProfile({
    required int userId,
    int? currentUserId,
  }) async {
    // Check cache first
    final cached = _cache[userId];
    if (cached != null && !cached.isExpired) {
      // Background refresh if stale (>2 min)
      if (DateTime.now().difference(cached.fetchedAt) > const Duration(minutes: 2)) {
        _refreshInBackground(userId, currentUserId);
      }
      PerfLogger.profileCacheHits++;
      PerfLogger.log('profile_cache_hit', {'userId': userId});
      return ProfileResult(success: true, profile: cached.profile);
    }

    return _fetchAndCache(userId, currentUserId);
  }

  Future<ProfileResult> _fetchAndCache(int userId, int? currentUserId) async {
    PerfLogger.profileCacheMisses++;
    try {
      String url = '$_baseUrl/users/$userId';
      if (currentUserId != null) {
        url += '?current_user_id=$currentUserId';
      }

      print('[ProfileService] Fetching profile from: $url');
      final response = await httpGetWithRetry(Uri.parse(url));
      print('[ProfileService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[ProfileService] Response success: ${data['success']}');
        if (data['success'] == true) {
          final profile = FullProfile.fromJson(data['data']);
          // Store in cache
          _cache[userId] = _CachedProfile(profile);
          // LRU eviction
          if (_cache.length > _maxCacheSize) {
            final oldest = _cache.entries.reduce((a, b) =>
                a.value.fetchedAt.isBefore(b.value.fetchedAt) ? a : b);
            _cache.remove(oldest.key);
          }
          return ProfileResult(success: true, profile: profile);
        }
        return ProfileResult(success: false, message: data['message'] ?? 'Failed to load profile');
      }
      print('[ProfileService] Non-200 response: ${response.body}');
      return ProfileResult(success: false, message: 'Profile not found');
    } catch (e) {
      print('[ProfileService] Error: $e');
      // Return stale cache on network error
      final stale = _cache[userId];
      if (stale != null) {
        return ProfileResult(success: true, profile: stale.profile);
      }
      return ProfileResult(success: false, message: 'Error: $e');
    }
  }

  void _refreshInBackground(int userId, int? currentUserId) {
    _fetchAndCache(userId, currentUserId);
  }

  /// Update profile photo with optional upload progress + cancellation.
  /// Spec: docs/superpowers/specs/2026-05-02-profile-photo-upload-design.md §4
  Future<PhotoUpdateResult> updateProfilePhoto({
    required int userId,
    required File photo,
    Map<String, int>? faceBbox,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(seconds: 30),
      ));

      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(photo.path, filename: photo.uri.pathSegments.last),
        if (faceBbox != null) 'face_bbox': jsonEncode(faceBbox),
      });

      final response = await dio.post(
        '/users/$userId/profile-photo',
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: onProgress == null
            ? null
            : (sent, total) {
                if (total > 0) onProgress(sent / total);
              },
      );

      final data = response.data is Map ? response.data as Map : <String, dynamic>{};
      if (response.statusCode == 200 && data['success'] == true) {
        final inner = data['data'] is Map ? data['data'] as Map : const {};
        invalidate(userId);
        return PhotoUpdateResult(
          success: true,
          photoUrl: inner['profile_photo_url'] as String?,
          message: data['message'] as String?,
        );
      }
      return PhotoUpdateResult(success: false, message: (data['message'] as String?) ?? 'Failed to update photo');
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return PhotoUpdateResult(success: false, message: 'cancelled');
      }
      return PhotoUpdateResult(success: false, message: 'Network error: ${e.message ?? e.type.name}');
    } catch (e) {
      return PhotoUpdateResult(success: false, message: 'Error: $e');
    }
  }

  /// POST /api/users/{id}/partner — set the user's tagged partner.
  Future<bool> setPartner({required int userId, required int partnerUserId}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/$userId/partner'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'partner_user_id': partnerUserId}),
      );
      final data = jsonDecode(response.body);
      final ok = response.statusCode == 200 && data['success'] == true;
      if (ok) invalidate(userId);
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// DELETE /api/users/{id}/partner — clear the user's tagged partner.
  Future<bool> removePartner({required int userId}) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/users/$userId/partner'));
      final data = jsonDecode(response.body);
      final ok = response.statusCode == 200 && data['success'] == true;
      if (ok) invalidate(userId);
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// GET /api/users/search?q=...&exclude_user_id=... — search users
  /// by @handle (or partial name) for the partner picker.
  Future<List<UserSearchResult>> searchUsers({
    required String query,
    int? excludeUserId,
    int limit = 20,
  }) async {
    try {
      final params = <String, String>{
        'q': query,
        'limit': '$limit',
        if (excludeUserId != null) 'exclude_user_id': '$excludeUserId',
      };
      final uri = Uri.parse('$_baseUrl/users/search').replace(queryParameters: params);
      final response = await httpGetWithRetry(uri);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body);
      if (data['success'] != true) return [];
      final list = (data['data'] as List?) ?? const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(UserSearchResult.fromJson)
          .toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  /// DELETE /api/users/{id}/profile-photo — clear the user's avatar.
  Future<PhotoUpdateResult> removeProfilePhoto({required int userId}) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/users/$userId/profile-photo'),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        invalidate(userId);
        return PhotoUpdateResult(
          success: true,
          photoUrl: null,
          message: data['message'] as String?,
        );
      }
      return PhotoUpdateResult(success: false, message: (data['message'] as String?) ?? 'Failed to remove profile photo');
    } catch (e) {
      return PhotoUpdateResult(success: false, message: 'Error: $e');
    }
  }

  /// Update cover photo
  /// Update cover photo with optional upload progress + cancellation.
  /// Spec: docs/superpowers/specs/2026-05-02-cover-photo-upload-design.md §4
  ///
  /// [onProgress] is called with a 0.0..1.0 fraction as the upload streams.
  /// [cancelToken] aborts the request when the user taps Cancel.
  Future<PhotoUpdateResult> updateCoverPhoto({
    required int userId,
    required File photo,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(seconds: 30),
      ));

      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(photo.path, filename: photo.uri.pathSegments.last),
      });

      final response = await dio.post(
        '/users/$userId/cover-photo',
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: onProgress == null
            ? null
            : (sent, total) {
                if (total > 0) onProgress(sent / total);
              },
      );

      final data = response.data is Map ? response.data as Map : <String, dynamic>{};
      if (response.statusCode == 200 && data['success'] == true) {
        final inner = data['data'] is Map ? data['data'] as Map : const {};
        // Drop the cached profile so the next getProfile() call hits the
        // server with the new cover_photo_url.
        invalidate(userId);
        return PhotoUpdateResult(
          success: true,
          photoUrl: inner['cover_photo_url'] as String?,
          message: data['message'] as String?,
        );
      }
      return PhotoUpdateResult(success: false, message: (data['message'] as String?) ?? 'Failed to update cover photo');
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return PhotoUpdateResult(success: false, message: 'cancelled');
      }
      return PhotoUpdateResult(success: false, message: 'Network error: ${e.message ?? e.type.name}');
    } catch (e) {
      return PhotoUpdateResult(success: false, message: 'Error: $e');
    }
  }

  /// DELETE /api/users/{id}/cover-photo — clear the user's cover photo.
  Future<PhotoUpdateResult> removeCoverPhoto({required int userId}) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/users/$userId/cover-photo'),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        invalidate(userId);
        return PhotoUpdateResult(
          success: true,
          photoUrl: null,
          message: data['message'] as String?,
        );
      }
      return PhotoUpdateResult(success: false, message: (data['message'] as String?) ?? 'Failed to remove cover photo');
    } catch (e) {
      return PhotoUpdateResult(success: false, message: 'Error: $e');
    }
  }

  /// Update bio and interests
  Future<BioUpdateResult> updateBio({
    required int userId,
    String? bio,
    List<String>? interests,
    String? relationshipStatus,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId/bio'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (bio != null) 'bio': bio,
          if (interests != null) 'interests': interests,
          if (relationshipStatus != null) 'relationship_status': relationshipStatus,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return BioUpdateResult(
          success: true,
          bio: data['data']['bio'],
          interests: data['data']['interests'] != null
              ? List<String>.from(data['data']['interests'])
              : null,
          relationshipStatus: data['data']['relationship_status'],
          message: data['message'],
        );
      }
      return BioUpdateResult(success: false, message: data['message'] ?? 'Failed to update bio');
    } catch (e) {
      return BioUpdateResult(success: false, message: 'Error: $e');
    }
  }

  /// Update username
  /// Update or clear the user's @handle.
  /// Pass `username: null` to remove it (CRUD delete).
  Future<UsernameUpdateResult> updateUsername({
    required int userId,
    required String? username,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId/username'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return UsernameUpdateResult(
          success: true,
          username: data['data']?['username'],
          message: data['message'],
        );
      }
      // 422 from Laravel returns `{success: false, errors: {username: [...]}}`.
      // Surface the first field error if present so the UI can show it.
      String? message = data['message'] as String?;
      if (data['errors'] is Map && data['errors']['username'] is List) {
        final firstErr = (data['errors']['username'] as List).first?.toString();
        if (firstErr != null && firstErr.isNotEmpty) message = firstErr;
      }
      return UsernameUpdateResult(success: false, message: message ?? 'Failed to update username');
    } catch (e) {
      return UsernameUpdateResult(success: false, message: 'Error: $e');
    }
  }

  /// Live availability check: hits `POST /users/check-handle`.
  /// Returns `null` on network error so the UI can fall back to "ask
  /// later" instead of falsely declaring the handle taken.
  Future<bool?> checkHandleAvailability(String handle) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/check-handle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': handle}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['available'] == true;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

// Result classes
class ProfileResult {
  final bool success;
  final FullProfile? profile;
  final String? message;

  ProfileResult({required this.success, this.profile, this.message});
}

class PhotoUpdateResult {
  final bool success;
  final String? photoUrl;
  final String? message;

  PhotoUpdateResult({required this.success, this.photoUrl, this.message});
}

/// Lightweight user record returned by the partner-search endpoint.
class UserSearchResult {
  final int id;
  final String name;
  final String? username;
  final String? photoUrl;

  const UserSearchResult({
    required this.id,
    required this.name,
    required this.username,
    required this.photoUrl,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      username: json['username'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }
}

class BioUpdateResult {
  final bool success;
  final String? bio;
  final List<String>? interests;
  final String? relationshipStatus;
  final String? message;

  BioUpdateResult({
    required this.success,
    this.bio,
    this.interests,
    this.relationshipStatus,
    this.message,
  });
}

class UsernameUpdateResult {
  final bool success;
  final String? username;
  final String? message;

  UsernameUpdateResult({required this.success, this.username, this.message});
}
