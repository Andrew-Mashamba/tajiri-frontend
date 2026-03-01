/// Messaging models for conversations and messages

import '../config/api_config.dart';
import 'post_models.dart';

class Conversation {
  final int id;
  final ConversationType type;
  /// When type is group, links to the profile group (Vikundi). Backend: conversations.group_id FK groups.id.
  final int? groupId;
  final String? name;
  final String? avatarPath;
  final int createdBy;
  final int? lastMessageId;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Message? lastMessage;
  final List<ConversationParticipant> participants;
  final String? displayName;
  final String? displayPhoto;
  final int unreadCount;
  final bool isMuted;
  final bool isAdmin;

  Conversation({
    required this.id,
    required this.type,
    this.groupId,
    this.name,
    this.avatarPath,
    required this.createdBy,
    this.lastMessageId,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.participants = const [],
    this.displayName,
    this.displayPhoto,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isAdmin = false,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final createdBy = json['created_by'];
    final createdAt = json['created_at'];
    final updatedAt = json['updated_at'];
    return Conversation(
      id: id is int ? id : (id != null ? int.tryParse(id.toString()) : 0) ?? 0,
      type: ConversationType.fromString(json['type'] ?? 'private'),
      groupId: json['group_id'] is int ? json['group_id'] as int : (json['group_id'] != null ? int.tryParse(json['group_id'].toString()) : null),
      name: json['name']?.toString(),
      avatarPath: json['avatar_path']?.toString(),
      createdBy: createdBy is int ? createdBy : (createdBy != null ? int.tryParse(createdBy.toString()) : null) ?? 0,
      lastMessageId: json['last_message_id'] is int ? json['last_message_id'] as int : (json['last_message_id'] != null ? int.tryParse(json['last_message_id'].toString()) : null),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'].toString())
          : null,
      createdAt: createdAt != null ? (createdAt is DateTime ? createdAt : DateTime.tryParse(createdAt.toString())) ?? DateTime.now() : DateTime.now(),
      updatedAt: updatedAt != null ? (updatedAt is DateTime ? updatedAt : DateTime.tryParse(updatedAt.toString())) ?? DateTime.now() : DateTime.now(),
      lastMessage: json['last_message'] != null && json['last_message'] is Map
          ? Message.fromJson(Map<String, dynamic>.from(json['last_message']))
          : null,
      participants: json['participants'] != null && json['participants'] is List
          ? (json['participants'] as List)
              .where((p) => p is Map)
              .map((p) => ConversationParticipant.fromJson(Map<String, dynamic>.from(p as Map)))
              .toList()
          : [],
      displayName: json['display_name']?.toString(),
      displayPhoto: json['display_photo']?.toString(),
      unreadCount: json['unread_count'] is int ? json['unread_count'] as int : (int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0),
      isMuted: json['is_muted'] == true,
      isAdmin: json['is_admin'] == true,
    );
  }

  bool get isPrivate => type == ConversationType.private;
  bool get isGroup => type == ConversationType.group;
  bool get hasUnread => unreadCount > 0;

  String get title => displayName ?? name ?? 'Mazungumzo';

  String? get avatarUrl => photo;

  String? get photo {
    if (displayPhoto != null) {
      return displayPhoto!.startsWith('http')
          ? displayPhoto
          : '${ApiConfig.storageUrl}/$displayPhoto';
    }
    if (avatarPath != null) {
      return avatarPath!.startsWith('http')
          ? avatarPath
          : '${ApiConfig.storageUrl}/$avatarPath';
    }
    return null;
  }
}

enum ConversationType {
  private('private'),
  group('group');

  final String value;
  const ConversationType(this.value);

  static ConversationType fromString(String value) {
    return ConversationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ConversationType.private,
    );
  }
}

/// One emoji reaction on a message: emoji + list of user ids who used it.
class MessageReaction {
  final String emoji;
  final List<int> userIds;

