// lib/games/models/game_result.dart

/// Generic wrapper for single-item API responses.
class GameResult<T> {
  final bool success;
  final T? data;
  final String? message;

  GameResult({required this.success, this.data, this.message});
}

/// Generic wrapper for list API responses.
class GameListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  GameListResult({required this.success, this.items = const [], this.message});
}
