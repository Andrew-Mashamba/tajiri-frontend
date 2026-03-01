/// Stream Reconnection Service
/// Handles automatic stream recovery after network drops
///
/// Features:
/// - Automatic reconnection with exponential backoff
/// - Network state monitoring with debouncing
/// - Graceful stream recovery
/// - User notifications
/// - Retry limit management

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Reconnection state
enum ReconnectionState {
  connected,
  disconnected,
  reconnecting,
  failed,
}

/// Reconnection event
class ReconnectionEvent {
  final ReconnectionState state;
  final int attemptNumber;
  final Duration? nextRetryIn;
  final String? errorMessage;

  const ReconnectionEvent({
    required this.state,
    this.attemptNumber = 0,
    this.nextRetryIn,
    this.errorMessage,
  });

  @override
  String toString() => 'ReconnectionEvent('
      'state: ${state.name}, '
      'attempt: $attemptNumber, '
      'nextRetry: $nextRetryIn, '
      'error: $errorMessage'
      ')';
}

class StreamReconnectionService {
  static final StreamReconnectionService _instance =
      StreamReconnectionService._internal();
  factory StreamReconnectionService() => _instance;
  StreamReconnectionService._internal();

  // Configuration
  static const int maxRetries = 5;
  static const Duration initialRetryDelay = Duration(seconds: 2);
  static const Duration maxRetryDelay = Duration(seconds: 30);
  static const Duration networkDebounceDelay = Duration(seconds: 3);

  // State
  ReconnectionState _state = ReconnectionState.connected;
  int _attemptNumber = 0;
  Timer? _reconnectTimer;
  Timer? _networkDebounceTimer;
  bool _isNetworkAvailable = true;
  bool _shouldReconnect = false;

  // Network monitoring
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _connectivitySubscription;

  // Stream controllers
  final _stateController = StreamController<ReconnectionEvent>.broadcast();

  // Public stream
  Stream<ReconnectionEvent> get stateStream => _stateController.stream;

  // Getters
  ReconnectionState get state => _state;
  int get attemptNumber => _attemptNumber;
  bool get isReconnecting => _state == ReconnectionState.reconnecting;
  bool get hasNetworkConnection => _isNetworkAvailable;

  // Callback for actual reconnection logic
  Future<bool> Function()? _onReconnect;

  /// Initialize the reconnection service
  Future<void> initialize({
    required Future<bool> Function() onReconnect,
  }) async {
    print('[Reconnect] 🚀 Initializing reconnection service');

    _onReconnect = onReconnect;

    // Start network monitoring
    _startNetworkMonitoring();

    print('[Reconnect] ✅ Reconnection service initialized');
  }

