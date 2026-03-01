import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/call_models.dart';
import '../config/api_config.dart';
import 'call_signaling_service.dart';

String get _baseUrl => ApiConfig.baseUrl;

class CallService {
  /// Initiate a new call. When [authToken] is set, uses new API (POST /api/calls) via CallSignalingService.
  Future<CallResult> initiateCall({
    required int userId,
    required int calleeId,
    String type = 'voice',
    String? authToken,
  }) async {
    if (authToken != null && authToken.isNotEmpty) {
      final signaling = CallSignalingService();
      final resp = await signaling.createCall(
        calleeId: calleeId,
        type: type,
        authToken: authToken,
        userId: userId,
      );
      if (resp.success && resp.callId != null) {
        final call = Call(
          id: 0,
          callId: resp.callId!,
          callerId: userId,
          calleeId: calleeId,
          type: resp.type ?? type,
          status: resp.status ?? 'pending',
        );
        return CallResult(success: true, call: call);
      }
      return CallResult(success: false, message: resp.message ?? 'Imeshindwa kuanzisha simu');
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/calls/initiate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'callee_id': calleeId,
          'type': type,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return CallResult(
          success: true,
          call: Call.fromJson(data['data']),
        );
      }
      return CallResult(success: false, message: data['message'] ?? 'Imeshindwa kuanzisha simu');
    } catch (e) {
      return CallResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Answer an incoming call. When [authToken] is set, uses new API (POST /api/calls/{id}/accept).
  Future<CallResult> answerCall({
    required int userId,
    required String callId,
    String? authToken,
  }) async {
    if (authToken != null && authToken.isNotEmpty) {
      final signaling = CallSignalingService();
      final resp = await signaling.acceptCall(
        callId: callId,
        authToken: authToken,
        userId: userId,
      );
      if (resp.success) {
        final call = Call(
          id: 0,
          callId: callId,
          callerId: 0,
          calleeId: userId,
          type: 'voice',
          status: resp.status ?? 'answered',
        );
        return CallResult(success: true, call: call);
      }
      return CallResult(success: false, message: resp.message ?? 'Imeshindwa kujibu simu');
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/calls/$callId/answer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return CallResult(
          success: true,
          call: Call.fromJson(data['data']),
        );
      }
      return CallResult(success: false, message: data['message'] ?? 'Imeshindwa kujibu simu');
    } catch (e) {
      return CallResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Decline an incoming call. When [authToken] is set, uses new API (POST /api/calls/{id}/reject).
  Future<CallResult> declineCall({
    required int userId,
    required String callId,
    String? authToken,
  }) async {
    if (authToken != null && authToken.isNotEmpty) {
      final signaling = CallSignalingService();
      final resp = await signaling.rejectCall(
        callId: callId,
        authToken: authToken,
        userId: userId,
      );
      if (resp.success) {
        final call = Call(
          id: 0,
          callId: callId,
          callerId: 0,
          calleeId: userId,
          type: 'voice',
          status: resp.status ?? 'rejected',
        );
        return CallResult(success: true, call: call);
      }
      return CallResult(success: false, message: resp.message ?? 'Imeshindwa kukataa simu');
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/calls/$callId/decline'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return CallResult(
          success: true,
          call: Call.fromJson(data['data']),
        );
      }
      return CallResult(success: false, message: data['message'] ?? 'Imeshindwa kukataa simu');
    } catch (e) {
      return CallResult(success: false, message: 'Kosa: $e');
    }
  }

