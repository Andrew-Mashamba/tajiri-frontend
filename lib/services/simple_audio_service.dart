import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/music_models.dart';
import 'audio_cache_service.dart';
import 'music_notification_service.dart';

/// Repeat mode enum for the audio service
enum RepeatMode { none, one, all }

/// Simple Audio Service with notification controls
class SimpleAudioService {
  static final SimpleAudioService _instance = SimpleAudioService._internal();
  factory SimpleAudioService() => _instance;
  SimpleAudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  final AudioCacheService _cacheService = AudioCacheService();
  final MusicNotificationService _notificationService = MusicNotificationService();
  bool _isInitialized = false;

  // Queue management
  final List<MusicTrack> _queue = [];
  int _currentIndex = 0;
  bool _shuffleEnabled = false;
  RepeatMode _repeatMode = RepeatMode.none;
  List<int> _shuffleOrder = [];

  // Current track info
  MusicTrack? _currentTrack;

  // Error handling
  final _errorController = StreamController<String?>.broadcast();
  String? _lastError;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  /// Check if service is ready
  bool get isReady => _isInitialized;

  // Public streams (directly from just_audio)
  Stream<bool> get playingStream => _player.playingStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<ProcessingState> get processingStateStream => _player.processingStateStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  // Buffering state helpers
  Duration get bufferedPosition => _player.bufferedPosition;
  bool get isBuffering => _player.processingState == ProcessingState.buffering;
  bool get isLoading => _player.processingState == ProcessingState.loading;

