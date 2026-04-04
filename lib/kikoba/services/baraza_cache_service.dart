import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// Local cache service for baraza (chat) messages
/// Provides instant display of recent messages while fresh data loads from Firestore
///
/// IMPORTANT: This cache is for UI responsiveness only.
/// Firestore is the source of truth for real-time messages.
class BarazaCacheService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  static const String _messagesKeyPrefix = 'baraza_messages_';
  static const String _versionKeyPrefix = 'baraza_version_';
  static const int _cacheExpiryMinutes = 30; // Messages valid for 30 min
  static const int _maxCachedMessages = 100; // Only cache recent 100 messages

  /// Save messages to local cache
  static Future<void> saveMessages(
      String kikobaId, List<Map<String, dynamic>> messages) async {
    if (kikobaId.isEmpty) {
      _logger.w('[BarazaCache] Cannot save - kikobaId is empty');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_messagesKeyPrefix$kikobaId';

      // Only cache the most recent messages
      final messagesToCache = messages.length > _maxCachedMessages
          ? messages.sublist(messages.length - _maxCachedMessages)
          : messages;

      final cacheData = {
        'data': messagesToCache,
        'cachedAt': DateTime.now().toIso8601String(),
        'count': messagesToCache.length,
      };

      await prefs.setString(cacheKey, jsonEncode(cacheData));
      _logger.d(
          '[BarazaCache] Saved ${messagesToCache.length} messages for kikoba: $kikobaId');
    } catch (e) {
      _logger.e('[BarazaCache] Error saving messages cache: $e');
    }
  }

  /// Get cached messages if available and not expired
  static Future<List<Map<String, dynamic>>?> getMessages(
      String kikobaId) async {
    if (kikobaId.isEmpty) {
      _logger.w('[BarazaCache] Cannot get - kikobaId is empty');
      return null;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_messagesKeyPrefix$kikobaId';
      final cached = prefs.getString(cacheKey);

      if (cached == null) {
        _logger.d('[BarazaCache] No cache found for kikoba: $kikobaId');
        return null;
      }

      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(decoded['cachedAt'] as String);
      final age = DateTime.now().difference(cachedAt);

      if (age.inMinutes > _cacheExpiryMinutes) {
        _logger.d('[BarazaCache] Cache expired (${age.inMinutes} min old)');
        return null;
      }

      final messagesList = decoded['data'] as List<dynamic>;
      final messages = messagesList
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList();

      _logger
          .d('[BarazaCache] Loaded ${messages.length} messages from cache (${age.inMinutes} min old)');
      return messages;
    } catch (e) {
      _logger.e('[BarazaCache] Error reading messages cache: $e');
      return null;
    }
  }

  /// Save the last known message count for change detection
  static Future<void> saveVersion(String kikobaId, int version) async {
    if (kikobaId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_versionKeyPrefix$kikobaId';
      await prefs.setInt(key, version);
      _logger.d('[BarazaCache] Saved version: $version for kikoba: $kikobaId');
    } catch (e) {
      _logger.e('[BarazaCache] Error saving version: $e');
    }
  }

  /// Get the last known version
  static Future<int?> getVersion(String kikobaId) async {
    if (kikobaId.isEmpty) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_versionKeyPrefix$kikobaId';
      return prefs.getInt(key);
    } catch (e) {
      _logger.e('[BarazaCache] Error reading version: $e');
      return null;
    }
  }

  /// Clear all caches for a specific kikoba
  static Future<void> clearCache(String kikobaId) async {
    if (kikobaId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesKey = '$_messagesKeyPrefix$kikobaId';
      final versionKey = '$_versionKeyPrefix$kikobaId';

      await prefs.remove(messagesKey);
      await prefs.remove(versionKey);

      _logger.d('[BarazaCache] Cleared cache for kikoba: $kikobaId');
    } catch (e) {
      _logger.e('[BarazaCache] Error clearing cache: $e');
    }
  }

  /// Check if cache exists and is valid
  static Future<bool> hasCachedData(String kikobaId) async {
    if (kikobaId.isEmpty) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_messagesKeyPrefix$kikobaId';
      final cached = prefs.getString(cacheKey);

      if (cached == null) return false;

      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(decoded['cachedAt'] as String);
      final age = DateTime.now().difference(cachedAt);

      return age.inMinutes <= _cacheExpiryMinutes;
    } catch (e) {
      return false;
    }
  }

  /// Get cache age in minutes (for UI display)
  static Future<int?> getCacheAgeMinutes(String kikobaId) async {
    if (kikobaId.isEmpty) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_messagesKeyPrefix$kikobaId';
      final cached = prefs.getString(cacheKey);

      if (cached == null) return null;

      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(decoded['cachedAt'] as String);
      return DateTime.now().difference(cachedAt).inMinutes;
    } catch (e) {
      return null;
    }
  }
}
