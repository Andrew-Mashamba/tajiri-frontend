import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/message_models.dart';

class MessageDatabase {
  static MessageDatabase? _instance;
  static Database? _database;

  MessageDatabase._();

  static MessageDatabase get instance {
    _instance ??= MessageDatabase._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/tajiri_messages.db';

    return openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Conversations table
    await db.execute('''
      CREATE TABLE conversations (
        id INTEGER PRIMARY KEY,
        type TEXT DEFAULT 'private',
        group_id INTEGER,
        name TEXT,
        avatar_path TEXT,
        created_by INTEGER NOT NULL,
        last_message_id INTEGER,
        last_message_at TEXT,
        last_message_preview TEXT,
        last_message_sender_id INTEGER,
        unread_count INTEGER DEFAULT 0,
        is_muted INTEGER DEFAULT 0,
        is_admin INTEGER DEFAULT 0,
        disappearing_timer INTEGER,
        display_name TEXT,
        display_photo TEXT,
        created_at TEXT,
        updated_at TEXT,
        json_data TEXT
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY,
        conversation_id INTEGER NOT NULL,
        sender_id INTEGER NOT NULL,
        content TEXT,
        message_type TEXT DEFAULT 'text',
        status TEXT DEFAULT 'sent',
        media_path TEXT,
        media_type TEXT,
        reply_to_id INTEGER,
        is_read INTEGER DEFAULT 0,
        read_at TEXT,
        is_forwarded INTEGER DEFAULT 0,
        is_starred INTEGER DEFAULT 0,
        link_preview_url TEXT,
        link_preview_title TEXT,
        link_preview_description TEXT,
        link_preview_image TEXT,
        link_preview_domain TEXT,
        poll_id INTEGER,
        transcript TEXT,
        edited_at TEXT,
        expires_at TEXT,
        delivered_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        json_data TEXT,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
      )
    ''');

    // Sync state table
    await db.execute('''
      CREATE TABLE sync_state (
        conversation_id INTEGER PRIMARY KEY,
        last_synced_message_id INTEGER DEFAULT 0,
        last_sync_timestamp TEXT,
        full_sync_complete INTEGER DEFAULT 0
      )
    ''');

    // Pending messages (offline queue)
    await db.execute('''
      CREATE TABLE pending_messages (
        local_id TEXT PRIMARY KEY,
        conversation_id INTEGER NOT NULL,
        sender_id INTEGER NOT NULL,
        content TEXT,
        message_type TEXT DEFAULT 'text',
        media_path TEXT,
        reply_to_id INTEGER,
        poll_id INTEGER,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_retry_at TEXT,
        json_data TEXT
      )
    ''');

    // Drafts table
    await db.execute('''
      CREATE TABLE drafts (
        conversation_id INTEGER PRIMARY KEY,
        content TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Call history table
    await db.execute('''
      CREATE TABLE call_history (
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        other_user_id INTEGER,
        call_id TEXT,
        type TEXT DEFAULT 'voice',
        direction TEXT DEFAULT 'outgoing',
        status TEXT DEFAULT 'missed',
        duration INTEGER,
        call_time TEXT NOT NULL,
        other_user_json TEXT,
        json_data TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_call_history_time ON call_history(call_time DESC)');
    await db.execute('CREATE INDEX idx_call_history_status ON call_history(status)');

    // Indexes for fast queries
    await db.execute(
        'CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC)');
    await db.execute(
        'CREATE INDEX idx_messages_sender ON messages(sender_id)');
    await db.execute(
        'CREATE INDEX idx_messages_type ON messages(conversation_id, message_type)');
    await db.execute(
        'CREATE INDEX idx_messages_starred ON messages(is_starred) WHERE is_starred = 1');
    await db.execute(
        'CREATE INDEX idx_messages_search ON messages(content)');
    await db.execute(
        'CREATE INDEX idx_conversations_updated ON conversations(updated_at DESC)');
    await db.execute(
        'CREATE INDEX idx_conversations_last_msg ON conversations(last_message_at DESC)');
    await db.execute(
        'CREATE INDEX idx_pending_conversation ON pending_messages(conversation_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS drafts (
          conversation_id INTEGER PRIMARY KEY,
          content TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS call_history (
          id INTEGER PRIMARY KEY,
          user_id INTEGER NOT NULL,
          other_user_id INTEGER,
          call_id TEXT,
          type TEXT DEFAULT 'voice',
          direction TEXT DEFAULT 'outgoing',
          status TEXT DEFAULT 'missed',
          duration INTEGER,
          call_time TEXT NOT NULL,
          other_user_json TEXT,
          json_data TEXT
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_call_history_time ON call_history(call_time DESC)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_call_history_status ON call_history(status)');
    }
  }

  // ==================== MESSAGES ====================

  /// Insert or update a single message
  Future<void> upsertMessage(Message message) async {
    final db = await database;
    await db.insert(
      'messages',
      _messageToRow(message),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert or update multiple messages (batch)
  Future<void> upsertMessages(List<Message> messages) async {
    if (messages.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final msg in messages) {
      batch.insert('messages', _messageToRow(msg),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Get messages for a conversation, paginated from local DB.
  /// Returns newest first (for chat display), limited to [limit] messages.
  Future<List<Message>> getMessages(int conversationId,
      {int limit = 50, int? beforeId}) async {
    final db = await database;
    String where = 'conversation_id = ?';
    List<dynamic> args = [conversationId];
    if (beforeId != null) {
      where += ' AND id < ?';
      args.add(beforeId);
    }
    final rows = await db.query(
      'messages',
      where: where,
      whereArgs: args,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(_rowToMessage).toList();
  }

  /// Get total message count for a conversation
  Future<int> getMessageCount(int conversationId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE conversation_id = ?',
      [conversationId],
    );
    return result.first['count'] as int? ?? 0;
  }

  /// Search messages locally
  Future<List<Message>> searchMessages(String query,
      {int? conversationId, int limit = 50}) async {
    final db = await database;
    String where = 'content LIKE ?';
    List<dynamic> args = ['%$query%'];
    if (conversationId != null) {
      where += ' AND conversation_id = ?';
      args.add(conversationId);
    }
    final rows = await db.query(
      'messages',
      where: where,
      whereArgs: args,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(_rowToMessage).toList();
  }

  /// Get starred messages
  Future<List<Message>> getStarredMessages(
      {int limit = 50, int offset = 0}) async {
    final db = await database;
    final rows = await db.query(
      'messages',
      where: 'is_starred = 1',
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(_rowToMessage).toList();
  }

  /// Delete messages by IDs (from server sync)
  Future<void> deleteMessages(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final placeholders = ids.map((_) => '?').join(',');
    await db.delete('messages',
        where: 'id IN ($placeholders)', whereArgs: ids);
  }

  /// Update message status
  Future<void> updateMessageStatus(int messageId, String status) async {
    final db = await database;
    await db.update('messages', {'status': status},
        where: 'id = ?', whereArgs: [messageId]);
  }

  /// Toggle star on message
  Future<void> toggleMessageStar(int messageId, bool isStarred) async {
    final db = await database;
    await db.update('messages', {'is_starred': isStarred ? 1 : 0},
        where: 'id = ?', whereArgs: [messageId]);
  }

  // ==================== CONVERSATIONS ====================

  /// Insert or update a conversation
  Future<void> upsertConversation(Conversation conversation) async {
    final db = await database;
    await db.insert(
      'conversations',
      _conversationToRow(conversation),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert or update multiple conversations
  Future<void> upsertConversations(List<Conversation> conversations) async {
    if (conversations.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final conv in conversations) {
      batch.insert('conversations', _conversationToRow(conv),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Get all conversations, sorted by last_message_at descending
  Future<List<Conversation>> getConversations() async {
    final db = await database;
    final rows = await db.query(
      'conversations',
      orderBy: 'last_message_at DESC',
    );
    return rows.map(_rowToConversation).toList();
  }

  /// Delete a conversation and all its messages
  Future<void> deleteConversation(int conversationId) async {
    final db = await database;
    await db.delete('messages',
        where: 'conversation_id = ?', whereArgs: [conversationId]);
    await db.delete('conversations',
        where: 'id = ?', whereArgs: [conversationId]);
    await db.delete('sync_state',
        where: 'conversation_id = ?', whereArgs: [conversationId]);
    await db.delete('pending_messages',
        where: 'conversation_id = ?', whereArgs: [conversationId]);
  }

  // ==================== SYNC STATE ====================

  /// Get sync state for a conversation
  Future<Map<String, dynamic>?> getSyncState(int conversationId) async {
    final db = await database;
    final rows = await db.query('sync_state',
        where: 'conversation_id = ?', whereArgs: [conversationId]);
    return rows.isEmpty ? null : rows.first;
  }

  /// Update sync state after successful sync
  Future<void> updateSyncState(
      int conversationId, int lastMessageId, String syncTimestamp) async {
    final db = await database;
    await db.insert(
        'sync_state',
        {
          'conversation_id': conversationId,
          'last_synced_message_id': lastMessageId,
          'last_sync_timestamp': syncTimestamp,
          'full_sync_complete': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ==================== PENDING MESSAGES (OFFLINE QUEUE) ====================

  /// Add a message to the offline send queue
  Future<void> addPendingMessage(Map<String, dynamic> pendingMsg) async {
    final db = await database;
    await db.insert('pending_messages', pendingMsg,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get all pending messages for a conversation (or all if conversationId is null)
  Future<List<Map<String, dynamic>>> getPendingMessages(
      {int? conversationId}) async {
    final db = await database;
    if (conversationId != null) {
      return db.query('pending_messages',
          where: 'conversation_id = ?',
          whereArgs: [conversationId],
          orderBy: 'created_at ASC');
    }
    return db.query('pending_messages', orderBy: 'created_at ASC');
  }

  /// Remove a pending message after successful send
  Future<void> removePendingMessage(String localId) async {
    final db = await database;
    await db.delete('pending_messages',
        where: 'local_id = ?', whereArgs: [localId]);
  }

  /// Increment retry count for a pending message
  Future<void> incrementPendingRetry(String localId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE pending_messages SET retry_count = retry_count + 1, last_retry_at = ? WHERE local_id = ?',
      [DateTime.now().toIso8601String(), localId],
    );
  }

  // ==================== DRAFTS ====================

  /// Save or update a draft for a conversation
  Future<void> saveDraft(int conversationId, String content) async {
    final db = await database;
    if (content.trim().isEmpty) {
      await db.delete('drafts', where: 'conversation_id = ?', whereArgs: [conversationId]);
      return;
    }
    await db.insert('drafts', {
      'conversation_id': conversationId,
      'content': content,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get draft for a conversation
  Future<String?> getDraft(int conversationId) async {
    final db = await database;
    final rows = await db.query('drafts',
      where: 'conversation_id = ?', whereArgs: [conversationId]);
    if (rows.isEmpty) return null;
    return rows.first['content'] as String?;
  }

  /// Get all drafts (for conversations list display)
  Future<Map<int, String>> getAllDrafts() async {
    final db = await database;
    final rows = await db.query('drafts');
    final map = <int, String>{};
    for (final row in rows) {
      final convId = row['conversation_id'] as int;
      final content = row['content'] as String? ?? '';
      if (content.isNotEmpty) map[convId] = content;
    }
    return map;
  }

  /// Clear draft for a conversation
  Future<void> clearDraft(int conversationId) async {
    final db = await database;
    await db.delete('drafts', where: 'conversation_id = ?', whereArgs: [conversationId]);
  }

  // ==================== CALL HISTORY ====================

  Future<void> upsertCallLog(Map<String, dynamic> callLog) async {
    final db = await database;
    await db.insert('call_history', callLog, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertCallLogs(List<Map<String, dynamic>> callLogs) async {
    if (callLogs.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final log in callLogs) {
      batch.insert('call_history', log, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCallHistory({String? status}) async {
    final db = await database;
    if (status != null) {
      return db.query('call_history', where: 'status = ?', whereArgs: [status], orderBy: 'call_time DESC');
    }
    return db.query('call_history', orderBy: 'call_time DESC');
  }

  Future<void> clearCallHistory() async {
    final db = await database;
    await db.delete('call_history');
  }

  // ==================== UTILITIES ====================

  /// Clear all data (for logout)
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('conversations');
    await db.delete('sync_state');
    await db.delete('pending_messages');
    await db.delete('drafts');
    await db.delete('call_history');
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // ==================== ROW CONVERTERS ====================

  Map<String, dynamic> _messageToRow(Message message) {
    return {
      'id': message.id,
      'conversation_id': message.conversationId,
      'sender_id': message.senderId,
      'content': message.content,
      'message_type': message.messageType.value,
      'status': message.status.name,
      'media_path': message.mediaPath,
      'media_type': message.mediaType,
      'reply_to_id': message.replyToId,
      'is_read': message.isRead ? 1 : 0,
      'read_at': message.readAt?.toIso8601String(),
      'is_forwarded': message.isForwarded ? 1 : 0,
      'is_starred': message.isStarred ? 1 : 0,
      'link_preview_url': message.linkPreviewUrl,
      'link_preview_title': message.linkPreviewTitle,
      'link_preview_description': message.linkPreviewDescription,
      'link_preview_image': message.linkPreviewImage,
      'link_preview_domain': message.linkPreviewDomain,
      'poll_id': message.pollId,
      'transcript': message.transcript,
      'edited_at': message.editedAt?.toIso8601String(),
      'expires_at': message.expiresAt?.toIso8601String(),
      'delivered_at': message.deliveredAt?.toIso8601String(),
      'created_at': message.createdAt.toIso8601String(),
      'updated_at': message.updatedAt.toIso8601String(),
      'json_data': jsonEncode(message.toJson()),
    };
  }

  Message _rowToMessage(Map<String, dynamic> row) {
    // Use json_data for full fidelity reconstruction
    // (includes sender, reactions, replyTo, etc.)
    if (row['json_data'] != null) {
      try {
        final json =
            jsonDecode(row['json_data'] as String) as Map<String, dynamic>;
        return Message.fromJson(json);
      } catch (_) {
        // Fall through to column-based reconstruction
      }
    }
    // Fallback: reconstruct from columns
    return Message.fromJson({
      'id': row['id'],
      'conversation_id': row['conversation_id'],
      'sender_id': row['sender_id'],
      'content': row['content'],
      'message_type': row['message_type'],
      'status': row['status'],
      'media_path': row['media_path'],
      'media_type': row['media_type'],
      'reply_to_id': row['reply_to_id'],
      'is_read': row['is_read'] == 1,
      'read_at': row['read_at'],
      'is_forwarded': row['is_forwarded'] == 1,
      'is_starred': row['is_starred'] == 1,
      'link_preview_url': row['link_preview_url'],
      'link_preview_title': row['link_preview_title'],
      'link_preview_description': row['link_preview_description'],
      'link_preview_image': row['link_preview_image'],
      'link_preview_domain': row['link_preview_domain'],
      'poll_id': row['poll_id'],
      'transcript': row['transcript'],
      'edited_at': row['edited_at'],
      'expires_at': row['expires_at'],
      'delivered_at': row['delivered_at'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
    });
  }

  Map<String, dynamic> _conversationToRow(Conversation conversation) {
    return {
      'id': conversation.id,
      'type': conversation.type.value,
      'group_id': conversation.groupId,
      'name': conversation.name,
      'avatar_path': conversation.avatarPath,
      'created_by': conversation.createdBy,
      'last_message_id': conversation.lastMessageId,
      'last_message_at': conversation.lastMessageAt?.toIso8601String(),
      'last_message_preview': conversation.lastMessage?.content ??
          conversation.lastMessage?.preview,
      'last_message_sender_id': conversation.lastMessage?.senderId,
      'unread_count': conversation.unreadCount,
      'is_muted': conversation.isMuted ? 1 : 0,
      'is_admin': conversation.isAdmin ? 1 : 0,
      'disappearing_timer': conversation.disappearingTimer,
      'display_name': conversation.displayName,
      'display_photo': conversation.displayPhoto,
      'created_at': conversation.createdAt.toIso8601String(),
      'updated_at': conversation.updatedAt.toIso8601String(),
      'json_data': jsonEncode(conversation.toJson()),
    };
  }

  Conversation _rowToConversation(Map<String, dynamic> row) {
    // Use json_data for full fidelity reconstruction
    // (includes participants, lastMessage, etc.)
    if (row['json_data'] != null) {
      try {
        final json =
            jsonDecode(row['json_data'] as String) as Map<String, dynamic>;
        return Conversation.fromJson(json);
      } catch (_) {
        // Fall through to column-based reconstruction
      }
    }
    return Conversation.fromJson({
      'id': row['id'],
      'type': row['type'],
      'group_id': row['group_id'],
      'name': row['name'],
      'avatar_path': row['avatar_path'],
      'created_by': row['created_by'],
      'last_message_id': row['last_message_id'],
      'last_message_at': row['last_message_at'],
      'unread_count': row['unread_count'],
      'is_muted': row['is_muted'] == 1,
      'is_admin': row['is_admin'] == 1,
      'disappearing_timer': row['disappearing_timer'],
      'display_name': row['display_name'],
      'display_photo': row['display_photo'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
    });
  }
}
