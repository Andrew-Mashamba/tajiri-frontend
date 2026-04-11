// lib/games/core/game_registry.dart
import 'game_definition.dart';
import 'game_enums.dart';

/// Singleton registry for all games available on the platform.
/// Game plugins register themselves here at app startup.
class GameRegistry {
  static final GameRegistry _instance = GameRegistry._();
  static GameRegistry get instance => _instance;
  GameRegistry._();

  final List<GameDefinition> _games = [];

  /// Register a game definition. Ignores duplicates by [GameDefinition.id].
  void register(GameDefinition definition) {
    final exists = _games.any((g) => g.id == definition.id);
    if (!exists) {
      _games.add(definition);
    }
  }

  /// All registered games, sorted alphabetically by name.
  List<GameDefinition> get allGames {
    final sorted = List<GameDefinition>.from(_games);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  /// Total count of registered games.
  int get count => _games.length;

  /// Games filtered by category. Returns all if [cat] is [GameCategory.all].
  List<GameDefinition> byCategory(GameCategory cat) {
    if (cat == GameCategory.all) return allGames;
    final filtered = _games.where((g) => g.category == cat).toList();
    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  }

  /// Look up a game by its unique ID. Returns null if not found.
  GameDefinition? get(String id) {
    for (final g in _games) {
      if (g.id == id) return g;
    }
    return null;
  }

  /// Search games by name (English or Swahili). Case-insensitive.
  List<GameDefinition> search(String query) {
    if (query.isEmpty) return allGames;
    final q = query.toLowerCase();
    final results = _games.where((g) {
      return g.name.toLowerCase().contains(q) ||
          g.nameSwahili.toLowerCase().contains(q) ||
          g.description.toLowerCase().contains(q) ||
          g.category.displayName.toLowerCase().contains(q);
    }).toList();
    results.sort((a, b) => a.name.compareTo(b.name));
    return results;
  }

  /// Clear all registrations. Useful for testing.
  void clear() {
    _games.clear();
  }
}
