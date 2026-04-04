import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../vicoba.dart';

/// Cache service for vikoba list
/// Provides instant display while fresh data loads from backend
///
/// IMPORTANT: This cache is for UI responsiveness only.
/// All actual data MUST be fetched from the backend API.
/// Firestore is used ONLY for change notifications, NOT for data.
class VikobaListCacheService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  static const String _listKeyPrefix = 'vikoba_list_';
  static const String _versionKeyPrefix = 'vikoba_version_';
  static const int _cacheExpiryMinutes = 15;

  /// Save vikoba list to cache
  static Future<void> saveVikobaList(String userId, List<vicoba> vikobaList) async {
    if (userId.isEmpty) {
      _logger.w('[VikobaListCache] Cannot save - userId is empty');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_listKeyPrefix$userId';

      final jsonList = vikobaList.map((v) => v.toJson()).toList();
      final cacheData = {
        'data': jsonList,
        'cachedAt': DateTime.now().toIso8601String(),
      };

      await prefs.setString(cacheKey, jsonEncode(cacheData));
      _logger.d('[VikobaListCache] Saved ${vikobaList.length} vikobas for user: $userId');
    } catch (e) {
      _logger.e('[VikobaListCache] Error saving cache: $e');
    }
  }

  /// Get cached vikoba list
  static Future<List<vicoba>?> getVikobaList(String userId) async {
    if (userId.isEmpty) {
      _logger.w('[VikobaListCache] Cannot get - userId is empty');
      return null;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_listKeyPrefix$userId';
      final cached = prefs.getString(cacheKey);

      if (cached == null) {
        _logger.d('[VikobaListCache] No cache found for user: $userId');
        return null;
      }

      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(decoded['cachedAt'] as String);
      final age = DateTime.now().difference(cachedAt);

      if (age.inMinutes > _cacheExpiryMinutes) {
        _logger.d('[VikobaListCache] Cache expired (${age.inMinutes} min old)');
        return null;
      }

      final jsonList = decoded['data'] as List<dynamic>;
      final vikobaList = jsonList
          .map((json) => vicoba.fromJson(json as Map<String, dynamic>))
          .toList();

      _logger.d('[VikobaListCache] Loaded ${vikobaList.length} vikobas from cache (${age.inMinutes} min old)');
      return vikobaList;
    } catch (e) {
      _logger.e('[VikobaListCache] Error reading cache: $e');
      return null;
    }
  }

  /// Save version for change detection
  static Future<void> saveVersion(String userId, int version) async {
    if (userId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_versionKeyPrefix$userId';
      await prefs.setInt(key, version);
      _logger.d('[VikobaListCache] Saved version: $version for user: $userId');
    } catch (e) {
      _logger.e('[VikobaListCache] Error saving version: $e');
    }
  }

  /// Get last known version
  static Future<int?> getVersion(String userId) async {
    if (userId.isEmpty) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_versionKeyPrefix$userId';
      return prefs.getInt(key);
    } catch (e) {
      _logger.e('[VikobaListCache] Error reading version: $e');
      return null;
    }
  }

  /// Clear cache for user
  static Future<void> clearCache(String userId) async {
    if (userId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final listKey = '$_listKeyPrefix$userId';
      final versionKey = '$_versionKeyPrefix$userId';

      await prefs.remove(listKey);
      await prefs.remove(versionKey);

      _logger.d('[VikobaListCache] Cleared cache for user: $userId');
    } catch (e) {
      _logger.e('[VikobaListCache] Error clearing cache: $e');
    }
  }

  /// Check if cache exists and is valid
  static Future<bool> hasCachedData(String userId) async {
    if (userId.isEmpty) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_listKeyPrefix$userId';
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
}
