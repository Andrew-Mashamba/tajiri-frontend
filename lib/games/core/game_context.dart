// lib/games/core/game_context.dart
import 'game_enums.dart';
import '../services/game_socket_service.dart';

/// Context object passed to game widgets when they are built.
/// Contains everything a game needs to communicate with the platform.
class GameContext {
  /// Backend session ID.
  final int sessionId;

  /// Current user's ID.
  final int userId;

  /// Opponent's user ID (null for practice mode).
  final int? opponentId;

  /// Opponent's display name.
  final String? opponentName;

  /// Game definition ID (e.g. 'tic_tac_toe').
  final String gameId;

  /// Current game mode.
  final GameMode mode;

  /// Server-generated seed for deterministic game setup.
  final String gameSeed;

  /// Saved game state for reconnection (null for new games).
  final Map<String, dynamic>? gameState;

  /// WebSocket/polling service for real-time communication.
  final GameSocketService socketService;

  /// Callback to invoke when the game finishes.
  /// Pass a result map with at minimum: {winner_id, player_1_score, player_2_score}.
  final void Function(Map<String, dynamic> result) onGameComplete;

  /// Optional callback for game widgets to report live score changes.
  /// Parameters: (myScore, opponentScore).
  final void Function(int myScore, int opponentScore)? onScoreUpdate;

  /// Listener for opponent moves. Games should register a callback here
  /// in their initState to receive moves from the opponent via polling/socket.
  /// Set by the game widget, invoked by GamePlayPage when a move arrives.
  void Function(Map<String, dynamic> moveData)? _onOpponentMoveListener;

  /// Register a listener for opponent moves.
  void setOnOpponentMove(void Function(Map<String, dynamic> moveData) listener) {
    _onOpponentMoveListener = listener;
  }

  /// Deliver an opponent move to the registered listener.
  void deliverOpponentMove(Map<String, dynamic> moveData) {
    _onOpponentMoveListener?.call(moveData);
  }

  GameContext({
    required this.sessionId,
    required this.userId,
    this.opponentId,
    this.opponentName,
    required this.gameId,
    required this.mode,
    required this.gameSeed,
    this.gameState,
    required this.socketService,
    required this.onGameComplete,
    this.onScoreUpdate,
  });
}