  /// Start monitoring network connectivity
  void _startNetworkMonitoring() {
    print('[Reconnect] 📡 Starting network monitoring');

    // Listen to connectivity changes
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      _handleConnectivityChange(results);
    });

    // Initial check
    _connectivity.checkConnectivity().then(_handleConnectivityChange);
  }

  /// Handle connectivity change with debouncing
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    // Cancel existing debounce timer
    _networkDebounceTimer?.cancel();

    // Debounce network changes (wait 3 seconds before acting)
    _networkDebounceTimer = Timer(networkDebounceDelay, () {
      final hasConnection =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);

      print('[Reconnect] 📡 Network state: ${hasConnection ? "CONNECTED" : "DISCONNECTED"}');

      if (_isNetworkAvailable && !hasConnection) {
        // Lost network
        _onNetworkLost();
      } else if (!_isNetworkAvailable && hasConnection) {
        // Regained network
        _onNetworkRegained();
      }

      _isNetworkAvailable = hasConnection;
    });
  }

  /// Called when network is lost
  void _onNetworkLost() {
    print('[Reconnect] ❌ Network lost - stream will disconnect');

    _updateState(ReconnectionState.disconnected);

    // Mark that we should reconnect when network returns
    _shouldReconnect = _state != ReconnectionState.connected;
  }

  /// Called when network is regained
  void _onNetworkRegained() {
    print('[Reconnect] ✅ Network regained');

    if (_shouldReconnect) {
      print('[Reconnect] 🔄 Attempting to reconnect...');
      _startReconnection();
    }
  }

  /// Notify that stream has disconnected (called from SDK)
  void notifyStreamDisconnected({String? reason}) {
    print('[Reconnect] 🔴 Stream disconnected: ${reason ?? "unknown reason"}');

    if (_state == ReconnectionState.reconnecting) {
      // Already reconnecting
      return;
    }

    _updateState(
      ReconnectionState.disconnected,
      errorMessage: reason,
    );

    // Only auto-reconnect if we have network
    if (_isNetworkAvailable) {
      _startReconnection();
    } else {
      print('[Reconnect] ⏸️ Waiting for network to return...');
      _shouldReconnect = true;
    }
  }

  /// Notify that stream has connected successfully
  void notifyStreamConnected() {
    print('[Reconnect] ✅ Stream connected successfully');

    _attemptNumber = 0;
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _updateState(ReconnectionState.connected);
  }

  /// Start reconnection attempts with exponential backoff
  void _startReconnection() {
    if (_attemptNumber >= maxRetries) {
      print('[Reconnect] ❌ Max retries reached ($maxRetries)');
      _updateState(
        ReconnectionState.failed,
        errorMessage: 'Failed after $maxRetries attempts',
      );
      return;
    }

    _attemptNumber++;

    // Calculate delay with exponential backoff
    final delay = _calculateBackoffDelay(_attemptNumber);

    print('[Reconnect] ⏱️ Attempt #$_attemptNumber in ${delay.inSeconds}s...');

    _updateState(
      ReconnectionState.reconnecting,
      attemptNumber: _attemptNumber,
      nextRetryIn: delay,
    );

    _reconnectTimer = Timer(delay, _attemptReconnection);
  }

  /// Calculate exponential backoff delay
  Duration _calculateBackoffDelay(int attempt) {
    // Exponential backoff: 2s, 4s, 8s, 16s, 30s (max)
    final delaySeconds = initialRetryDelay.inSeconds * (1 << (attempt - 1));
    final delay = Duration(seconds: delaySeconds);

    return delay > maxRetryDelay ? maxRetryDelay : delay;
  }

  /// Attempt reconnection
  Future<void> _attemptReconnection() async {
    if (!_isNetworkAvailable) {
      print('[Reconnect] ⏸️ No network - pausing reconnection');
      return;
    }

    print('[Reconnect] 🔄 Attempting reconnection #$_attemptNumber...');

    try {
      final success = await _onReconnect?.call() ?? false;

      if (success) {
        print('[Reconnect] ✅ Reconnection successful!');
        notifyStreamConnected();
      } else {
        print('[Reconnect] ❌ Reconnection failed');
        _startReconnection(); // Try again
      }
    } catch (e) {
      print('[Reconnect] ❌ Reconnection error: $e');
      _startReconnection(); // Try again
    }
  }

  /// Manually retry reconnection
  Future<void> retryNow() async {
    print('[Reconnect] 👤 Manual retry requested');

    _reconnectTimer?.cancel();
    _attemptNumber = 0;
    _startReconnection();
  }

  /// Stop reconnection attempts
  void stopReconnection() {
    print('[Reconnect] 🛑 Stopping reconnection');

    _reconnectTimer?.cancel();
    _attemptNumber = 0;
    _shouldReconnect = false;

    if (_state == ReconnectionState.reconnecting) {
      _updateState(ReconnectionState.disconnected);
    }
  }

  /// Reset reconnection state
  void reset() {
    print('[Reconnect] 🔄 Resetting reconnection state');

    _reconnectTimer?.cancel();
    _attemptNumber = 0;
    _shouldReconnect = false;
    _updateState(ReconnectionState.connected);
  }

  /// Update state and notify listeners
  void _updateState(
    ReconnectionState newState, {
    int? attemptNumber,
    Duration? nextRetryIn,
    String? errorMessage,
  }) {
    _state = newState;

    final event = ReconnectionEvent(
      state: newState,
      attemptNumber: attemptNumber ?? _attemptNumber,
      nextRetryIn: nextRetryIn,
      errorMessage: errorMessage,
    );

    _stateController.add(event);

    print('[Reconnect] 📢 State: ${event.toString()}');
  }

  /// Dispose resources
  void dispose() {
    print('[Reconnect] 🧹 Disposing reconnection service');

    _reconnectTimer?.cancel();
    _networkDebounceTimer?.cancel();
    _connectivitySubscription?.cancel();
    _stateController.close();
  }
}
