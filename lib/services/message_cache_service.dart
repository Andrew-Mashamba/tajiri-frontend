import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/message_models.dart';

/// Local cache of messages per conversation for instant open and offline.
/// See MESSAGES_REALTIME_CACHING_AND_NOTIFICATIONS.md §4.2.
class MessageCacheService {
  MessageCacheService._();
  static final MessageCacheService instance = MessageCacheService._();

  static const String _boxName = 'message_cache';
  static const int _maxMessagesPerConversation = 500;

  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    _box ??= await Hive.openBox<String>(_boxName);
    return _box!;
  }

  String _key(int conversationId) => 'conv_$conversationId';

  /// Load cached messages for a conversation (oldest to newest). Returns empty if none.
  Future<List<Message>> getMessages(int conversationId) async {
    try {
      final box = await _getBox();
      final json = box.get(_key(conversationId));
      if (json == null || json.isEmpty) return [];
      final list = jsonDecode(json) as List<dynamic>?;
      if (list == null) return [];
      final messages = <Message>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          try {
            messages.add(Message.fromJson(e));
          } catch (_) {}
        }
      }
      return messages;
    } catch (e) {
      return [];
    }
  }

  /// Merge API messages into cache: by id, sort by created_at, keep last [_maxMessagesPerConversation].
  Future<void> saveMessages(int conversationId, List<Message> messages) async {
    if (messages.isEmpty) return;
    try {
      final box = await _getBox();
      final existing = await getMessages(conversationId);
      final byId = <int, Message>{};
      for (final m in existing) byId[m.id] = m;
      for (final m in messages) byId[m.id] = m;
      final merged = byId.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final toStore = merged.length > _maxMessagesPerConversation
          ? merged.sublist(merged.length - _maxMessagesPerConversation)
          : merged;
      final list = toStore.map((m) => m.toJson()).toList();
      await box.put(_key(conversationId), jsonEncode(list));
    } catch (e) {
      // ignore
    }
  }

  /// Append one message (e.g. after send or on push). Merges with existing and trims.
  Future<void> appendMessage(int conversationId, Message message) async {
    final existing = await getMessages(conversationId);
    final merged = [...existing];
    final i = merged.indexWhere((m) => m.id == message.id);
    if (i >= 0) {
      merged[i] = message;
    } else {
      merged.add(message);
      merged.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    await saveMessages(conversationId, merged);
  }

  /// Clear cache for one conversation (e.g. on logout or clear data).
  Future<void> clearConversation(int conversationId) async {
    try {
      final box = await _getBox();
      await box.delete(_key(conversationId));
    } catch (_) {}
  }
}
