import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../config/api_config.dart';
import 'cached_media_image.dart';

/// Displays a Live Photo / Motion Photo — static image by default,
/// plays the video component on long-press.
class LivePhotoViewer extends StatefulWidget {
  final String imageUrl;
  final String? videoUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const LivePhotoViewer({
    super.key,
    required this.imageUrl,
    this.videoUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<LivePhotoViewer> createState() => _LivePhotoViewerState();
}

class _LivePhotoViewerState extends State<LivePhotoViewer> {
  VideoPlayerController? _videoController;
  bool _isPlayingVideo = false;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl != null) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    if (widget.videoUrl == null) return;
    final url = widget.videoUrl!.startsWith('http')
        ? widget.videoUrl!
        : '${ApiConfig.storageUrl}/${widget.videoUrl}';
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      if (mounted) setState(() => _videoInitialized = true);
    } catch (_) {
      // Video init failed — will fall back to still image only
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _startPlaying() {
    if (!_videoInitialized || _videoController == null) return;
    _videoController!.seekTo(Duration.zero);
    _videoController!.play();
    setState(() => _isPlayingVideo = true);
  }

  void _stopPlaying() {
    _videoController?.pause();
    setState(() => _isPlayingVideo = false);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = widget.imageUrl.startsWith('http')
        ? widget.imageUrl
        : '${ApiConfig.storageUrl}/${widget.imageUrl}';

    return GestureDetector(
      onLongPressStart: widget.videoUrl != null ? (_) => _startPlaying() : null,
      onLongPressEnd: widget.videoUrl != null ? (_) => _stopPlaying() : null,
      child: Stack(
        children: [
          if (_isPlayingVideo && _videoController != null)
            SizedBox(
              width: widget.width,
              height: widget.height,
              child: FittedBox(
                fit: widget.fit,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedMediaImage(
                imageUrl: resolvedImageUrl,
                width: widget.width ?? 200,
                height: widget.height ?? 150,
                fit: widget.fit,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          // "LIVE" badge
          if (widget.videoUrl != null)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isPlayingVideo ? Icons.pause_circle_filled : Icons.motion_photos_on,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
