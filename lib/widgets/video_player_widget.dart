import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../models/ad_models.dart';
import '../models/clip_models.dart';
import '../services/ad_service.dart';
import '../services/local_storage_service.dart';
import '../services/media_cache_service.dart';
import '../services/video_cache_service.dart';
import 'cached_media_image.dart';
import 'video_preroll_overlay.dart';

/// Debug logger for video player
void _logVideo(String message) {
  if (kDebugMode) {
    debugPrint('[VideoPlayer] $message');
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final bool autoPlayOnVisible; // Auto-play when scrolled into view
  final bool looping;
  final double? aspectRatio;
  final bool showControls;
  final bool muted; // Start muted (like Instagram/TikTok)
  final bool enableDoubleTapSeek; // YouTube-style double-tap to seek
  final bool showBufferIndicator; // Show buffer health
  final VoidCallback? onVideoEnd; // Callback when video ends
  final void Function(double aspectRatio)? onAspectRatioResolved; // Real dims
  final VoidCallback? onTap; // Tap to open fullscreen viewer

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.autoPlayOnVisible = true,
    this.looping = true,
    this.aspectRatio,
    this.showControls = true,
    this.muted = true,
    this.enableDoubleTapSeek = true,
    this.showBufferIndicator = true,
    this.onVideoEnd,
    this.onAspectRatioResolved,
    this.onTap,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  // Pre-roll ad: show every 3rd video in the session
  static int _videosThisSession = 0;
  static const int _prerollFrequency = 3;
  bool _showPreroll = false;
  ServedAd? _prerollAd;

  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isVisible = false;
  bool _isMuted = true;
  bool _isPlaying = false;
  bool _showControls = false;

  // YouTube-style double-tap seek
  bool _showSeekIndicator = false;
  bool _seekingForward = true;
  int _seekSeconds = 0;
  Timer? _seekIndicatorTimer;
  Timer? _doubleTapTimer;
  int _tapCount = 0;
  Offset? _lastTapPosition;

  // Buffer state
  VideoBufferState _bufferState = VideoBufferState();
  Timer? _bufferCheckTimer;

  final MediaCacheService _cacheService = MediaCacheService();
  final VideoCacheService _videoCacheService = VideoCacheService();
  final String _visibilityKey = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
    _isMuted = widget.muted;
    // Pre-cache the video in background
    _cacheService.preloadMedia(widget.videoUrl);
    // Check if this video should show a pre-roll ad
    _videosThisSession++;
    if (_videosThisSession % _prerollFrequency == 0) {
      _fetchPrerollAd();
    }
  }

  Future<void> _fetchPrerollAd() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final ads = await AdService.getServedAds(token, 'video_preroll', 1);
      if (ads.isNotEmpty && mounted) {
        setState(() {
          _prerollAd = ads.first;
          _showPreroll = true;
        });
        // Record impression (fire-and-forget)
        final ad = ads.first;
        AdService.recordAdEvent(
          token, ad.campaignId, ad.creativeId,
          0, 'video_preroll', 'impression',
        );
      }
    } catch (_) {
      // Pre-roll fetch failure is non-fatal — just play the video
    }
  }

  Future<void> _recordPrerollClick() async {
    if (_prerollAd == null) return;
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      AdService.recordAdEvent(
        token, _prerollAd!.campaignId, _prerollAd!.creativeId,
        0, 'video_preroll', 'click',
      );
    } catch (_) {}
  }

  void _onPrerollComplete() {
    if (mounted) {
      setState(() => _showPreroll = false);
      // Auto-play video after preroll
      if (_isVisible && widget.autoPlayOnVisible) {
        _play();
      }
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _videoController?.removeListener(_onVideoUpdate);
    _videoController?.dispose();
    _videoController = null;
    _seekIndicatorTimer?.cancel();
    _doubleTapTimer?.cancel();
    _bufferCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    if (_isInitializing || _isInitialized) return;

    _isInitializing = true;
    _logVideo('=== INITIALIZING VIDEO ===');
    _logVideo('URL: ${widget.videoUrl}');

    try {
      final uri = Uri.tryParse(widget.videoUrl);
      if (uri == null || !uri.hasScheme) {
        throw Exception('Invalid video URL: ${widget.videoUrl}');
      }

      // Try cached video first
      final cachedPath = await _cacheService.getCachedMediaPath(widget.videoUrl);

      if (cachedPath != null && File(cachedPath).existsSync()) {
        _logVideo('Using cached video: $cachedPath');
        _videoController = VideoPlayerController.file(File(cachedPath));
      } else {
        _logVideo('Playing from network');
        _videoController = VideoPlayerController.networkUrl(
          uri,
          httpHeaders: {'Accept': '*/*'},
        );
      }

      _videoController!.addListener(_onVideoUpdate);
      await _videoController!.initialize();

      // Set initial volume
      await _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
      await _videoController!.setLooping(widget.looping);

      _logVideo('Video initialized: ${_videoController!.value.duration}');

      // Report real aspect ratio if dimensions are available
      if (widget.onAspectRatioResolved != null) {
        final size = _videoController!.value.size;
        if (size.width > 0 && size.height > 0) {
          widget.onAspectRatioResolved!(size.width / size.height);
        }
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isInitializing = false;
        });

        // Auto-play if visible (but not if preroll ad is showing)
        if (_isVisible && widget.autoPlayOnVisible && !_showPreroll) {
          _play();
        }
      }
    } catch (e, stackTrace) {
      _logVideo('=== VIDEO ERROR ===');
      _logVideo('Error: $e');
      _logVideo('Stack: $stackTrace');

      String userMessage = 'Imeshindwa kupakia video';
      if (e.toString().contains('403')) {
        userMessage = 'Video haipatikani (403)';
      } else if (e.toString().contains('404')) {
        userMessage = 'Video haipatikani (404)';
      }

      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = userMessage;
          _isInitializing = false;
        });
      }
    }
  }

  void _onVideoUpdate() {
    if (!mounted || _disposed) return;

    final isPlaying = _videoController?.value.isPlaying ?? false;
    if (isPlaying != _isPlaying) {
      setState(() => _isPlaying = isPlaying);
    }

    // Update buffer state
    if (_videoController != null && widget.showBufferIndicator) {
      _bufferState = _videoCacheService.getBufferState(_videoController!);
    }

    // Check for video end
    if (_videoController != null && !widget.looping) {
      final position = _videoController!.value.position;
      final duration = _videoController!.value.duration;
      if (position >= duration && duration.inMilliseconds > 0) {
        widget.onVideoEnd?.call();
      }
    }

    if (_videoController?.value.hasError == true) {
      _logVideo('Video error: ${_videoController!.value.errorDescription}');
    }
  }

  // ============================================================================
  // YouTube-style Double-Tap Seek
  // ============================================================================

  void _handleTapDown(TapDownDetails details) {
    _lastTapPosition = details.localPosition;
  }

  void _handleTap() {
    // Single tap opens fullscreen viewer if callback provided
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    if (!widget.enableDoubleTapSeek) {
      _toggleControls();
      return;
    }

    _tapCount++;

    if (_tapCount == 1) {
      // Wait for potential second tap
      _doubleTapTimer = Timer(const Duration(milliseconds: 300), () {
        if (_tapCount == 1) {
          // Single tap - toggle controls
          _toggleControls();
        }
        _tapCount = 0;
      });
    } else if (_tapCount == 2) {
      // Double tap - seek
      _doubleTapTimer?.cancel();
      _tapCount = 0;
      _handleDoubleTapSeek();
    }
  }

  void _handleDoubleTapSeek() {
    if (_lastTapPosition == null || _videoController == null || !_isInitialized) return;

    final screenWidth = context.size?.width ?? 300;
    final tapX = _lastTapPosition!.dx;

    // Left side = rewind, Right side = forward
    final isForward = tapX > screenWidth / 2;
    const seekDuration = Duration(seconds: 10);

    final currentPosition = _videoController!.value.position;
    final duration = _videoController!.value.duration;

    Duration newPosition;
    if (isForward) {
      newPosition = currentPosition + seekDuration;
      if (newPosition > duration) newPosition = duration;
      _seekSeconds = 10;
      _seekingForward = true;
    } else {
      newPosition = currentPosition - seekDuration;
      if (newPosition.isNegative) newPosition = Duration.zero;
      _seekSeconds = 10;
      _seekingForward = false;
    }

    _videoController!.seekTo(newPosition);
    _logVideo('Seek ${isForward ? "forward" : "backward"} 10s to ${newPosition.inSeconds}s');

    // Show seek indicator
    setState(() => _showSeekIndicator = true);

    _seekIndicatorTimer?.cancel();
    _seekIndicatorTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showSeekIndicator = false);
      }
    });
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_disposed || !mounted) return;

    final visibleFraction = info.visibleFraction;
    final wasVisible = _isVisible;
    _isVisible = visibleFraction > 0.5; // Consider visible if >50% shown

    if (_isVisible && !wasVisible) {
      _logVideo('Video became visible');
      if (widget.autoPlayOnVisible) {
        if (!_isInitialized && !_isInitializing) {
          _initializeVideo();
        } else if (_isInitialized) {
          _play();
        }
      }
    } else if (!_isVisible && wasVisible) {
      _logVideo('Video went out of view');
      _pause();
    }
  }

  Future<void> _play() async {
    if (_videoController != null && _isInitialized && !_disposed) {
      await _videoController!.play();
      _logVideo('Playing');
    }
  }

  Future<void> _pause() async {
    if (_videoController != null && _isInitialized && !_disposed) {
      await _videoController!.pause();
      _logVideo('Paused');
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _videoController?.setVolume(_isMuted ? 0.0 : 1.0);
    });
    _logVideo('Muted: $_isMuted');
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    // Auto-hide controls after 3 seconds
    if (_showControls) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showControls) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(_visibilityKey),
      onVisibilityChanged: _onVisibilityChanged,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio ?? 16 / 9,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_hasError) {
      return _buildErrorWidget();
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTap: _handleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail or Video
          if (_isInitialized && _videoController != null)
            VideoPlayer(_videoController!)
          else
            _buildThumbnail(),

          // Loading indicator
          if (_isInitializing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Buffering indicator (YouTube-style)
          if (_isInitialized && _bufferState.isBuffering)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),

          // Double-tap seek indicator (YouTube-style)
          if (_showSeekIndicator)
            _buildSeekIndicator(),

          // Play/Pause visual indicator (non-interactive, shows when paused)
          if (_isInitialized && !_isPlaying && !_showSeekIndicator && !_showPreroll)
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
              ),
            ),

          // Play/Pause + Mute buttons (bottom-right)
          if (_isInitialized && !_showPreroll)
            Positioned(
              bottom: 12,
              right: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPlayPauseButton(),
                  const SizedBox(width: 8),
                  _buildMuteButton(),
                ],
              ),
            ),

          // Buffer health indicator
          if (_isInitialized && widget.showBufferIndicator)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBufferIndicator(),
            ),

          // Progress bar (on top of buffer indicator)
          if (_isInitialized && _showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildProgressBar(),
            ),

          // Video badge (when not playing)
          if (!_isInitialized || !_isPlaying)
            Positioned(
              bottom: 8,
              left: 8,
              child: _buildVideoBadge(),
            ),

          // Pre-roll ad overlay
          if (_showPreroll && _prerollAd != null)
            Positioned.fill(
              child: VideoPrerollOverlay(
                servedAd: _prerollAd!,
                onComplete: _onPrerollComplete,
                onClick: _recordPrerollClick,
              ),
            ),
        ],
      ),
    );
  }

  /// YouTube-style seek indicator (shows +10s / -10s)
  Widget _buildSeekIndicator() {
    return Positioned(
      left: _seekingForward ? null : 20,
      right: _seekingForward ? 20 : null,
      top: 0,
      bottom: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _seekingForward ? Icons.fast_forward : Icons.fast_rewind,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                '${_seekSeconds}s',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// YouTube-style buffer indicator (gray bar behind progress)
  Widget _buildBufferIndicator() {
    return Container(
      height: 3,
      color: Colors.white.withValues(alpha: 0.2),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: _bufferState.bufferPercent.clamp(0.0, 1.0),
        child: Container(color: Colors.white.withValues(alpha: 0.4)),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty) {
      return CachedMediaImage(
        imageUrl: widget.thumbnailUrl,
        fit: BoxFit.cover,
        backgroundColor: Colors.grey.shade900,
      );
    }
    return Container(
      color: Colors.grey.shade900,
      child: const Center(
        child: Icon(Icons.videocam, color: Colors.white54, size: 48),
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildMuteButton() {
    return GestureDetector(
      onTap: _toggleMute,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isMuted ? Icons.volume_off : Icons.volume_up,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final duration = _videoController?.value.duration ?? Duration.zero;
    final position = _videoController?.value.position ?? Duration.zero;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Container(
      height: 4,
      color: Colors.white24,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(color: Colors.white),
      ),
    );
  }

  Widget _buildVideoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            _formatDuration(_videoController?.value.duration),
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'Video';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 42, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Imeshindwa kupakia video',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorMessage = null;
                });
                _initializeVideo();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Jaribu tena'),
            ),
          ],
        ),
      ),
    );
  }
}
