import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/media_cache_service.dart';

/// Debug logger for audio player
void _logAudio(String message) {
  if (kDebugMode) {
    print('[AudioPlayer] $message');
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final int? duration; // Duration in seconds
  final String? title;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    this.duration,
    this.title,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final MediaCacheService _cacheService = MediaCacheService();
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;
  String? _cachedPath; // Cached local file path

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
    _preloadAudio(); // Start caching in background
  }

  /// Preload audio in background for faster playback
  Future<void> _preloadAudio() async {
    _cachedPath = await _cacheService.getCachedMediaPath(widget.audioUrl);
    if (_cachedPath != null) {
      _logAudio('Audio pre-cached at: $_cachedPath');
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _playerState = state);
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _playerState = PlayerState.stopped;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPause() async {
    _logAudio('=== PLAY/PAUSE TRIGGERED ===');
    _logAudio('Current state: $_playerState');
    _logAudio('Position: $_position');
    _logAudio('Audio URL: ${widget.audioUrl}');

    if (_playerState == PlayerState.playing) {
      _logAudio('Pausing audio...');
      await _audioPlayer.pause();
    } else if (_playerState == PlayerState.paused) {
      _logAudio('Resuming from pause...');
      setState(() => _isLoading = true);
      try {
        await _audioPlayer.resume();
        _logAudio('Resumed successfully');
      } catch (e) {
        _logAudio('Resume failed: $e');
        // If resume fails, try playing from current position
        await _audioPlayer.seek(_position);
        await _audioPlayer.resume();
      }
      if (mounted) setState(() => _isLoading = false);
    } else {
      // Stopped or completed - start fresh
      _logAudio('Starting/restarting playback...');
      setState(() => _isLoading = true);
      try {
        // Reset position state
        setState(() => _position = Duration.zero);

        // Try cached file first, then fall back to network
        if (_cachedPath != null && File(_cachedPath!).existsSync()) {
          _logAudio('Playing from cache: $_cachedPath');
          await _audioPlayer.play(DeviceFileSource(_cachedPath!));
        } else {
          // Try to get cached path (might have been cached since init)
          _cachedPath = await _cacheService.getCachedMediaPath(widget.audioUrl);
          if (_cachedPath != null && File(_cachedPath!).existsSync()) {
            _logAudio('Playing from newly cached: $_cachedPath');
            await _audioPlayer.play(DeviceFileSource(_cachedPath!));
          } else {
            _logAudio('Playing from network: ${widget.audioUrl}');
            await _audioPlayer.play(UrlSource(widget.audioUrl));
            // Cache for next time
            _cacheService.preloadMedia(widget.audioUrl);
          }
        }
        _logAudio('Playback started successfully');
      } catch (e, stackTrace) {
        _logAudio('=== AUDIO PLAYBACK ERROR ===');
        _logAudio('Error: $e');
        _logAudio('Stack trace: $stackTrace');
        _logAudio('URL was: ${widget.audioUrl}');

        if (mounted) {
          String errorMessage = 'Imeshindwa kucheza sauti';
          if (e.toString().contains('403')) {
            errorMessage = 'Sauti haipatikani (403)';
          } else if (e.toString().contains('404')) {
            errorMessage = 'Sauti haipatikani (404)';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _seekTo(double value) {
    final position = Duration(milliseconds: (value * _duration.inMilliseconds).round());
    _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final displayDuration = _duration.inSeconds > 0
        ? _duration
        : Duration(seconds: widget.duration ?? 0);
    final progress = displayDuration.inMilliseconds > 0
        ? _position.inMilliseconds / displayDuration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _isLoading ? null : _playPause,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      _playerState == PlayerState.playing
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Progress and duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Audio waveform visualization
                Row(
                  children: [
                    const Icon(Icons.mic, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      widget.title ?? 'Sauti',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Progress bar
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    inactiveTrackColor: Colors.grey.shade300,
                    thumbColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: _duration.inMilliseconds > 0 ? _seekTo : null,
                  ),
                ),

                // Duration text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        _formatDuration(displayDuration),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
