import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// Local cache service for dashboard data
/// Provides instant display while fresh data loads from backend
class DashboardCacheService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  static const String _summaryKeyPrefix = 'dashboard_summary_';
  static const String _memberDataKeyPrefix = 'dashboard_member_';
  static const String _versionKeyPrefix = 'dashboard_version_';
  static const int _cacheExpiryMinutes = 10; // Dashboard data changes frequently

  /// Save dashboard summary data to local cache
  static Future<void> saveSummary(String visitorId, String kikobaId, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_summaryKeyPrefix${visitorId}_$kikobaId';
      final cacheData = {
        'data': data,
        'cachedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(cacheKey, jsonEncode(cacheData));
      _logger.d('[DashboardCache] Saved summary cache for visitor: $visitorId, kikoba: $kikobaId');
    } catch (e) {
      _logger.e('[DashboardCache] Error saving summary cache: $e');
    }
  }

  /// Get cached dashboard summary data if available and not expired
  static Future<Map<String, dynamic>?> getSummary(String visitorId, String kikobaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_summaryKeyPrefix${visitorId}_$kikobaId';
      final cached = prefs.getString(cacheKey);

      if (cached == null) {
        _logger.d('[DashboardCache] No summary cache found');
        return null;
      }

      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(decoded['cachedAt'] as String);
      final age = DateTime.now().difference(cachedAt);

      if (age.inMinutes > _cacheExpiryMinutes) {
        _logger.d('[DashboardCache] Summary cache expired (${age.inMinutes} min old)');
        return null;
      }

      _logger.d('[DashboardCache] Using cached summary (${age.inMinutes} min old)');
      return decoded['data'] as Map<String, dynamic>;
    } catch (e) {
      _logger.e('[DashboardCache] Error reading summary cache: $e');
      return null;
    }
  }

  /// Save member financial data (ada, hisa, akiba lists) to cache
  static Future<void> saveMemberData(String visitorId, String kikobaId, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_memberDataKeyPrefix${visitorId}_$kikobaId';
      final cacheData = {
        'data': data,
        'cachedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(cacheKey, jsonEncode(cacheData));
      _logger.d('[DashboardCache] Saved member data cache');
    } catch (e) {
      _logger.e('[DashboardCache] Error saving member data cache: $e');
    }
  }

  /// Get cached member financial data
  static Future<Map<String, dynamic>?> getMemberData(String visitorId, String kikobaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_memberDataKeyPrefix${visitorId}_$kikobaId';
      final cached = prefs.getString(cacheKey);

      if (cached == null) return null;

      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(decoded['cachedAt'] as String);
      final age = DateTime.now().difference(cachedAt);

      if (age.inMinutes > _cacheExpiryMinutes) {
        return null;
      }

      return decoded['data'] as Map<String, dynamic>;
    } catch (e) {
      _logger.e('[DashboardCache] Error reading member data cache: $e');
      return null;
    }
  }

  /// Save the last known version from Firestore
  static Future<void> saveVersion(String visitorId, String kikobaId, int version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_versionKeyPrefix${visitorId}_$kikobaId';
      await prefs.setInt(key, version);
      _logger.d('[DashboardCache] Saved version $version');
    } catch (e) {
      _logger.e('[DashboardCache] Error saving version: $e');
    }
  }

  /// Get the last known version
  static Future<int?> getVersion(String visitorId, String kikobaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_versionKeyPrefix${visitorId}_$kikobaId';
      return prefs.getInt(key);
    } catch (e) {
      _logger.e('[DashboardCache] Error reading version: $e');
      return null;
    }
  }

  /// Clear all caches for a specific visitor/kikoba
  static Future<void> clearCache(String visitorId, String kikobaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.contains(visitorId) && key.contains(kikobaId) &&
            (key.startsWith(_summaryKeyPrefix) ||
                key.startsWith(_memberDataKeyPrefix) ||
                key.startsWith(_versionKeyPrefix))) {
          await prefs.remove(key);
        }
      }
      _logger.d('[DashboardCache] Cleared all caches for visitor: $visitorId, kikoba: $kikobaId');
    } catch (e) {
      _logger.e('[DashboardCache] Error clearing cache: $e');
    }
  }
}
