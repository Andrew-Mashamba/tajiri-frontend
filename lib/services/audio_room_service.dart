import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'local_storage_service.dart';

class AudioRoom {
  final int id;
  final String title;
  final String? description;
  final int hostId;
  final int? conversationId;
  final String status; // active, ended
  final int participantCount;
  final int speakerCount;
  final int listenerCount;
  final DateTime createdAt;
  final DateTime? endedAt;
  final AudioRoomUser? host;
  final List<AudioRoomParticipant> participants;

  AudioRoom({
    required this.id,
    required this.title,
    this.description,
    required this.hostId,
    this.conversationId,
    required this.status,
    this.participantCount = 0,
    this.speakerCount = 0,
    this.listenerCount = 0,
    required this.createdAt,
    this.endedAt,
    this.host,
    this.participants = const [],
  });

  factory AudioRoom.fromJson(Map<String, dynamic> json) => AudioRoom(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        hostId: json['host_id'] as int? ?? 0,
        conversationId: json['conversation_id'] as int?,
        status: json['status'] as String? ?? 'active',
        participantCount: json['participant_count'] as int? ?? 0,
        speakerCount: json['speaker_count'] as int? ?? 0,
        listenerCount: json['listener_count'] as int? ?? 0,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        endedAt: json['ended_at'] != null
            ? DateTime.tryParse(json['ended_at'] as String)
            : null,
        host: json['host'] != null
            ? AudioRoomUser.fromJson(json['host'] as Map<String, dynamic>)
            : null,
        participants: (json['participants'] as List? ?? [])
            .map((p) =>
                AudioRoomParticipant.fromJson(p as Map<String, dynamic>))
            .toList(),
      );

  bool get isActive => status == 'active';
}

class AudioRoomUser {
  final int id;
  final String firstName;
  final String lastName;
  final String? profilePhotoPath;

  AudioRoomUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePhotoPath,
  });

  factory AudioRoomUser.fromJson(Map<String, dynamic> json) => AudioRoomUser(
        id: json['id'] as int,
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        profilePhotoPath: json['profile_photo_path'] as String?,
      );

  String get fullName => '$firstName $lastName';
  String get avatarUrl => profilePhotoPath != null
      ? '${ApiConfig.storageUrl}/$profilePhotoPath'
      : '';
}

class AudioRoomParticipant {
  final int userId;
  final String role; // host, speaker, listener
  final bool isMuted;
  final bool hasRaisedHand;
  final AudioRoomUser? user;

  AudioRoomParticipant({
    required this.userId,
    required this.role,
    this.isMuted = false,
    this.hasRaisedHand = false,
    this.user,
  });

  factory AudioRoomParticipant.fromJson(Map<String, dynamic> json) =>
      AudioRoomParticipant(
        userId: json['user_id'] as int? ?? 0,
        role: json['role'] as String? ?? 'listener',
        isMuted: json['is_muted'] == true,
        hasRaisedHand: json['has_raised_hand'] == true,
        user: json['user'] != null
            ? AudioRoomUser.fromJson(json['user'] as Map<String, dynamic>)
            : null,
      );

  bool get isHost => role == 'host';
  bool get isSpeaker => role == 'speaker' || role == 'host';
  bool get isListener => role == 'listener';
}

class AudioRoomService {
  static Future<String?> _getToken() async {
    final storage = await LocalStorageService.getInstance();
    return storage.getAuthToken();
  }

  /// Create a new audio room.
  static Future<AudioRoom?> createRoom({
    required String title,
    String? description,
    int? conversationId,
  }) async {
    final token = await _getToken();
    if (token == null) return null;
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/audio-rooms'),
        headers: {
          ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          if (description != null) 'description': description,
          if (conversationId != null) 'conversation_id': conversationId,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final roomData = data['data'] ?? data['room'] ?? data;
        if (roomData is Map<String, dynamic>) {
          return AudioRoom.fromJson(roomData);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// List active audio rooms (discovery feed).
  static Future<List<AudioRoom>> getActiveRooms({int page = 1}) async {
    final token = await _getToken();
    if (token == null) return [];
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/audio-rooms?page=$page&status=active'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] ?? data['rooms'] ?? []) as List;
        return list
            .map((r) => AudioRoom.fromJson(r as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Join a room as listener.
  static Future<AudioRoom?> joinRoom(int roomId) async {
    final token = await _getToken();
    if (token == null) return null;
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/audio-rooms/$roomId/join'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final roomData = data['data'] ?? data['room'] ?? data;
        if (roomData is Map<String, dynamic>) {
          return AudioRoom.fromJson(roomData);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Leave a room.
  static Future<bool> leaveRoom(int roomId) async {
    final token = await _getToken();
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/audio-rooms/$roomId/leave'),
        headers: ApiConfig.authHeaders(token),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// End a room (host only).
  static Future<bool> endRoom(int roomId) async {
    final token = await _getToken();
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/audio-rooms/$roomId/end'),
        headers: ApiConfig.authHeaders(token),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Raise/lower hand (listener requesting to speak).
  static Future<bool> toggleRaiseHand(int roomId, bool raised) async {
    final token = await _getToken();
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/audio-rooms/$roomId/raise-hand'),
        headers: {
          ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'raised': raised}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Promote listener to speaker (host only).
  static Future<bool> promoteSpeaker(int roomId, int userId) async {
    final token = await _getToken();
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/audio-rooms/$roomId/promote'),
        headers: {
          ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Demote speaker to listener (host only).
  static Future<bool> demoteSpeaker(int roomId, int userId) async {
    final token = await _getToken();
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/audio-rooms/$roomId/demote'),
        headers: {
          ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Toggle mute state.
  static Future<bool> toggleMute(int roomId, bool muted) async {
    final token = await _getToken();
    if (token == null) return false;
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/audio-rooms/$roomId/mute'),
        headers: {
          ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'muted': muted}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Get room details with participants.
  static Future<AudioRoom?> getRoom(int roomId) async {
    final token = await _getToken();
    if (token == null) return null;
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/audio-rooms/$roomId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final roomData = data['data'] ?? data['room'] ?? data;
        if (roomData is Map<String, dynamic>) {
          return AudioRoom.fromJson(roomData);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
