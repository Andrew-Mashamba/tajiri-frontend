import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/livestream_models.dart';
import '../config/api_config.dart';
// TODO: Wire ExpenditureService into sendGift() once gift value (price * quantity)
// is passed as a parameter. Currently only giftId is available, not the monetary value.
// import 'expenditure_service.dart';

String get _baseUrl => ApiConfig.baseUrl;

class LiveStreamService {
  Future<StreamsResult> getStreams({String? status, int? currentUserId}) async {
    try {
      String url = '$_baseUrl/streams?';
      if (status != null) url += 'status=$status&';
      if (currentUserId != null) url += 'current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final streams = (data['data'] as List).map((s) => LiveStream.fromJson(s)).toList();
          return StreamsResult(success: true, streams: streams);
        }
      }
      return StreamsResult(success: false, message: 'Failed to load streams');
    } catch (e) {
      return StreamsResult(success: false, message: 'Error: $e');
    }
  }

  Future<StreamsResult> getLiveStreams({int? currentUserId}) async {
    return getStreams(status: 'live', currentUserId: currentUserId);
  }

  /// Get upcoming/scheduled streams
  Future<StreamsResult> getUpcomingStreams({int? currentUserId}) async {
    return getStreams(status: 'scheduled', currentUserId: currentUserId);
  }

  Future<StreamResult> createStream({
    required int userId,
    required String title,
    String? description,
    File? thumbnail,
    String? category,
    List<String>? tags,
    String privacy = 'public',
    bool isRecorded = true,
    bool allowComments = true,
    bool allowGifts = true,
    DateTime? scheduledAt,
  }) async {
    print('[LiveStreamService] createStream called');
    print('[LiveStreamService] URL: $_baseUrl/streams');
    print('[LiveStreamService] userId: $userId');
    print('[LiveStreamService] title: $title');
    print('[LiveStreamService] description: $description');
    print('[LiveStreamService] category: $category');
    print('[LiveStreamService] tags: $tags');
    print('[LiveStreamService] privacy: $privacy');
    print('[LiveStreamService] thumbnail: ${thumbnail?.path}');

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/streams'));

      request.fields['user_id'] = userId.toString();
      request.fields['title'] = title;
      if (description != null) request.fields['description'] = description;
      if (category != null) request.fields['category'] = category;

      // Laravel multipart form data expects arrays with bracket notation
      if (tags != null && tags.isNotEmpty) {
        for (int i = 0; i < tags.length; i++) {
          request.fields['tags[$i]'] = tags[i];
        }
      }

      request.fields['privacy'] = privacy;
      // Laravel expects "1" or "0" for boolean fields
      request.fields['is_recorded'] = isRecorded ? '1' : '0';
      request.fields['allow_comments'] = allowComments ? '1' : '0';
      request.fields['allow_gifts'] = allowGifts ? '1' : '0';
      if (scheduledAt != null) request.fields['scheduled_at'] = scheduledAt.toIso8601String();

      print('[LiveStreamService] Request fields: ${request.fields}');

      if (thumbnail != null) {
        print('[LiveStreamService] Adding thumbnail file: ${thumbnail.path}');
        request.files.add(await http.MultipartFile.fromPath('thumbnail', thumbnail.path));
        print('[LiveStreamService] Thumbnail added, file size: ${await thumbnail.length()} bytes');
      }

      print('[LiveStreamService] Sending request...');
      final streamedResponse = await request.send();
      print('[LiveStreamService] Response status code: ${streamedResponse.statusCode}');

      final response = await http.Response.fromStream(streamedResponse);
      print('[LiveStreamService] Response body: ${response.body}');

      final data = jsonDecode(response.body);
      print('[LiveStreamService] Decoded response: $data');

      if (response.statusCode == 201 && data['success'] == true) {
        print('[LiveStreamService] Stream created successfully!');
        return StreamResult(success: true, stream: LiveStream.fromJson(data['data']));
      }

      // Extract error message
      String errorMessage = data['message'] ?? 'Failed';
      if (data['errors'] != null) {
        // Laravel validation errors format: {"errors": {"field": ["error message"]}}
        final errors = data['errors'] as Map<String, dynamic>;
        final errorMessages = errors.values.map((e) => (e as List).first).join(', ');
        errorMessage = errorMessages.isNotEmpty ? errorMessages : errorMessage;
      }

      print('[LiveStreamService] Stream creation failed - status: ${response.statusCode}, success: ${data['success']}, message: $errorMessage');
      return StreamResult(success: false, message: errorMessage);
    } catch (e, stackTrace) {
      print('[LiveStreamService] EXCEPTION in createStream: $e');
      print('[LiveStreamService] Stack trace: $stackTrace');
      return StreamResult(success: false, message: 'Error: $e');
    }
  }

  /// GET /streams/{id}/check — lightweight status for reconnection/polling.
  Future<StreamCheckResponse> checkStream(int streamId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/streams/$streamId/check'));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return StreamCheckResponse.fromJson(data);
    } catch (e) {
      return StreamCheckResponse(
        success: false,
        exists: false,
        isActive: false,
        streamEnded: false,
        message: 'Error: $e',
      );
    }
  }

  Future<StreamResult> getStream(int streamId, {int? currentUserId}) async {
    try {
      String url = '$_baseUrl/streams/$streamId';
      if (currentUserId != null) url += '?current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          final stream = LiveStream.fromJson(data['data'] as Map<String, dynamic>);
          // Top-level playback_url and websocket when stream is active (API guide)
          final playbackUrl = data['playback_url'] as String? ?? stream.playbackUrl;
          final websocketJson = data['websocket'] as Map<String, dynamic>?;
          final streamStatusInfo = data['stream_status_info'] != null
              ? StreamStatusInfo.fromJson(data['stream_status_info'] as Map<String, dynamic>)
              : null;
          final endedSummary = data['ended_summary'] != null
              ? StreamEndedSummary.fromJson(data['ended_summary'] as Map<String, dynamic>)
              : null;
          return StreamResult(
            success: true,
            stream: playbackUrl != null ? stream.copyWith(playbackUrl: playbackUrl) : stream,
            streamStatusInfo: streamStatusInfo,
            websocket: websocketJson != null ? StreamWebSocketInfo.fromJson(websocketJson) : null,
            endedSummary: endedSummary,
          );
        }
      }
      return StreamResult(success: false, message: 'Stream not found');
    } catch (e) {
      return StreamResult(success: false, message: 'Error: $e');
    }
  }

  Future<StreamResult> startStream(int streamId) async {
    print('[LiveStreamService] startStream called for streamId: $streamId');
    print('[LiveStreamService] URL: $_baseUrl/streams/$streamId/start');

    try {
      final response = await http.post(Uri.parse('$_baseUrl/streams/$streamId/start'));
      print('[LiveStreamService] startStream - Response status code: ${response.statusCode}');
      print('[LiveStreamService] startStream - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[LiveStreamService] startStream - Decoded response: $data');

        if (data['success'] == true) {
          print('[LiveStreamService] Stream started successfully!');
          return StreamResult(success: true, stream: LiveStream.fromJson(data['data']));
        }
      }

      // Extract error message
      String errorMessage = 'Failed to start stream';
      try {
        final data = jsonDecode(response.body);
        if (data['message'] != null) {
          errorMessage = data['message'];
        } else if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          final errorMessages = errors.values.map((e) => (e as List).first).join(', ');
          errorMessage = errorMessages.isNotEmpty ? errorMessages : errorMessage;
        }
      } catch (e) {
        print('[LiveStreamService] Failed to parse error message: $e');
      }

      print('[LiveStreamService] startStream failed - message: $errorMessage');
      return StreamResult(success: false, message: errorMessage);
    } catch (e, stackTrace) {
      print('[LiveStreamService] EXCEPTION in startStream: $e');
      print('[LiveStreamService] Stack trace: $stackTrace');
      return StreamResult(success: false, message: 'Error: $e');
    }
  }

  Future<StreamResult> endStream(int streamId) async {
    try {
      final response = await http.post(Uri.parse('$_baseUrl/streams/$streamId/end'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return StreamResult(success: true, stream: LiveStream.fromJson(data['data']));
        }
      }
      return StreamResult(success: false, message: 'Failed to end stream');
    } catch (e) {
      return StreamResult(success: false, message: 'Error: $e');
    }
  }

  /// POST /streams/{id}/join — returns playback_url + websocket; handle 200/404/409/410 per API guide.
  Future<JoinStreamResult> joinStream(int streamId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      final data = response.body.isNotEmpty
          ? (jsonDecode(response.body) as Map<String, dynamic>? ?? <String, dynamic>{})
          : <String, dynamic>{};

      final success = data['success'] == true;
      final message = data['message'] as String?;
      final streamStatus = data['stream_status'] as String?;
      final streamEnded = data['stream_ended'] == true;
      final playbackUrl = data['playback_url'] as String?;
      final currentViewers = data['current_viewers'] is int
          ? data['current_viewers'] as int
          : int.tryParse(data['current_viewers']?.toString() ?? '');
      final websocketJson = data['websocket'] as Map<String, dynamic>?;
      final websocket = websocketJson != null ? StreamWebSocketInfo.fromJson(websocketJson) : null;
      final endedAtStr = data['ended_at'] as String?;
      final endedAt = endedAtStr != null && endedAtStr.isNotEmpty ? DateTime.tryParse(endedAtStr) : null;
      final duration = data['duration'] is int ? data['duration'] as int : int.tryParse(data['duration']?.toString() ?? '');
      final totalViewers = data['total_viewers'] is int ? data['total_viewers'] as int : int.tryParse(data['total_viewers']?.toString() ?? '');
      final peakViewers = data['peak_viewers'] is int ? data['peak_viewers'] as int : int.tryParse(data['peak_viewers']?.toString() ?? '');
      final scheduledAtStr = data['scheduled_at'] as String?;
      final scheduledAt = scheduledAtStr != null && scheduledAtStr.isNotEmpty ? DateTime.tryParse(scheduledAtStr) : null;

      return JoinStreamResult(
        statusCode: response.statusCode,
        success: success,
        message: message,
        streamStatus: streamStatus,
        streamEnded: streamEnded,
        playbackUrl: playbackUrl,
        currentViewers: currentViewers,
        websocket: websocket,
        endedAt: endedAt,
        duration: duration,
        totalViewers: totalViewers,
        peakViewers: peakViewers,
        scheduledAt: scheduledAt,
      );
    } catch (e) {
      return JoinStreamResult(
        statusCode: 0,
        success: false,
        message: 'Error: $e',
      );
    }
  }

  Future<bool> leaveStream(int streamId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/leave'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> likeStream(int streamId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Comments
  Future<CommentsResult> getComments(int streamId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/streams/$streamId/comments'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final comments = (data['data'] as List).map((c) => StreamComment.fromJson(c)).toList();
          return CommentsResult(success: true, comments: comments);
        }
      }
      return CommentsResult(success: false, message: 'Failed');
    } catch (e) {
      return CommentsResult(success: false, message: 'Error: $e');
    }
  }

  Future<CommentResult> addComment(int streamId, int userId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/comments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'content': content}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return CommentResult(success: true, comment: StreamComment.fromJson(data['data']));
      }
      return CommentResult(success: false, message: data['message'] ?? 'Failed');
    } catch (e) {
      return CommentResult(success: false, message: 'Error: $e');
    }
  }

  Future<bool> pinComment(int streamId, int commentId) async {
    try {
      final response = await http.post(Uri.parse('$_baseUrl/streams/$streamId/comments/$commentId/pin'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Gifts
  Future<GiftsResult> getAvailableGifts() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/streams/gifts'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final gifts = (data['data'] as List).map((g) => VirtualGift.fromJson(g)).toList();
          return GiftsResult(success: true, gifts: gifts);
        }
      }
      return GiftsResult(success: false, message: 'Failed');
    } catch (e) {
      return GiftsResult(success: false, message: 'Error: $e');
    }
  }

  Future<bool> sendGift(int streamId, int senderId, int giftId, {int quantity = 1, String? message}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/gifts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_id': senderId,
          'gift_id': giftId,
          'quantity': quantity,
          if (message != null) 'message': message,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Co-hosts
  Future<bool> inviteCohost(int streamId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/cohosts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> respondToCohost(int streamId, int cohostId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/streams/$streamId/cohosts/$cohostId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeCohost(int streamId, int cohostId) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/streams/$streamId/cohosts/$cohostId'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Viewers
  Future<ViewersResult> getViewers(int streamId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/streams/$streamId/viewers'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final viewers = (data['data'] as List).map((v) => StreamViewer.fromJson(v)).toList();
          return ViewersResult(success: true, viewers: viewers);
        }
      }
      return ViewersResult(success: false, message: 'Failed');
    } catch (e) {
      return ViewersResult(success: false, message: 'Error: $e');
    }
  }

  /// DELETE /streams/{id} — delete a stream.
  Future<bool> deleteStream(int streamId) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/streams/$streamId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// PUT /streams/{id} — update a stream's title/description.
  Future<StreamResult> updateStream(int streamId, {String? title, String? description}) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;

      final response = await http.put(
        Uri.parse('$_baseUrl/streams/$streamId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return StreamResult(success: true, stream: LiveStream.fromJson(data['data']));
        }
        return StreamResult(success: false, message: data['message'] ?? 'Failed to update stream');
      }
      return StreamResult(success: false, message: 'Failed to update stream');
    } catch (e) {
      return StreamResult(success: false, message: 'Error: $e');
    }
  }

  // User's streams
  Future<StreamsResult> getUserStreams(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/streams/user/$userId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final streams = (data['data'] as List).map((s) => LiveStream.fromJson(s)).toList();
          return StreamsResult(success: true, streams: streams);
        }
      }
      return StreamsResult(success: false, message: 'Failed');
    } catch (e) {
      return StreamsResult(success: false, message: 'Error: $e');
    }
  }
}

// Result classes
class StreamsResult {
  final bool success;
  final List<LiveStream> streams;
  final String? message;

  StreamsResult({required this.success, this.streams = const [], this.message});
}

class StreamResult {
  final bool success;
  final LiveStream? stream;
  final String? message;
  final StreamStatusInfo? streamStatusInfo;
  final StreamWebSocketInfo? websocket;
  final StreamEndedSummary? endedSummary;

  StreamResult({
    required this.success,
    this.stream,
    this.message,
    this.streamStatusInfo,
    this.websocket,
    this.endedSummary,
  });
}

class CommentsResult {
  final bool success;
  final List<StreamComment> comments;
  final String? message;

  CommentsResult({required this.success, this.comments = const [], this.message});
}

class CommentResult {
  final bool success;
  final StreamComment? comment;
  final String? message;

  CommentResult({required this.success, this.comment, this.message});
}

class GiftsResult {
  final bool success;
  final List<VirtualGift> gifts;
  final String? message;

  GiftsResult({required this.success, this.gifts = const [], this.message});
}

class ViewersResult {
  final bool success;
  final List<StreamViewer> viewers;
  final String? message;

  ViewersResult({required this.success, this.viewers = const [], this.message});
}
