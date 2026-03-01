// Video & Audio Calls — Signaling (docs/video-audio-calls, backend-requirements/01)
// New API: POST /api/calls, accept, reject, end, signaling, turn-credentials.
// Use with Bearer token when backend supports it; optional userId for legacy.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

String get _baseUrl => ApiConfig.baseUrl;

class CallSignalingService {
  /// Create a 1:1 call. Returns call_id and ice_servers.
  /// [authToken] — Bearer token for Laravel Sanctum. If null, backend may rely on session/user_id.
  Future<CreateCallResponse> createCall({
    required int calleeId,
    required String type,
    String? authToken,
    int? userId,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final body = <String, dynamic>{
        'callee_id': calleeId,
        'type': type,
      };
      if (userId != null) body['user_id'] = userId;

      final response = await http.post(
        Uri.parse('$_baseUrl/calls'),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};

      if (response.statusCode == 201) {
        final iceServers = _parseIceServers(data['ice_servers']);
        return CreateCallResponse(
          success: true,
          callId: data['call_id']?.toString() ?? '',
          status: data['status']?.toString() ?? 'pending',
          type: data['type']?.toString() ?? type,
          iceServers: iceServers,
          createdAt: data['created_at'] != null
              ? DateTime.tryParse(data['created_at'].toString())
              : null,
        );
      }
      return CreateCallResponse(
        success: false,
        message: data['message']?.toString() ?? 'Failed to create call',
      );
    } catch (e) {
      return CreateCallResponse(success: false, message: 'Error: $e');
    }
  }

  /// Accept call. Optionally send SDP answer in body.
  Future<AcceptCallResponse> acceptCall({
    required String callId,
    String? authToken,
    int? userId,
    Map<String, dynamic>? sdpAnswer,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final body = <String, dynamic>{};
      if (userId != null) body['user_id'] = userId;
      if (sdpAnswer != null) body['sdp_answer'] = sdpAnswer;

      final response = await http.post(
        Uri.parse('$_baseUrl/calls/$callId/accept'),
        headers: headers,
        body: body.isEmpty ? null : jsonEncode(body),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};

      if (response.statusCode == 200) {
        final iceServers = _parseIceServers(data['ice_servers']);
        return AcceptCallResponse(
          success: true,
          callId: data['call_id']?.toString() ?? callId,
          status: data['status']?.toString() ?? 'connected',
          startedAt: data['started_at'] != null
              ? DateTime.tryParse(data['started_at'].toString())
              : null,
          iceServers: iceServers,
        );
      }
      return AcceptCallResponse(
        success: false,
        message: data['message']?.toString() ?? 'Failed to accept call',
      );
    } catch (e) {
      return AcceptCallResponse(success: false, message: 'Error: $e');
    }
  }

  /// Reject call.
  Future<RejectCallResponse> rejectCall({
    required String callId,
    String? authToken,
    int? userId,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final body = userId != null ? jsonEncode({'user_id': userId}) : null;

      final response = await http.post(
        Uri.parse('$_baseUrl/calls/$callId/reject'),
        headers: headers,
        body: body,
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};

      if (response.statusCode == 200) {
        return RejectCallResponse(
          success: true,
          callId: data['call_id']?.toString() ?? callId,
          status: data['status']?.toString() ?? 'rejected',
        );
      }
      return RejectCallResponse(
        success: false,
        message: data['message']?.toString() ?? 'Failed to reject call',
      );
    } catch (e) {
      return RejectCallResponse(success: false, message: 'Error: $e');
    }
  }

  /// End call (either party).
  Future<EndCallResponse> endCall({
    required String callId,
    String? authToken,
    int? userId,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final body = userId != null ? jsonEncode({'user_id': userId}) : null;

      final response = await http.post(
        Uri.parse('$_baseUrl/calls/$callId/end'),
        headers: headers,
        body: body,
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};

      if (response.statusCode == 200) {
        return EndCallResponse(
          success: true,
          callId: data['call_id']?.toString() ?? callId,
          status: data['status']?.toString() ?? 'ended',
          endedAt: data['ended_at'] != null
              ? DateTime.tryParse(data['ended_at'].toString())
              : null,
          durationSeconds: data['duration_seconds'] as int?,
        );
      }
      return EndCallResponse(
        success: false,
        message: data['message']?.toString() ?? 'Failed to end call',
      );
    } catch (e) {
      return EndCallResponse(success: false, message: 'Error: $e');
    }
  }

