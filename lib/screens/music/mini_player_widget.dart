import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_service/audio_service.dart';
import '../../models/music_models.dart';
import '../../services/background_audio_service.dart';

/// Spotify-style Mini Player Widget
/// Features:
/// - Blurred background from album art
/// - Play/pause control
/// - Progress indicator
/// - Swipe to dismiss
/// - Tap to expand
class MiniPlayerWidget extends StatelessWidget {
  final MusicTrack track;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onDismiss;
  final double progress;

  const MiniPlayerWidget({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.onTap,
    required this.onPlayPause,
    this.onNext,
    this.onDismiss,
    this.progress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(track.id),
      direction: DismissDirection.down,
      onDismissed: (_) => onDismiss?.call(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 64,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // Blurred background
                if (track.coverUrl.isNotEmpty)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: track.coverUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      // Album art
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: track.coverUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: track.coverUrl,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Track info
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              track.artist?.name ?? 'Msanii',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Controls
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Device indicator
                          Icon(
                            Icons.speaker_group,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                          const SizedBox(width: 16),

                          // Play/Pause
                          GestureDetector(
                            onTap: onPlayPause,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.black,
                                size: 22,
                              ),
                            ),
                          ),

                          // Next (if available)
                          if (onNext != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: onNext,
                              icon: const Icon(
                                Icons.skip_next,
                                color: Colors.white,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Progress bar at bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF1DB954),
                    ),
                    minHeight: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Expanded Mini Player for larger display
class ExpandedMiniPlayer extends StatefulWidget {
  final MusicTrack track;
  final bool isPlaying;
  final double progress;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final Function(double)? onSeek;
  final VoidCallback? onShuffle;
  final VoidCallback? onRepeat;
  final VoidCallback onClose;

  const ExpandedMiniPlayer({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.progress,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    this.onPrevious,
    this.onNext,
    this.onSeek,
    this.onShuffle,
    this.onRepeat,
    required this.onClose,
  });

  @override
  State<ExpandedMiniPlayer> createState() => _ExpandedMiniPlayerState();
}

class _ExpandedMiniPlayerState extends State<ExpandedMiniPlayer> {
  bool _isShuffle = false;
  int _repeatMode = 0; // 0: off, 1: all, 2: one

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[900]!,
            Colors.black,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: Colors.white, size: 32),
                  ),
                  Column(
                    children: [
                      Text(
                        'INACHEZA KUTOKA',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        widget.track.category?.name ?? 'Maktaba Yako',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Album Art
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.track.coverUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.track.coverUrl,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.grey,
                              size: 100,
                            ),
                          ),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Track Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.track.artist?.name ?? 'Msanii',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      widget.track.isSaved == true
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: widget.track.isSaved == true
                          ? const Color(0xFF1DB954)
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Progress Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.grey[700],
                      thumbColor: Colors.white,
                      overlayColor: Colors.white.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: widget.progress.clamp(0.0, 1.0),
                      onChanged: widget.onSeek,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(widget.position),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _formatDuration(widget.duration),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Main Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Shuffle
                  IconButton(
                    onPressed: () {
                      setState(() => _isShuffle = !_isShuffle);
                      widget.onShuffle?.call();
                    },
                    icon: Icon(
                      Icons.shuffle,
                      color: _isShuffle
                          ? const Color(0xFF1DB954)
                          : Colors.grey[400],
                    ),
                  ),

                  // Previous
                  IconButton(
                    onPressed: widget.onPrevious,
                    icon: const Icon(
                      Icons.skip_previous,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),

                  // Play/Pause
                  GestureDetector(
                    onTap: widget.onPlayPause,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.black,
                        size: 36,
                      ),
                    ),
                  ),

                  // Next
                  IconButton(
                    onPressed: widget.onNext,
                    icon: const Icon(
                      Icons.skip_next,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),

                  // Repeat
                  IconButton(
                    onPressed: () {
                      setState(() => _repeatMode = (_repeatMode + 1) % 3);
                      widget.onRepeat?.call();
                    },
                    icon: Icon(
                      _repeatMode == 2 ? Icons.repeat_one : Icons.repeat,
                      color: _repeatMode > 0
                          ? const Color(0xFF1DB954)
                          : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bottom Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.speaker_group, color: Colors.grey[400]),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.share, color: Colors.grey[400]),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.queue_music, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Persistent Mini Player that connects to BackgroundAudioService
/// Shows on all screens when music is playing in the background
class PersistentMiniPlayer extends StatefulWidget {
  final VoidCallback? onTap;
  final int currentUserId;

  const PersistentMiniPlayer({
    super.key,
    this.onTap,
    required this.currentUserId,
  });

  @override
  State<PersistentMiniPlayer> createState() => _PersistentMiniPlayerState();
}

class _PersistentMiniPlayerState extends State<PersistentMiniPlayer> {
  final BackgroundAudioService _audioService = BackgroundAudioService();

  MediaItem? _currentItem;
  bool _isPlaying = false;
  double _progress = 0.0;

  StreamSubscription? _mediaItemSub;
  StreamSubscription? _playbackStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initListeners();
  }

  void _initListeners() {
    _mediaItemSub = _audioService.mediaItemStream.listen((item) {
      if (mounted) {
        setState(() => _currentItem = item);
      }
    });

    _playbackStateSub = _audioService.playbackStateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state.playing);
      }
    });

    _positionSub = _audioService.positionStream.listen((pos) {
      if (mounted) {
        setState(() {
          _progress = _duration.inMilliseconds > 0
              ? pos.inMilliseconds / _duration.inMilliseconds
              : 0.0;
        });
      }
    });

    _durationSub = _audioService.durationStream.listen((dur) {
      if (mounted && dur != null) {
        setState(() => _duration = dur);
      }
    });

    // Get initial state
    if (_audioService.currentMediaItem != null) {
      setState(() {
        _currentItem = _audioService.currentMediaItem;
        _isPlaying = _audioService.isPlaying;
      });
    }
  }

  @override
  void dispose() {
    _mediaItemSub?.cancel();
    _playbackStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentItem == null) return const SizedBox.shrink();

    return Dismissible(
      key: ValueKey(_currentItem!.id),
      direction: DismissDirection.down,
      onDismissed: (_) => _audioService.stop(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 64,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // Blurred background
                if (_currentItem!.artUri != null)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: _currentItem!.artUri.toString(),
                      fit: BoxFit.cover,
                    ),
                  ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      // Album art
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: _currentItem!.artUri != null
                              ? CachedNetworkImage(
                                  imageUrl: _currentItem!.artUri.toString(),
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Track info
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentItem!.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currentItem!.artist ?? 'Msanii',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Controls
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Play/Pause
                          GestureDetector(
                            onTap: () => _audioService.playPause(),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.black,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Next
                          IconButton(
                            onPressed: () => _audioService.skipToNext(),
                            icon: const Icon(
                              Icons.skip_next,
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Progress bar at bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(
                    value: _progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF1DB954),
                    ),
                    minHeight: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
