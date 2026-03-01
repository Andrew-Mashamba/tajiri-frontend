import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/music_models.dart';
import 'audio_cache_service.dart';

/// Background Audio Service for Spotify-style playback
/// Features:
/// - Background playback with system notification controls
/// - Queue management (next/previous/shuffle)
/// - Loop modes (off/all/one)
/// - Wakelock to prevent screen sleep
/// - Integration with audio caching
class BackgroundAudioService {
  static final BackgroundAudioService _instance = BackgroundAudioService._internal();
  factory BackgroundAudioService() => _instance;
  BackgroundAudioService._internal();

  AudioHandler? _audioHandler;
  final AudioCacheService _cacheService = AudioCacheService();
  bool _isInitialized = false;

  /// Check if audio service is ready to use
  bool get isReady => _isInitialized && _audioHandler != null;

  // Stream controllers for UI updates
  final _playbackStateController = StreamController<PlaybackState>.broadcast();
  final _mediaItemController = StreamController<MediaItem?>.broadcast();
  final _queueController = StreamController<List<MediaItem>>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();

  // Public streams
  Stream<PlaybackState> get playbackStateStream => _playbackStateController.stream;
  Stream<MediaItem?> get mediaItemStream => _mediaItemController.stream;
  Stream<List<MediaItem>> get queueStream => _queueController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;

  // Current state getters
  PlaybackState? get playbackState => (_audioHandler as TajiriAudioHandler?)?.playbackState.value;
  MediaItem? get currentMediaItem => (_audioHandler as TajiriAudioHandler?)?.mediaItem.value;
  List<MediaItem> get queue => (_audioHandler as TajiriAudioHandler?)?.queue.value ?? [];
  bool get isPlaying => playbackState?.playing ?? false;
  Duration get position => (_audioHandler as TajiriAudioHandler?)?.position ?? Duration.zero;
  Duration? get duration => (_audioHandler as TajiriAudioHandler?)?.duration;

  /// Initialize the audio service
  Future<void> initialize() async {
    if (_isInitialized && _audioHandler != null) {
      debugPrint('[BackgroundAudio] Already initialized');
      return;
    }

    // Reset state if previous init failed
    _isInitialized = false;

    debugPrint('[BackgroundAudio] Initializing...');

    try {
      await _cacheService.initialize();
      debugPrint('[BackgroundAudio] Cache service initialized');

      _audioHandler = await AudioService.init(
        builder: () => TajiriAudioHandler(_cacheService),
        config: AudioServiceConfig(
          androidNotificationChannelId: 'com.tajiri.app.audio',
          androidNotificationChannelName: 'Tajiri Music',
          androidNotificationChannelDescription: 'Sikiliza muziki wa Tajiri',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true, // Required when androidNotificationOngoing is true
          androidShowNotificationBadge: true,
          notificationColor: const Color(0xFF1DB954),
          androidNotificationIcon: 'drawable/ic_notification',
          preloadArtwork: true,
        ),
      );

      // Forward streams
      (_audioHandler as TajiriAudioHandler).playbackState.listen((state) {
        _playbackStateController.add(state);
      });

      (_audioHandler as TajiriAudioHandler).mediaItem.listen((item) {
        _mediaItemController.add(item);
      });

      (_audioHandler as TajiriAudioHandler).queue.listen((q) {
        _queueController.add(q);
      });

      (_audioHandler as TajiriAudioHandler).positionStream.listen((pos) {
        _positionController.add(pos);
      });

      (_audioHandler as TajiriAudioHandler).durationStream.listen((dur) {
        _durationController.add(dur);
      });

      _isInitialized = true;
      debugPrint('[BackgroundAudio] Service initialized successfully');
    } catch (e) {
      debugPrint('[BackgroundAudio] Init error: $e');
      // Check if it's "already initialized" error - just ignore and mark as failed
      // User needs to restart the app for a clean init
      _isInitialized = false;
      _audioHandler = null;
      rethrow; // Let caller handle the error
    }
  }

  /// Play a single track
  Future<void> playTrack(MusicTrack track) async {
    if (!_isInitialized) await initialize();
    await (_audioHandler as TajiriAudioHandler?)?.playTrack(track);
  }

  /// Play a list of tracks starting from index
  Future<void> playQueue(List<MusicTrack> tracks, {int startIndex = 0}) async {
    if (!_isInitialized) await initialize();
    await (_audioHandler as TajiriAudioHandler?)?.playQueue(tracks, startIndex: startIndex);
  }

  /// Add track to queue
  Future<void> addToQueue(MusicTrack track) async {
    if (!_isInitialized) await initialize();
    await (_audioHandler as TajiriAudioHandler?)?.addToQueue(track);
  }

