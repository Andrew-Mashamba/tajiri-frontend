import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/music_models.dart';
import '../../services/music_service.dart';
import '../../services/simple_audio_service.dart';

/// Spotify-style Music Player Sheet with Background Playback
/// Features:
/// - Background audio playback
/// - Notification controls
/// - Queue management (next/previous)
/// - Shuffle and repeat modes
/// - Forward/rewind 10 seconds
/// - Wakelock to prevent screen sleep
class MusicPlayerSheet extends StatefulWidget {
  final MusicTrack track;
  final int currentUserId;
  final List<MusicTrack>? queue;
  final int? startIndex;
  final VoidCallback? onClose;

  const MusicPlayerSheet({
    super.key,
    required this.track,
    required this.currentUserId,
    this.queue,
    this.startIndex,
    this.onClose,
  });

  @override
  State<MusicPlayerSheet> createState() => _MusicPlayerSheetState();
}

class _MusicPlayerSheetState extends State<MusicPlayerSheet>
    with SingleTickerProviderStateMixin {
  final SimpleAudioService _audioService = SimpleAudioService();
  final MusicService _musicService = MusicService();

  // State
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _bufferedPosition = Duration.zero;
  bool _isSaved = false;
  RepeatMode _repeatMode = RepeatMode.none;
  bool _isShuffleEnabled = false;
  MusicTrack? _currentTrack;
  ProcessingState _processingState = ProcessingState.idle;

  // Stream subscriptions
  StreamSubscription? _playingSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _processingStateSub;
  StreamSubscription? _bufferedPositionSub;
  StreamSubscription? _errorSub;

  // Error state
  String? _errorMessage;

  // Animation
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.track.isSaved == true;
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _initAudio();
  }

  Future<void> _initAudio() async {
    print('🎵 [PlayerSheet] _initAudio starting...');

    try {
      await _audioService.initialize();
      print('🎵 [PlayerSheet] Audio initialization completed');
    } catch (e) {
      print('🎵 [PlayerSheet] Audio initialization failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imeshindikana kuanzisha muziki: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Listen to playing state
    _playingSub = _audioService.playingStream.listen((playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
          _repeatMode = _audioService.repeatMode;
          _isShuffleEnabled = _audioService.shuffleEnabled;
        });

        // Animate album art rotation when playing
        if (_isPlaying) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }
      }
    });

    // Listen to position updates
    _positionSub = _audioService.positionStream.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });

    // Listen to duration updates
    _durationSub = _audioService.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() => _duration = duration);
      }
    });

    // Listen to processing state (for track changes and buffering)
    _processingStateSub = _audioService.processingStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _processingState = state;
          _currentTrack = _audioService.currentTrack;
          _isSaved = _currentTrack?.isSaved ?? false;
        });
      }
    });

    // Listen to buffered position
    _bufferedPositionSub = _audioService.bufferedPositionStream.listen((buffered) {
      if (mounted) {
        setState(() => _bufferedPosition = buffered);
      }
    });

    // Listen to errors
    _errorSub = _audioService.errorStream.listen((error) {
      if (mounted) {
        setState(() => _errorMessage = error);
        if (error != null && !error.contains('Inajaribu')) {
          // Show snackbar for persistent errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(error)),
                ],
              ),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Jaribu tena',
                textColor: Colors.white,
                onPressed: () => _audioService.retry(),
              ),
            ),
          );
        }
      }
    });

    // Start playback
    if (widget.queue != null && widget.queue!.isNotEmpty) {
      await _audioService.playQueue(
        widget.queue!,
        startIndex: widget.startIndex ?? 0,
      );
    } else {
      await _audioService.playTrack(widget.track);
    }

    // Set initial state
    if (mounted) {
      setState(() {
        _currentTrack = _audioService.currentTrack ?? widget.track;
        _isSaved = _currentTrack?.isSaved ?? widget.track.isSaved ?? false;
      });
    }
  }

  Future<void> _toggleSave() async {
    final trackId = _currentTrack?.id ?? widget.track.id;
    if (trackId == 0) return;

    if (_isSaved) {
      await _musicService.unsaveTrack(trackId, widget.currentUserId);
    } else {
      await _musicService.saveTrack(trackId, widget.currentUserId);
    }
    setState(() => _isSaved = !_isSaved);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSaved ? 'Imehifadhiwa' : 'Imeondolewa'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF282828),
        ),
      );
    }
  }

  void _cycleRepeatMode() {
    _audioService.cycleRepeatMode();
    setState(() {
      _repeatMode = _audioService.repeatMode;
    });
  }

  void _toggleShuffle() {
    _audioService.setShuffle(!_isShuffleEnabled);
    setState(() {
      _isShuffleEnabled = _audioService.shuffleEnabled;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildPlayPauseIcon() {
    // Show loading spinner when loading
    if (_processingState == ProcessingState.loading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          ),
        ),
      );
    }

    // Show buffering indicator (spinner with play icon overlay)
    if (_processingState == ProcessingState.buffering) {
      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black.withOpacity(0.3)),
            ),
          ),
          Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.black,
            size: 28,
          ),
        ],
      );
    }

    // Normal play/pause icon
    return Icon(
      _isPlaying ? Icons.pause : Icons.play_arrow,
      color: Colors.black,
      size: 32,
    );
  }

  /// Check if content is locked (subscribers-only and user not subscribed)
  bool get _isContentLocked {
    final track = _currentTrack ?? widget.track;
    // Own tracks are never locked
    if (track.artistId == widget.currentUserId) return false;
    // Only lock if privacy is subscribers and user is not subscribed
    return track.privacy == 'subscribers' && !track.isSubscribedToArtist;
  }

  @override
  Widget build(BuildContext context) {
    final title = _currentTrack?.title ?? widget.track.title;
    final artist = _currentTrack?.artist?.name ?? widget.track.artist?.name ?? 'Msanii';
    final artUri = _currentTrack?.coverUrl ?? widget.track.coverUrl;
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[900]!,
            Colors.black,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: _isContentLocked
            ? _buildSubscriberOverlay(title, artist, artUri)
            : Column(
                children: [
                  // Header
                  _buildHeader(context),

                  const Spacer(),

                  // Album Art with rotation animation
                  _buildAlbumArt(artUri),

                  const Spacer(),

                  // Track Info
                  _buildTrackInfo(title, artist),

                  const SizedBox(height: 24),

                  // Progress Slider
                  _buildProgressSlider(progress),

                  const SizedBox(height: 8),

                  // Main Controls
                  _buildMainControls(),

                  const SizedBox(height: 24),

                  // Bottom Actions
                  _buildBottomActions(),

                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  Widget _buildSubscriberOverlay(String title, String artist, String artUri) {
    return Column(
      children: [
        // Header (allow closing)
        _buildHeader(context),

        const Spacer(),

        // Album Art (blurred/dimmed)
        Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0.3,
              child: _buildAlbumArt(artUri),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star,
                size: 56,
                color: Color(0xFFF59E0B),
              ),
            ),
          ],
        ),

        const Spacer(),

        // Locked message
        const Text(
          'Kwa Wasajili Pekee',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          artist,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Jisajili kwa msanii huyu\nkusikiliza nyimbo zake',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: _navigateToSubscribe,
          icon: const Icon(Icons.star, size: 22),
          label: const Text(
            'Jisajili Sasa',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),

        const Spacer(),
        const SizedBox(height: 32),
      ],
    );
  }

  void _navigateToSubscribe() {
    final track = _currentTrack ?? widget.track;
    Navigator.pushNamed(
      context,
      '/profile',
      arguments: {'userId': track.artistId},
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              widget.onClose?.call();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.keyboard_arrow_down,
                color: Colors.white, size: 32),
          ),
          Column(
            children: [
              Text(
                'INACHEZA SASA',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              Text(
                widget.track.category?.name ?? 'Muziki',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _showQueueSheet(context),
            icon: const Icon(Icons.queue_music, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(String artUri) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            Container(
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
                child: artUri.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: artUri,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[800],
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color?>(const Color(0xFF1DB954)),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.music_note,
                              color: Colors.grey, size: 100),
                        ),
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.music_note,
                            color: Colors.grey, size: 100),
                      ),
              ),
            ),
            // Retry overlay when retrying
            if (_errorMessage != null && _errorMessage!.contains('Inajaribu'))
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackInfo(String title, String artist) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
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
                  artist,
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
            onPressed: _toggleSave,
            icon: Icon(
              _isSaved ? Icons.favorite : Icons.favorite_border,
              color: _isSaved ? const Color(0xFF1DB954) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSlider(double progress) {
    final bufferedProgress = _duration.inMilliseconds > 0
        ? (_bufferedPosition.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Custom progress bar with buffering indicator
          SizedBox(
            height: 24,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return GestureDetector(
                  onTapDown: (details) {
                    final tapPosition = details.localPosition.dx / width;
                    final newPosition = Duration(
                      milliseconds: (tapPosition * _duration.inMilliseconds).toInt(),
                    );
                    _audioService.seek(newPosition);
                  },
                  onHorizontalDragUpdate: (details) {
                    final dragPosition = (details.localPosition.dx / width).clamp(0.0, 1.0);
                    final newPosition = Duration(
                      milliseconds: (dragPosition * _duration.inMilliseconds).toInt(),
                    );
                    _audioService.seek(newPosition);
                  },
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Background track
                      Container(
                        height: 4,
                        width: width,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Buffered progress (light grey)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 4,
                        width: width * bufferedProgress,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Played progress (white/green)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        height: 4,
                        width: width * progress,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Thumb
                      Positioned(
                        left: (width * progress - 6).clamp(0.0, width - 12),
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                // Show buffering status
                if (_processingState == ProcessingState.buffering ||
                    _processingState == ProcessingState.loading)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Inapakia...',
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                      ),
                    ],
                  ),
                Text(
                  _formatDuration(_duration),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Shuffle
          _buildControlButton(
            onPressed: _toggleShuffle,
            icon: Icons.shuffle,
            size: 20,
            color: _isShuffleEnabled ? const Color(0xFF1DB954) : Colors.grey[400],
          ),

          const SizedBox(width: 8),

          // Previous
          _buildControlButton(
            onPressed: () => _audioService.skipToPrevious(),
            icon: Icons.skip_previous,
            size: 28,
            color: Colors.white,
          ),

          const SizedBox(width: 4),

          // Rewind 10s
          _buildControlButton(
            onPressed: () => _audioService.rewind(),
            icon: Icons.replay_10,
            size: 22,
            color: Colors.white,
          ),

          const SizedBox(width: 8),

          // Play/Pause with buffering indicator
          GestureDetector(
            onTap: () {
              debugPrint('[PlayerSheet] Play/Pause tapped. isPlaying: $_isPlaying, state: $_processingState');
              if (_processingState != ProcessingState.loading) {
                _audioService.playPause();
              }
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: _buildPlayPauseIcon(),
            ),
          ),

          const SizedBox(width: 8),

          // Forward 10s
          _buildControlButton(
            onPressed: () => _audioService.fastForward(),
            icon: Icons.forward_10,
            size: 22,
            color: Colors.white,
          ),

          const SizedBox(width: 4),

          // Next
          _buildControlButton(
            onPressed: () => _audioService.skipToNext(),
            icon: Icons.skip_next,
            size: 28,
            color: Colors.white,
          ),

          const SizedBox(width: 8),

          // Repeat
          _buildControlButton(
            onPressed: _cycleRepeatMode,
            icon: _repeatMode == RepeatMode.one
                ? Icons.repeat_one
                : Icons.repeat,
            size: 20,
            color: _repeatMode != RepeatMode.none
                ? const Color(0xFF1DB954)
                : Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required double size,
    Color? color,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: size, color: color),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.speaker_group, color: Colors.grey[400]),
          ),
          IconButton(
            onPressed: () => _shareTrack(),
            icon: Icon(Icons.share, color: Colors.grey[400]),
          ),
          IconButton(
            onPressed: () => _showQueueSheet(context),
            icon: Icon(Icons.queue_music, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  void _showQueueSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _QueueSheet(audioService: _audioService),
    );
  }

  void _shareTrack() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kushiriki nyimbo kunakuja hivi karibuni'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF282828),
      ),
    );
  }

  @override
  void dispose() {
    _playingSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _processingStateSub?.cancel();
    _bufferedPositionSub?.cancel();
    _errorSub?.cancel();
    _rotationController.dispose();
    // Don't stop audio - let it continue in background
    super.dispose();
  }
}

