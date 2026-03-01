import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import '../models/clip_models.dart';

/// YouTube-style Video Cache Service for offline viewing.
/// Cached videos are stored on disk and played from local path when available.
/// Implements:
/// - LRU (Least Recently Used) cache eviction
/// - Priority-based preloading (current ±2 videos)
/// - Network-aware quality selection
/// - Background downloading
/// - Buffer health monitoring
/// - Concurrent download management
class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();

  // ============================================================================
  // Configuration
  // ============================================================================

  /// Maximum cache size in bytes (500 MB default)
  static const int maxCacheSizeBytes = 500 * 1024 * 1024;

  /// Maximum number of cached videos
  static const int maxCachedVideos = 50;

  /// Number of concurrent downloads allowed
  static const int maxConcurrentDownloads = 3;

  /// Preload window: videos to preload ahead/behind current
  static const int preloadAhead = 2;
  static const int preloadBehind = 1;

  /// Minimum buffer health in seconds before quality downgrade
  static const double minBufferHealth = 3.0;

  // ============================================================================
  // State
  // ============================================================================

  /// LRU cache tracking (URL -> cache entry)
  final LinkedHashMap<String, VideoCacheEntry> _lruCache = LinkedHashMap();

  /// Active downloads (URL -> download future)
  final Map<String, _DownloadTask> _activeDownloads = {};

  /// Download queue with priorities
  final List<_DownloadTask> _downloadQueue = [];

  /// Preload states for clips
  final Map<int, VideoPreloadInfo> _preloadStates = {};

  /// VideoPlayerController cache (for instant playback)
  final Map<String, VideoPlayerController> _controllerCache = {};

  /// Current network type
  NetworkType _networkType = NetworkType.unknown;

  /// Current quality preference
  VideoQuality _qualityPreference = VideoQuality.auto;

  /// Cache manager instance
  late final CacheManager _cacheManager;

  /// Initialization flag
  bool _initialized = false;

  // ============================================================================
  // Initialization
  // ============================================================================

  /// Initialize the video cache service (called lazily if not yet initialized).
  Future<void> initialize() async {
    if (_initialized) return;

    _cacheManager = CacheManager(
      Config(
        'tajiriVideoCache',
        stalePeriod: const Duration(days: 7),
        maxNrOfCacheObjects: maxCachedVideos,
        repo: JsonCacheInfoRepository(databaseName: 'tajiriVideoCache'),
        fileService: HttpFileService(),
      ),
    );

    // Load existing cache entries
    await _loadCacheIndex();

    _initialized = true;
    _log('VideoCacheService initialized');
  }

  /// Load cache index from disk
  Future<void> _loadCacheIndex() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final indexFile = File('${cacheDir.path}/video_cache_index.json');

      if (await indexFile.exists()) {
        // Load and restore LRU order
        // For now, we'll rebuild on first access
      }
    } catch (e) {
      _log('Error loading cache index: $e');
    }
  }

  // ============================================================================
  // Video Controller Management (YouTube-style instant playback)
  // ============================================================================

  /// Get or create VideoPlayerController for a clip (uses cache for offline playback).
  Future<VideoPlayerController> getControllerForClip(Clip clip) async {
    if (!_initialized) await initialize();

    final url = clip.videoUrl;

    // Check if we have a cached controller
    if (_controllerCache.containsKey(url)) {
      final controller = _controllerCache[url]!;
      if (controller.value.isInitialized) {
        _log('Returning cached controller for clip ${clip.id}');
        _touchCache(url);
        return controller;
      } else {
        // Controller exists but not initialized, dispose and recreate
        await controller.dispose();
        _controllerCache.remove(url);
      }
    }

    // Check if video is cached locally
    final cachedPath = await getCachedVideoPath(url);

    VideoPlayerController controller;
    if (cachedPath != null) {
      _log('Creating controller from cache for clip ${clip.id}');
      controller = VideoPlayerController.file(File(cachedPath));
    } else {
      _log('Creating network controller for clip ${clip.id}');
      controller = VideoPlayerController.networkUrl(Uri.parse(url));

      // Start caching in background
      _queueDownload(clip.id, url, priority: 10);
    }

    // Initialize controller
    await controller.initialize();

    // Cache the controller
    _controllerCache[url] = controller;

    // Manage controller cache size
    _evictOldControllers();

    return controller;
  }

  /// Dispose controller for a clip
  Future<void> disposeController(String url) async {
    if (_controllerCache.containsKey(url)) {
      await _controllerCache[url]!.dispose();
      _controllerCache.remove(url);
      _log('Disposed controller for $url');
    }
  }

  /// Evict old controllers to prevent memory issues
  void _evictOldControllers() {
    const maxControllers = 5;

    if (_controllerCache.length > maxControllers) {
      final toRemove = _controllerCache.length - maxControllers;
      final keys = _controllerCache.keys.toList();

      for (var i = 0; i < toRemove; i++) {
        final key = keys[i];
        _controllerCache[key]?.dispose();
        _controllerCache.remove(key);
      }

      _log('Evicted $toRemove controllers');
    }
  }

  // ============================================================================
  // Cache Management (LRU)
  // ============================================================================

  /// Get cached video path if available (for offline playback).
  Future<String?> getCachedVideoPath(String url) async {
    if (url.isEmpty) return null;

    if (!_initialized) await initialize();

    try {
      final fileInfo = await _cacheManager.getFileFromCache(url);
      if (fileInfo != null) {
        _touchCache(url);
        return fileInfo.file.path;
      }
    } catch (e) {
      _log('Error getting cached video: $e');
    }
    return null;
  }

  /// Check if video is cached (for offline viewing).
  Future<bool> isVideoCached(String url) async {
    if (url.isEmpty) return false;
    if (!_initialized) await initialize();
    try {
      final fileInfo = await _cacheManager.getFileFromCache(url);
      return fileInfo != null;
    } catch (e) {
      return false;
    }
  }

  /// Touch cache entry (move to end of LRU)
  void _touchCache(String url) {
    if (_lruCache.containsKey(url)) {
      final entry = _lruCache.remove(url)!;
      _lruCache[url] = entry.touch();
    }
  }

  /// Evict least recently used entries if cache is full
  Future<void> _evictIfNeeded() async {
    // Check cache size
    int totalSize = 0;
    for (final entry in _lruCache.values) {
      totalSize += entry.fileSize;
    }

    // Evict until under limit
    while ((totalSize > maxCacheSizeBytes || _lruCache.length > maxCachedVideos) &&
        _lruCache.isNotEmpty) {
      final oldestKey = _lruCache.keys.first;
      final oldestEntry = _lruCache.remove(oldestKey)!;
      totalSize -= oldestEntry.fileSize;

      // Remove from cache manager
      await _cacheManager.removeFile(oldestKey);

      _log('Evicted LRU entry: $oldestKey (${oldestEntry.fileSizeMB.toStringAsFixed(1)} MB)');
    }
  }

  // ============================================================================
  // Preloading (YouTube-style prefetching)
  // ============================================================================

  /// Preload videos around current index
  Future<void> preloadForFeed(List<Clip> clips, int currentIndex) async {
    if (clips.isEmpty) return;

    // Calculate preload range
    final startIdx = (currentIndex - preloadBehind).clamp(0, clips.length - 1);
    final endIdx = (currentIndex + preloadAhead).clamp(0, clips.length - 1);

    // Assign priorities (current = highest)
    for (var i = startIdx; i <= endIdx; i++) {
      final clip = clips[i];
      final priority = 10 - (i - currentIndex).abs();

      _queueDownload(clip.id, clip.videoUrl, priority: priority);
    }
  }

  /// Queue a video for download
  void _queueDownload(int clipId, String url, {int priority = 0}) {
    // Skip if already downloading or cached
    if (_activeDownloads.containsKey(url)) return;
    if (_downloadQueue.any((t) => t.url == url)) return;

    final task = _DownloadTask(
      clipId: clipId,
      url: url,
      priority: priority,
    );

    _downloadQueue.add(task);
    _downloadQueue.sort((a, b) => b.priority.compareTo(a.priority));

    _updatePreloadState(clipId, url, PreloadState.queued);

    // Process queue
    _processDownloadQueue();
  }

  /// Process download queue
  Future<void> _processDownloadQueue() async {
    if (!_initialized) await initialize();

    while (_activeDownloads.length < maxConcurrentDownloads &&
        _downloadQueue.isNotEmpty) {
      final task = _downloadQueue.removeAt(0);

      // Check if already cached
      if (await isVideoCached(task.url)) {
        _updatePreloadState(task.clipId, task.url, PreloadState.complete);
        continue;
      }

      _startDownload(task);
    }
  }

  /// Start downloading a video
  Future<void> _startDownload(_DownloadTask task) async {
    _activeDownloads[task.url] = task;
    _updatePreloadState(task.clipId, task.url, PreloadState.loading,
        startedAt: DateTime.now());

    _log('Starting download: ${task.url} (priority: ${task.priority})');

    try {
      final file = await _cacheManager.getSingleFile(
        task.url,
        headers: {
          'Accept': 'video/*',
        },
      );

      // Add to LRU cache
      final fileSize = await file.length();
      _lruCache[task.url] = VideoCacheEntry(
        url: task.url,
        localPath: file.path,
        fileSize: fileSize,
        cachedAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
        clipId: task.clipId,
      );

      _updatePreloadState(task.clipId, task.url, PreloadState.complete);
      _log('Download complete: ${task.url} (${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB)');

      // Evict old entries if needed
      await _evictIfNeeded();
    } catch (e) {
      _log('Download failed: ${task.url} - $e');
      _updatePreloadState(task.clipId, task.url, PreloadState.failed, error: e.toString());
    } finally {
      _activeDownloads.remove(task.url);
      _processDownloadQueue();
    }
  }

  /// Update preload state for a clip
  void _updatePreloadState(
    int clipId,
    String url,
    PreloadState state, {
    double progress = 0.0,
    int bytesLoaded = 0,
    DateTime? startedAt,
    String? error,
  }) {
    final current = _preloadStates[clipId];
    _preloadStates[clipId] = VideoPreloadInfo(
      clipId: clipId,
      url: url,
      state: state,
      progress: progress,
      bytesLoaded: bytesLoaded,
      startedAt: startedAt ?? current?.startedAt,
      error: error,
    );
  }

  /// Get preload state for a clip
  VideoPreloadInfo? getPreloadState(int clipId) => _preloadStates[clipId];

  /// Get all preload states
  Map<int, VideoPreloadInfo> get preloadStates => Map.unmodifiable(_preloadStates);

  // ============================================================================
  // Network-Aware Quality Selection
  // ============================================================================

  /// Update current network type
  void updateNetworkType(NetworkType type) {
    _networkType = type;
    _log('Network type updated: $type');
  }

  /// Get recommended quality based on network
  VideoQuality getRecommendedQuality() {
    if (_qualityPreference != VideoQuality.auto) {
      return _qualityPreference;
    }
    return _networkType.recommendedQuality;
  }

  /// Set quality preference
  void setQualityPreference(VideoQuality quality) {
    _qualityPreference = quality;
    _log('Quality preference set: $quality');
  }

  // ============================================================================
  // Buffer Health Monitoring
  // ============================================================================

  /// Calculate buffer health for a controller
  VideoBufferState getBufferState(VideoPlayerController controller) {
    if (!controller.value.isInitialized) {
      return VideoBufferState();
    }

    final buffered = controller.value.buffered;
    final position = controller.value.position;
    final duration = controller.value.duration;

    Duration bufferedPosition = Duration.zero;
    if (buffered.isNotEmpty) {
      // Find buffered range containing current position
      for (final range in buffered) {
        if (range.start <= position && range.end > position) {
          bufferedPosition = range.end;
          break;
        }
        if (range.end > bufferedPosition) {
          bufferedPosition = range.end;
        }
      }
    }

    final bufferHealth =
        (bufferedPosition - position).inMilliseconds / 1000.0;

    return VideoBufferState(
      bufferedPosition: bufferedPosition,
      currentPosition: position,
      totalDuration: duration,
      isBuffering: controller.value.isBuffering,
      bufferHealth: bufferHealth.clamp(0.0, double.infinity),
    );
  }

  // ============================================================================
  // Cache Statistics
  // ============================================================================

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    int totalSize = 0;
    for (final entry in _lruCache.values) {
      totalSize += entry.fileSize;
    }

    return {
      'cached_videos': _lruCache.length,
      'total_size_bytes': totalSize,
      'total_size_mb': (totalSize / 1024 / 1024).toStringAsFixed(1),
      'max_size_mb': (maxCacheSizeBytes / 1024 / 1024).toStringAsFixed(0),
      'active_downloads': _activeDownloads.length,
      'queued_downloads': _downloadQueue.length,
      'cached_controllers': _controllerCache.length,
      'network_type': _networkType.name,
      'quality_preference': _qualityPreference.label,
    };
  }

  /// Clear all video cache
  Future<void> clearCache() async {
    // Dispose all controllers
    for (final controller in _controllerCache.values) {
      await controller.dispose();
    }
    _controllerCache.clear();

    if (!_initialized) return;

    // Clear cache manager
    await _cacheManager.emptyCache();

    // Clear state
    _lruCache.clear();
    _preloadStates.clear();
    _downloadQueue.clear();

    _log('Video cache cleared');
  }

  /// Dispose service
  Future<void> dispose() async {
    await clearCache();
    _initialized = false;
  }
}

/// Internal download task
class _DownloadTask {
  final int clipId;
  final String url;
  final int priority;
  final DateTime createdAt;

  _DownloadTask({
    required this.clipId,
    required this.url,
    this.priority = 0,
  }) : createdAt = DateTime.now();
}

void _log(String message) {
  if (kDebugMode) {
    debugPrint('[VideoCache] $message');
  }
}
