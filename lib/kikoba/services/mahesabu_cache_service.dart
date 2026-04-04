import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// Local cache service for mahesabu (reports) data
/// Provides instant display while fresh data loads from backend
class MahesabuCacheService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  static const String _summaryKeyPrefix = 'mahesabu_summary_';
  static const String _reportKeyPrefix = 'mahesabu_report_';
  static const String _versionKeyPrefix = 'mahesabu_version_';
  static const int _summaryCacheExpiryMinutes = 30; // Summary valid for 30 min
  static const int _reportCacheExpiryMinutes = 15; // Individual reports valid for 15 min

  /// Save summary data (full statement) to local cache
  static Future<void> saveSummary(String kikobaId, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'cachedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString('$_summaryKeyPrefix$kikobaId', jsonEncode(cacheData));
      _logger.d('[MahesabuCache] Saved summary cache for kikoba: $kikobaId');
    } catch (e) {
      _logger.e('[MahesabuCache] Error saving summary cache: $e');
    }
  }

  /// Get cached summary data if available and not expired
  static Future<Map<String, dynamic>?> getSummary(String kikobaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('$_summaryKeyPrefix$kikobaId');

      if (cached == null) {
        _logger.d('[MahesabuCache] No summary cache found for kikoba: $kikobaId');
        return null;
      }

      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(decoded['cachedAt'] as String);
      final age = DateTime.now().difference(cachedAt);

      if (age.inMinutes > _summaryCacheExpiryMinutes) {
        _logger.d('[MahesabuCache] Summary cache expired (${age.inMinutes} min old)');
        return null;
      }

      _logger.d('[MahesabuCache] Using cached summary (${age.inMinutes} min old)');
      return decoded['data'] as Map<String, dynamic>;
    } catch (e) {
      _logger.e('[MahesabuCache] Error reading summary cache: $e');
      return null;
    }
  }

  /// Save individual report data to local cache
  /// Key includes reportType and dateRange for uniqueness
  static Future<void> saveReport({
    required String kikobaId,
    required String reportType,
    required String startDate,
    required String endDate,
    required Map<String, dynamic> data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _buildReportKey(kikobaId, reportType, startDate, endDate);
      final cacheData = {
        'data': data,
        'cachedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(cacheKey, jsonEncode(cacheData));
      _logger.d('[MahesabuCache] Saved report cache: $reportType ($startDate to $endDate)');
    } catch (e) {
      _logger.e('[MahesabuCache] Error saving report cache: $e');
    }
  }

  /// Get cached report data if available and not expired
  static Future<Map<String, dynamic>?> getReport({
    required String kikobaId,
    required String reportType,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _buildReportKey(kikobaId, reportType, startDate, endDate);
      final cached = prefs.getString(cacheKey);

      if (cached == null) {
        return null;
      }

      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(decoded['cachedAt'] as String);
      final age = DateTime.now().difference(cachedAt);

      if (age.inMinutes > _reportCacheExpiryMinutes) {
        _logger.d('[MahesabuCache] Report cache expired (${age.inMinutes} min old)');
        return null;
      }

      _logger.d('[MahesabuCache] Using cached report: $reportType (${age.inMinutes} min old)');
      return decoded['data'] as Map<String, dynamic>;
    } catch (e) {
      _logger.e('[MahesabuCache] Error reading report cache: $e');
      return null;
    }
  }

  /// Build cache key for individual reports
  static String _buildReportKey(
    String kikobaId,
    String reportType,
    String startDate,
    String endDate,
  ) {
    return '$_reportKeyPrefix${kikobaId}_${reportType}_${startDate}_$endDate';
  }

  /// Save the last known version from Firestore
  static Future<void> saveVersion(String kikobaId, int version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_versionKeyPrefix$kikobaId', version);
      _logger.d('[MahesabuCache] Saved version $version for kikoba: $kikobaId');
    } catch (e) {
      _logger.e('[MahesabuCache] Error saving version: $e');
    }
  }

  /// Get the last known version
  static Future<int?> getVersion(String kikobaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('$_versionKeyPrefix$kikobaId');
    } catch (e) {
      _logger.e('[MahesabuCache] Error reading version: $e');
      return null;
    }
  }

  /// Clear all caches for a specific kikoba (when notified of data change)
  static Future<void> clearCache(String kikobaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.contains(kikobaId) &&
            (key.startsWith(_summaryKeyPrefix) ||
                key.startsWith(_reportKeyPrefix) ||
                key.startsWith(_versionKeyPrefix))) {
          await prefs.remove(key);
        }
      }
      _logger.d('[MahesabuCache] Cleared all caches for kikoba: $kikobaId');
    } catch (e) {
      _logger.e('[MahesabuCache] Error clearing cache: $e');
    }
  }

  /// Clear only report caches (keep summary)
  static Future<void> clearReportCaches(String kikobaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.contains(kikobaId) && key.startsWith(_reportKeyPrefix)) {
          await prefs.remove(key);
        }
      }
      _logger.d('[MahesabuCache] Cleared report caches for kikoba: $kikobaId');
    } catch (e) {
      _logger.e('[MahesabuCache] Error clearing report caches: $e');
    }
  }
}