  /// Send SDP offer, answer, or ICE candidate to the other peer via backend.
  Future<bool> sendSignaling({
    required String callId,
    required String type,
    Map<String, dynamic>? sdp,
    Map<String, dynamic>? candidate,
    String? authToken,
    int? userId,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final body = <String, dynamic>{'type': type};
      if (userId != null) body['user_id'] = userId;
      if (sdp != null) body['sdp'] = sdp;
      if (candidate != null) body['candidate'] = candidate;

      final response = await http.post(
        Uri.parse('$_baseUrl/calls/$callId/signaling'),
        headers: headers,
        body: jsonEncode(body),
      );

      return response.statusCode == 200 || response.statusCode == 202;
    } catch (_) {
      return false;
    }
  }

  /// Get TURN/STUN credentials for WebRTC. Call before creating peer connection.
  Future<TurnCredentialsResponse> getTurnCredentials({
    String? authToken,
    int? userId,
  }) async {
    try {
      String url = '$_baseUrl/calls/turn-credentials';
      if (userId != null) url += '?user_id=$userId';

      final headers = <String, String>{'Accept': 'application/json'};
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.get(Uri.parse(url), headers: headers);
      final data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};

      if (response.statusCode == 200) {
        final iceServers = _parseIceServers(data['ice_servers']);
        return TurnCredentialsResponse(
          success: true,
          iceServers: iceServers,
          ttlSeconds: data['ttl_seconds'] as int?,
        );
      }
      return TurnCredentialsResponse(
        success: false,
        message: data['message']?.toString() ?? 'Failed to get TURN credentials',
      );
    } catch (e) {
      return TurnCredentialsResponse(success: false, message: 'Error: $e');
    }
  }

  /// Call log (list). Paginated.
  Future<CallLogListResponse> getCallLog({
    int page = 1,
    int perPage = 20,
    String? type,
    String? direction,
    String? authToken,
    int? userId,
  }) async {
    try {
      var url = '$_baseUrl/calls?page=$page&per_page=$perPage';
      if (type != null) url += '&type=$type';
      if (direction != null) url += '&direction=$direction';
      if (userId != null) url += '&user_id=$userId';

      final headers = <String, String>{'Accept': 'application/json'};
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.get(Uri.parse(url), headers: headers);
      final data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};

      if (response.statusCode == 200 && data['data'] != null) {
        final list = (data['data'] as List)
            .map((e) => CallLogEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        final meta = data['meta'] != null
            ? CallLogMeta.fromJson(data['meta'] as Map<String, dynamic>)
            : null;
        return CallLogListResponse(success: true, data: list, meta: meta);
      }
      return CallLogListResponse(
        success: false,
        message: data['message']?.toString() ?? 'Failed to load call log',
      );
    } catch (e) {
      return CallLogListResponse(success: false, message: 'Error: $e');
    }
  }

  /// Create group call (Phase 2). POST /api/calls with group_id + invited_user_ids.
  Future<CreateCallResponse> createGroupCall({
    required int groupId,
    required List<int> invitedUserIds,
    required String type,
    String? authToken,
    int? userId,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      final body = <String, dynamic>{
        'group_id': groupId,
        'invited_user_ids': invitedUserIds,
        'type': type,
      };
      if (userId != null) body['user_id'] = userId;

      final response = await http.post(
        Uri.parse('$_baseUrl/calls'),
        headers: headers,
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
      if (response.statusCode == 201) {
        final iceServers = _parseIceServers(data['ice_servers']);
        return CreateCallResponse(
          success: true,
          callId: data['call_id']?.toString() ?? '',
          status: data['status']?.toString() ?? 'pending',
          type: data['type']?.toString() ?? type,
          iceServers: iceServers,
          createdAt: data['created_at'] != null
              ? DateTime.tryParse(data['created_at'].toString())
              : null,
        );
      }
      return CreateCallResponse(
        success: false,
        message: data['message']?.toString() ?? 'Failed to create group call',
      );
    } catch (e) {
      return CreateCallResponse(success: false, message: 'Error: $e');
    }
  }

  /// Add participant to call (Phase 2). POST /api/calls/{id}/participants.
  Future<bool> addParticipant({
    required String callId,
    required int newUserId,
    String? authToken,
    int? userId,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      final body = <String, dynamic>{'user_id': newUserId};
      if (userId != null) body['inviter_user_id'] = userId;

      final response = await http.post(
        Uri.parse('$_baseUrl/calls/$callId/participants'),
        headers: headers,
        body: jsonEncode(body),
      );
      return response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 202;
    } catch (_) {
      return false;
    }
  }

  /// Leave call (Phase 2). POST /api/calls/{id}/leave.
  Future<bool> leaveCall({
    required String callId,
    String? authToken,
    int? userId,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      final body = userId != null ? jsonEncode({'user_id': userId}) : null;
      final response = await http.post(
        Uri.parse('$_baseUrl/calls/$callId/leave'),
        headers: headers,
        body: body,
      );
      return response.statusCode == 200 || response.statusCode == 202;
    } catch (_) {
      return false;
    }
  }

  /// Get participants (Phase 2). GET /api/calls/{id}/participants.
  Future<List<Map<String, dynamic>>> getParticipants({
    required String callId,
    String? authToken,
  }) async {
    try {
      final headers = <String, String>{'Accept': 'application/json'};
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      final response = await http.get(
        Uri.parse('$_baseUrl/calls/$callId/participants'),
        headers: headers,
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
      if (response.statusCode == 200 && data['data'] != null) {
        final list = data['data'] as List;
        return list
            .map((e) => e is Map<String, dynamic> ? Map<String, dynamic>.from(e) : <String, dynamic>{})
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Send reaction (Phase 4). POST /api/calls/{id}/reactions.
  Future<bool> sendReaction({
    required String callId,
    required String emoji,
    String? authToken,
    int? userId,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      final body = <String, dynamic>{'emoji': emoji};
      if (userId != null) body['user_id'] = userId;
      final response = await http.post(
        Uri.parse('$_baseUrl/calls/$callId/reactions'),
        headers: headers,
        body: jsonEncode(body),
      );
      return response.statusCode == 200 || response.statusCode == 202;
    } catch (_) {
      return false;
    }
  }

  /// Raise hand (Phase 4). POST /api/calls/{id}/raise-hand.
  Future<bool> sendRaiseHand({
    required String callId,
    required bool raised,
    String? authToken,
    int? userId,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      final body = <String, dynamic>{'raised': raised};
      if (userId != null) body['user_id'] = userId;
      final response = await http.post(
        Uri.parse('$_baseUrl/calls/$callId/raise-hand'),
        headers: headers,
        body: jsonEncode(body),
      );
      return response.statusCode == 200 || response.statusCode == 202;
    } catch (_) {
      return false;
    }
  }

  /// Missed-call voice message (Phase 4). POST /api/calls/{id}/missed-call-voice-message (multipart).
  Future<MissedCallVoiceResponse> postMissedCallVoiceMessage({
    required String callId,
    required List<int> voiceFileBytes,
    String? fileName,
    int? durationSeconds,
    String? authToken,
    int? userId,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/calls/$callId/missed-call-voice-message');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';
      if (authToken != null && authToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      request.files.add(http.MultipartFile.fromBytes(
        'voice',
        voiceFileBytes,
        filename: fileName ?? 'voice.webm',
      ));
      if (durationSeconds != null) {
        request.fields['duration_seconds'] = durationSeconds.toString();
      }
      if (userId != null) {
        request.fields['user_id'] = userId.toString();
      }
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
      if (response.statusCode == 201) {
        return MissedCallVoiceResponse(
          success: true,
          messageId: data['message_id'] is int ? data['message_id'] as int : null,
          conversationId: data['conversation_id'] is int ? data['conversation_id'] as int : null,
          attachmentUrl: data['attachment_url']?.toString(),
          durationSeconds: data['duration_seconds'] as int?,
        );
      }
      return MissedCallVoiceResponse(
        success: false,
        message: data['message']?.toString() ?? 'Failed to send voice message',
      );
    } catch (e) {
      return MissedCallVoiceResponse(success: false, message: 'Error: $e');
    }
  }

  /// Scheduled calls: create. POST /api/scheduled-calls.
  Future<ScheduledCallResponse> createScheduledCall({
    required DateTime scheduledAt,
    required String type,
    required List<int> inviteeIds,
    String? title,
    String? authToken,
    int? userId,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      final body = <String, dynamic>{
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        'type': type,
        'invitee_ids': inviteeIds,
      };
      if (title != null && title.isNotEmpty) body['title'] = title;
      if (userId != null) body['user_id'] = userId;
      final response = await http.post(
        Uri.parse('$_baseUrl/scheduled-calls'),
        headers: headers,
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
      if (response.statusCode == 201) {
        return ScheduledCallResponse(
          success: true,
          id: data['id']?.toString(),
          scheduledAt: data['scheduled_at'] != null ? DateTime.tryParse(data['scheduled_at'].toString()) : null,
          type: data['type']?.toString(),
          title: data['title']?.toString(),
          invitees: data['invitees'] is List ? List<Map<String, dynamic>>.from((data['invitees'] as List).map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})) : null,
        );
      }
      return ScheduledCallResponse(success: false, message: data['message']?.toString());
    } catch (e) {
      return ScheduledCallResponse(success: false, message: 'Error: $e');
    }
  }

  /// Scheduled calls: list. GET /api/scheduled-calls.
  Future<ScheduledCallListResponse> getScheduledCalls({
    int page = 1,
    int perPage = 20,
    String scope = 'upcoming',
    String? authToken,
    int? userId,
  }) async {
    try {
      var url = '$_baseUrl/scheduled-calls?page=$page&per_page=$perPage&scope=$scope';
      if (userId != null) url += '&user_id=$userId';
      final headers = <String, String>{'Accept': 'application/json'};
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      final response = await http.get(Uri.parse(url), headers: headers);
      final data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
      if (response.statusCode == 200 && data['data'] != null) {
        final list = (data['data'] as List)
            .map((e) => ScheduledCallItem.fromJson(e as Map<String, dynamic>))
            .toList();
        return ScheduledCallListResponse(success: true, data: list);
      }
      return ScheduledCallListResponse(success: false, message: data['message']?.toString());
    } catch (e) {
      return ScheduledCallListResponse(success: false, message: 'Error: $e');
    }
  }

  /// Scheduled calls: delete. DELETE /api/scheduled-calls/{id}.
  Future<bool> deleteScheduledCall(String id, {String? authToken, int? userId}) async {
    try {
      var url = '$_baseUrl/scheduled-calls/$id';
      if (userId != null) url += '?user_id=$userId';
      final headers = <String, String>{'Accept': 'application/json'};
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      final response = await http.delete(Uri.parse(url), headers: headers);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// Scheduled calls: start (create real call). POST /api/scheduled-calls/{id}/start.
  Future<CreateCallResponse> startScheduledCall(String scheduledCallId, {
    String? authToken,
    int? userId,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      final body = userId != null ? jsonEncode({'user_id': userId}) : null;
      final response = await http.post(
        Uri.parse('$_baseUrl/scheduled-calls/$scheduledCallId/start'),
        headers: headers,
        body: body,
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
      if (response.statusCode == 201) {
        final iceServers = _parseIceServers(data['ice_servers']);
        return CreateCallResponse(
          success: true,
          callId: data['call_id']?.toString(),
          status: data['status']?.toString(),
          type: data['type']?.toString(),
          iceServers: iceServers,
          createdAt: data['created_at'] != null ? DateTime.tryParse(data['created_at'].toString()) : null,
        );
      }
      return CreateCallResponse(success: false, message: data['message']?.toString());
    } catch (e) {
      return CreateCallResponse(success: false, message: 'Error: $e');
    }
  }

  static List<Map<String, dynamic>> _parseIceServers(dynamic raw) {
    if (raw == null) return [];
    if (raw is! List) return [];
    return raw
        .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

// ——— Response DTOs ———

class CreateCallResponse {
  final bool success;
  final String? callId;
  final String? status;
  final String? type;
  final List<Map<String, dynamic>> iceServers;
  final DateTime? createdAt;
  final String? message;

  CreateCallResponse({
    required this.success,
    this.callId,
    this.status,
    this.type,
    this.iceServers = const [],
    this.createdAt,
    this.message,
  });
}

class AcceptCallResponse {
  final bool success;
  final String? callId;
  final String? status;
  final DateTime? startedAt;
  final List<Map<String, dynamic>> iceServers;
  final String? message;

  AcceptCallResponse({
    required this.success,
    this.callId,
    this.status,
    this.startedAt,
    this.iceServers = const [],
    this.message,
  });
}

class RejectCallResponse {
  final bool success;
  final String? callId;
  final String? status;
  final String? message;

  RejectCallResponse({
    required this.success,
    this.callId,
    this.status,
    this.message,
  });
}

class EndCallResponse {
  final bool success;
  final String? callId;
  final String? status;
  final DateTime? endedAt;
  final int? durationSeconds;
  final String? message;

  EndCallResponse({
    required this.success,
    this.callId,
    this.status,
    this.endedAt,
    this.durationSeconds,
    this.message,
  });
}

class TurnCredentialsResponse {
  final bool success;
  final List<Map<String, dynamic>> iceServers;
  final int? ttlSeconds;
  final String? message;

  TurnCredentialsResponse({
    required this.success,
    this.iceServers = const [],
    this.ttlSeconds,
    this.message,
  });
}

class CallLogEntry {
  final String callId;
  final String type;
  final String status;
  final String direction;
  final Map<String, dynamic>? otherParty;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  final DateTime? createdAt;

  CallLogEntry({
    required this.callId,
    required this.type,
    required this.status,
    required this.direction,
    this.otherParty,
    this.startedAt,
    this.endedAt,
    this.durationSeconds,
    this.createdAt,
  });

  factory CallLogEntry.fromJson(Map<String, dynamic> json) {
    return CallLogEntry(
      callId: json['call_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'voice',
      status: json['status']?.toString() ?? '',
      direction: json['direction']?.toString() ?? 'outgoing',
      otherParty: json['other_party'] != null
          ? Map<String, dynamic>.from(json['other_party'] as Map)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'].toString())
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.tryParse(json['ended_at'].toString())
          : null,
      durationSeconds: json['duration_seconds'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class CallLogMeta {
  final int currentPage;
  final int perPage;
  final int total;

  CallLogMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
  });

  factory CallLogMeta.fromJson(Map<String, dynamic> json) {
    return CallLogMeta(
      currentPage: json['current_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
    );
  }
}

class CallLogListResponse {
  final bool success;
  final List<CallLogEntry> data;
  final CallLogMeta? meta;
  final String? message;

  CallLogListResponse({
    required this.success,
    this.data = const [],
    this.meta,
    this.message,
  });
}

class MissedCallVoiceResponse {
  final bool success;
  final int? messageId;
  final int? conversationId;
  final String? attachmentUrl;
  final int? durationSeconds;
  final String? message;

  MissedCallVoiceResponse({
    required this.success,
    this.messageId,
    this.conversationId,
    this.attachmentUrl,
    this.durationSeconds,
    this.message,
  });
}

class ScheduledCallResponse {
  final bool success;
  final String? id;
  final DateTime? scheduledAt;
  final String? type;
  final String? title;
  final List<Map<String, dynamic>>? invitees;
  final String? message;

  ScheduledCallResponse({
    required this.success,
    this.id,
    this.scheduledAt,
    this.type,
    this.title,
    this.invitees,
    this.message,
  });
}

class ScheduledCallItem {
  final String id;
  final DateTime? scheduledAt;
  final String type;
  final String? title;
  final Map<String, dynamic>? creator;
  final List<Map<String, dynamic>>? invitees;
  final bool isCreator;
  final String? startedCallId;

  ScheduledCallItem({
    required this.id,
    this.scheduledAt,
    required this.type,
    this.title,
    this.creator,
    this.invitees,
    this.isCreator = false,
    this.startedCallId,
  });

  factory ScheduledCallItem.fromJson(Map<String, dynamic> json) {
    return ScheduledCallItem(
      id: json['id']?.toString() ?? '',
      scheduledAt: json['scheduled_at'] != null ? DateTime.tryParse(json['scheduled_at'].toString()) : null,
      type: json['type']?.toString() ?? 'voice',
      title: json['title']?.toString(),
      creator: json['creator'] is Map ? Map<String, dynamic>.from(json['creator'] as Map) : null,
      invitees: json['invitees'] is List ? (json['invitees'] as List).map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList() : null,
      isCreator: json['is_creator'] == true,
      startedCallId: json['started_call_id']?.toString(),
    );
  }
}

class ScheduledCallListResponse {
  final bool success;
  final List<ScheduledCallItem> data;
  final String? message;

  ScheduledCallListResponse({
    required this.success,
    this.data = const [],
    this.message,
  });
}
