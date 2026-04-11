// lib/games/core/game_interface.dart

/// Interface that every game widget should implement.
/// Provides hooks for the platform to communicate with the game.
abstract class GameInterface {
  /// Unique identifier matching the [GameDefinition.id].
  String get gameId;

  /// Called when the opponent submits a move via WebSocket/polling.
  /// The game should update its state to reflect the opponent's action.
  void onOpponentMove(Map<String, dynamic> moveData);

  /// Called when reconnecting to a game in progress.
  /// The game should restore its state from [savedState].
  void onReconnect(Map<String, dynamic> savedState);

  /// Returns the current game state for persistence/sync.
  /// Called periodically and on disconnect to save progress.
  Map<String, dynamic> getCurrentState();
}
