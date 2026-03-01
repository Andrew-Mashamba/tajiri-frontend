import '../config/api_config.dart';

class Call {
  final int id;
  final String callId;
  final int callerId;
  final int calleeId;
  final String type; // voice, video
  final String status; // pending, ringing, answered, ended, missed, declined
  final DateTime? startedAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;
  final int? duration;
  final String? endReason;
  final CallUser? caller;
  final CallUser? callee;

  Call({
    required this.id,
    required this.callId,
    required this.callerId,
    required this.calleeId,
    required this.type,
    required this.status,
    this.startedAt,
    this.answeredAt,
    this.endedAt,
    this.duration,
    this.endReason,
    this.caller,
    this.callee,
  });

  factory Call.fromJson(Map<String, dynamic> json) {
    return Call(
      id: json['id'],
      callId: json['call_id'] ?? '',
      callerId: json['caller_id'],
      calleeId: json['callee_id'],
      type: json['type'] ?? 'voice',
      status: json['status'] ?? 'pending',
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      answeredAt: json['answered_at'] != null ? DateTime.parse(json['answered_at']) : null,
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      duration: json['duration'],
      endReason: json['end_reason'],
      caller: json['caller'] != null ? CallUser.fromJson(json['caller']) : null,
      callee: json['callee'] != null ? CallUser.fromJson(json['callee']) : null,
    );
  }

  bool get isVoice => type == 'voice';
  bool get isVideo => type == 'video';
  bool get isActive => ['pending', 'ringing', 'answered'].contains(status);

  String get durationFormatted {
    if (duration == null) return '0:00';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class CallUser {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? profilePhotoPath;

  CallUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    this.profilePhotoPath,
  });

  factory CallUser.fromJson(Map<String, dynamic> json) {
    return CallUser(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'],
      profilePhotoPath: json['profile_photo_path'],
    );
  }

  String get fullName => '$firstName $lastName';
  String get displayName => username ?? fullName;
  String get avatarUrl => profilePhotoPath != null
      ? '${ApiConfig.storageUrl}/$profilePhotoPath'
      : '';
}

class CallLog {
  final int id;
  final int userId;
  final int? otherUserId;
  final String type;
  final String direction; // incoming, outgoing
  final String status; // answered, missed, declined
  final int? duration;
  final DateTime callTime;
  final CallUser? otherUser;
  /// When from new API (getCallLog), backend call_id for missed-call voice message.
  final String? callId;

  CallLog({
    required this.id,
    required this.userId,
    this.otherUserId,
    required this.type,
    required this.direction,
    required this.status,
    this.duration,
    required this.callTime,
    this.otherUser,
    this.callId,
  });

  factory CallLog.fromJson(Map<String, dynamic> json) {
    return CallLog(
      id: json['id'],
      userId: json['user_id'],
      otherUserId: json['other_user_id'],
      type: json['type'] ?? 'voice',
      direction: json['direction'] ?? 'outgoing',
      status: json['status'] ?? 'missed',
      duration: json['duration'],
      callTime: DateTime.parse(json['call_time']),
      otherUser: json['other_user'] != null ? CallUser.fromJson(json['other_user']) : null,
      callId: json['call_id']?.toString(),
    );
  }

  bool get isIncoming => direction == 'incoming';
  bool get isOutgoing => direction == 'outgoing';
  bool get wasMissed => status == 'missed';
  bool get wasDeclined => status == 'declined';
  bool get wasAnswered => status == 'answered';

  String get durationFormatted {
    if (duration == null) return '';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class GroupCall {
  final int id;
  final String callId;
  final int conversationId;
  final int initiatedBy;
  final String type;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int maxParticipants;
  final List<GroupCallParticipant>? participants;

  GroupCall({
    required this.id,
    required this.callId,
    required this.conversationId,
    required this.initiatedBy,
    required this.type,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.maxParticipants = 0,
    this.participants,
  });

  factory GroupCall.fromJson(Map<String, dynamic> json) {
    return GroupCall(
      id: json['id'],
      callId: json['call_id'] ?? '',
      conversationId: json['conversation_id'],
      initiatedBy: json['initiated_by'],
      type: json['type'] ?? 'voice',
      status: json['status'] ?? 'active',
      startedAt: DateTime.parse(json['started_at']),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      maxParticipants: json['max_participants'] ?? 0,
      participants: json['participants'] != null
          ? (json['participants'] as List).map((p) => GroupCallParticipant.fromJson(p)).toList()
          : null,
    );
  }

  bool get isActive => status == 'active';
}

class GroupCallParticipant {
  final int id;
  final int groupCallId;
  final int userId;
  final String status;
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final bool isMuted;
  final bool isVideoOff;
  final CallUser? user;

  GroupCallParticipant({
    required this.id,
    required this.groupCallId,
    required this.userId,
    required this.status,
    this.joinedAt,
    this.leftAt,
    this.isMuted = false,
    this.isVideoOff = false,
    this.user,
  });

  factory GroupCallParticipant.fromJson(Map<String, dynamic> json) {
    return GroupCallParticipant(
      id: json['id'],
      groupCallId: json['group_call_id'],
      userId: json['user_id'],
      status: json['status'] ?? 'invited',
      joinedAt: json['joined_at'] != null ? DateTime.parse(json['joined_at']) : null,
      leftAt: json['left_at'] != null ? DateTime.parse(json['left_at']) : null,
      isMuted: json['is_muted'] ?? false,
      isVideoOff: json['is_video_off'] ?? false,
      user: json['user'] != null ? CallUser.fromJson(json['user']) : null,
    );
  }
}
