import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

/// Custom cache manager for media files (video, audio)
/// Provides longer cache duration and larger cache size for media
class MediaCacheManager {
  static const key = 'tajiriMediaCache';

  static CacheManager? _instance;

  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        key,
        stalePeriod: const Duration(days: 30), // Cache for 30 days
        maxNrOfCacheObjects: 1000, // Max 1000 files
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: HttpFileService(),
      ),
    );
    return _instance!;
  }

  /// Clear the entire media cache
  static Future<void> clearCache() async {
    await instance.emptyCache();
    _log('Media cache cleared');
  }

  /// Get cache size in bytes
  static Future<int> getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final mediaCacheDir = Directory('${cacheDir.path}/$key');
      if (await mediaCacheDir.exists()) {
        int size = 0;
        await for (var entity in mediaCacheDir.list(recursive: true)) {
          if (entity is File) {
            size += await entity.length();
          }
        }
        return size;
      }
    } catch (e) {
      _log('Error getting cache size: $e');
    }
    return 0;
  }

  /// Format bytes to human readable string
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Service for caching and preloading media (images, audio, and other assets).
/// Cached files are stored on disk and available for offline viewing.
/// Use [getCachedMediaPath] for playback; use with [CachedMediaImage] for images.
class MediaCacheService {
  static final MediaCacheService _instance = MediaCacheService._internal();
  factory MediaCacheService() => _instance;
  MediaCacheService._internal();

  final CacheManager _cacheManager = MediaCacheManager.instance;

  // Track ongoing downloads to avoid duplicates
  final Map<String, Future<File>> _pendingDownloads = {};

  // Track preloaded URLs
  final Set<String> _preloadedUrls = {};

  /// Get cached file or download if not cached
  /// Returns local file path for playback
  Future<String?> getCachedMediaPath(String url) async {
    if (url.isEmpty) return null;

    try {
      _log('Getting cached media: $url');

      // Check if already downloading
      if (_pendingDownloads.containsKey(url)) {
        _log('Already downloading, waiting...');
        final file = await _pendingDownloads[url];
        return file?.path;
      }

      // Start download/cache retrieval
      final downloadFuture = _cacheManager.getSingleFile(url);
      _pendingDownloads[url] = downloadFuture;

      try {
        final file = await downloadFuture;
        _log('Media cached at: ${file.path}');
        return file.path;
      } finally {
        _pendingDownloads.remove(url);
      }
    } catch (e) {
      _log('Error caching media: $e');
      // Return original URL as fallback
      return null;
    }
  }

  /// Check if media is already cached
  Future<bool> isMediaCached(String url) async {
    if (url.isEmpty) return false;
    try {
      final fileInfo = await _cacheManager.getFileFromCache(url);
      return fileInfo != null;
    } catch (e) {
      return false;
    }
  }

  /// Preload media in background (for scroll preloading)
  Future<void> preloadMedia(String url, {bool highPriority = false}) async {
    if (url.isEmpty || _preloadedUrls.contains(url)) return;

    // Check if already cached
    if (await isMediaCached(url)) {
      _preloadedUrls.add(url);
      return;
    }

    _log('Preloading media: $url');
    _preloadedUrls.add(url);

    try {
      // Use downloadFile for background preloading (doesn't block)
      if (highPriority) {
        await _cacheManager.getSingleFile(url);
      } else {
        // Low priority - don't await
        _cacheManager.downloadFile(url).then((_) {
          _log('Preload complete: $url');
        }).catchError((e) {
          _log('Preload failed: $e');
          _preloadedUrls.remove(url);
        });
      }
    } catch (e) {
      _log('Preload error: $e');
      _preloadedUrls.remove(url);
    }
  }

  /// Preload multiple media URLs (for feed preloading)
  Future<void> preloadMediaList(List<String> urls) async {
    for (final url in urls) {
      if (url.isNotEmpty && !_preloadedUrls.contains(url)) {
        preloadMedia(url);
        // Small delay to avoid overwhelming the network
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }
  }

  /// Remove specific URL from cache
  Future<void> removeFromCache(String url) async {
    try {
      await _cacheManager.removeFile(url);
      _preloadedUrls.remove(url);
      _log('Removed from cache: $url');
    } catch (e) {
      _log('Error removing from cache: $e');
    }
  }

  /// Clear all cached media
  Future<void> clearAllCache() async {
    await MediaCacheManager.clearCache();
    _preloadedUrls.clear();
    _pendingDownloads.clear();
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final size = await MediaCacheManager.getCacheSize();
    return {
      'size_bytes': size,
      'size_formatted': MediaCacheManager.formatBytes(size),
      'preloaded_count': _preloadedUrls.length,
      'pending_downloads': _pendingDownloads.length,
    };
  }
}

void _log(String message) {
  if (kDebugMode) {
    print('[MediaCache] $message');
  }
}
