import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// Local cache service for katiba data
/// Provides instant display while fresh data loads from backend
class KatibaCacheService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  static const String _cacheKeyPrefix = 'katiba_cache_';
  static const String _versionKeyPrefix = 'katiba_version_';
  static const int _cacheExpiryMinutes = 30; // Cache valid for 30 minutes

  /// Save katiba data to local cache
  static Future<void> saveKatiba(String kikobaId, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'cachedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString('$_cacheKeyPrefix$kikobaId', jsonEncode(cacheData));
      _logger.d('[KatibaCache] Saved cache for kikoba: $kikobaId');
    } catch (e) {
      _logger.e('[KatibaCache] Error saving cache: $e');
    }
  }

  /// Get cached katiba data if available and not expired
  static Future<Map<String, dynamic>?> getKatiba(String kikobaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('$_cacheKeyPrefix$kikobaId');

      if (cached == null) {
        _logger.d('[KatibaCache] No cache found for kikoba: $kikobaId');
        return null;
      }

      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(decoded['cachedAt'] as String);
      final age = DateTime.now().difference(cachedAt);

      if (age.inMinutes > _cacheExpiryMinutes) {
        _logger.d('[KatibaCache] Cache expired (${age.inMinutes} min old)');
        return null;
      }

      _logger.d('[KatibaCache] Using cached data (${age.inMinutes} min old)');
      return decoded['data'] as Map<String, dynamic>;
    } catch (e) {
      _logger.e('[KatibaCache] Error reading cache: $e');
      return null;
    }
  }

  /// Save the last known version from Firestore
  static Future<void> saveVersion(String kikobaId, int version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_versionKeyPrefix$kikobaId', version);
      _logger.d('[KatibaCache] Saved version $version for kikoba: $kikobaId');
    } catch (e) {
      _logger.e('[KatibaCache] Error saving version: $e');
    }
  }

  /// Get the last known version
  static Future<int?> getVersion(String kikobaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('$_versionKeyPrefix$kikobaId');
    } catch (e) {
      _logger.e('[KatibaCache] Error reading version: $e');
      return null;
    }
  }

  /// Check if version has changed (returns true if should refresh)
  static Future<bool> hasVersionChanged(String kikobaId, int? newVersion) async {
    if (newVersion == null) return true;

    final lastVersion = await getVersion(kikobaId);
    if (lastVersion == null) return true;

    return newVersion != lastVersion;
  }

  /// Clear cache for a specific kikoba
  static Future<void> clearCache(String kikobaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cacheKeyPrefix$kikobaId');
      await prefs.remove('$_versionKeyPrefix$kikobaId');
      _logger.d('[KatibaCache] Cleared cache for kikoba: $kikobaId');
    } catch (e) {
      _logger.e('[KatibaCache] Error clearing cache: $e');
    }
  }

  /// Clear all katiba caches
  static Future<void> clearAllCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_cacheKeyPrefix) || key.startsWith(_versionKeyPrefix)) {
          await prefs.remove(key);
        }
      }
      _logger.d('[KatibaCache] Cleared all katiba caches');
    } catch (e) {
      _logger.e('[KatibaCache] Error clearing all caches: $e');
    }
  }
}
