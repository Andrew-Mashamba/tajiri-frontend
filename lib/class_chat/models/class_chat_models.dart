// lib/class_chat/models/class_chat_models.dart

// ─── Channel Type ────────────────────────────────────────────

enum ChannelType {
  general,
  announcements,
  subject,
  qa;

  String get displayName {
    switch (this) {
      case ChannelType.general:
        return 'Jumla';
      case ChannelType.announcements:
        return 'Matangazo';
      case ChannelType.subject:
        return 'Somo';
      case ChannelType.qa:
        return 'Maswali';
    }
  }

  String get subtitle {
    switch (this) {
      case ChannelType.general:
        return 'General';
      case ChannelType.announcements:
        return 'Announcements';
      case ChannelType.subject:
        return 'Subject';
      case ChannelType.qa:
        return 'Q&A';
    }
  }

  static ChannelType fromString(String? s) {
    return ChannelType.values.firstWhere(
      (v) => v.name == s,
      orElse: () => ChannelType.general,
    );
  }
}

// ─── ClassChannel ────────────────────────────────────────────

class ClassChannel {
  final int id;
  final int classId;
  final String name;
  final String? description;
  final ChannelType type;
  final int conversationId;
  final int unreadCount;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  ClassChannel({
    required this.id,
    required this.classId,
    required this.name,
    this.description,
    required this.type,
    required this.conversationId,
    this.unreadCount = 0,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory ClassChannel.fromJson(Map<String, dynamic> json) {
    return ClassChannel(
      id: _parseInt(json['id']),
      classId: _parseInt(json['class_id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      type: ChannelType.fromString(json['type']?.toString()),
      conversationId: _parseInt(json['conversation_id']),
      unreadCount: _parseInt(json['unread_count']),
      lastMessage: json['last_message']?.toString(),
      lastMessageAt:
          DateTime.tryParse(json['last_message_at']?.toString() ?? ''),
    );
  }
}

// ─── ClassChatMessage ────────────────────────────────────────

class ClassChatMessage {
  final int id;
  final int channelId;
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final String body;
  final String? attachmentUrl;
  final String? attachmentType;
  final bool isPinned;
  final bool isQuestion;
  final bool isAnswered;
  final int? replyToId;
  final DateTime createdAt;

  ClassChatMessage({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.body,
    this.attachmentUrl,
    this.attachmentType,
    this.isPinned = false,
    this.isQuestion = false,
    this.isAnswered = false,
    this.replyToId,
    required this.createdAt,
  });

  factory ClassChatMessage.fromJson(Map<String, dynamic> json) {
    return ClassChatMessage(
      id: _parseInt(json['id']),
      channelId: _parseInt(json['channel_id']),
      senderId: _parseInt(json['sender_id']),
      senderName: json['sender_name']?.toString() ?? '',
      senderAvatar: json['sender_avatar']?.toString(),
      body: json['body']?.toString() ?? '',
      attachmentUrl: json['attachment_url']?.toString(),
      attachmentType: json['attachment_type']?.toString(),
      isPinned: _parseBool(json['is_pinned']),
      isQuestion: _parseBool(json['is_question']),
      isAnswered: _parseBool(json['is_answered']),
      replyToId:
          json['reply_to_id'] != null ? _parseInt(json['reply_to_id']) : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// ─── ChatPoll ────────────────────────────────────────────────

class ChatPoll {
  final int id;
  final int channelId;
  final String question;
  final List<PollOption> options;
  final int totalVotes;
  final bool hasVoted;
  final DateTime createdAt;
  final DateTime? expiresAt;

  ChatPoll({
    required this.id,
    required this.channelId,
    required this.question,
    required this.options,
    this.totalVotes = 0,
    this.hasVoted = false,
    required this.createdAt,
    this.expiresAt,
  });

  factory ChatPoll.fromJson(Map<String, dynamic> json) {
    return ChatPoll(
      id: _parseInt(json['id']),
      channelId: _parseInt(json['channel_id']),
      question: json['question']?.toString() ?? '',
      options: (json['options'] as List?)
              ?.map((o) => PollOption.fromJson(o))
              .toList() ??
          [],
      totalVotes: _parseInt(json['total_votes']),
      hasVoted: _parseBool(json['has_voted']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
    );
  }
}

class PollOption {
  final int id;
  final String text;
  final int votes;

  PollOption({required this.id, required this.text, this.votes = 0});

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: _parseInt(json['id']),
      text: json['text']?.toString() ?? '',
      votes: _parseInt(json['votes']),
    );
  }
}

// ─── Result wrappers ─────────────────────────────────────────

class ChatResult<T> {
  final bool success;
  final T? data;
  final String? message;

  ChatResult({required this.success, this.data, this.message});
}

class ChatListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  ChatListResult({required this.success, this.items = const [], this.message});
}

// ─── Parse helpers ───────────────────────────────────────────

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}
