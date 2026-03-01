import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

/// Professional Audio Caching Service
/// Implements Spotify-style audio prefetching and caching:
/// - Multi-tier caching (memory + disk)
/// - Priority-based prefetching
/// - Bandwidth-aware downloads
/// - LRU cache eviction
/// - Background downloading
class AudioCacheService {
  static final AudioCacheService _instance = AudioCacheService._internal();
  factory AudioCacheService() => _instance;
  AudioCacheService._internal();

  // Cache configuration
  static const int _maxMemoryCacheSize = 50 * 1024 * 1024; // 50MB
  static const int _maxDiskCacheSize = 500 * 1024 * 1024; // 500MB
  static const int _maxConcurrentDownloads = 3;
  static const Duration _cacheExpiry = Duration(days: 30);

  // State
  final Map<String, Uint8List> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, _DownloadTask> _activeDownloads = {};
  final List<_PrefetchRequest> _prefetchQueue = [];
  int _currentMemoryCacheSize = 0;
  bool _isInitialized = false;
  String? _cacheDir;

  /// Initialize the cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final dir = await getTemporaryDirectory();
      _cacheDir = '${dir.path}/audio_cache';
      await Directory(_cacheDir!).create(recursive: true);

      // Clean expired cache on init
      await _cleanExpiredCache();

      _isInitialized = true;
      debugPrint('[AudioCache] Initialized at $_cacheDir');
    } catch (e) {
      debugPrint('[AudioCache] Init error: $e');
    }
  }

  /// Get cached audio file path, downloading if necessary
  Future<String?> getAudioFile(String url, {int priority = 5}) async {
    if (!_isInitialized) await initialize();

    final cacheKey = _getCacheKey(url);

    // Check memory cache first
    if (_memoryCache.containsKey(cacheKey)) {
      debugPrint('[AudioCache] Memory hit: $cacheKey');
      _updateAccessTime(cacheKey);
      return _getFilePath(cacheKey);
    }

    // Check disk cache
    final filePath = _getFilePath(cacheKey);
    final file = File(filePath);
    if (await file.exists()) {
      debugPrint('[AudioCache] Disk hit: $cacheKey');
      _updateAccessTime(cacheKey);

      // Load into memory if small enough
      final size = await file.length();
      if (size < 5 * 1024 * 1024) {
        // 5MB
        _loadToMemory(cacheKey, file);
      }

      return filePath;
    }

    // Download
    debugPrint('[AudioCache] Downloading: $url');
    return await _downloadAndCache(url, priority: priority);
  }

  /// Prefetch audio for upcoming tracks
  void prefetchAudio(String url, {int priority = 3}) {
    if (url.isEmpty) return;

    final cacheKey = _getCacheKey(url);

    // Skip if already cached or downloading
    if (_memoryCache.containsKey(cacheKey)) return;
    if (_activeDownloads.containsKey(cacheKey)) return;

    // Check disk cache
    final filePath = _getFilePath(cacheKey);
    if (File(filePath).existsSync()) return;

    // Add to prefetch queue
    _prefetchQueue.add(_PrefetchRequest(url, priority));
    _prefetchQueue.sort((a, b) => b.priority.compareTo(a.priority));

    // Process queue
    _processPrefetchQueue();
  }

  /// Prefetch multiple tracks with priority
  void prefetchTracks(List<String> urls, {int basePriority = 3}) {
    for (var i = 0; i < urls.length; i++) {
      if (urls[i].isNotEmpty) {
        prefetchAudio(urls[i], priority: basePriority - i);
      }
    }
  }

  /// Check if audio is cached
  bool isCached(String url) {
    final cacheKey = _getCacheKey(url);

    if (_memoryCache.containsKey(cacheKey)) return true;

    final filePath = _getFilePath(cacheKey);
    return File(filePath).existsSync();
  }

  /// Get cache size
  Future<int> getCacheSize() async {
    if (!_isInitialized) await initialize();

    int totalSize = _currentMemoryCacheSize;

    final dir = Directory(_cacheDir!);
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    }

    return totalSize;
  }

  /// Clear all cache
  Future<void> clearCache() async {
    _memoryCache.clear();
    _cacheTimestamps.clear();
    _currentMemoryCacheSize = 0;

    if (_cacheDir != null) {
      final dir = Directory(_cacheDir!);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
      }
    }

    debugPrint('[AudioCache] Cache cleared');
  }

  /// Cancel all active downloads
  void cancelAllDownloads() {
    for (final task in _activeDownloads.values) {
      task.cancel();
    }
    _activeDownloads.clear();
    _prefetchQueue.clear();
  }

  // Private methods

  String _getCacheKey(String url) {
    // Create a hash of the URL for the filename
    final hash = url.hashCode.abs().toString();
    final ext = url.split('.').last.split('?').first;
    return 'audio_$hash.$ext';
  }

  String _getFilePath(String cacheKey) {
    return '$_cacheDir/$cacheKey';
  }

  void _updateAccessTime(String cacheKey) {
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  Future<void> _loadToMemory(String cacheKey, File file) async {
    try {
      final bytes = await file.readAsBytes();
      final size = bytes.length;

      // Evict if needed
      while (_currentMemoryCacheSize + size > _maxMemoryCacheSize &&
          _memoryCache.isNotEmpty) {
        _evictOldestFromMemory();
      }

      _memoryCache[cacheKey] = bytes;
      _currentMemoryCacheSize += size;
      _updateAccessTime(cacheKey);
    } catch (e) {
      debugPrint('[AudioCache] Memory load error: $e');
    }
  }

  void _evictOldestFromMemory() {
    if (_memoryCache.isEmpty) return;

    // Find oldest entry
    String? oldestKey;
    DateTime? oldestTime;

    for (final key in _memoryCache.keys) {
      final time = _cacheTimestamps[key];
      if (time == null || oldestTime == null || time.isBefore(oldestTime)) {
        oldestKey = key;
        oldestTime = time;
      }
    }

    if (oldestKey != null) {
      final size = _memoryCache[oldestKey]!.length;
      _memoryCache.remove(oldestKey);
      _currentMemoryCacheSize -= size;
      debugPrint('[AudioCache] Evicted from memory: $oldestKey');
    }
  }

  Future<String?> _downloadAndCache(String url, {int priority = 5}) async {
    final cacheKey = _getCacheKey(url);
    final filePath = _getFilePath(cacheKey);

    // Check if already downloading
    if (_activeDownloads.containsKey(cacheKey)) {
      return await _activeDownloads[cacheKey]!.future;
    }

    // Start download
    final completer = Completer<String?>();
    final task = _DownloadTask(completer);
    _activeDownloads[cacheKey] = task;

    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(minutes: 5),
        onTimeout: () => throw TimeoutException('Download timeout'),
      );

      if (task.isCancelled) {
        _activeDownloads.remove(cacheKey);
        return null;
      }

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Ensure disk space
        await _ensureDiskSpace(bytes.length);

        // Save to disk
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        // Save to memory if small
        if (bytes.length < 5 * 1024 * 1024) {
          await _loadToMemory(cacheKey, file);
        }

        _updateAccessTime(cacheKey);
        debugPrint('[AudioCache] Downloaded: $cacheKey (${bytes.length} bytes)');

        completer.complete(filePath);
      } else {
        debugPrint('[AudioCache] Download failed: ${response.statusCode}');
        completer.complete(null);
      }
    } catch (e) {
      debugPrint('[AudioCache] Download error: $e');
      completer.complete(null);
    } finally {
      _activeDownloads.remove(cacheKey);
    }

    return completer.future;
  }

  void _processPrefetchQueue() {
    while (_prefetchQueue.isNotEmpty &&
        _activeDownloads.length < _maxConcurrentDownloads) {
      final request = _prefetchQueue.removeAt(0);
      _downloadAndCache(request.url, priority: request.priority);
    }
  }

  Future<void> _ensureDiskSpace(int requiredBytes) async {
    if (_cacheDir == null) return;

    final dir = Directory(_cacheDir!);
    if (!await dir.exists()) return;

    // Calculate current size and files
    final files = <File, DateTime>{};
    int totalSize = 0;

    await for (final entity in dir.list()) {
      if (entity is File) {
        final stat = await entity.stat();
        files[entity] = stat.modified;
        totalSize += stat.size;
      }
    }

    // Evict old files if needed
    while (totalSize + requiredBytes > _maxDiskCacheSize && files.isNotEmpty) {
      // Find oldest file
      File? oldestFile;
      DateTime? oldestTime;

      for (final entry in files.entries) {
        if (oldestTime == null || entry.value.isBefore(oldestTime)) {
          oldestFile = entry.key;
          oldestTime = entry.value;
        }
      }

      if (oldestFile != null) {
        final size = await oldestFile.length();
        await oldestFile.delete();
        files.remove(oldestFile);
        totalSize -= size;
        debugPrint('[AudioCache] Evicted from disk: ${oldestFile.path}');
      }
    }
  }

  Future<void> _cleanExpiredCache() async {
    if (_cacheDir == null) return;

    final dir = Directory(_cacheDir!);
    if (!await dir.exists()) return;

    final expiry = DateTime.now().subtract(_cacheExpiry);

    await for (final entity in dir.list()) {
      if (entity is File) {
        final stat = await entity.stat();
        if (stat.modified.isBefore(expiry)) {
          await entity.delete();
          debugPrint('[AudioCache] Expired: ${entity.path}');
        }
      }
    }
  }
}

