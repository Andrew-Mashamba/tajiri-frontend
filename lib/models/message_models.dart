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
  final int? disappearingTimer;
  /// Bridge type if this conversation is linked to an external platform (e.g. 'matrix', 'rcs', 'sms', 'email').
  final String? bridgeType;
  /// External ID on the bridged platform.
  final String? bridgeExternalId;

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
    this.disappearingTimer,
    this.bridgeType,
    this.bridgeExternalId,
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
      disappearingTimer: json['disappearing_timer'] as int?,
      bridgeType: json['bridge_type'] as String?,
      bridgeExternalId: json['bridge_external_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'group_id': groupId,
      'name': name,
      'avatar_path': avatarPath,
      'created_by': createdBy,
      'last_message_id': lastMessageId,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_message': lastMessage?.toJson(),
      'participants': participants.map((p) => p.toJson()).toList(),
      'display_name': displayName,
      'display_photo': displayPhoto,
      'unread_count': unreadCount,
      'is_muted': isMuted,
      'is_admin': isAdmin,
      'disappearing_timer': disappearingTimer,
      'bridge_type': bridgeType,
      'bridge_external_id': bridgeExternalId,
    };
  }

  bool get isPrivate => type == ConversationType.private;
  bool get isGroup => type == ConversationType.group;
  bool get hasUnread => unreadCount > 0;

  bool get isBridged => bridgeType != null && bridgeType!.isNotEmpty;

  bool get hasDisappearingMessages => disappearingTimer != null && disappearingTimer! > 0;
  String get disappearingLabel {
    if (disappearingTimer == null) return '';
    if (disappearingTimer! <= 86400) return '24h';
    if (disappearingTimer! <= 604800) return '7d';
    return '90d';
  }

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
  final MessageStatus status;
  final DateTime? deliveredAt;
  final bool isForwarded;
  final DateTime? editedAt;
  final bool isStarred;
  final String? linkPreviewUrl;
  final String? linkPreviewTitle;
  final String? linkPreviewDescription;
  final String? linkPreviewImage;
  final String? linkPreviewDomain;
  final DateTime? expiresAt;
  final int? pollId;
  final String? transcript;

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
    this.status = MessageStatus.sent,
    this.deliveredAt,
    this.isForwarded = false,
    this.editedAt,
    this.isStarred = false,
    this.linkPreviewUrl,
    this.linkPreviewTitle,
    this.linkPreviewDescription,
    this.linkPreviewImage,
    this.linkPreviewDomain,
    this.expiresAt,
    this.pollId,
    this.transcript,
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
      status: MessageStatus.fromString(json['status'] as String?),
      deliveredAt: json['delivered_at'] != null ? DateTime.tryParse(json['delivered_at'].toString()) : null,
      isForwarded: json['is_forwarded'] == true || json['is_forwarded'] == 1,
      editedAt: json['edited_at'] != null ? DateTime.tryParse(json['edited_at'].toString()) : null,
      isStarred: json['is_starred'] == true || json['is_starred'] == 1,
      linkPreviewUrl: json['link_preview_url'] as String?,
      linkPreviewTitle: json['link_preview_title'] as String?,
      linkPreviewDescription: json['link_preview_description'] as String?,
      linkPreviewImage: json['link_preview_image'] as String?,
      linkPreviewDomain: json['link_preview_domain'] as String?,
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'].toString()) : null,
      pollId: json['poll_id'] is int ? json['poll_id'] as int : (json['poll_id'] != null ? int.tryParse(json['poll_id'].toString()) : null),
      transcript: json['transcript']?.toString(),
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
      'status': status.name,
      'delivered_at': deliveredAt?.toIso8601String(),
      'is_forwarded': isForwarded,
      'edited_at': editedAt?.toIso8601String(),
      'is_starred': isStarred,
      'link_preview_url': linkPreviewUrl,
      'link_preview_title': linkPreviewTitle,
      'link_preview_description': linkPreviewDescription,
      'link_preview_image': linkPreviewImage,
      'link_preview_domain': linkPreviewDomain,
      'expires_at': expiresAt?.toIso8601String(),
      'poll_id': pollId,
      'transcript': transcript,
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
      'status': m.status.name,
      'delivered_at': m.deliveredAt?.toIso8601String(),
      'is_forwarded': m.isForwarded,
      'edited_at': m.editedAt?.toIso8601String(),
      'is_starred': m.isStarred,
      'link_preview_url': m.linkPreviewUrl,
      'link_preview_title': m.linkPreviewTitle,
      'link_preview_description': m.linkPreviewDescription,
      'link_preview_image': m.linkPreviewImage,
      'link_preview_domain': m.linkPreviewDomain,
      'expires_at': m.expiresAt?.toIso8601String(),
      'poll_id': m.pollId,
      'transcript': m.transcript,
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
    MessageStatus? status,
    DateTime? deliveredAt,
    bool? isForwarded,
    DateTime? editedAt,
    bool? isStarred,
    String? linkPreviewUrl,
    String? linkPreviewTitle,
    String? linkPreviewDescription,
    String? linkPreviewImage,
    String? linkPreviewDomain,
    DateTime? expiresAt,
    int? pollId,
    String? transcript,
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
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      isForwarded: isForwarded ?? this.isForwarded,
      editedAt: editedAt ?? this.editedAt,
      isStarred: isStarred ?? this.isStarred,
      linkPreviewUrl: linkPreviewUrl ?? this.linkPreviewUrl,
      linkPreviewTitle: linkPreviewTitle ?? this.linkPreviewTitle,
      linkPreviewDescription: linkPreviewDescription ?? this.linkPreviewDescription,
      linkPreviewImage: linkPreviewImage ?? this.linkPreviewImage,
      linkPreviewDomain: linkPreviewDomain ?? this.linkPreviewDomain,
      expiresAt: expiresAt ?? this.expiresAt,
      pollId: pollId ?? this.pollId,
      transcript: transcript ?? this.transcript,
    );
  }

  bool get hasMedia => mediaPath != null;

  String? get mediaUrl => mediaPath != null
      ? (mediaPath!.startsWith('http')
          ? mediaPath
          : '${ApiConfig.storageUrl}/$mediaPath')
      : null;

  bool get hasLinkPreview => linkPreviewUrl != null && linkPreviewUrl!.isNotEmpty;

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
      case MessageType.sharedPost:
        return 'Chapisho';
      case MessageType.poll:
        return 'Kura';
      case MessageType.livePhoto:
        return 'Live Photo';
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
  contact('contact'),
  sharedPost('shared_post'),
  poll('poll'),
  livePhoto('live_photo');

  final String value;
  const MessageType(this.value);

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageType.text,
    );
  }
}

