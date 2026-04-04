import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/message_models.dart';
import 'message_database.dart';
import 'local_storage_service.dart';

/// Delta-sync service for messages.
///
/// Singleton that fetches only new/edited/deleted messages since the last
/// sync checkpoint, applies them to the local [MessageDatabase], and returns
/// the changes for immediate UI update. Network failures are non-fatal — the
/// caller still sees whatever is cached locally.
class MessageSyncService {
  static final MessageSyncService instance = MessageSyncService._();
  MessageSyncService._();

  bool _isSyncing = false;

  // ApiConfig.baseUrl already ends with '/api'
  static String get _baseUrl => ApiConfig.baseUrl;

  /// Sync messages for a conversation (delta sync).
  /// Returns the list of new/updated messages for immediate UI update.
  Future<List<Message>> syncConversation(int conversationId, int userId) async {
    if (_isSyncing) return [];
    _isSyncing = true;

    try {
      return await _syncConversationInner(conversationId, userId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MessageSyncService] syncConversation error: $e');
      }
      return [];
    } finally {
      _isSyncing = false;
    }
  }

  /// Inner recursive worker — does NOT touch [_isSyncing] so that paging
  /// within a single sync session works correctly.
  ///
  /// Tries the delta `/sync` endpoint first. If the backend returns 404
  /// (endpoint not yet deployed), falls back to a standard paginated fetch
  /// from `/messages` so the local cache is always kept fresh.
  Future<List<Message>> _syncConversationInner(
    int conversationId,
    int userId,
  ) async {
    final db = MessageDatabase.instance;
    final syncState = await db.getSyncState(conversationId);
    final sinceId = syncState?['last_synced_message_id'] as int? ?? 0;
    final sinceTimestamp = syncState?['last_sync_timestamp'] as String?;

    final token = LocalStorageService.instanceSync?.getAuthToken();
    if (token == null) return [];

    // Build sync URL
    final queryParams = <String, String>{
      'user_id': userId.toString(),
      'since_id': sinceId.toString(),
    };
    if (sinceTimestamp != null) {
      queryParams['since_timestamp'] = sinceTimestamp;
    }
    final url = Uri.parse(
      '$_baseUrl/conversations/$conversationId/sync',
    ).replace(queryParameters: queryParams);

    if (kDebugMode) {
      debugPrint('[MessageSyncService] GET $url');
    }

    final response = await http.get(url, headers: ApiConfig.authHeaders(token));

    // If /sync endpoint doesn't exist (404), fall back to standard messages fetch
    if (response.statusCode == 404) {
      if (kDebugMode) {
        debugPrint('[MessageSyncService] /sync returned 404 — falling back to paginated fetch');
      }
      return _fallbackFetch(conversationId, userId);
    }
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    if (data['success'] != true) return [];

    // Parse new messages
    final List<Message> newMessages = (data['messages'] as List? ?? [])
        .map((m) => Message.fromJson(m as Map<String, dynamic>))
        .toList();

    // Parse edited messages
    final List<Message> editedMessages =
        (data['edited_messages'] as List? ?? [])
            .map((m) => Message.fromJson(m as Map<String, dynamic>))
            .toList();

    // Parse deleted IDs
    final List<int> deletedIds = (data['deleted_ids'] as List? ?? [])
        .map((id) => id is int ? id : int.tryParse(id.toString()) ?? 0)
        .where((id) => id > 0)
        .toList();

    // Apply to local database
    if (newMessages.isNotEmpty) {
      await db.upsertMessages(newMessages);
    }
    if (editedMessages.isNotEmpty) {
      await db.upsertMessages(editedMessages);
    }
    if (deletedIds.isNotEmpty) {
      await db.deleteMessages(deletedIds);
    }

    // Update sync state
    final maxId = newMessages.isNotEmpty
        ? newMessages.map((m) => m.id).reduce((a, b) => a > b ? a : b)
        : sinceId;
    final syncTimestamp =
        data['sync_timestamp'] as String? ?? DateTime.now().toIso8601String();
    await db.updateSyncState(conversationId, maxId, syncTimestamp);

    // Check if there are more messages to sync
    if (data['has_more'] == true) {
      final moreMessages =
          await _syncConversationInner(conversationId, userId);
      return [...newMessages, ...editedMessages, ...moreMessages];
    }

    return [...newMessages, ...editedMessages];
  }

  /// Fallback: fetch latest messages via standard paginated endpoint when
  /// the delta /sync endpoint is unavailable (404). Stores results in SQLite
  /// and updates sync state so the UI always has fresh data.
  Future<List<Message>> _fallbackFetch(int conversationId, int userId) async {
    final token = LocalStorageService.instanceSync?.getAuthToken();
    if (token == null) return [];

    final url = Uri.parse(
      '$_baseUrl/conversations/$conversationId/messages'
      '?user_id=$userId&page=1&per_page=50',
    );

    if (kDebugMode) {
      debugPrint('[MessageSyncService] fallbackFetch GET $url');
    }

    final response = await http.get(url, headers: ApiConfig.authHeaders(token));
    if (response.statusCode != 200) return [];

    final body = jsonDecode(response.body);
    final List<dynamic> msgList;
    if (body is Map<String, dynamic> &&
        body['success'] == true &&
        body['data'] is List) {
      msgList = body['data'] as List;
    } else if (body is List) {
      msgList = body;
    } else if (body is Map) {
      msgList = (body['data'] ?? body['messages'] ?? []) as List<dynamic>;
    } else {
      msgList = [];
    }

    final messages = <Message>[];
    for (final m in msgList) {
      if (m is Map<String, dynamic>) {
        try {
          messages.add(Message.fromJson(m));
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[MessageSyncService] Skip message parse: $e');
          }
        }
      }
    }

    if (messages.isNotEmpty) {
      final db = MessageDatabase.instance;
      await db.upsertMessages(messages);
      final maxId = messages.map((m) => m.id).reduce((a, b) => a > b ? a : b);
      await db.updateSyncState(
          conversationId, maxId, DateTime.now().toIso8601String());
    }

    return messages;
  }

  /// Sync conversation list.
  Future<List<Conversation>> syncConversationList(int userId) async {
    try {
      final token = LocalStorageService.instanceSync?.getAuthToken();
      if (token == null) return [];

      // Full fetch — will be upgraded to delta sync when the backend endpoint
      // supports it.
      final url = Uri.parse(
        '$_baseUrl/conversations?user_id=$userId&include_groups=1&per_page=100',
      );

      if (kDebugMode) {
        debugPrint('[MessageSyncService] GET $url');
      }

      final response =
          await http.get(url, headers: ApiConfig.authHeaders(token));
      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body);

      // Backend wraps list in { success, data, meta }
      final List<dynamic> convList;
      if (body is Map<String, dynamic> &&
          body['success'] == true &&
          body['data'] is List) {
        convList = body['data'] as List;
      } else if (body is List) {
        convList = body;
      } else if (body is Map) {
        convList =
            (body['data'] ?? body['conversations'] ?? []) as List<dynamic>;
      } else {
        convList = [];
      }

      final conversations = <Conversation>[];
      for (final c in convList) {
        if (c is Map<String, dynamic>) {
          try {
            conversations.add(Conversation.fromJson(c));
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                  '[MessageSyncService] Skip conversation parse: $e');
            }
          }
        }
      }

      // Store in local DB
      final db = MessageDatabase.instance;
      await db.upsertConversations(conversations);

      return conversations;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MessageSyncService] syncConversationList error: $e');
      }
      return [];
    }
  }

  /// Send a pending message from the offline queue.
  Future<bool> sendPendingMessage(
      Map<String, dynamic> pending, int userId) async {
    try {
      final token = LocalStorageService.instanceSync?.getAuthToken();
      if (token == null) return false;

      final conversationId = pending['conversation_id'];
      final url = Uri.parse(
          '$_baseUrl/conversations/$conversationId/messages');

      final response = await http.post(
        url,
        headers: {
          ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'content': pending['content'],
          'message_type': pending['message_type'] ?? 'text',
          if (pending['reply_to_id'] != null)
            'reply_to_id': pending['reply_to_id'],
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final db = MessageDatabase.instance;
        // Remove from pending queue
        await db.removePendingMessage(pending['local_id'] as String);

        // Parse server response and store the real message
        final data = jsonDecode(response.body);
        final messageData = data['data'] ?? data['message'] ?? data;
        if (messageData is Map<String, dynamic>) {
          final message = Message.fromJson(messageData);
          await db.upsertMessage(message);
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MessageSyncService] sendPendingMessage error: $e');
      }
      return false;
    }
  }

  /// Flush all pending messages (called on reconnect).
  Future<void> flushPendingMessages(int userId) async {
    final db = MessageDatabase.instance;
    final pending = await db.getPendingMessages();

    for (final msg in pending) {
      final retryCount = msg['retry_count'] as int? ?? 0;
      if (retryCount >= 5) continue; // Give up after 5 retries

      final success = await sendPendingMessage(msg, userId);
      if (!success) {
        await db.incrementPendingRetry(msg['local_id'] as String);
      }
    }
  }

  /// Initial full sync for a conversation (first time opening).
  Future<List<Message>> initialSync(int conversationId, int userId) async {
    try {
      final token = LocalStorageService.instanceSync?.getAuthToken();
      if (token == null) return [];

      final url = Uri.parse(
        '$_baseUrl/conversations/$conversationId/messages'
        '?user_id=$userId&page=1&per_page=50',
      );

      if (kDebugMode) {
        debugPrint('[MessageSyncService] initialSync GET $url');
      }

      final response =
          await http.get(url, headers: ApiConfig.authHeaders(token));
      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body);

      // Backend: { success, data: [...], meta }
      final List<dynamic> msgList;
      if (body is Map<String, dynamic> &&
          body['success'] == true &&
          body['data'] is List) {
        msgList = body['data'] as List;
      } else if (body is List) {
        msgList = body;
      } else if (body is Map) {
        msgList =
            (body['data'] ?? body['messages'] ?? []) as List<dynamic>;
      } else {
        msgList = [];
      }

      final messages = <Message>[];
      for (final m in msgList) {
        if (m is Map<String, dynamic>) {
          try {
            messages.add(Message.fromJson(m));
          } catch (e) {
            if (kDebugMode) {
              debugPrint('[MessageSyncService] Skip message parse: $e');
            }
          }
        }
      }

      if (messages.isNotEmpty) {
        final db = MessageDatabase.instance;
        await db.upsertMessages(messages);

        // Set sync state so future syncs are incremental
        final maxId =
            messages.map((m) => m.id).reduce((a, b) => a > b ? a : b);
        await db.updateSyncState(
            conversationId, maxId, DateTime.now().toIso8601String());
      }

      return messages;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MessageSyncService] initialSync error: $e');
      }
      return [];
    }
  }
}
