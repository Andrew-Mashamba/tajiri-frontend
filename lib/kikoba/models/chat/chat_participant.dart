/// Model representing a chat participant (member who can be chatted with)
class ChatParticipant {
  final String userId;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final String? role;
  final bool hasConversation;
  final String? conversationId;
  final int unreadCount;
  final DateTime? lastMessageAt;
  final bool isBlocked;
  final bool isOnline;

  ChatParticipant({
    required this.userId,
    required this.name,
    this.phone,
    this.avatarUrl,
    this.role,
    this.hasConversation = false,
    this.conversationId,
    this.unreadCount = 0,
    this.lastMessageAt,
    this.isBlocked = false,
    this.isOnline = false,
  });

  /// Create from JSON (API response)
  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      userId: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown',
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      role: json['role'] ?? json['role_code'],
      hasConversation: json['has_conversation'] ?? false,
      conversationId: json['conversation_id'],
      unreadCount: json['unread_count'] ?? 0,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'])
          : null,
      isBlocked: json['is_blocked'] ?? false,
      isOnline: json['is_online'] ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role,
      'has_conversation': hasConversation,
      'conversation_id': conversationId,
      'unread_count': unreadCount,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'is_blocked': isBlocked,
      'is_online': isOnline,
    };
  }

  /// Get initials from name
  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  /// Get display phone (formatted)
  String get displayPhone {
    if (phone == null || phone!.isEmpty) return '';
    // Format: 0XXX XXX XXX
    if (phone!.length >= 10) {
      return '${phone!.substring(0, 4)} ${phone!.substring(4, 7)} ${phone!.substring(7)}';
    }
    return phone!;
  }

  /// Create a copy with updated fields
  ChatParticipant copyWith({
    String? userId,
    String? name,
    String? phone,
    String? avatarUrl,
    String? role,
    bool? hasConversation,
    String? conversationId,
    int? unreadCount,
    DateTime? lastMessageAt,
    bool? isBlocked,
    bool? isOnline,
  }) {
    return ChatParticipant(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      hasConversation: hasConversation ?? this.hasConversation,
      conversationId: conversationId ?? this.conversationId,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isBlocked: isBlocked ?? this.isBlocked,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatParticipant && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
