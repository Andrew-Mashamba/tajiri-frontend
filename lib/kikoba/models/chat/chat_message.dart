import 'message_type.dart';

/// Model representing a chat message
class ChatMessage {
  final String messageId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType messageType;
  final String? attachmentUrl;
  final String? attachmentName;
  final int? attachmentSize;
  final String? thumbnailUrl;
  final bool isRead;
  final bool isDeleted;
  final bool isEdited;
  final DateTime sentAt;
  final DateTime? readAt;
  final DateTime? editedAt;

  // Local state for optimistic updates
  final bool isSending;
  final bool isFailed;
  final String? localId;

  ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.messageType = MessageType.text,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentSize,
    this.thumbnailUrl,
    this.isRead = false,
    this.isDeleted = false,
    this.isEdited = false,
    required this.sentAt,
    this.readAt,
    this.editedAt,
    this.isSending = false,
    this.isFailed = false,
    this.localId,
  });

  /// Create from JSON (API response)
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['message_id'] ?? json['id'] ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderName: json['sender_name'] ?? '',
      content: json['content'] ?? '',
      messageType: MessageType.fromString(json['message_type']),
      attachmentUrl: json['attachment_url'],
      attachmentName: json['attachment_name'],
      attachmentSize: json['attachment_size'],
      thumbnailUrl: json['thumbnail_url'],
      isRead: json['is_read'] ?? false,
      isDeleted: json['is_deleted'] ?? false,
      isEdited: json['is_edited'] ?? false,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'])
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now()),
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at']) : null,
      editedAt: json['edited_at'] != null ? DateTime.tryParse(json['edited_at']) : null,
    );
  }

  /// Create from Firebase Realtime Database (handles dynamic types)
  factory ChatMessage.fromFirebase(Map<dynamic, dynamic> json) {
    return ChatMessage(
      messageId: json['message_id']?.toString() ?? json['id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      messageType: MessageType.fromString(json['message_type']?.toString()),
      attachmentUrl: json['attachment_url']?.toString(),
      attachmentName: json['attachment_name']?.toString(),
      attachmentSize: json['attachment_size'] is int ? json['attachment_size'] : null,
      thumbnailUrl: json['thumbnail_url']?.toString(),
      isRead: json['is_read'] == true,
      isDeleted: json['is_deleted'] == true,
      isEdited: json['is_edited'] == true,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'].toString())
          : DateTime.now(),
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'].toString())
          : null,
    );
  }

  /// Create a temporary message for optimistic updates
  factory ChatMessage.temporary({
    required String senderId,
    required String senderName,
    required String content,
    MessageType messageType = MessageType.text,
    String? attachmentUrl,
    String? attachmentName,
  }) {
    final localId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    return ChatMessage(
      messageId: localId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      messageType: messageType,
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
      sentAt: DateTime.now(),
      isSending: true,
      localId: localId,
    );
  }

  /// Create a system message
  factory ChatMessage.system({
    required String content,
  }) {
    return ChatMessage(
      messageId: 'system_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'system',
      senderName: 'System',
      content: content,
      messageType: MessageType.system,
      sentAt: DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'sender_id': senderId,
      'sender_name': senderName,
      'content': content,
      'message_type': messageType.value,
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
      'attachment_size': attachmentSize,
      'thumbnail_url': thumbnailUrl,
      'is_read': isRead,
      'is_deleted': isDeleted,
      'is_edited': isEdited,
      'sent_at': sentAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
    };
  }

  /// Check if message is from the given user
  bool isFromMe(String myUserId) => senderId == myUserId;

  /// Check if message has attachment
  bool get hasAttachment =>
      messageType.hasAttachment && attachmentUrl != null;

  /// Check if message is a system message
  bool get isSystemMessage => messageType == MessageType.system;

  /// Get display content (handles deleted messages)
  String get displayContent {
    if (isDeleted) return 'Ujumbe huu umefutwa';
    if (messageType == MessageType.image) return attachmentName ?? 'Picha';
    if (messageType == MessageType.file) return attachmentName ?? 'Faili';
    return content;
  }

  /// Get formatted file size
  String get formattedFileSize {
    if (attachmentSize == null) return '';
    final kb = attachmentSize! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Get time display string
  String get timeDisplay {
    return '${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}';
  }

  /// Create a copy with updated fields
  ChatMessage copyWith({
    String? messageId,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? messageType,
    String? attachmentUrl,
    String? attachmentName,
    int? attachmentSize,
    String? thumbnailUrl,
    bool? isRead,
    bool? isDeleted,
    bool? isEdited,
    DateTime? sentAt,
    DateTime? readAt,
    DateTime? editedAt,
    bool? isSending,
    bool? isFailed,
    String? localId,
  }) {
    return ChatMessage(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentSize: attachmentSize ?? this.attachmentSize,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      editedAt: editedAt ?? this.editedAt,
      isSending: isSending ?? this.isSending,
      isFailed: isFailed ?? this.isFailed,
      localId: localId ?? this.localId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.messageId == messageId;
  }

  @override
  int get hashCode => messageId.hashCode;
}