  /// Play/Pause toggle
  Future<void> playPause() async {
    debugPrint('[BackgroundAudio] playPause called. isReady: $isReady, isPlaying: $isPlaying');
    if (!isReady) {
      debugPrint('[BackgroundAudio] ERROR: Audio service not ready!');
      return;
    }
    if (isPlaying) {
      debugPrint('[BackgroundAudio] Pausing...');
      await _audioHandler?.pause();
    } else {
      debugPrint('[BackgroundAudio] Playing...');
      await _audioHandler?.play();
    }
  }

  /// Play
  Future<void> play() async => await _audioHandler?.play();

  /// Pause
  Future<void> pause() async => await _audioHandler?.pause();

  /// Stop
  Future<void> stop() async => await _audioHandler?.stop();

  /// Skip to next
  Future<void> skipToNext() async => await _audioHandler?.skipToNext();

  /// Skip to previous
  Future<void> skipToPrevious() async => await _audioHandler?.skipToPrevious();

  /// Seek to position
  Future<void> seek(Duration position) async => await _audioHandler?.seek(position);

  /// Fast forward 10 seconds
  Future<void> fastForward() async => await _audioHandler?.fastForward();

  /// Rewind 10 seconds
  Future<void> rewind() async => await _audioHandler?.rewind();

  /// Set shuffle mode
  Future<void> setShuffle(bool enabled) async {
    await _audioHandler?.setShuffleMode(
      enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    );
  }

  /// Set repeat mode
  Future<void> setRepeatMode(AudioServiceRepeatMode mode) async {
    await _audioHandler?.setRepeatMode(mode);
  }

  /// Cycle through repeat modes
  Future<void> cycleRepeatMode() async {
    await (_audioHandler as TajiriAudioHandler?)?.cycleRepeatMode();
  }

  /// Get current repeat mode
  AudioServiceRepeatMode get repeatMode =>
      (_audioHandler as TajiriAudioHandler?)?.currentRepeatMode ?? AudioServiceRepeatMode.none;

  /// Get shuffle state
  bool get shuffleEnabled =>
      (_audioHandler as TajiriAudioHandler?)?.shuffleEnabled ?? false;

  /// Skip to specific index in queue
  Future<void> skipToQueueItem(int index) async {
    await _audioHandler?.skipToQueueItem(index);
  }

  /// Remove item from queue
  Future<void> removeQueueItem(MediaItem item) async {
    await _audioHandler?.removeQueueItem(item);
  }

  /// Clear queue
  Future<void> clearQueue() async {
    await (_audioHandler as TajiriAudioHandler?)?.clearQueue();
  }

  /// Dispose
  void dispose() {
    _playbackStateController.close();
    _mediaItemController.close();
    _queueController.close();
    _positionController.close();
    _durationController.close();
  }
}

