import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/story_models.dart';
import '../config/api_config.dart';

String get _baseUrl => ApiConfig.baseUrl;

class StoryService {
  Future<StoryListResult> getStories({int? currentUserId}) async {
    try {
      String url = '$_baseUrl/stories';
      if (currentUserId != null) url += '?current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final groups = (data['data'] as List)
              .map((g) => StoryGroup.fromJson(g))
              .toList();
          return StoryListResult(success: true, groups: groups);
        }
      }
      return StoryListResult(success: false, message: 'Failed to load stories');
    } catch (e) {
      return StoryListResult(success: false, message: 'Error: $e');
    }
  }

  Future<StoryResult> createStory({
    required int userId,
    required String mediaType,
    File? media,
    String? caption,
    int? duration,
    List<Map<String, dynamic>>? textOverlays,
    List<Map<String, dynamic>>? stickers,
    String? filter,
    int? musicId,
    int? musicStart,
    String? backgroundColor,
    String? linkUrl,
    String? locationName,
    double? latitude,
    double? longitude,
    String privacy = 'everyone',
    bool allowReplies = true,
    bool allowSharing = true,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/stories'));

      request.fields['user_id'] = userId.toString();
      request.fields['media_type'] = mediaType;
      if (caption != null) request.fields['caption'] = caption;
      if (duration != null) request.fields['duration'] = duration.toString();
      if (filter != null) request.fields['filter'] = filter;
      if (musicId != null) request.fields['music_id'] = musicId.toString();
      if (musicStart != null) request.fields['music_start'] = musicStart.toString();
      if (backgroundColor != null) request.fields['background_color'] = backgroundColor;
      if (linkUrl != null) request.fields['link_url'] = linkUrl;
      if (locationName != null) request.fields['location_name'] = locationName;
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();
      request.fields['privacy'] = privacy;
      request.fields['allow_replies'] = allowReplies.toString();
      request.fields['allow_sharing'] = allowSharing.toString();

      if (textOverlays != null) {
        request.fields['text_overlays'] = jsonEncode(textOverlays);
      }
      if (stickers != null) {
        request.fields['stickers'] = jsonEncode(stickers);
      }

      if (media != null) {
        request.files.add(await http.MultipartFile.fromPath('media', media.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return StoryResult(success: true, story: Story.fromJson(data['data']));
      }
      return StoryResult(success: false, message: data['message'] ?? 'Failed');
    } catch (e) {
      return StoryResult(success: false, message: 'Error: $e');
    }
  }

  Future<StoryResult> getStory(int storyId, {int? currentUserId}) async {
    try {
      String url = '$_baseUrl/stories/$storyId';
      if (currentUserId != null) url += '?current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return StoryResult(success: true, story: Story.fromJson(data['data']));
        }
      }
      return StoryResult(success: false, message: 'Story not found');
    } catch (e) {
      return StoryResult(success: false, message: 'Error: $e');
    }
  }

  Future<bool> deleteStory(int storyId) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/stories/$storyId'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<UserStoriesResult> getUserStories(int userId, {int? currentUserId}) async {
    try {
      String url = '$_baseUrl/stories/user/$userId';
      if (currentUserId != null) url += '?current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final stories = (data['data'] as List)
              .map((s) => Story.fromJson(s))
              .toList();
          return UserStoriesResult(success: true, stories: stories);
        }
      }
      return UserStoriesResult(success: false, message: 'Failed');
    } catch (e) {
      return UserStoriesResult(success: false, message: 'Error: $e');
    }
  }

  Future<bool> viewStory(int storyId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/stories/$storyId/view'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<ViewersResult> getViewers(int storyId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/stories/$storyId/viewers'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final viewers = (data['data'] as List)
              .map((v) => StoryViewer.fromJson(v))
              .toList();
          return ViewersResult(success: true, viewers: viewers);
        }
      }
      return ViewersResult(success: false, message: 'Failed');
    } catch (e) {
      return ViewersResult(success: false, message: 'Error: $e');
    }
  }

  Future<bool> reactToStory(int storyId, int userId, String emoji) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/stories/$storyId/react'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'emoji': emoji}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> replyToStory(int storyId, int userId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/stories/$storyId/reply'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'content': content}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Highlights
  Future<HighlightsResult> getHighlights(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/stories/highlights/$userId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final highlights = (data['data'] as List)
              .map((h) => StoryHighlight.fromJson(h))
              .toList();
          return HighlightsResult(success: true, highlights: highlights);
        }
      }
      return HighlightsResult(success: false, message: 'Failed');
    } catch (e) {
      return HighlightsResult(success: false, message: 'Error: $e');
    }
  }

  Future<HighlightResult> createHighlight({
    required int userId,
    required String title,
    required List<int> storyIds,
    File? cover,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/stories/highlights'));

      request.fields['user_id'] = userId.toString();
      request.fields['title'] = title;
      request.fields['story_ids'] = jsonEncode(storyIds);

      if (cover != null) {
        request.files.add(await http.MultipartFile.fromPath('cover', cover.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return HighlightResult(success: true, highlight: StoryHighlight.fromJson(data['data']));
      }
      return HighlightResult(success: false, message: data['message'] ?? 'Failed');
    } catch (e) {
      return HighlightResult(success: false, message: 'Error: $e');
    }
  }

  Future<bool> deleteHighlight(int highlightId) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/stories/highlights/$highlightId'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Add a story to an existing highlight. Requires backend support.
  Future<bool> addStoryToHighlight(int highlightId, int storyId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/stories/highlights/$highlightId/stories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'story_id': storyId}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}

// Result classes
class StoryListResult {
  final bool success;
  final List<StoryGroup> groups;
  final String? message;

  StoryListResult({required this.success, this.groups = const [], this.message});
}

class StoryResult {
  final bool success;
  final Story? story;
  final String? message;

  StoryResult({required this.success, this.story, this.message});
}

class UserStoriesResult {
  final bool success;
  final List<Story> stories;
  final String? message;

  UserStoriesResult({required this.success, this.stories = const [], this.message});
}

class ViewersResult {
  final bool success;
  final List<StoryViewer> viewers;
  final String? message;

  ViewersResult({required this.success, this.viewers = const [], this.message});
}

class HighlightsResult {
  final bool success;
  final List<StoryHighlight> highlights;
  final String? message;

  HighlightsResult({required this.success, this.highlights = const [], this.message});
}

class HighlightResult {
  final bool success;
  final StoryHighlight? highlight;
  final String? message;

  HighlightResult({required this.success, this.highlight, this.message});
}
