import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'http_retry.dart';
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

      final response = await httpGetWithRetry(Uri.parse(url));

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
      final response = await httpGetWithRetry(Uri.parse('$_baseUrl/streams/$streamId/check'));
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

      final response = await httpGetWithRetry(Uri.parse(url));

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
  /// [shareUid] is forwarded so backend fires `view_from_share·sharer` for the original
  /// link sharer (streams.md §III row 26).
  Future<JoinStreamResult> joinStream(int streamId, int userId, {String? shareUid}) async {
    try {
      final body = <String, dynamic>{'user_id': userId};
      if (shareUid != null && shareUid.isNotEmpty) body['share_uid'] = shareUid;
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
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
      final response = await httpGetWithRetry(Uri.parse('$_baseUrl/streams/$streamId/comments'));

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
      final response = await httpGetWithRetry(Uri.parse('$_baseUrl/streams/gifts'));

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

  Future<bool> sendGift(int streamId, int senderId, int giftId, {int quantity = 1, String? message, String? transactionId}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/gifts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          // Backend validation requires `user_id` (not `sender_id`).
          'user_id': senderId,
          'gift_id': giftId,
          'quantity': quantity,
          if (message != null) 'message': message,
          // L1 — idempotency. Caller passes a stable UUIDv4 per tap so a
          // network retry short-circuits via the partial unique index
          // stream_gifts_transaction_id_unique.
          if (transactionId != null) 'transaction_id': transactionId,
        }),
      );
      return response.statusCode == 201 || response.statusCode == 200;
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
      final response = await httpGetWithRetry(Uri.parse('$_baseUrl/streams/$streamId/viewers'));

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
      final response = await httpGetWithRetry(Uri.parse('$_baseUrl/streams/user/$userId'));

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

  // ─── Phase A — viewer earnings emitters ────────────────────────────

  /// streams.md §I row 3 — live_reaction·author. Fires per heart/fire/clap.
  /// reaction_type ∈ {heart, fire, love, wow, clap, laugh}
  Future<bool> sendReaction(int streamId, int userId, String reactionType) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/reaction'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'reaction_type': reactionType}),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  /// streams.md §I row 2 — live_watch_minute·author. Client should call once
  /// per minute while video is playing. Backend dedupes per (actor, stream,
  /// minute-bucket) via funding_source.
  Future<bool> heartbeat(int streamId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/heartbeat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  /// streams.md §I row 16 — screenshot_during_live·author. Fired by the
  /// ScreenCaptureEvent listener on iOS/Android.
  Future<bool> screenshotFeedback(int streamId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/screenshot'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  /// streams.md §III row 25 — stream_share·sharer. Returns share_uid + URL.
  Future<({bool success, String? shareUid, String? shareUrl})> shareStream(
      int streamId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/share'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      if (response.statusCode == 200) {
        final d = jsonDecode(response.body) as Map<String, dynamic>;
        return (
          success: d['success'] == true,
          shareUid: d['share_uid'] as String?,
          shareUrl: d['share_url'] as String?,
        );
      }
      return (success: false, shareUid: null, shareUrl: null);
    } catch (_) {
      return (success: false, shareUid: null, shareUrl: null);
    }
  }

  /// streams.md §I row 5 — live_super_chat·author. Paid pinned chat.
  Future<bool> sendSuperChat(int streamId, int userId, int amount, {String? message}) async {
    try {
      final body = <String, dynamic>{'user_id': userId, 'amount': amount};
      if (message != null && message.isNotEmpty) body['message'] = message;
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/super-chats'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  /// streams.md §II — Q&A (rows 20, 21).
  Future<({bool success, int? questionId})> submitQuestion(
      int streamId, int userId, String question) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/questions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'question': question}),
      );
      if (response.statusCode == 200) {
        final d = jsonDecode(response.body) as Map<String, dynamic>;
        final qid = (d['question'] is Map ? (d['question'] as Map)['id'] : null)
            ?? (d['data'] is Map ? (d['data'] as Map)['id'] : null);
        return (success: d['success'] == true, questionId: qid is int ? qid : null);
      }
      return (success: false, questionId: null);
    } catch (_) { return (success: false, questionId: null); }
  }

  Future<bool> upvoteQuestion(int streamId, int userId, int questionId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/questions/$questionId/upvote'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  Future<bool> answerQuestion(int streamId, int userId, int questionId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/questions/$questionId/answer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  // ─── Phase A — negative attribution ────────────────────────────────

  /// Streams Integrity Framework §A. signal ∈ {
  ///   negative_reaction_during_live, rapid_leave, session_exit_after_join,
  ///   mute_streamer, unfollow_during_or_after_stream, block_streamer,
  ///   report_stream, not_interested_in_streams_like_this,
  ///   negative_share_during_stream, chat_disable_for_creator
  /// }
  Future<bool> negativeFeedback(int streamId, int userId, String signal,
      {Map<String, dynamic>? metadata}) async {
    try {
      final body = <String, dynamic>{
        'user_id': userId,
        'signal_type': signal,
      };
      if (metadata != null) body['metadata'] = metadata;
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  // ─── Phase A — external link click ─────────────────────────────────

  Future<bool> externalLinkClick(int streamId, int userId, String url) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/external-link-click'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'url': url}),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  // ─── Phase B — streamer tools ──────────────────────────────────────

  /// streams.md §III row 28 — raid_in·raid_streamer.
  Future<bool> raidStream({
    required int sourceStreamId,
    required int raidStreamerId,
    required int targetStreamId,
    int viewerCount = 0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$sourceStreamId/raid'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'raid_streamer_id': raidStreamerId,
          'target_stream_id': targetStreamId,
          'viewer_count': viewerCount,
        }),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  /// streams.md §III row 29 — host_in·host_streamer.
  Future<bool> hostStream({
    required int hostStreamId,
    required int hostStreamerId,
    required int hostedStreamId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$hostStreamId/host'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'host_streamer_id': hostStreamerId,
          'hosted_stream_id': hostedStreamId,
        }),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  /// streams.md §IX row 54 — live_product_show·author.
  Future<bool> pinStreamProduct({
    required int streamId,
    required int streamerUserId,
    int? productId,
    String? externalUrl,
    String? label,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'streamer_user_id': streamerUserId,
          if (productId != null) 'product_id': productId,
          if (externalUrl != null) 'external_url': externalUrl,
          if (label != null) 'label': label,
        }),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  /// streams.md §IX row 55 — live_product_expand·author.
  Future<bool> expandStreamProduct({
    required int streamId,
    required int streamProductId,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/products/$streamProductId/expand'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  /// streams.md §IX row 56 — live_wishlist_add·author.
  Future<bool> wishlistStreamProduct({
    required int streamId,
    required int streamProductId,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/products/$streamProductId/wishlist'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  /// streams.md §XI row 71 — synthetic_avatar_disclosed·author.
  Future<bool> disclosesyntheticAvatar({
    required int streamId,
    required int subjectUserId,
    String? avatarProvider,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/ai/synthetic-avatar-disclosed'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'stream_id': streamId,
          'subject_user_id': subjectUserId,
          if (avatarProvider != null) 'avatar_provider': avatarProvider,
        }),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  // ─── Phase C — VOD ─────────────────────────────────────────────────

  Future<bool> vodView({required int streamId, required int userId}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/vod/view'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  Future<bool> vodHeartbeat({required int streamId, required int userId, int watchedSeconds = 30}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/vod/heartbeat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'watched_seconds': watchedSeconds}),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  /// streams.md §VIII rows 51-53 — utility events.
  /// event ∈ {tutorial-completion, bookmark, transcript-save}
  Future<bool> recordUtilityEvent({
    required int streamId,
    required int userId,
    required String event,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/utility/$event'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          if (metadata != null) 'metadata': metadata,
        }),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  // ─── Phase A — notify followers (creator-side) ────────────────────

  Future<bool> notifyFollowers(int streamId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/notify-followers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Phase F — Remaining 14 surfaces (closes streams.md §V/§VII/§XI/§III)
  // ═══════════════════════════════════════════════════════════════════

  // ─── §V Localization (4) ──────────────────────────────────────────

  /// streams.md §V row 40 — live_caption_create·captioner.
  Future<int?> createCaption({
    required int streamId,
    required int captionerUserId,
    String languageCode = 'en',
    String? captionUrl,
    bool isLive = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/captions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'captioner_user_id': captionerUserId,
          'language_code': languageCode,
          if (captionUrl != null) 'caption_url': captionUrl,
          'is_live': isLive,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['caption_id'] as int?;
      }
      return null;
    } catch (_) { return null; }
  }

  /// streams.md §V row 41 — subtitle_localization·translator.
  Future<int?> createTranslation({
    required int streamId,
    required int translatorUserId,
    required String sourceLanguageCode,
    required String targetLanguageCode,
    String? subtitleUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/translations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'translator_user_id': translatorUserId,
          'source_language_code': sourceLanguageCode,
          'target_language_code': targetLanguageCode,
          if (subtitleUrl != null) 'subtitle_url': subtitleUrl,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['translation_id'] as int?;
      }
      return null;
    } catch (_) { return null; }
  }

  /// streams.md §V row 42 — dub_overlay·voice_actor.
  Future<int?> createDub({
    required int streamId,
    required int voiceActorUserId,
    required String languageCode,
    String? audioUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/dubs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'voice_actor_user_id': voiceActorUserId,
          'language_code': languageCode,
          if (audioUrl != null) 'audio_url': audioUrl,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['dub_id'] as int?;
      }
      return null;
    } catch (_) { return null; }
  }

  /// streams.md §V row 43 — translated_vod_view·translator.
  /// Fired when a viewer activates a non-default subtitle track on VOD.
  Future<bool> viewTranslation({
    required int streamId,
    required int translationId,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/translations/$translationId/view'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  // ─── §XI AI provenance (3 — synthetic_avatar already wired above) ─

  /// streams.md §XI row 68 — ai_clip_generation·author.
  /// Fired when an AI pipeline generates a derivative clip from this stream.
  /// Original creator earns; pipeline/clipper is recorded as actor.
  Future<bool> aiClipGeneration({
    required int streamId,
    required int subjectUserId,
    required int actorUserId,
    String? modelId,
    String? licenseId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/ai/clip-generation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'stream_id': streamId,
          'subject_user_id': subjectUserId,
          'actor_user_id': actorUserId,
          if (modelId != null) 'model_id': modelId,
          if (licenseId != null) 'license_id': licenseId,
        }),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  /// streams.md §XI row 69 — ai_voice_clone_usage·author.
  Future<bool> aiVoiceCloneUsage({
    required int subjectUserId,
    required int actorUserId,
    int? streamId,
    String? licenseId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/ai/voice-clone-usage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (streamId != null) 'stream_id': streamId,
          'subject_user_id': subjectUserId,
          'actor_user_id': actorUserId,
          if (licenseId != null) 'license_id': licenseId,
        }),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  /// streams.md §XI row 70 — ai_assisted_remix·remixer.
  Future<bool> aiAssistedRemix({
    required int streamId,
    required int remixerUserId,
    String? modelId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/ai/assisted-remix'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'stream_id': streamId,
          'remixer_user_id': remixerUserId,
          if (modelId != null) 'model_id': modelId,
        }),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  // ─── §III Distribution — cross_post_view (1) ──────────────────────

  /// streams.md §IV row 38 — highlight_compilation·editor.
  /// Fired when an AI auto-clip pipeline (Lever 3) compiles a highlight
  /// reel from a stream. Caller is typically the pipeline service or a
  /// human curator who triggers the job.
  Future<bool> highlightCompilation({
    required int streamId,
    required int editorUserId,
    String? modelId,
    List<int>? sourceClipIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/ai/highlight-compilation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'stream_id': streamId,
          'editor_user_id': editorUserId,
          if (modelId != null) 'model_id': modelId,
          if (sourceClipIds != null) 'source_clip_ids': sourceClipIds,
        }),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  /// streams.md §III row 32 — cross_post_view·sharer (Lever 4).
  /// Fired when a stream is opened from a cross-post on an external
  /// platform (the share link carries `?from=<platform>`).
  Future<bool> crossPostView({
    required int streamId,
    required int sharerUserId,
    required String externalPlatform,
    int? viewerUserId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/cross-post-view'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sharer_user_id': sharerUserId,
          if (viewerUserId != null) 'viewer_user_id': viewerUserId,
          'external_platform': externalPlatform,
        }),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  // ─── §VII Multi-streamer (cohost variants + guest) ────────────────

  /// streams.md §VII — invite a user to co-host this stream.
  Future<bool> cohostInvite({
    required int streamId,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/cohost/invite'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  /// streams.md §VII — accept (or decline) a co-host invitation.
  /// Backend sets joined_at when accept=true; cohost_split fires
  /// automatically as tip_pool_distributions roll in.
  Future<bool> cohostRespond({
    required int streamId,
    required int userId,
    required bool accept,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/cohost/respond'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'accept': accept}),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  /// streams.md §VII — leave an active co-host slot.
  Future<bool> cohostLeave({
    required int streamId,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/cohost/leave'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  /// streams.md §VII row 50 — guest_appearance·guest.
  /// Records a guest drop-in / panel / interview appearance.
  Future<bool> guestAppearance({
    required int streamId,
    required int guestUserId,
    String role = 'guest',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/guests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'guest_user_id': guestUserId,
          'role': role,
        }),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  // ─── §I Direct — host-side dwell (1) ──────────────────────────────

  /// streams.md §I — host_duration_heartbeat·author.
  /// Mirrors viewer heartbeat; host fires every 60s while broadcasting.
  Future<bool> hostHeartbeat({
    required int streamId,
    required int streamerUserId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/host-heartbeat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'streamer_user_id': streamerUserId}),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  // ─── §VI Curation (2) ─────────────────────────────────────────────

  /// streams.md §VI row 44 — category_feature·curator.
  Future<bool> curationCategoryFeature({
    required int streamId,
    required int curatorUserId,
    required String category,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/curation/category-feature'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'curator_user_id': curatorUserId,
          'category': category,
        }),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  /// Phase G — broadcaster persists a pinned outbound link.
  /// Pass `url=null` (or empty) to clear. When set, the backend self-fires
  /// external_link_click·author for attribution; viewers see it via
  /// the standard getStream payload (`pinned_link_url`/`pinned_link_label`).
  Future<bool> setPinnedLink({
    required int streamId,
    required int streamerUserId,
    String? url,
    String? label,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/pinned-link'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'streamer_user_id': streamerUserId,
          if (url != null) 'url': url,
          if (label != null) 'label': label,
        }),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  /// streams.md §I row 11 — notify_live_optin·author.
  /// Per-viewer toggle: opts the viewer in/out of "notify when this
  /// streamer goes live" pushes. Enabling fires the earnings event
  /// (creator earns) the first time it's enabled.
  Future<bool> notifyLiveToggle({
    required int streamerUserId,
    required int userId,
    required bool enabled,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/streamer/$streamerUserId/notify-live-toggle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'enabled': enabled}),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  Future<bool> notifyLiveStatus({
    required int streamerUserId,
    required int userId,
  }) async {
    try {
      final response = await httpGetWithRetry(
        Uri.parse('$_baseUrl/streams/streamer/$streamerUserId/notify-live-toggle?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['enabled'] == true;
      }
      return false;
    } catch (_) { return false; }
  }

  /// streams.md §II row 18 — chat_reaction·chat_author.
  /// Viewer reacts to another viewer's chat message; backend upserts
  /// (one per comment+user) and credits the chat author.
  Future<bool> reactToComment({
    required int streamId,
    required int commentId,
    required int userId,
    required String reactionType, // heart|fire|clap|wow|laugh|sad
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/comments/$commentId/reaction'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'reaction_type': reactionType,
        }),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  /// streams.md §II row 20 — list questions submitted on a stream
  /// (viewer-side Q&A panel reads this to show upvote-able questions).
  Future<List<StreamQuestion>> getQuestions(int streamId) async {
    try {
      final response = await httpGetWithRetry(
        Uri.parse('$_baseUrl/streams/$streamId/questions'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['questions'] as List)
              .map((q) => StreamQuestion.fromJson(q as Map<String, dynamic>))
              .toList();
        }
      }
      return const [];
    } catch (_) { return const []; }
  }

  /// streams.md §VI row 45 — collection_add·curator.
  Future<bool> curationCollectionAdd({
    required int streamId,
    required int curatorUserId,
    required int collectionId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/streams/$streamId/curation/collection-add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'curator_user_id': curatorUserId,
          'collection_id': collectionId,
        }),
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
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
