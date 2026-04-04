import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/message_models.dart';

/// Hive-backed cache for the conversation list.
/// Shows cached conversations instantly on Messages tab open.
class ConversationCacheService {
  ConversationCacheService._();
  static final ConversationCacheService instance = ConversationCacheService._();

  static const String _boxName = 'conversation_cache';
  static const int _maxConversations = 50;

  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    _box ??= await Hive.openBox<String>(_boxName);
    return _box!;
  }

  /// Save conversations list.
  Future<void> saveConversations(List<Conversation> conversations) async {
    try {
      final box = await _getBox();
      final toStore = conversations.length > _maxConversations
          ? conversations.sublist(0, _maxConversations)
          : conversations;
      final list = toStore.map((c) => c.toJson()).toList();
      await box.put('conversations', jsonEncode(list));
      await box.put('fetched_at', DateTime.now().toIso8601String());
      if (kDebugMode) debugPrint('[ConvCache] Saved ${toStore.length} conversations');
    } catch (e) {
      if (kDebugMode) debugPrint('[ConvCache] Save error: $e');
    }
  }

  /// Load cached conversations.
  Future<List<Conversation>> getConversations() async {
    try {
      final box = await _getBox();
      final json = box.get('conversations');
      if (json == null || json.isEmpty) return [];
      final list = jsonDecode(json) as List<dynamic>?;
      if (list == null) return [];
      final conversations = <Conversation>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          try {
            conversations.add(Conversation.fromJson(e));
          } catch (_) {}
        }
      }
      if (kDebugMode) debugPrint('[ConvCache] Loaded ${conversations.length} cached conversations');
      return conversations;
    } catch (e) {
      if (kDebugMode) debugPrint('[ConvCache] Load error: $e');
      return [];
    }
  }

  /// Clear cache (on logout).
  Future<void> clear() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (_) {}
  }
}