/// Custom Audio Handler for Tajiri
class TajiriAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final AudioCacheService _cacheService;
  final List<MusicTrack> _trackList = [];
  int _currentIndex = 0;
  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;
  bool _shuffleEnabled = false;
  List<int> _shuffleOrder = [];

  // Position stream
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;

  AudioServiceRepeatMode get currentRepeatMode => _repeatMode;
  bool get shuffleEnabled => _shuffleEnabled;

  TajiriAudioHandler(this._cacheService) {
    _init();
  }

  void _init() {
    // Listen to player state changes
    _player.playbackEventStream.listen(_broadcastState);

    // Listen for track completion
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _handleTrackCompletion();
      }
    });

    // Listen for playing state to manage wakelock
    _player.playingStream.listen((playing) {
      if (playing) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    });
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
      shuffleMode: _shuffleEnabled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
      repeatMode: _repeatMode,
    ));
  }

  /// Play a single track
  Future<void> playTrack(MusicTrack track) async {
    await playQueue([track], startIndex: 0);
  }

  /// Play a queue of tracks
  Future<void> playQueue(List<MusicTrack> tracks, {int startIndex = 0}) async {
    _trackList.clear();
    _trackList.addAll(tracks);
    _currentIndex = startIndex;
    _generateShuffleOrder();

    // Update queue
    queue.add(_tracksToMediaItems(tracks));

    // Play current track
    await _playCurrentTrack();

    // Prefetch next tracks
    _prefetchUpcoming();
  }

  /// Add track to queue
  Future<void> addToQueue(MusicTrack track) async {
    _trackList.add(track);
    final items = queue.value;
    items.add(_trackToMediaItem(track));
    queue.add(items);
    _generateShuffleOrder();
  }

  /// Clear queue
  Future<void> clearQueue() async {
    await stop();
    _trackList.clear();
    queue.add([]);
    mediaItem.add(null);
  }

  Future<void> _playCurrentTrack() async {
    if (_trackList.isEmpty) return;

    final index = _shuffleEnabled ? _shuffleOrder[_currentIndex] : _currentIndex;
    final track = _trackList[index];

    // Update current media item
    mediaItem.add(_trackToMediaItem(track));

    try {
      // Try to get cached file first
      final cachedPath = await _cacheService.getAudioFile(track.audioUrl);

      if (cachedPath != null) {
        await _player.setFilePath(cachedPath);
      } else {
        await _player.setUrl(track.audioUrl);
      }

      await _player.play();
    } catch (e) {
      debugPrint('[TajiriAudioHandler] Play error: $e');
      // Try direct URL as fallback
      try {
        await _player.setUrl(track.audioUrl);
        await _player.play();
      } catch (e2) {
        debugPrint('[TajiriAudioHandler] Fallback error: $e2');
      }
    }
  }

  void _prefetchUpcoming() {
    // Prefetch next 3 tracks
    for (var i = 1; i <= 3; i++) {
      final nextIndex = (_currentIndex + i) % _trackList.length;
      final index = _shuffleEnabled ? _shuffleOrder[nextIndex] : nextIndex;
      if (index < _trackList.length) {
        _cacheService.prefetchAudio(_trackList[index].audioUrl, priority: 4 - i);
      }
    }
  }

  void _handleTrackCompletion() {
    switch (_repeatMode) {
      case AudioServiceRepeatMode.one:
        // Replay current track
        _player.seek(Duration.zero);
        _player.play();
        break;
      case AudioServiceRepeatMode.all:
        // Go to next, loop back to start if at end
        skipToNext();
        break;
      case AudioServiceRepeatMode.none:
      case AudioServiceRepeatMode.group:
        // Go to next if not at end
        if (_currentIndex < _trackList.length - 1) {
          skipToNext();
        } else {
          // Stop at end of queue
          stop();
        }
        break;
    }
  }

  void _generateShuffleOrder() {
    _shuffleOrder = List.generate(_trackList.length, (i) => i);
    if (_shuffleEnabled) {
      _shuffleOrder.shuffle();
      // Keep current track at current position
      final currentActualIndex = _shuffleEnabled ? _shuffleOrder[_currentIndex] : _currentIndex;
      _shuffleOrder.remove(currentActualIndex);
      _shuffleOrder.insert(_currentIndex, currentActualIndex);
    }
  }

  MediaItem _trackToMediaItem(MusicTrack track) {
    return MediaItem(
      id: track.id.toString(),
      title: track.title,
      artist: track.artist?.name ?? 'Msanii',
      album: track.album ?? '',
      duration: Duration(seconds: track.duration),
      artUri: track.coverUrl.isNotEmpty ? Uri.parse(track.coverUrl) : null,
      extras: {
        'trackId': track.id,
        'audioUrl': track.audioUrl,
        'isSaved': track.isSaved ?? false,
      },
    );
  }

  List<MediaItem> _tracksToMediaItems(List<MusicTrack> tracks) {
    return tracks.map(_trackToMediaItem).toList();
  }

  /// Cycle through repeat modes
  Future<void> cycleRepeatMode() async {
    switch (_repeatMode) {
      case AudioServiceRepeatMode.none:
        await setRepeatMode(AudioServiceRepeatMode.all);
        break;
      case AudioServiceRepeatMode.all:
        await setRepeatMode(AudioServiceRepeatMode.one);
        break;
      case AudioServiceRepeatMode.one:
      case AudioServiceRepeatMode.group:
        await setRepeatMode(AudioServiceRepeatMode.none);
        break;
    }
  }

  // BaseAudioHandler overrides

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    WakelockPlus.disable();
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_trackList.isEmpty) return;

    _currentIndex = (_currentIndex + 1) % _trackList.length;
    await _playCurrentTrack();
    _prefetchUpcoming();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_trackList.isEmpty) return;

    // If more than 3 seconds in, restart current track
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    _currentIndex = (_currentIndex - 1 + _trackList.length) % _trackList.length;
    await _playCurrentTrack();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _trackList.length) return;
    _currentIndex = index;
    await _playCurrentTrack();
    _prefetchUpcoming();
  }

  @override
  Future<void> fastForward() async {
    final newPosition = _player.position + const Duration(seconds: 10);
    await _player.seek(newPosition);
  }

  @override
  Future<void> rewind() async {
    final newPosition = _player.position - const Duration(seconds: 10);
    await _player.seek(newPosition.isNegative ? Duration.zero : newPosition);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    _shuffleEnabled = shuffleMode == AudioServiceShuffleMode.all;
    _generateShuffleOrder();
    _broadcastState(PlaybackEvent());
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    _repeatMode = repeatMode;
    _broadcastState(PlaybackEvent());
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }
}
