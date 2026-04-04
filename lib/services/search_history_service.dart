import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive-backed search history for recent query suggestions.
/// Stores up to 20 recent search queries.
class SearchHistoryService {
  SearchHistoryService._();
  static final SearchHistoryService instance = SearchHistoryService._();

  static const String _boxName = 'search_history';
  static const String _key = 'queries';
  static const int _maxQueries = 20;

  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    _box ??= await Hive.openBox<String>(_boxName);
    return _box!;
  }

  /// Get recent search queries (newest first).
  Future<List<String>> getHistory() async {
    try {
      final box = await _getBox();
      final json = box.get(_key);
      if (json == null || json.isEmpty) return [];
      final list = jsonDecode(json) as List<dynamic>?;
      return list?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      if (kDebugMode) debugPrint('[SearchHistory] Load error: $e');
      return [];
    }
  }

  /// Add a query to history. Deduplicates and keeps max [_maxQueries].
  Future<void> addQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    try {
      final box = await _getBox();
      final history = await getHistory();
      // Remove duplicate if exists
      history.remove(trimmed);
      // Add to front (newest first)
      history.insert(0, trimmed);
      // Trim to max
      final toStore = history.length > _maxQueries
          ? history.sublist(0, _maxQueries)
          : history;
      await box.put(_key, jsonEncode(toStore));
    } catch (e) {
      if (kDebugMode) debugPrint('[SearchHistory] Save error: $e');
    }
  }

  /// Remove a specific query from history.
  Future<void> removeQuery(String query) async {
    try {
      final box = await _getBox();
      final history = await getHistory();
      history.remove(query.trim());
      await box.put(_key, jsonEncode(history));
    } catch (e) {
      if (kDebugMode) debugPrint('[SearchHistory] Remove error: $e');
    }
  }

  /// Clear all search history.
  Future<void> clear() async {
    try {
      final box = await _getBox();
      await box.delete(_key);
    } catch (_) {}
  }
}