  MessageReaction({required this.emoji, this.userIds = const []});

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    final list = json['user_ids'];
    return MessageReaction(
      emoji: json['emoji']?.toString() ?? '👍',
      userIds: list is List ? list.map((e) => (e as num).toInt()).toList() : [],
    );
  }

  Map<String, dynamic> toJson() => {'emoji': emoji, 'user_ids': userIds};

  MessageReaction copyWith({String? emoji, List<int>? userIds}) =>
      MessageReaction(emoji: emoji ?? this.emoji, userIds: userIds ?? this.userIds);
}

class Message {
  final int id;
  final int conversationId;
  final int senderId;
  final String? content;
  final MessageType messageType;
  final String? mediaPath;
  final String? mediaType;
  final int? replyToId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PostUser? sender;
  final Message? replyTo;
  /// Reactions (emoji -> who reacted). From API or local state.
  final List<MessageReaction> reactions;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    this.messageType = MessageType.text,
    this.mediaPath,
    this.mediaType,
    this.replyToId,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
    this.sender,
    this.replyTo,
    this.reactions = const [],
  });

  static int _intFrom(dynamic v) =>
      v is int ? v : (v != null ? int.tryParse(v.toString()) ?? 0 : 0);

  factory Message.fromJson(Map<String, dynamic> json) {
    List<MessageReaction> reactions = [];
    if (json['reactions'] is List) {
      for (final e in json['reactions'] as List) {
        if (e is Map<String, dynamic>) reactions.add(MessageReaction.fromJson(e));
      }
    }
    final createdAtRaw = json['created_at'];
    final updatedAtRaw = json['updated_at'];
    final createdAt = createdAtRaw != null
        ? (createdAtRaw is DateTime
            ? createdAtRaw
            : DateTime.tryParse(createdAtRaw.toString()))
        : null;
    final created = createdAt ?? DateTime.now();
    final updatedAt = updatedAtRaw != null
        ? (updatedAtRaw is DateTime
            ? updatedAtRaw
            : DateTime.tryParse(updatedAtRaw.toString()))
        : null;
    return Message(
      id: _intFrom(json['id']),
      conversationId: _intFrom(json['conversation_id']),
      senderId: _intFrom(json['sender_id']),
      content: json['content']?.toString(),
      messageType: MessageType.fromString(json['message_type'] ?? 'text'),
      mediaPath: json['media_path']?.toString(),
      mediaType: json['media_type']?.toString(),
      replyToId: json['reply_to_id'] is int ? json['reply_to_id'] as int : (json['reply_to_id'] != null ? int.tryParse(json['reply_to_id'].toString()) : null),
      isRead: json['is_read'] == true,
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null,
      createdAt: created,
      updatedAt: updatedAt ?? created,
      sender: json['sender'] != null && json['sender'] is Map
          ? PostUser.fromJson(Map<String, dynamic>.from(json['sender']))
          : null,
      replyTo: json['reply_to'] != null && json['reply_to'] is Map
          ? Message.fromJson(Map<String, dynamic>.from(json['reply_to']))
          : null,
      reactions: reactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType.value,
      'media_path': mediaPath,
      'media_type': mediaType,
      'reply_to_id': replyToId,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sender': sender != null
          ? {
              'id': sender!.id,
              'first_name': sender!.firstName,
              'last_name': sender!.lastName,
              'username': sender!.username,
              'profile_photo_path': sender!.profilePhotoPath,
            }
          : null,
      'reply_to': replyTo != null ? _messageToJsonShallow(replyTo!) : null,
      'reactions': reactions.map((r) => r.toJson()).toList(),
    };
  }

  static Map<String, dynamic> _messageToJsonShallow(Message m) {
    return {
      'id': m.id,
      'conversation_id': m.conversationId,
      'sender_id': m.senderId,
      'content': m.content,
      'message_type': m.messageType.value,
      'media_path': m.mediaPath,
      'media_type': m.mediaType,
      'reply_to_id': m.replyToId,
      'is_read': m.isRead,
      'read_at': m.readAt?.toIso8601String(),
      'created_at': m.createdAt.toIso8601String(),
      'updated_at': m.updatedAt.toIso8601String(),
      'sender': m.sender != null
          ? {
              'id': m.sender!.id,
              'first_name': m.sender!.firstName,
              'last_name': m.sender!.lastName,
              'username': m.sender!.username,
              'profile_photo_path': m.sender!.profilePhotoPath,
            }
          : null,
      'reply_to': null,
      'reactions': m.reactions.map((r) => r.toJson()).toList(),
    };
  }

  Message copyWith({
    int? id,
    int? conversationId,
    int? senderId,
    String? content,
    MessageType? messageType,
    String? mediaPath,
    String? mediaType,
    int? replyToId,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    PostUser? sender,
    Message? replyTo,
    List<MessageReaction>? reactions,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      mediaPath: mediaPath ?? this.mediaPath,
      mediaType: mediaType ?? this.mediaType,
      replyToId: replyToId ?? this.replyToId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sender: sender ?? this.sender,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
    );
  }

  bool get hasMedia => mediaPath != null;

  String? get mediaUrl => mediaPath != null
      ? (mediaPath!.startsWith('http')
          ? mediaPath
          : '${ApiConfig.storageUrl}/$mediaPath')
      : null;

  bool isFromUser(int userId) => senderId == userId;

  String get preview {
    switch (messageType) {
      case MessageType.text:
        return content ?? '';
      case MessageType.image:
        return 'Picha';
      case MessageType.video:
        return 'Video';
      case MessageType.audio:
        return 'Sauti';
      case MessageType.document:
        return 'Faili';
      case MessageType.location:
        return 'Mahali';
      case MessageType.contact:
        return 'Anwani';
    }
  }
}

