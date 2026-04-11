// lib/games/services/game_socket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

/// Service for real-time game communication.
///
/// Uses REST polling as the MVP transport. The interface is designed so that
/// when we add a Pusher/Reverb WebSocket client later, only the internals
/// change — all callbacks and public methods stay the same.
class GameSocketService {
  int? _sessionId;
  Timer? _pollTimer;
  bool _connected = false;
  bool _gameStarted = false;
  String? _lastStatus;
  int? _lastPlayer2Id;
  Map<String, dynamic>? _lastGameState;

  /// Whether the service is actively polling/connected.
  bool get connected => _connected;

  // ─── Callbacks ─────────────────────────────────────────────────

  /// Called when a second player joins the session.
  void Function(Map<String, dynamic> data)? onPlayerJoined;

  /// Called when the game transitions to active state.
  void Function(Map<String, dynamic> data)? onGameStarted;

  /// Called when the opponent submits a move.
  void Function(Map<String, dynamic> moveData)? onPlayerMove;

  /// Called when the game ends (win/loss/draw).
  void Function(Map<String, dynamic> data)? onGameEnded;

  /// Called when the opponent disconnects.
  void Function(Map<String, dynamic> data)? onPlayerDisconnected;

  // ─── Connection ────────────────────────────────────────────────

  /// Start polling for updates on the given session.
  void connect(int sessionId) {
    _sessionId = sessionId;
    _connected = true;
    _gameStarted = false;
    _lastStatus = null;
    _lastPlayer2Id = null;
    _lastGameState = null;
    _startPolling();
  }

  /// Stop polling and clean up.
  void disconnect() {
    _connected = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _sessionId = null;
  }

  /// Send a move to the server via REST.
  /// The polling loop will pick up the opponent's response.
  Future<bool> sendMove(int userId, Map<String, dynamic> moveData, {Map<String, dynamic>? gameState}) async {
    if (_sessionId == null) return false;
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/games/sessions/$_sessionId/move'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'user_id': userId,
          'move_data': moveData,
          if (gameState != null) 'game_state': gameState,
        }),
      );
      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // ─── Polling ───────────────────────────────────────────────────

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
    // Also poll immediately
    _poll();
  }

  Future<void> _poll() async {
    if (!_connected || _sessionId == null) return;
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/games/sessions/$_sessionId'),
        headers: ApiConfig.headers,
      );
      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);
      if (data['success'] != true || data['data'] == null) return;

      final session = data['data'] as Map<String, dynamic>;
      final status = session['status']?.toString();
      final player2Id = session['player_2_id'] != null
          ? _parseIntSafe(session['player_2_id'])
          : null;
      final gameState = session['game_state'] is Map<String, dynamic>
          ? session['game_state'] as Map<String, dynamic>
          : null;

      // Detect player joined
      if (player2Id != null && _lastPlayer2Id == null) {
        onPlayerJoined?.call(session);
      }

      // Detect game started
      if (status == 'active' && _lastStatus != 'active') {
        _gameStarted = true;
        onGameStarted?.call(session);
      }

      // Detect game state change (opponent move).
      // Only fire onPlayerMove after the game has started to avoid
      // treating the initial state sync as an opponent move.
      if (_gameStarted && gameState != null && _lastGameState != null) {
        final stateChanged = jsonEncode(gameState) != jsonEncode(_lastGameState);
        if (stateChanged) {
          onPlayerMove?.call(gameState);
        }
      }

      // Detect game ended
      if ((status == 'completed' || status == 'forfeited' || status == 'cancelled') &&
          _lastStatus != status) {
        onGameEnded?.call(session);
        disconnect();
        return;
      }

      _lastStatus = status;
      _lastPlayer2Id = player2Id;
      _lastGameState = gameState;
    } catch (_) {
      // Silently retry on next poll
    }
  }

  /// Manually poll once (for use outside the automatic timer).
  Future<Map<String, dynamic>?> pollOnce(int sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/games/sessions/$sessionId'),
        headers: ApiConfig.headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
      }
    } catch (_) {
      // ignore
    }
    return null;
  }

  /// Dispose resources.
  void dispose() {
    disconnect();
    onPlayerJoined = null;
    onGameStarted = null;
    onPlayerMove = null;
    onGameEnded = null;
    onPlayerDisconnected = null;
  }
}

int _parseIntSafe(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
