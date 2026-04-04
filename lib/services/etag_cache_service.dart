import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive-backed ETag cache for HTTP conditional requests.
/// Stores ETags and response bodies. On repeat requests, sends If-None-Match
/// and uses cached body when server returns 304 Not Modified.
class ETagCacheService {
  ETagCacheService._();
  static final ETagCacheService instance = ETagCacheService._();

  static const String _boxName = 'etag_cache';

  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    _box ??= await Hive.openBox<String>(_boxName);
    return _box!;
  }

  String _etagKey(String url) => 'etag_$url';
  String _bodyKey(String url) => 'body_$url';

  /// Get the cached ETag for a URL (to send as If-None-Match).
  Future<String?> getETag(String url) async {
    try {
      final box = await _getBox();
      return box.get(_etagKey(url));
    } catch (_) {
      return null;
    }
  }

  /// Get the cached response body for a URL (used on 304).
  Future<String?> getCachedBody(String url) async {
    try {
      final box = await _getBox();
      return box.get(_bodyKey(url));
    } catch (_) {
      return null;
    }
  }

  /// Store ETag and response body for a URL.
  Future<void> store(String url, String etag, String body) async {
    try {
      final box = await _getBox();
      await box.put(_etagKey(url), etag);
      await box.put(_bodyKey(url), body);
      if (kDebugMode) debugPrint('[ETagCache] Stored ETag for $url');
    } catch (e) {
      if (kDebugMode) debugPrint('[ETagCache] Store error: $e');
    }
  }

  /// Remove cached data for a URL.
  Future<void> invalidate(String url) async {
    try {
      final box = await _getBox();
      await box.delete(_etagKey(url));
      await box.delete(_bodyKey(url));
    } catch (_) {}
  }

  /// Clear all ETag caches.
  Future<void> clear() async {
    try {
      final box = await _getBox();
      await box.clear();
      if (kDebugMode) debugPrint('[ETagCache] Cleared all ETag caches');
    } catch (_) {}
  }
}
