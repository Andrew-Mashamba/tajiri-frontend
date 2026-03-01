import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

String get _baseUrl => ApiConfig.baseUrl;

/// Result of starting or joining a group call.
class GroupCallJoinResult {
  final bool success;
  final String? message;
  final String? callId;
  final String? roomToken;
  final List<GroupCallParticipantState> participants;

  const GroupCallJoinResult({
    required this.success,
    this.message,
    this.callId,
    this.roomToken,
    this.participants = const [],
  });
}

/// Participant state in a group call (from backend or local).
class GroupCallParticipantState {
  final int userId;
  final String? displayName;
  final String? avatarUrl;
  final bool isMuted;
  final bool videoEnabled;
  final bool isLocal;

  const GroupCallParticipantState({
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.isMuted = false,
    this.videoEnabled = true,
    this.isLocal = false,
  });
}

/// Result of leaving a group call.
class GroupCallLeaveResult {
  final bool success;
  final String? message;

  const GroupCallLeaveResult({required this.success, this.message});
}

/// Service for group voice/video calls. Uses POST /api/calls/group (Story 60).
class GroupCallService {
  /// Start or join a group call for the given conversation.
  /// POST /api/calls/group
  Future<GroupCallJoinResult> startOrJoinGroupCall({
    required int conversationId,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/calls/group'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'conversation_id': conversationId,
          'user_id': userId,
        }),
      );

      final data = response.body.isNotEmpty
          ? (jsonDecode(response.body) as Map<String, dynamic>)
          : <String, dynamic>{};

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          final rawParticipants = data['participants'] as List<dynamic>? ?? [];
          final participants = rawParticipants
              .map((p) => _participantFromJson(p as Map<String, dynamic>, userId))
              .toList();
          return GroupCallJoinResult(
            success: true,
            callId: data['call_id']?.toString(),
            roomToken: data['room_token']?.toString(),
            participants: participants,
          );
        }
      }
      return GroupCallJoinResult(
        success: false,
        message: data['message']?.toString() ?? 'Failed to join group call',
      );
    } catch (e) {
      return GroupCallJoinResult(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  static GroupCallParticipantState _participantFromJson(
    Map<String, dynamic> json,
    int currentUserId,
  ) {
    final uid = json['user_id'] is int
        ? json['user_id'] as int
        : (json['user_id'] as num?)?.toInt() ?? 0;
    return GroupCallParticipantState(
      userId: uid,
      displayName: json['display_name']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      isMuted: json['is_muted'] == true,
      videoEnabled: json['video_enabled'] != false,
      isLocal: uid == currentUserId,
    );
  }

  /// Leave the group call. Backend may expect POST /api/calls/group/leave or DELETE.
  Future<GroupCallLeaveResult> leaveGroupCall({
    required String? callId,
    required int conversationId,
    required int userId,
  }) async {
    try {
      if (callId != null && callId.isNotEmpty) {
        final response = await http.post(
          Uri.parse('$_baseUrl/calls/group/leave'),
          headers: ApiConfig.headers,
          body: jsonEncode({
            'call_id': callId,
            'user_id': userId,
          }),
        );
        final data = response.body.isNotEmpty
            ? (jsonDecode(response.body) as Map<String, dynamic>)
            : <String, dynamic>{};
        if (response.statusCode == 200) {
          return GroupCallLeaveResult(
            success: data['success'] != false,
            message: data['message']?.toString(),
          );
        }
      }
      // No call_id: treat as success (client-only leave)
      return const GroupCallLeaveResult(success: true);
    } catch (e) {
      return GroupCallLeaveResult(success: false, message: 'Error: $e');
    }
  }

  /// Update mute state. Optional backend: PATCH /api/calls/group/state
  Future<bool> setMuted({
    required String? callId,
    required int userId,
    required bool muted,
  }) async {
    if (callId == null || callId.isEmpty) return true;
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/calls/group/state'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'call_id': callId,
          'user_id': userId,
          'muted': muted,
        }),
      );
      if (response.statusCode == 200) {
        final data = response.body.isNotEmpty
            ? (jsonDecode(response.body) as Map<String, dynamic>)
            : <String, dynamic>{};
        return data['success'] != false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Update video enabled state. Optional backend: PATCH /api/calls/group/state
  Future<bool> setVideoEnabled({
    required String? callId,
    required int userId,
    required bool videoEnabled,
  }) async {
    if (callId == null || callId.isEmpty) return true;
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/calls/group/state'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'call_id': callId,
          'user_id': userId,
          'video_enabled': videoEnabled,
        }),
      );
      if (response.statusCode == 200) {
        final data = response.body.isNotEmpty
            ? (jsonDecode(response.body) as Map<String, dynamic>)
            : <String, dynamic>{};
        return data['success'] != false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