/// Download task wrapper
class _DownloadTask {
  final Completer<String?> _completer;
  bool _isCancelled = false;

  _DownloadTask(this._completer);

  Future<String?> get future => _completer.future;
  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
    if (!_completer.isCompleted) {
      _completer.complete(null);
    }
  }
}

/// Prefetch request
class _PrefetchRequest {
  final String url;
  final int priority;

  _PrefetchRequest(this.url, this.priority);
}

/// Audio quality settings
enum AudioQuality {
  low(64, 'Chini'),
  normal(128, 'Kawaida'),
  high(256, 'Juu'),
  veryHigh(320, 'Juu Sana');

  final int bitrate;
  final String label;

  const AudioQuality(this.bitrate, this.label);
}

/// Network-aware audio quality selector
class AdaptiveAudioQuality {
  static AudioQuality getRecommendedQuality(NetworkType networkType) {
    switch (networkType) {
      case NetworkType.wifi:
        return AudioQuality.veryHigh;
      case NetworkType.mobile4g:
        return AudioQuality.high;
      case NetworkType.mobile3g:
        return AudioQuality.normal;
      case NetworkType.mobile2g:
      case NetworkType.offline:
        return AudioQuality.low;
    }
  }
}

enum NetworkType {
  wifi,
  mobile4g,
  mobile3g,
  mobile2g,
  offline,
}