enum MessageType {
  text('text'),
  image('image'),
  video('video'),
  audio('audio'),
  document('document'),
  location('location'),
  contact('contact');

  final String value;
  const MessageType(this.value);

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageType.text,
    );
  }
}

class ConversationParticipant {
  final int id;
  final int conversationId;
  final int userId;
  final bool isAdmin;
  final DateTime? lastReadAt;
  final int unreadCount;
  final bool isMuted;
  final PostUser? user;

  ConversationParticipant({
    required this.id,
    required this.conversationId,
    required this.userId,
    this.isAdmin = false,
    this.lastReadAt,
    this.unreadCount = 0,
    this.isMuted = false,
    this.user,
  });

  static int _intFrom(dynamic v) =>
      v is int ? v : (v != null ? int.tryParse(v.toString()) ?? 0 : 0);

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    // Laravel pivot format: participant is the user object with pivot: { conversation_id, user_id, ... }
    final pivot = json['pivot'] is Map ? Map<String, dynamic>.from(json['pivot'] as Map) : null;
    if (pivot != null) {
      final userId = _intFrom(pivot['user_id'] ?? json['id']);
      return ConversationParticipant(
        id: _intFrom(pivot['id'] ?? pivot['user_id'] ?? json['id']),
        conversationId: _intFrom(pivot['conversation_id']),
        userId: userId,
        isAdmin: pivot['is_admin'] == true,
        lastReadAt: pivot['last_read_at'] != null
            ? DateTime.tryParse(pivot['last_read_at'].toString())
            : null,
        unreadCount: _intFrom(pivot['unread_count']),
        isMuted: pivot['is_muted'] == true,
        user: PostUser.fromJson(json),
      );
    }
    // Standard format: { id, conversation_id, user_id, user: { ... } }
    return ConversationParticipant(
      id: _intFrom(json['id']),
      conversationId: _intFrom(json['conversation_id']),
      userId: _intFrom(json['user_id']),
      isAdmin: json['is_admin'] == true,
      lastReadAt: json['last_read_at'] != null
          ? DateTime.tryParse(json['last_read_at'].toString())
          : null,
      unreadCount: _intFrom(json['unread_count']),
      isMuted: json['is_muted'] == true,
      user: json['user'] != null && json['user'] is Map
          ? PostUser.fromJson(Map<String, dynamic>.from(json['user']))
          : null,
    );
  }
}