  /// End a call. When [authToken] is set, uses new API (POST /api/calls/{id}/end).
  Future<CallResult> endCall({
    required int userId,
    required String callId,
    String? authToken,
  }) async {
    if (authToken != null && authToken.isNotEmpty) {
      final signaling = CallSignalingService();
      final resp = await signaling.endCall(
        callId: callId,
        authToken: authToken,
        userId: userId,
      );
      if (resp.success) {
        final call = Call(
          id: 0,
          callId: callId,
          callerId: 0,
          calleeId: userId,
          type: 'voice',
          status: resp.status ?? 'ended',
        );
        return CallResult(success: true, call: call);
      }
      return CallResult(success: false, message: resp.message ?? 'Imeshindwa kumaliza simu');
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/calls/$callId/end'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return CallResult(
          success: true,
          call: Call.fromJson(data['data']),
        );
      }
      return CallResult(success: false, message: data['message'] ?? 'Imeshindwa kumaliza simu');
    } catch (e) {
      return CallResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Get call status (legacy endpoint). Call history screen uses CallSignalingService.getCallLog when authToken is set.
  Future<CallResult> getCallStatus(String callId, int userId, {String? authToken}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/calls/$callId/status?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return CallResult(
            success: true,
            call: Call.fromJson(data['data']),
          );
        }
      }
      return CallResult(success: false, message: 'Simu haipatikani');
    } catch (e) {
      return CallResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Get call history
  Future<CallLogListResult> getCallHistory({
    required int userId,
    int page = 1,
    int perPage = 20,
    String? type, // voice, video
    String? direction, // incoming, outgoing
  }) async {
    try {
      String url = '$_baseUrl/calls/history?user_id=$userId&page=$page&per_page=$perPage';
      if (type != null) url += '&type=$type';
      if (direction != null) url += '&direction=$direction';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final logs = (data['data'] as List)
              .map((l) => CallLog.fromJson(l))
              .toList();
          return CallLogListResult(
            success: true,
            logs: logs,
            meta: data['meta'] != null ? CallPaginationMeta.fromJson(data['meta']) : null,
          );
        }
      }
      return CallLogListResult(success: false, message: 'Imeshindwa kupakia historia ya simu');
    } catch (e) {
      return CallLogListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ========== GROUP CALLS ==========

  /// Start a group call in a conversation
  Future<GroupCallResult> startGroupCall({
    required int userId,
    required int conversationId,
    String type = 'voice',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/calls/group/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'conversation_id': conversationId,
          'type': type,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return GroupCallResult(
          success: true,
          groupCall: GroupCall.fromJson(data['data']),
        );
      }
      return GroupCallResult(success: false, message: data['message'] ?? 'Imeshindwa kuanzisha simu ya kikundi');
    } catch (e) {
      return GroupCallResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Join a group call
  Future<GroupCallResult> joinGroupCall({
    required int userId,
    required String callId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/calls/group/$callId/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return GroupCallResult(
          success: true,
          groupCall: GroupCall.fromJson(data['data']),
        );
      }
      return GroupCallResult(success: false, message: data['message'] ?? 'Imeshindwa kujiunga na simu');
    } catch (e) {
      return GroupCallResult(success: false, message: 'Kosa: $e');
    }
  }

  /// Leave a group call
  Future<bool> leaveGroupCall({
    required int userId,
    required String callId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/calls/group/$callId/leave'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// End a group call (for initiator)
  Future<bool> endGroupCall({
    required int userId,
    required String callId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/calls/group/$callId/end'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Toggle mute in group call
  Future<bool> toggleMute({
    required int userId,
    required String callId,
    required bool muted,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/calls/group/$callId/toggle-mute'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'muted': muted,
        }),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Toggle video in group call
  Future<bool> toggleVideo({
    required int userId,
    required String callId,
    required bool videoOff,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/calls/group/$callId/toggle-video'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'video_off': videoOff,
        }),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get active call in a conversation
  Future<GroupCallResult?> getActiveCall(int conversationId, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/calls/group/active/$conversationId?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return GroupCallResult(
            success: true,
            groupCall: GroupCall.fromJson(data['data']),
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

// Result classes
class CallResult {
  final bool success;
  final Call? call;
  final String? message;

  CallResult({required this.success, this.call, this.message});
}

class CallLogListResult {
  final bool success;
  final List<CallLog> logs;
  final CallPaginationMeta? meta;
  final String? message;

  CallLogListResult({
    required this.success,
    this.logs = const [],
    this.meta,
    this.message,
  });
}

class GroupCallResult {
  final bool success;
  final GroupCall? groupCall;
  final String? message;

  GroupCallResult({required this.success, this.groupCall, this.message});
}

class CallPaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  CallPaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory CallPaginationMeta.fromJson(Map<String, dynamic> json) {
    return CallPaginationMeta(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      total: json['total'] ?? 0,
    );
  }
}
