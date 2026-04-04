import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import '../models/chat/chat_models.dart';

/// Service for offline caching of chat data using Hive
class OfflineChatService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  // Box names
  static const String _conversationsBox = 'chat_conversations';
  static const String _messagesBox = 'chat_messages';
  static const String _pendingMessagesBox = 'pending_messages';
  static const String _draftMessagesBox = 'draft_messages';

  static bool _isInitialized = false;

  /// Initialize Hive for offline storage
  static Future<void> initialize() async {
    if (_isInitialized) return;

    _logger.i('Initializing OfflineChatService...');

    try {
      await Hive.initFlutter();

      // Open boxes
      await Hive.openBox<String>(_conversationsBox);
      await Hive.openBox<String>(_messagesBox);
      await Hive.openBox<String>(_pendingMessagesBox);
      await Hive.openBox<String>(_draftMessagesBox);

      _isInitialized = true;
      _logger.i('OfflineChatService initialized');
    } catch (e) {
      _logger.e('Failed to initialize OfflineChatService: $e');
    }
  }

  // ==================== Conversations ====================

  /// Cache conversations list
  static Future<void> cacheConversations(
    String userId,
    List<Conversation> conversations,
  ) async {
    await initialize();
    final box = Hive.box<String>(_conversationsBox);

    final conversationsJson = conversations.map((c) => c.toJson()).toList();
    await box.put(userId, jsonEncode(conversationsJson));

    _logger.d('Cached ${conversations.length} conversations for user $userId');
  }

  /// Get cached conversations
  static Future<List<Conversation>> getCachedConversations(String userId) async {
    await initialize();
    final box = Hive.box<String>(_conversationsBox);

    final cached = box.get(userId);
    if (cached == null) return [];

    try {
      final List<dynamic> conversationsJson = jsonDecode(cached);
      return conversationsJson
          .map((c) => Conversation.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Failed to parse cached conversations: $e');
      return [];
    }
  }

  // ==================== Messages ====================

  /// Cache messages for a conversation
  static Future<void> cacheMessages(
    String conversationId,
    List<ChatMessage> messages,
  ) async {
    await initialize();
    final box = Hive.box<String>(_messagesBox);

    final messagesJson = messages.map((m) => m.toJson()).toList();
    await box.put(conversationId, jsonEncode(messagesJson));

    _logger.d('Cached ${messages.length} messages for conversation $conversationId');
  }

  /// Get cached messages for a conversation
  static Future<List<ChatMessage>> getCachedMessages(String conversationId) async {
    await initialize();
    final box = Hive.box<String>(_messagesBox);

    final cached = box.get(conversationId);
    if (cached == null) return [];

    try {
      final List<dynamic> messagesJson = jsonDecode(cached);
      return messagesJson
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Failed to parse cached messages: $e');
      return [];
    }
  }

  /// Add a single message to cache
  static Future<void> addMessageToCache(
    String conversationId,
    ChatMessage message,
  ) async {
    final messages = await getCachedMessages(conversationId);
    messages.add(message);
    await cacheMessages(conversationId, messages);
  }

  /// Update a message in cache
  static Future<void> updateMessageInCache(
    String conversationId,
    ChatMessage updatedMessage,
  ) async {
    final messages = await getCachedMessages(conversationId);
    final index = messages.indexWhere((m) => m.messageId == updatedMessage.messageId);
    if (index != -1) {
      messages[index] = updatedMessage;
      await cacheMessages(conversationId, messages);
    }
  }

  /// Remove a message from cache
  static Future<void> removeMessageFromCache(
    String conversationId,
    String messageId,
  ) async {
    final messages = await getCachedMessages(conversationId);
    messages.removeWhere((m) => m.messageId == messageId);
    await cacheMessages(conversationId, messages);
  }

  // ==================== Pending Messages (Offline Queue) ====================

  /// Add a message to the pending queue for later sending
  static Future<void> addPendingMessage(
    String conversationId,
    ChatMessage message,
  ) async {
    await initialize();
    final box = Hive.box<String>(_pendingMessagesBox);

    final pendingList = await getPendingMessages();
    pendingList.add({
      'conversation_id': conversationId,
      'message': message.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    });

    await box.put('pending', jsonEncode(pendingList));
    _logger.d('Added message to pending queue');
  }

  /// Get all pending messages
  static Future<List<Map<String, dynamic>>> getPendingMessages() async {
    await initialize();
    final box = Hive.box<String>(_pendingMessagesBox);

    final cached = box.get('pending');
    if (cached == null) return [];

    try {
      return List<Map<String, dynamic>>.from(jsonDecode(cached));
    } catch (e) {
      _logger.e('Failed to parse pending messages: $e');
      return [];
    }
  }

  /// Remove a message from pending queue
  static Future<void> removePendingMessage(String localId) async {
    await initialize();
    final box = Hive.box<String>(_pendingMessagesBox);

    final pendingList = await getPendingMessages();
    pendingList.removeWhere((p) {
      final message = p['message'] as Map<String, dynamic>?;
      return message?['message_id'] == localId || message?['local_id'] == localId;
    });

    await box.put('pending', jsonEncode(pendingList));
  }

  /// Clear all pending messages
  static Future<void> clearPendingMessages() async {
    await initialize();
    final box = Hive.box<String>(_pendingMessagesBox);
    await box.delete('pending');
  }

  // ==================== Draft Messages ====================

  /// Save a draft message for a conversation
  static Future<void> saveDraft(String conversationId, String content) async {
    await initialize();
    final box = Hive.box<String>(_draftMessagesBox);

    if (content.isEmpty) {
      await box.delete(conversationId);
    } else {
      await box.put(conversationId, content);
    }
  }

  /// Get draft message for a conversation
  static Future<String?> getDraft(String conversationId) async {
    await initialize();
    final box = Hive.box<String>(_draftMessagesBox);
    return box.get(conversationId);
  }

  /// Clear draft for a conversation
  static Future<void> clearDraft(String conversationId) async {
    await initialize();
    final box = Hive.box<String>(_draftMessagesBox);
    await box.delete(conversationId);
  }

  // ==================== Utility Methods ====================

  /// Clear all cached data
  static Future<void> clearAllCache() async {
    await initialize();

    await Hive.box<String>(_conversationsBox).clear();
    await Hive.box<String>(_messagesBox).clear();
    await Hive.box<String>(_pendingMessagesBox).clear();
    await Hive.box<String>(_draftMessagesBox).clear();

    _logger.i('All chat cache cleared');
  }

  /// Clear cache for a specific user
  static Future<void> clearUserCache(String userId) async {
    await initialize();

    final conversationsBox = Hive.box<String>(_conversationsBox);
    await conversationsBox.delete(userId);

    _logger.i('Chat cache cleared for user $userId');
  }

  /// Get cache size (approximate)
  static Future<int> getCacheSize() async {
    await initialize();

    int size = 0;

    for (final boxName in [_conversationsBox, _messagesBox, _pendingMessagesBox, _draftMessagesBox]) {
      final box = Hive.box<String>(boxName);
      for (final key in box.keys) {
        final value = box.get(key);
        if (value != null) {
          size += value.length;
        }
      }
    }

    return size;
  }

  /// Close all boxes
  static Future<void> dispose() async {
    if (!_isInitialized) return;

    await Hive.close();
    _isInitialized = false;
    _logger.i('OfflineChatService disposed');
  }
}
