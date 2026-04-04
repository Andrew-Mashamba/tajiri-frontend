import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/chat/chat_models.dart';
import '../kikoba_firebase.dart';

/// Service for Firebase Realtime Database chat operations
class FirebaseChatService {
  FirebaseDatabase get _database => KikobaFirebase.database;

  // Cache for active subscriptions
  final Map<String, StreamSubscription> _subscriptions = {};

  /// Stream of all messages for a conversation (real-time updates)
  Stream<List<ChatMessage>> getMessagesStream(String firebasePath) {
    final ref = _database.ref('$firebasePath/messages');

    return ref.orderByChild('sent_at').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <ChatMessage>[];

      final Map<dynamic, dynamic> messagesMap = data as Map<dynamic, dynamic>;
      final messages = messagesMap.entries.map((entry) {
        return ChatMessage.fromFirebase(entry.value as Map<dynamic, dynamic>);
      }).toList();

      // Sort by sent_at ascending
      messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      return messages;
    });
  }

  /// Stream for only new messages (child_added) - more efficient for real-time
  Stream<ChatMessage> getNewMessagesStream(String firebasePath) {
    final ref = _database.ref('$firebasePath/messages');

    return ref.orderByChild('sent_at').onChildAdded.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return ChatMessage.fromFirebase(data);
    });
  }

  /// Stream for message updates (edits, deletions, read status)
  Stream<ChatMessage> getMessageUpdatesStream(String firebasePath) {
    final ref = _database.ref('$firebasePath/messages');

    return ref.onChildChanged.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return ChatMessage.fromFirebase(data);
    });
  }

  /// Stream for deleted messages
  Stream<String> getDeletedMessagesStream(String firebasePath) {
    final ref = _database.ref('$firebasePath/messages');

    return ref.onChildRemoved.map((event) {
      return event.snapshot.key ?? '';
    });
  }

  /// Stream for last message (for conversation list updates)
  Stream<LastMessageInfo?> getLastMessageStream(String firebasePath) {
    final ref = _database.ref('$firebasePath/last_message');

    return ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return null;

      final Map<dynamic, dynamic> messageMap = data as Map<dynamic, dynamic>;
      return LastMessageInfo(
        content: messageMap['content']?.toString() ?? '',
        senderId: messageMap['sender_id']?.toString() ?? '',
        senderName: messageMap['sender_name']?.toString() ?? '',
        messageType: MessageType.fromString(messageMap['message_type']?.toString()),
        sentAt: messageMap['sent_at'] != null
            ? DateTime.parse(messageMap['sent_at'].toString())
            : DateTime.now(),
      );
    });
  }

  /// Stream for read status of a user
  Stream<ReadStatus?> getReadStatusStream(String firebasePath, String userId) {
    final ref = _database.ref('$firebasePath/read_status/$userId');

    return ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return null;

      final Map<dynamic, dynamic> statusMap = data as Map<dynamic, dynamic>;
      return ReadStatus(
        userId: userId,
        lastReadAt: statusMap['last_read_at'] != null
            ? DateTime.parse(statusMap['last_read_at'].toString())
            : null,
        lastReadMessageId: statusMap['last_read_message_id']?.toString(),
      );
    });
  }

  /// Stream for typing status of the other user
  Stream<bool> getTypingStream(String firebasePath, String otherUserId) {
    final ref = _database.ref('$firebasePath/typing/$otherUserId');

    return ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return false;

      if (data is Map) {
        final isTyping = data['is_typing'] == true;
        final timestamp = data['timestamp'];

        // Check if typing status is recent (within 10 seconds)
        if (isTyping && timestamp != null) {
          final typingTime = DateTime.parse(timestamp.toString());
          final diff = DateTime.now().difference(typingTime);
          return diff.inSeconds < 10;
        }
        return isTyping;
      }

      return data == true;
    });
  }

  /// Set typing status for current user
  Future<void> setTyping(String firebasePath, String userId, bool isTyping) async {
    try {
      final ref = _database.ref('$firebasePath/typing/$userId');

      if (isTyping) {
        await ref.set({
          'is_typing': true,
          'timestamp': DateTime.now().toIso8601String(),
        });

        // Auto-remove after 5 seconds
        Future.delayed(const Duration(seconds: 5), () async {
          try {
            await ref.remove();
          } catch (_) {}
        });
      } else {
        await ref.remove();
      }
    } catch (_) {
      // Silently fail - Firebase rules may not allow typing status
    }
  }

  /// Update read status
  Future<void> updateReadStatus(
    String firebasePath,
    String userId,
    String? lastMessageId,
  ) async {
    final ref = _database.ref('$firebasePath/read_status/$userId');
    await ref.set({
      'last_read_at': DateTime.now().toIso8601String(),
      'last_read_message_id': lastMessageId,
    });
  }

  /// Stream for online/presence status
  Stream<bool> getOnlineStream(String userId) {
    final ref = _database.ref('presence/$userId');

    return ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return false;

      if (data is Map) {
        return data['online'] == true;
      }
      return false;
    });
  }

  /// Set online status
  Future<void> setOnlineStatus(String userId, bool isOnline) async {
    final ref = _database.ref('presence/$userId');

    if (isOnline) {
      await ref.set({
        'online': true,
        'last_seen': DateTime.now().toIso8601String(),
      });

      // Set up disconnect handler
      ref.onDisconnect().set({
        'online': false,
        'last_seen': ServerValue.timestamp,
      });
    } else {
      await ref.set({
        'online': false,
        'last_seen': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Get unread count for a conversation
  Stream<int> getUnreadCountStream(String firebasePath, String userId) {
    final messagesRef = _database.ref('$firebasePath/messages');
    final readStatusRef = _database.ref('$firebasePath/read_status/$userId/last_read_at');

    return readStatusRef.onValue.asyncMap((readEvent) async {
      final lastReadAt = readEvent.snapshot.value != null
          ? DateTime.parse(readEvent.snapshot.value.toString())
          : DateTime.fromMillisecondsSinceEpoch(0);

      final messagesSnapshot = await messagesRef.get();
      if (!messagesSnapshot.exists) return 0;

      final messagesMap = messagesSnapshot.value as Map<dynamic, dynamic>?;
      if (messagesMap == null) return 0;

      int unread = 0;
      for (final entry in messagesMap.entries) {
        final message = entry.value as Map<dynamic, dynamic>;
        final senderId = message['sender_id']?.toString();
        final sentAt = message['sent_at'] != null
            ? DateTime.parse(message['sent_at'].toString())
            : DateTime.now();

        // Count messages from other user that are newer than last read
        if (senderId != userId && sentAt.isAfter(lastReadAt)) {
          unread++;
        }
      }
      return unread;
    });
  }

  /// Cancel a specific subscription
  void cancelSubscription(String key) {
    _subscriptions[key]?.cancel();
    _subscriptions.remove(key);
  }

  /// Cancel all subscriptions
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
}

/// Info about the last message in a conversation
class LastMessageInfo {
  final String content;
  final String senderId;
  final String senderName;
  final MessageType messageType;
  final DateTime sentAt;

  LastMessageInfo({
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.messageType,
    required this.sentAt,
  });

  String get displayContent {
    switch (messageType) {
      case MessageType.image:
        return 'Picha';
      case MessageType.file:
        return 'Faili';
      case MessageType.system:
        return content;
      default:
        return content;
    }
  }
}

/// Read status for a user
class ReadStatus {
  final String userId;
  final DateTime? lastReadAt;
  final String? lastReadMessageId;

  ReadStatus({
    required this.userId,
    this.lastReadAt,
    this.lastReadMessageId,
  });
}

/// Singleton instance for global access
class ChatFirebaseService {
  static final ChatFirebaseService _instance = ChatFirebaseService._internal();
  factory ChatFirebaseService() => _instance;
  ChatFirebaseService._internal();

  final FirebaseChatService _service = FirebaseChatService();

  FirebaseChatService get service => _service;

  void dispose() => _service.dispose();
}