  /// Get buffering progress as percentage (0.0 to 1.0)
  double get bufferingProgress {
    final duration = _player.duration;
    if (duration == null || duration.inMilliseconds == 0) return 0.0;
    return (_player.bufferedPosition.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  // Error handling
  Stream<String?> get errorStream => _errorController.stream;
  String? get lastError => _lastError;
  bool get hasError => _lastError != null;

  // Current state getters
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  MusicTrack? get currentTrack => _currentTrack;
  List<MusicTrack> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  bool get shuffleEnabled => _shuffleEnabled;
  RepeatMode get repeatMode => _repeatMode;

  /// Initialize the audio service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[SimpleAudio] Already initialized');
      return;
    }

    debugPrint('[SimpleAudio] Initializing...');

    try {
      await _cacheService.initialize();
      debugPrint('[SimpleAudio] Cache service initialized');

      await _notificationService.initialize();
      debugPrint('[SimpleAudio] Notification service initialized');

      // Listen for track completion
      _player.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) {
          _handleTrackCompletion();
        }
      });

      // Manage wakelock and notification based on playing state
      _player.playingStream.listen((playing) async {
        try {
          if (playing) {
            await WakelockPlus.enable();
          } else {
            await WakelockPlus.disable();
          }
        } catch (e) {
          debugPrint('[SimpleAudio] Wakelock error (ignored): $e');
        }
        // Update notification
        if (_currentTrack != null) {
          _notificationService.updateNotification(isPlaying: playing);
        }
      });

      // Listen for playback errors
      _player.playbackEventStream.listen(
        (_) {},
        onError: (Object e, StackTrace st) {
          debugPrint('[SimpleAudio] Playback error event: $e');
          if (_currentTrack != null && _retryCount < _maxRetries) {
            _retryCount++;
            _setError('Tatizo la mtandao. Inajaribu tena...');
            Future.delayed(_retryDelay, () {
              if (_currentTrack != null) {
                _attemptPlayback(_currentTrack!);
              }
            });
          }
        },
      );

      _isInitialized = true;
      debugPrint('[SimpleAudio] Service initialized successfully');
    } catch (e) {
      debugPrint('[SimpleAudio] Init error: $e');
      rethrow;
    }
  }

  /// Play a single track
  Future<void> playTrack(MusicTrack track) async {
    if (!_isInitialized) await initialize();
    await playQueue([track], startIndex: 0);
  }

  /// Play a queue of tracks
  Future<void> playQueue(List<MusicTrack> tracks, {int startIndex = 0}) async {
    if (!_isInitialized) await initialize();

    _queue.clear();
    _queue.addAll(tracks);
    _currentIndex = startIndex;
    _generateShuffleOrder();

    await _playCurrentTrack();
  }

  /// Add track to queue
  Future<void> addToQueue(MusicTrack track) async {
    _queue.add(track);
    _generateShuffleOrder();
  }

  /// Clear queue
  Future<void> clearQueue() async {
    await stop();
    _queue.clear();
    _currentTrack = null;
  }

  Future<void> _playCurrentTrack() async {
    if (_queue.isEmpty) return;

    final index = _shuffleEnabled ? _shuffleOrder[_currentIndex] : _currentIndex;
    final track = _queue[index];
    _currentTrack = track;
    _retryCount = 0;
    _clearError();

    debugPrint('[SimpleAudio] Playing: ${track.title}');
    debugPrint('[SimpleAudio] URL: ${track.audioUrl}');

    // Start notification
    _notificationService.startForegroundTask(track: track, isPlaying: true);

    await _attemptPlayback(track);
  }

  Future<void> _attemptPlayback(MusicTrack track) async {
    try {
      // Check if already cached
      final isCached = _cacheService.isCached(track.audioUrl);

      if (isCached) {
        final cacheKey = track.audioUrl.hashCode.abs().toString();
        final ext = track.audioUrl.split('.').last.split('?').first;
        final cacheDir = await _getCacheDir();
        final cachedPath = '$cacheDir/audio_$cacheKey.$ext';
        debugPrint('[SimpleAudio] Using cached file: $cachedPath');
        await _player.setFilePath(cachedPath);
      } else {
        debugPrint('[SimpleAudio] Streaming from URL');
        await _player.setUrl(track.audioUrl);
        _cacheService.prefetchAudio(track.audioUrl, priority: 10);
      }

      await _player.play();
      _clearError();
      debugPrint('[SimpleAudio] Playback started');
    } catch (e) {
      debugPrint('[SimpleAudio] Play error: $e');

      if (_retryCount < _maxRetries) {
        _retryCount++;
        _setError('Inajaribu tena... ($_retryCount/$_maxRetries)');
        await Future.delayed(_retryDelay);

        try {
          await _player.setUrl(track.audioUrl);
          await _player.play();
          _clearError();
        } catch (retryError) {
          if (_retryCount < _maxRetries) {
            await _attemptPlayback(track);
          } else {
            _setError('Imeshindikana kupakia wimbo. Angalia mtandao wako.');
          }
        }
      } else {
        _setError('Imeshindikana kupakia wimbo. Angalia mtandao wako.');
      }
    }
  }

  void _setError(String message) {
    _lastError = message;
    _errorController.add(message);
    debugPrint('[SimpleAudio] Error: $message');
  }

  void _clearError() {
    _lastError = null;
    _errorController.add(null);
  }

  /// Retry playing the current track
  Future<void> retry() async {
    if (_currentTrack != null) {
      _retryCount = 0;
      await _attemptPlayback(_currentTrack!);
    }
  }

  Future<String> _getCacheDir() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/audio_cache';
  }

  void _handleTrackCompletion() {
    debugPrint('[SimpleAudio] Track completed');
    switch (_repeatMode) {
      case RepeatMode.one:
        _player.seek(Duration.zero);
        _player.play();
        break;
      case RepeatMode.all:
        skipToNext();
        break;
      case RepeatMode.none:
        if (_currentIndex < _queue.length - 1) {
          skipToNext();
        } else {
          stop();
        }
        break;
    }
  }

  void _generateShuffleOrder() {
    _shuffleOrder = List.generate(_queue.length, (i) => i);
    if (_shuffleEnabled && _queue.isNotEmpty) {
      _shuffleOrder.shuffle();
      // Keep current track at current position
      final currentActualIndex = _currentIndex < _shuffleOrder.length ? _shuffleOrder[_currentIndex] : 0;
      _shuffleOrder.remove(currentActualIndex);
      if (_currentIndex < _shuffleOrder.length) {
        _shuffleOrder.insert(_currentIndex, currentActualIndex);
      } else {
        _shuffleOrder.add(currentActualIndex);
      }
    }
  }

  // Playback controls

  Future<void> play() async => await _player.play();

  Future<void> pause() async => await _player.pause();

  Future<void> playPause() async {
    debugPrint('[SimpleAudio] playPause called. isPlaying: $isPlaying');
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    await _notificationService.stopForegroundTask();
    try {
      await WakelockPlus.disable();
    } catch (e) {
      debugPrint('[SimpleAudio] Wakelock disable error (ignored): $e');
    }
  }

  Future<void> seek(Duration position) async => await _player.seek(position);

  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _queue.length;
    await _playCurrentTrack();
  }

  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;

    // If more than 3 seconds in, restart current track
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    await _playCurrentTrack();
  }

  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    await _playCurrentTrack();
  }

  Future<void> fastForward() async {
    final newPosition = _player.position + const Duration(seconds: 10);
    await _player.seek(newPosition);
  }

  Future<void> rewind() async {
    final newPosition = _player.position - const Duration(seconds: 10);
    await _player.seek(newPosition.isNegative ? Duration.zero : newPosition);
  }

  // Shuffle and repeat

  void setShuffle(bool enabled) {
    _shuffleEnabled = enabled;
    _generateShuffleOrder();
  }

  void setRepeatMode(RepeatMode mode) {
    _repeatMode = mode;
  }

  void cycleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.none:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.none;
        break;
    }
  }

  /// Remove item from queue
  void removeQueueItem(int index) {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex && _queue.isNotEmpty) {
      _currentIndex = _currentIndex % _queue.length;
    }
    _generateShuffleOrder();
  }

  /// Dispose resources
  void dispose() {
    _errorController.close();
    _player.dispose();
    _notificationService.dispose();
    try {
      WakelockPlus.disable();
    } catch (e) {
      debugPrint('[SimpleAudio] Wakelock dispose error (ignored): $e');
    }
  }
}
