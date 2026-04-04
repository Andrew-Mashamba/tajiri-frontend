import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// Unified local cache service for all pages
/// Provides instant display while fresh data loads from backend
///
/// IMPORTANT: This cache is for UI responsiveness only.
/// All actual data MUST be fetched from the backend API.
/// Firestore is used ONLY for change notifications, NOT for data.
class PageCacheService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  // Cache key prefixes for different page types
  static const String _adaKeyPrefix = 'page_ada_';
  static const String _hisaKeyPrefix = 'page_hisa_';
  static const String _akibaKeyPrefix = 'page_akiba_';
  static const String _loansKeyPrefix = 'page_loans_';
  static const String _mikopoKeyPrefix = 'page_mikopo_';
  static const String _udhaminiKeyPrefix = 'page_udhamini_';
  static const String _michangoKeyPrefix = 'page_michango_';
  static const String _uongoziKeyPrefix = 'page_uongozi_';
  static const String _versionKeyPrefix = 'page_version_';

  // Cache expiry times (in minutes) - shorter for frequently changing data
  static const int _defaultCacheExpiryMinutes = 15;
  static const int _financialCacheExpiryMinutes = 10; // Financial data changes more often

  /// Generic method to save page data to cache
  static Future<void> savePageData({
    required String pageType,
    required String visitorId,
    required String kikobaId,
    required Map<String, dynamic> data,
    String? subKey, // For pages with multiple data types (e.g., tabs)
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _buildCacheKey(pageType, visitorId, kikobaId, subKey);
      final cacheData = {
        'data': data,
        'cachedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(cacheKey, jsonEncode(cacheData));
      _logger.d('[PageCache] Saved $pageType cache for visitor: $visitorId, kikoba: $kikobaId${subKey != null ? ', subKey: $subKey' : ''}');
    } catch (e) {
      _logger.e('[PageCache] Error saving $pageType cache: $e');
    }
  }

  /// Generic method to get cached page data
  static Future<Map<String, dynamic>?> getPageData({
    required String pageType,
    required String visitorId,
    required String kikobaId,
    String? subKey,
    int? customExpiryMinutes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _buildCacheKey(pageType, visitorId, kikobaId, subKey);
      final cached = prefs.getString(cacheKey);

      if (cached == null) {
        _logger.d('[PageCache] No $pageType cache found');
        return null;
      }

      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(decoded['cachedAt'] as String);
      final age = DateTime.now().difference(cachedAt);

      final expiryMinutes = customExpiryMinutes ?? _getExpiryMinutes(pageType);
      if (age.inMinutes > expiryMinutes) {
        _logger.d('[PageCache] $pageType cache expired (${age.inMinutes} min old)');
        return null;
      }

      _logger.d('[PageCache] Using cached $pageType (${age.inMinutes} min old)');
      return decoded['data'] as Map<String, dynamic>;
    } catch (e) {
      _logger.e('[PageCache] Error reading $pageType cache: $e');
      return null;
    }
  }

  /// Save version for a specific page type
  static Future<void> saveVersion({
    required String pageType,
    required String visitorId,
    required String kikobaId,
    required int version,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_versionKeyPrefix}${pageType}_${visitorId}_$kikobaId';
      await prefs.setInt(key, version);
      _logger.d('[PageCache] Saved $pageType version: $version');
    } catch (e) {
      _logger.e('[PageCache] Error saving $pageType version: $e');
    }
  }

  /// Get last known version for a specific page type
  static Future<int?> getVersion({
    required String pageType,
    required String visitorId,
    required String kikobaId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_versionKeyPrefix}${pageType}_${visitorId}_$kikobaId';
      return prefs.getInt(key);
    } catch (e) {
      _logger.e('[PageCache] Error reading $pageType version: $e');
      return null;
    }
  }

  /// Clear cache for a specific page type
  static Future<void> clearPageCache({
    required String pageType,
    required String visitorId,
    required String kikobaId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final prefix = _getKeyPrefix(pageType);

      for (final key in keys) {
        if (key.contains(visitorId) && key.contains(kikobaId) &&
            (key.startsWith(prefix) || key.startsWith('${_versionKeyPrefix}$pageType'))) {
          await prefs.remove(key);
        }
      }
      _logger.d('[PageCache] Cleared $pageType cache for visitor: $visitorId, kikoba: $kikobaId');
    } catch (e) {
      _logger.e('[PageCache] Error clearing $pageType cache: $e');
    }
  }

  /// Clear all caches for a kikoba (use when user logs out or switches kikoba)
  static Future<void> clearAllCaches({
    required String visitorId,
    required String kikobaId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.contains(visitorId) && key.contains(kikobaId) &&
            (key.startsWith('page_') || key.startsWith(_versionKeyPrefix))) {
          await prefs.remove(key);
        }
      }
      _logger.d('[PageCache] Cleared ALL page caches for visitor: $visitorId, kikoba: $kikobaId');
    } catch (e) {
      _logger.e('[PageCache] Error clearing all caches: $e');
    }
  }

  /// Build cache key based on page type and identifiers
  static String _buildCacheKey(String pageType, String visitorId, String kikobaId, String? subKey) {
    final prefix = _getKeyPrefix(pageType);
    if (subKey != null) {
      return '$prefix${visitorId}_${kikobaId}_$subKey';
    }
    return '$prefix${visitorId}_$kikobaId';
  }

  /// Get key prefix for page type
  static String _getKeyPrefix(String pageType) {
    switch (pageType) {
      case 'ada':
        return _adaKeyPrefix;
      case 'hisa':
        return _hisaKeyPrefix;
      case 'akiba':
        return _akibaKeyPrefix;
      case 'loans':
        return _loansKeyPrefix;
      case 'mikopo':
        return _mikopoKeyPrefix;
      case 'udhamini':
        return _udhaminiKeyPrefix;
      case 'michango':
        return _michangoKeyPrefix;
      case 'uongozi':
        return _uongoziKeyPrefix;
      default:
        return 'page_${pageType}_';
    }
  }

  /// Get cache expiry time based on page type
  static int _getExpiryMinutes(String pageType) {
    switch (pageType) {
      case 'ada':
      case 'hisa':
      case 'akiba':
      case 'loans':
      case 'mikopo':
        return _financialCacheExpiryMinutes; // Financial data - 10 min
      case 'udhamini':
      case 'michango':
      case 'uongozi':
        return _defaultCacheExpiryMinutes; // Other data - 15 min
      default:
        return _defaultCacheExpiryMinutes;
    }
  }

  // ============ Convenience methods for specific page types ============

  /// Ada page cache methods
  static Future<void> saveAdaData(String visitorId, String kikobaId, Map<String, dynamic> data) =>
      savePageData(pageType: 'ada', visitorId: visitorId, kikobaId: kikobaId, data: data);

  static Future<Map<String, dynamic>?> getAdaData(String visitorId, String kikobaId) =>
      getPageData(pageType: 'ada', visitorId: visitorId, kikobaId: kikobaId);

  /// Hisa page cache methods
  static Future<void> saveHisaData(String visitorId, String kikobaId, Map<String, dynamic> data) =>
      savePageData(pageType: 'hisa', visitorId: visitorId, kikobaId: kikobaId, data: data);

  static Future<Map<String, dynamic>?> getHisaData(String visitorId, String kikobaId) =>
      getPageData(pageType: 'hisa', visitorId: visitorId, kikobaId: kikobaId);

  /// Akiba page cache methods
  static Future<void> saveAkibaData(String visitorId, String kikobaId, Map<String, dynamic> data) =>
      savePageData(pageType: 'akiba', visitorId: visitorId, kikobaId: kikobaId, data: data);

  static Future<Map<String, dynamic>?> getAkibaData(String visitorId, String kikobaId) =>
      getPageData(pageType: 'akiba', visitorId: visitorId, kikobaId: kikobaId);

  /// Loans page cache methods
  static Future<void> saveLoansData(String visitorId, String kikobaId, Map<String, dynamic> data) =>
      savePageData(pageType: 'loans', visitorId: visitorId, kikobaId: kikobaId, data: data);

  static Future<Map<String, dynamic>?> getLoansData(String visitorId, String kikobaId) =>
      getPageData(pageType: 'loans', visitorId: visitorId, kikobaId: kikobaId);

  /// Mikopo page cache methods
  static Future<void> saveMikopoData(String visitorId, String kikobaId, Map<String, dynamic> data) =>
      savePageData(pageType: 'mikopo', visitorId: visitorId, kikobaId: kikobaId, data: data);

  static Future<Map<String, dynamic>?> getMikopoData(String visitorId, String kikobaId) =>
      getPageData(pageType: 'mikopo', visitorId: visitorId, kikobaId: kikobaId);

  /// Udhamini page cache methods
  static Future<void> saveUdhaminiData(String visitorId, String kikobaId, Map<String, dynamic> data, {String? tabKey}) =>
      savePageData(pageType: 'udhamini', visitorId: visitorId, kikobaId: kikobaId, data: data, subKey: tabKey);

  static Future<Map<String, dynamic>?> getUdhaminiData(String visitorId, String kikobaId, {String? tabKey}) =>
      getPageData(pageType: 'udhamini', visitorId: visitorId, kikobaId: kikobaId, subKey: tabKey);

  /// Michango page cache methods
  static Future<void> saveMichangoData(String visitorId, String kikobaId, Map<String, dynamic> data) =>
      savePageData(pageType: 'michango', visitorId: visitorId, kikobaId: kikobaId, data: data);

  static Future<Map<String, dynamic>?> getMichangoData(String visitorId, String kikobaId) =>
      getPageData(pageType: 'michango', visitorId: visitorId, kikobaId: kikobaId);

  /// Uongozi page cache methods
  static Future<void> saveUongoziData(String visitorId, String kikobaId, Map<String, dynamic> data, {String? tabKey}) =>
      savePageData(pageType: 'uongozi', visitorId: visitorId, kikobaId: kikobaId, data: data, subKey: tabKey);

  static Future<Map<String, dynamic>?> getUongoziData(String visitorId, String kikobaId, {String? tabKey}) =>
      getPageData(pageType: 'uongozi', visitorId: visitorId, kikobaId: kikobaId, subKey: tabKey);
}
