import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../models/music_models.dart';
import 'simple_audio_service.dart';

/// Music Notification Service using flutter_foreground_task
/// Shows a persistent notification with track info and playback controls
class MusicNotificationService {
  static final MusicNotificationService _instance = MusicNotificationService._internal();
  factory MusicNotificationService() => _instance;
  MusicNotificationService._internal();

  bool _isInitialized = false;
  bool _isRunning = false;
  bool _callbackRegistered = false;
  MusicTrack? _currentTrack;
  bool _isPlaying = false;

  bool get isRunning => _isRunning;

  /// Initialize the foreground task notification channels
  Future<void> initialize() async {
    if (_isInitialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'tajiri_music_channel',
        channelName: 'Tajiri Music',
        channelDescription: 'Music playback controls',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        playSound: false,
        enableVibration: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );

    // Initialize communication port
    FlutterForegroundTask.initCommunicationPort();

    _isInitialized = true;
    debugPrint('[MusicNotification] Initialized');
  }

  /// Start the foreground task with current track info
  Future<void> startForegroundTask({
    required MusicTrack track,
    required bool isPlaying,
  }) async {
    if (!_isInitialized) await initialize();

    _currentTrack = track;
    _isPlaying = isPlaying;

    if (_isRunning) {
      await updateNotification(track: track, isPlaying: isPlaying);
      return;
    }

    debugPrint('[MusicNotification] Starting foreground task for: ${track.title}');

    // Request permission for Android 13+
    final notificationPermission = await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    try {
      _registerTaskDataCallback();

      final serviceResult = await FlutterForegroundTask.startService(
        notificationTitle: track.title,
        notificationText: '${track.artist?.name ?? "Msanii"} ${isPlaying ? "- Inacheza" : "- Imesimama"}',
        notificationButtons: _buildNotificationButtons(isPlaying),
        callback: startCallback,
      );
      debugPrint('[MusicNotification] Start service result: $serviceResult');

      _isRunning = true;
    } catch (e) {
      debugPrint('[MusicNotification] Failed to start: $e');
    }
  }

  /// Update the notification
  Future<void> updateNotification({
    MusicTrack? track,
    bool? isPlaying,
  }) async {
    if (!_isRunning) return;

    if (track != null) _currentTrack = track;
    if (isPlaying != null) _isPlaying = isPlaying;

    final currentTrack = _currentTrack;
    if (currentTrack == null) return;

    await FlutterForegroundTask.updateService(
      notificationTitle: currentTrack.title,
      notificationText: '${currentTrack.artist?.name ?? "Msanii"} ${_isPlaying ? "- Inacheza" : "- Imesimama"}',
      notificationButtons: _buildNotificationButtons(_isPlaying),
    );
  }

  List<NotificationButton> _buildNotificationButtons(bool isPlaying) {
    return [
      const NotificationButton(id: 'prev', text: '<<'),
      NotificationButton(id: 'playPause', text: isPlaying ? '| |' : '>'),
      const NotificationButton(id: 'next', text: '>>'),
      const NotificationButton(id: 'stop', text: 'X'),
    ];
  }

  void _registerTaskDataCallback() {
    if (_callbackRegistered) return;

    FlutterForegroundTask.addTaskDataCallback(_handleNotificationAction);
    _callbackRegistered = true;
  }

  void _handleNotificationAction(dynamic message) {
    if (message is! String) return;

    final audioService = SimpleAudioService();

    switch (message) {
      case 'prev':
        audioService.skipToPrevious();
        break;
      case 'playPause':
        audioService.playPause();
        Future.delayed(const Duration(milliseconds: 100), () {
          updateNotification(isPlaying: audioService.isPlaying);
        });
        break;
      case 'next':
        audioService.skipToNext();
        break;
      case 'stop':
        audioService.stop();
        stopForegroundTask();
        break;
    }
  }

  void ensureCallbackActive() {
    if (_isRunning && !_callbackRegistered) {
      _registerTaskDataCallback();
    }
  }

  Future<void> stopForegroundTask() async {
    if (!_isRunning) return;

    await FlutterForegroundTask.stopService();
    _isRunning = false;
    _currentTrack = null;
  }

  void dispose() {
    debugPrint('[MusicNotification] Disposed');
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MusicTaskHandler());
}

class MusicTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[MusicTaskHandler] Started');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    FlutterForegroundTask.sendDataToMain('stop');
  }

  @override
  void onNotificationButtonPressed(String id) {
    FlutterForegroundTask.launchApp();
    FlutterForegroundTask.sendDataToMain(id);
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationDismissed() {
    FlutterForegroundTask.sendDataToMain('stop');
  }
}
