import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/draft_models.dart';
import '../config/api_config.dart';

/// Result of a draft operation
class DraftResult {
  final bool success;
  final String? message;
  final PostDraft? draft;
  final List<PostDraft>? drafts;
  final DraftCounts? counts;

  DraftResult({
    required this.success,
    this.message,
    this.draft,
    this.drafts,
    this.counts,
  });
}

/// Service for managing post drafts
class DraftService {
  static const String _localDraftsKey = 'local_drafts';
  static const Duration _autoSaveDebounce = Duration(seconds: 3);

  Timer? _autoSaveTimer;
  PostDraft? _pendingDraft;

  /// Get all drafts for a user
  Future<DraftResult> getDrafts({
    required int userId,
    String? type,
    bool scheduledOnly = false,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final queryParams = {
        'user_id': userId.toString(),
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (type != null) 'type': type,
        if (scheduledOnly) 'scheduled_only': '1',
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/drafts')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final drafts = (data['data'] as List)
            .map((d) => PostDraft.fromJson(d))
            .toList();

        return DraftResult(success: true, drafts: drafts);
      } else {
        final error = json.decode(response.body);
        return DraftResult(
          success: false,
          message: error['message'] ?? 'Failed to load drafts',
        );
      }
    } catch (e) {
      // Try to get local drafts as fallback
      final localDrafts = await _getLocalDrafts(userId);
      if (localDrafts.isNotEmpty) {
        return DraftResult(success: true, drafts: localDrafts);
      }
      return DraftResult(success: false, message: e.toString());
    }
  }