enum MessageStatus {
  pending,
  sent,
  delivered,
  read,
  failed;

  factory MessageStatus.fromString(String? s) {
    switch (s) {
      case 'sent': return MessageStatus.sent;
      case 'delivered': return MessageStatus.delivered;
      case 'read': return MessageStatus.read;
      case 'failed': return MessageStatus.failed;
      default: return MessageStatus.pending;
    }
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
  final bool isPinned;
  final bool isArchived;
  final DateTime? mutedUntil;
  final bool isStarred;
  /// Custom member tag (e.g., 'Moderator', 'VIP') set by admins.
  final String? tag;
  /// Per-chat custom notification settings.
  final bool customTone;
  final bool customVibrate;
  final bool customPopup;

  ConversationParticipant({
    required this.id,
    required this.conversationId,
    required this.userId,
    this.isAdmin = false,
    this.lastReadAt,
    this.unreadCount = 0,
    this.isMuted = false,
    this.user,
    this.isPinned = false,
    this.isArchived = false,
    this.mutedUntil,
    this.isStarred = false,
    this.tag,
    this.customTone = false,
    this.customVibrate = false,
    this.customPopup = false,
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
        isPinned: pivot['is_pinned'] == true || pivot['is_pinned'] == 1,
        isArchived: pivot['is_archived'] == true || pivot['is_archived'] == 1,
        mutedUntil: pivot['muted_until'] != null
            ? DateTime.tryParse(pivot['muted_until'].toString())
            : null,
        isStarred: pivot['is_starred'] == true || pivot['is_starred'] == 1,
        tag: pivot['tag'] as String?,
        customTone: pivot['custom_tone'] == true || pivot['custom_tone'] == 1,
        customVibrate: pivot['custom_vibrate'] == true || pivot['custom_vibrate'] == 1,
        customPopup: pivot['custom_popup'] == true || pivot['custom_popup'] == 1,
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
      isPinned: json['is_pinned'] == true || json['is_pinned'] == 1,
      isArchived: json['is_archived'] == true || json['is_archived'] == 1,
      mutedUntil: json['muted_until'] != null
          ? DateTime.tryParse(json['muted_until'].toString())
          : null,
      isStarred: json['is_starred'] == true || json['is_starred'] == 1,
      tag: json['tag'] as String?,
      customTone: json['custom_tone'] == true || json['custom_tone'] == 1,
      customVibrate: json['custom_vibrate'] == true || json['custom_vibrate'] == 1,
      customPopup: json['custom_popup'] == true || json['custom_popup'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'user_id': userId,
      'is_admin': isAdmin,
      'last_read_at': lastReadAt?.toIso8601String(),
      'unread_count': unreadCount,
      'is_muted': isMuted,
      'user': user?.toJson(),
      'is_pinned': isPinned,
      'is_archived': isArchived,
      'muted_until': mutedUntil?.toIso8601String(),
      'is_starred': isStarred,
      'tag': tag,
      'custom_tone': customTone,
      'custom_vibrate': customVibrate,
      'custom_popup': customPopup,
    };
  }
}

class MessageReceipt {
  final int userId;
  final PostUser? user;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  const MessageReceipt({required this.userId, this.user, this.deliveredAt, this.readAt});

  factory MessageReceipt.fromJson(Map<String, dynamic> json) => MessageReceipt(
    userId: json['user_id'] as int? ?? 0,
    user: json['user'] != null ? PostUser.fromJson(json['user']) : null,
    deliveredAt: json['delivered_at'] != null ? DateTime.tryParse(json['delivered_at'].toString()) : null,
    readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null,
  );
}