/// Queue Sheet Widget
class _QueueSheet extends StatefulWidget {
  final SimpleAudioService audioService;

  const _QueueSheet({required this.audioService});

  @override
  State<_QueueSheet> createState() => _QueueSheetState();
}

class _QueueSheetState extends State<_QueueSheet> {
  @override
  Widget build(BuildContext context) {
    final queue = widget.audioService.queue;
    final currentIndex = widget.audioService.currentIndex;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Foleni',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.audioService.clearQueue();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Futa yote',
                    style: TextStyle(color: Color(0xFF1DB954)),
                  ),
                ),
              ],
            ),
          ),

          // Queue List
          Expanded(
            child: queue.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.queue_music, size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text(
                          'Foleni tupu',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: queue.length,
                    itemBuilder: (context, index) {
                      final track = queue[index];
                      final isCurrentTrack = index == currentIndex;

                      return ListTile(
                        onTap: () {
                          widget.audioService.skipToQueueItem(index);
                          Navigator.pop(context);
                        },
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: track.coverUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: track.coverUrl,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.music_note,
                                        color: Colors.grey),
                                  ),
                          ),
                        ),
                        title: Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                isCurrentTrack ? const Color(0xFF1DB954) : Colors.white,
                            fontWeight:
                                isCurrentTrack ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          track.artist?.name ?? 'Msanii',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        trailing: isCurrentTrack
                            ? const Icon(Icons.equalizer, color: Color(0xFF1DB954))
                            : IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.grey),
                                onPressed: () {
                                  widget.audioService.removeQueueItem(index);
                                  setState(() {}); // Refresh the list
                                },
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
