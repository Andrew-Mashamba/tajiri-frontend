import 'chat_participant.dart';
import 'message_type.dart';

/// Model representing a chat conversation
class Conversation {
  final String conversationId;
  final String firebasePath;
  final ChatParticipant otherParticipant;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSender;
  final MessageType? lastMessageType;
  final int unreadCount;
  final bool isMuted;
  final bool isArchived;
  final bool isBlocked;
  final DateTime createdAt;
  final DateTime? mutedAt;
  final DateTime? archivedAt;

  Conversation({
    required this.conversationId,
    required this.firebasePath,
    required this.otherParticipant,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSender,
    this.lastMessageType,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isArchived = false,
    this.isBlocked = false,
    DateTime? createdAt,
    this.mutedAt,
    this.archivedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from JSON (API response)
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      conversationId: json['conversation_id'] ?? json['id'] ?? '',
      firebasePath: json['firebase_path'] ?? '',
      otherParticipant: json['other_participant'] != null
          ? ChatParticipant.fromJson(json['other_participant'])
          : ChatParticipant(userId: '', name: 'Unknown'),
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'])
          : null,
      lastMessageSender: json['last_message_sender'],
      lastMessageType: json['last_message_type'] != null
          ? MessageType.fromString(json['last_message_type'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      isMuted: json['is_muted'] ?? false,
      isArchived: json['is_archived'] ?? false,
      isBlocked: json['is_blocked'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      mutedAt: json['muted_at'] != null
          ? DateTime.tryParse(json['muted_at'])
          : null,
      archivedAt: json['archived_at'] != null
          ? DateTime.tryParse(json['archived_at'])
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'firebase_path': firebasePath,
      'other_participant': otherParticipant.toJson(),
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'last_message_sender': lastMessageSender,
      'last_message_type': lastMessageType?.value,
      'unread_count': unreadCount,
      'is_muted': isMuted,
      'is_archived': isArchived,
      'is_blocked': isBlocked,
      'created_at': createdAt.toIso8601String(),
      'muted_at': mutedAt?.toIso8601String(),
      'archived_at': archivedAt?.toIso8601String(),
    };
  }

  /// Check if has unread messages
  bool get hasUnread => unreadCount > 0;

  /// Check if last message is from me
  bool isFromMe(String myUserId) => lastMessageSender == myUserId;

  /// Get display last message (handles different types)
  String get displayLastMessage {
    if (lastMessage == null || lastMessage!.isEmpty) {
      return 'Hakuna ujumbe';
    }

    switch (lastMessageType) {
      case MessageType.image:
        return 'Picha';
      case MessageType.file:
        return 'Faili';
      case MessageType.system:
        return lastMessage!;
      default:
        return lastMessage!;
    }
  }

  /// Get relative time display for last message
  String getTimeDisplay() {
    if (lastMessageAt == null) return '';

    final now = DateTime.now();
    final diff = now.difference(lastMessageAt!);

    if (diff.inDays == 0) {
      // Today - show time
      return '${lastMessageAt!.hour.toString().padLeft(2, '0')}:${lastMessageAt!.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Jana';
    } else if (diff.inDays < 7) {
      // This week - show day name
      const days = ['Jumatatu', 'Jumanne', 'Jumatano', 'Alhamisi', 'Ijumaa', 'Jumamosi', 'Jumapili'];
      return days[lastMessageAt!.weekday - 1];
    } else {
      // Older - show date
      return '${lastMessageAt!.day}/${lastMessageAt!.month}';
    }
  }

  /// Create a copy with updated fields
  Conversation copyWith({
    String? conversationId,
    String? firebasePath,
    ChatParticipant? otherParticipant,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastMessageSender,
    MessageType? lastMessageType,
    int? unreadCount,
    bool? isMuted,
    bool? isArchived,
    bool? isBlocked,
    DateTime? createdAt,
    DateTime? mutedAt,
    DateTime? archivedAt,
  }) {
    return Conversation(
      conversationId: conversationId ?? this.conversationId,
      firebasePath: firebasePath ?? this.firebasePath,
      otherParticipant: otherParticipant ?? this.otherParticipant,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      isArchived: isArchived ?? this.isArchived,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
      mutedAt: mutedAt ?? this.mutedAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Conversation && other.conversationId == conversationId;
  }

  @override
  int get hashCode => conversationId.hashCode;
}

/// Response wrapper for conversations list
class ConversationsResponse {
  final List<Conversation> conversations;
  final int totalUnread;

  ConversationsResponse({
    required this.conversations,
    required this.totalUnread,
  });

  factory ConversationsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> conversationsList = json['conversations'] ?? [];
    return ConversationsResponse(
      conversations: conversationsList
          .map((c) => Conversation.fromJson(c as Map<String, dynamic>))
          .toList(),
      totalUnread: json['total_unread'] ?? 0,
    );
  }
}

/// Model for blocked user
class BlockedUser {
  final String userId;
  final String name;
  final String? phone;
  final DateTime blockedAt;
  final String? reason;

  BlockedUser({
    required this.userId,
    required this.name,
    this.phone,
    required this.blockedAt,
    this.reason,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      userId: json['user_id']?.toString() ?? json['blocked_id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown',
      phone: json['phone'],
      blockedAt: json['blocked_at'] != null
          ? DateTime.parse(json['blocked_at'])
          : DateTime.now(),
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'phone': phone,
      'blocked_at': blockedAt.toIso8601String(),
      'reason': reason,
    };
  }
}