  /// Get draft counts
  Future<DraftResult> getDraftCounts() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/drafts/counts'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DraftResult(
          success: true,
          counts: DraftCounts.fromJson(data['data']),
        );
      } else {
        return DraftResult(success: false, message: 'Failed to get counts');
      }
    } catch (e) {
      return DraftResult(success: false, message: e.toString());
    }
  }

  /// Get a specific draft
  Future<DraftResult> getDraft(int draftId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/drafts/$draftId'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DraftResult(
          success: true,
          draft: PostDraft.fromJson(data['data']),
        );
      } else {
        return DraftResult(success: false, message: 'Draft not found');
      }
    } catch (e) {
      return DraftResult(success: false, message: e.toString());
    }
  }

  /// Save or update a draft
  Future<DraftResult> saveDraft({
    required int userId,
    int? draftId,
    required DraftPostType postType,
    String? content,
    String? backgroundColor,
    String? privacy,
    String? locationName,
    double? locationLat,
    double? locationLng,
    List<int>? taggedUsers,
    DateTime? scheduledAt,
    String? title,
    List<File>? mediaFiles,
    File? audioFile,
    File? coverImage,
    int? musicTrackId,
    int? musicStartTime,
    double? originalAudioVolume,
    double? musicVolume,
    double? videoSpeed,
    String? videoFilter,
    List<Map<String, dynamic>>? textOverlays,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/drafts'),
      );

      // Add headers
      request.headers.addAll(ApiConfig.headers);

      // Add fields
      if (draftId != null) request.fields['draft_id'] = draftId.toString();
      request.fields['post_type'] = postType.value;
      if (content != null) request.fields['content'] = content;
      if (backgroundColor != null) request.fields['background_color'] = backgroundColor;
      if (privacy != null) request.fields['privacy'] = privacy;
      if (locationName != null) request.fields['location_name'] = locationName;
      if (locationLat != null) request.fields['location_lat'] = locationLat.toString();
      if (locationLng != null) request.fields['location_lng'] = locationLng.toString();
      if (taggedUsers != null) {
        for (var i = 0; i < taggedUsers.length; i++) {
          request.fields['tagged_users[$i]'] = taggedUsers[i].toString();
        }
      }
      if (scheduledAt != null) {
        request.fields['scheduled_at'] = scheduledAt.toIso8601String();
      }
      if (title != null) request.fields['title'] = title;
      if (musicTrackId != null) request.fields['music_track_id'] = musicTrackId.toString();
      if (musicStartTime != null) request.fields['music_start_time'] = musicStartTime.toString();
      if (originalAudioVolume != null) {
        request.fields['original_audio_volume'] = originalAudioVolume.toString();
      }
      if (musicVolume != null) request.fields['music_volume'] = musicVolume.toString();
      if (videoSpeed != null) request.fields['video_speed'] = videoSpeed.toString();
      if (videoFilter != null) request.fields['video_filter'] = videoFilter;
      if (textOverlays != null) {
        request.fields['text_overlays'] = json.encode(textOverlays);
      }

      // Add media files
      if (mediaFiles != null) {
        for (var i = 0; i < mediaFiles.length; i++) {
          request.files.add(await http.MultipartFile.fromPath(
            'media[$i]',
            mediaFiles[i].path,
          ));
        }
      }

      // Add audio file
      if (audioFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'audio',
          audioFile.path,
        ));
      }

      // Add cover image
      if (coverImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'cover_image',
          coverImage.path,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return DraftResult(
          success: true,
          message: data['message'],
          draft: PostDraft.fromJson(data['data']),
        );
      } else {
        final error = json.decode(response.body);
        return DraftResult(
          success: false,
          message: error['message'] ?? 'Failed to save draft',
        );
      }
    } catch (e) {
      // Save locally as fallback
      final localDraft = PostDraft(
        userId: userId,
        postType: postType,
        content: content,
        backgroundColor: backgroundColor,
        privacy: privacy ?? 'public',
        locationName: locationName,
        locationLat: locationLat,
        locationLng: locationLng,
        taggedUsers: taggedUsers,
        scheduledAt: scheduledAt,
        title: title,
        lastEditedAt: DateTime.now(),
        syncStatus: DraftStatus.local,
      );

      await _saveLocalDraft(localDraft);

      return DraftResult(
        success: true,
        message: 'Saved locally (will sync when online)',
        draft: localDraft,
      );
    }
  }

  /// Auto-save draft with debouncing
  void autoSaveDraft(PostDraft draft) {
    _pendingDraft = draft;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDebounce, () {
      if (_pendingDraft != null) {
        _performAutoSave(_pendingDraft!);
        _pendingDraft = null;
      }
    });
  }

  Future<void> _performAutoSave(PostDraft draft) async {
    await saveDraft(
      userId: draft.userId,
      draftId: draft.id,
      postType: draft.postType,
      content: draft.content,
      backgroundColor: draft.backgroundColor,
      privacy: draft.privacy,
      locationName: draft.locationName,
      locationLat: draft.locationLat,
      locationLng: draft.locationLng,
      taggedUsers: draft.taggedUsers,
      scheduledAt: draft.scheduledAt,
      title: draft.title,
      musicTrackId: draft.musicTrackId,
      musicStartTime: draft.musicStartTime,
      originalAudioVolume: draft.originalAudioVolume,
      musicVolume: draft.musicVolume,
      videoSpeed: draft.videoSpeed,
      videoFilter: draft.videoFilter,
      textOverlays: draft.textOverlays,
    );
  }

  /// Cancel pending auto-save
  void cancelAutoSave() {
    _autoSaveTimer?.cancel();
    _pendingDraft = null;
  }

  /// Delete a draft
  Future<DraftResult> deleteDraft(int draftId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/drafts/$draftId'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        return DraftResult(success: true, message: 'Draft deleted');
      } else {
        final error = json.decode(response.body);
        return DraftResult(
          success: false,
          message: error['message'] ?? 'Failed to delete draft',
        );
      }
    } catch (e) {
      return DraftResult(success: false, message: e.toString());
    }
  }

  /// Publish a draft
  Future<DraftResult> publishDraft(int draftId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/drafts/$draftId/publish'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DraftResult(
          success: true,
          message: data['message'],
        );
      } else {
        final error = json.decode(response.body);
        return DraftResult(
          success: false,
          message: error['message'] ?? 'Failed to publish draft',
        );
      }
    } catch (e) {
      return DraftResult(success: false, message: e.toString());
    }
  }

  /// Duplicate a draft
  Future<DraftResult> duplicateDraft(int draftId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/drafts/$draftId/duplicate'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return DraftResult(
          success: true,
          message: data['message'],
          draft: PostDraft.fromJson(data['data']),
        );
      } else {
        final error = json.decode(response.body);
        return DraftResult(
          success: false,
          message: error['message'] ?? 'Failed to duplicate draft',
        );
      }
    } catch (e) {
      return DraftResult(success: false, message: e.toString());
    }
  }

  /// Delete all drafts
  Future<DraftResult> deleteAllDrafts() async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/drafts'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        // Also clear local drafts
        await _clearLocalDrafts();
        return DraftResult(success: true, message: 'All drafts deleted');
      } else {
        final error = json.decode(response.body);
        return DraftResult(
          success: false,
          message: error['message'] ?? 'Failed to delete drafts',
        );
      }
    } catch (e) {
      return DraftResult(success: false, message: e.toString());
    }
  }

  // ==================== Local Storage ====================

  Future<List<PostDraft>> _getLocalDrafts(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftsJson = prefs.getString('${_localDraftsKey}_$userId');
      if (draftsJson == null) return [];

      final List<dynamic> draftsList = json.decode(draftsJson);
      return draftsList
          .map((d) => PostDraft.fromJson(d as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveLocalDraft(PostDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingDrafts = await _getLocalDrafts(draft.userId);

      // Find and update or add new
      final index = existingDrafts.indexWhere(
        (d) => d.id == draft.id || (d.id == null && draft.id == null && d.createdAt == draft.createdAt),
      );

      if (index >= 0) {
        existingDrafts[index] = draft;
      } else {
        existingDrafts.insert(0, draft);
      }

      await prefs.setString(
        '${_localDraftsKey}_${draft.userId}',
        json.encode(existingDrafts.map((d) => d.toJson()).toList()),
      );
    } catch (e) {
      // Ignore local save errors
    }
  }

  Future<void> _clearLocalDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_localDraftsKey));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      // Ignore
    }
  }

  /// Sync local drafts with server
  Future<void> syncLocalDrafts(int userId) async {
    final localDrafts = await _getLocalDrafts(userId);
    final unsyncedDrafts = localDrafts.where((d) => d.syncStatus == DraftStatus.local);

    for (final draft in unsyncedDrafts) {
      final result = await saveDraft(
        userId: draft.userId,
        postType: draft.postType,
        content: draft.content,
        backgroundColor: draft.backgroundColor,
        privacy: draft.privacy,
        locationName: draft.locationName,
        locationLat: draft.locationLat,
        locationLng: draft.locationLng,
        taggedUsers: draft.taggedUsers,
        scheduledAt: draft.scheduledAt,
        title: draft.title,
      );

      if (result.success && result.draft != null) {
        // Update local draft with server ID
        await _saveLocalDraft(result.draft!);
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _autoSaveTimer?.cancel();
  }
}
