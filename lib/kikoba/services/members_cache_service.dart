import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// Local cache service for members data
/// Provides instant display while fresh data loads from backend
class MembersCacheService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  static const String _cacheKeyPrefix = 'members_cache_';
  static const String _versionKeyPrefix = 'members_version_';
  static const String _leaderboardCachePrefix = 'members_leaderboard_';
  static const int _cacheExpiryMinutes = 15; // Cache valid for 15 minutes (members change more often)

  /// Save members data to local cache
  static Future<void> saveMembers(
    String kikobaId,
    Map<String, dynamic> data, {
    String? sortBy,
    String? statusFilter,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _buildCacheKey(kikobaId, sortBy, statusFilter);
      final cacheData = {
        'data': data,
        'cachedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(cacheKey, jsonEncode(cacheData));
      _logger.d('[MembersCache] Saved cache for kikoba: $kikobaId (sort: $sortBy, status: $statusFilter)');
    } catch (e) {
      _logger.e('[MembersCache] Error saving cache: $e');
    }
  }

  /// Get cached members data if available and not expired
  static Future<Map<String, dynamic>?> getMembers(
    String kikobaId, {
    String? sortBy,
    String? statusFilter,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _buildCacheKey(kikobaId, sortBy, statusFilter);
      final cached = prefs.getString(cacheKey);

      if (cached == null) {
        _logger.d('[MembersCache] No cache found for kikoba: $kikobaId');
        return null;
      }

      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(decoded['cachedAt'] as String);
      final age = DateTime.now().difference(cachedAt);

      if (age.inMinutes > _cacheExpiryMinutes) {
        _logger.d('[MembersCache] Cache expired (${age.inMinutes} min old)');
        return null;
      }

      _logger.d('[MembersCache] Using cached data (${age.inMinutes} min old)');
      return decoded['data'] as Map<String, dynamic>;
    } catch (e) {
      _logger.e('[MembersCache] Error reading cache: $e');
      return null;
    }
  }

  /// Save leaderboard data to local cache
  static Future<void> saveLeaderboard(String kikobaId, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'cachedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString('$_leaderboardCachePrefix$kikobaId', jsonEncode(cacheData));
      _logger.d('[MembersCache] Saved leaderboard cache for kikoba: $kikobaId');
    } catch (e) {
      _logger.e('[MembersCache] Error saving leaderboard cache: $e');
    }
  }

  /// Get cached leaderboard data
  static Future<Map<String, dynamic>?> getLeaderboard(String kikobaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('$_leaderboardCachePrefix$kikobaId');

      if (cached == null) return null;

      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(decoded['cachedAt'] as String);
      final age = DateTime.now().difference(cachedAt);

      if (age.inMinutes > _cacheExpiryMinutes) {
        return null;
      }

      return decoded['data'] as Map<String, dynamic>;
    } catch (e) {
      _logger.e('[MembersCache] Error reading leaderboard cache: $e');
      return null;
    }
  }

  /// Build cache key based on filters
  static String _buildCacheKey(String kikobaId, String? sortBy, String? statusFilter) {
    return '$_cacheKeyPrefix${kikobaId}_${sortBy ?? 'default'}_${statusFilter ?? 'all'}';
  }

  /// Save the last known version from Firestore
  static Future<void> saveVersion(String kikobaId, int version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_versionKeyPrefix$kikobaId', version);
      _logger.d('[MembersCache] Saved version $version for kikoba: $kikobaId');
    } catch (e) {
      _logger.e('[MembersCache] Error saving version: $e');
    }
  }

  /// Get the last known version
  static Future<int?> getVersion(String kikobaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('$_versionKeyPrefix$kikobaId');
    } catch (e) {
      _logger.e('[MembersCache] Error reading version: $e');
      return null;
    }
  }

  /// Clear cache for a specific kikoba
  static Future<void> clearCache(String kikobaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.contains(kikobaId) &&
            (key.startsWith(_cacheKeyPrefix) ||
                key.startsWith(_versionKeyPrefix) ||
                key.startsWith(_leaderboardCachePrefix))) {
          await prefs.remove(key);
        }
      }
      _logger.d('[MembersCache] Cleared cache for kikoba: $kikobaId');
    } catch (e) {
      _logger.e('[MembersCache] Error clearing cache: $e');
    }
  }
}
