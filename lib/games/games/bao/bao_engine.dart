// lib/games/games/bao/bao_engine.dart
// Pure Dart — no Flutter imports.
//
// Board layout (32 pits):
//   North outer: [0][1][2][3][4][5][6][7]
//   North inner: [8][9][10][11][12*][13][14][15]   *12 = North kuu
//   ─────────────────────────────────────────
//   South inner: [16][17][18][19][20*][21][22][23]  *20 = South kuu
//   South outer: [24][25][26][27][28][29][30][31]

enum BaoPlayer {
  north,
  south;

  BaoPlayer get opponent => this == north ? south : north;
}

enum BaoPhase {
  namua,
  mtaji,
}

/// A single animation step for the UI to display.
class BaoAnimStep {
  final int pitIndex;
  final String action; // 'place', 'sow', 'capture', 'pickup'
  final List<int> pitsSnapshot;

  const BaoAnimStep({
    required this.pitIndex,
    required this.action,
    required this.pitsSnapshot,
  });
}

class BaoBoard {
  List<int> pits;
  int northStock;
  int southStock;
  BaoPhase phase;
  BaoPlayer currentPlayer;

  static const int northKuu = 12;
  static const int southKuu = 20;

  BaoBoard({
    List<int>? pits,
    this.northStock = 10,
    this.southStock = 10,
    this.phase = BaoPhase.namua,
    this.currentPlayer = BaoPlayer.south,
  }) : pits = pits ?? List<int>.filled(32, 0);

  factory BaoBoard.initial() {
    final board = BaoBoard();
    // 2 seeds in each inner pit
    for (int i = 8; i <= 15; i++) {
      board.pits[i] = 2;
    }
    for (int i = 16; i <= 23; i++) {
      board.pits[i] = 2;
    }
    return board;
  }

  // ── Pit topology helpers ──────────────────────────────────

  bool _isNorthInner(int i) => i >= 8 && i <= 15;
  bool _isSouthInner(int i) => i >= 16 && i <= 23;

  bool _isPlayerInner(BaoPlayer p, int i) =>
      p == BaoPlayer.north ? _isNorthInner(i) : _isSouthInner(i);

  /// Opposite inner pit: south inner i <-> north inner (31 - i)
  int oppositePit(int i) => 31 - i;

  /// Outer pit behind an inner pit.
  int outerBehind(int i) {
    if (_isSouthInner(i)) return i + 8; // south inner -> south outer
    if (_isNorthInner(i)) return i - 8; // north inner -> north outer
    return -1;
  }

  // ── Sowing path ──────────────────────────────────────────

  /// Returns the ordered sowing path for [player] starting AFTER [startPit].
  /// The path goes counter-clockwise within the player's two rows.
  List<int> _sowingPath(BaoPlayer player, int startPit) {
    List<int> fullPath;
    if (player == BaoPlayer.south) {
      // Inner: 16→17→...→23, Outer: 31→30→...→24
      final inner = List.generate(8, (i) => 16 + i);
      final outer = List.generate(8, (i) => 31 - i);
      fullPath = [...inner, ...outer]; // 16 pits total
    } else {
      // Inner: 15→14→...→8, Outer: 0→1→...→7
      final inner = List.generate(8, (i) => 15 - i);
      final outer = List.generate(8, (i) => i);
      fullPath = [...inner, ...outer];
    }

    // Rotate so that the pit AFTER startPit is first
    final idx = fullPath.indexOf(startPit);
    if (idx == -1) return fullPath;
    return [...fullPath.sublist(idx + 1), ...fullPath.sublist(0, idx + 1)];
  }

  // ── Legal moves ──────────────────────────────────────────

  List<int> legalMoves(BaoPlayer player) {
    if (phase == BaoPhase.namua) {
      return _namuaLegalMoves(player);
    }
    return _mtajiLegalMoves(player);
  }

  List<int> _namuaLegalMoves(BaoPlayer player) {
    final stock = player == BaoPlayer.north ? northStock : southStock;
    if (stock <= 0) return [];

    // Inner pits that are non-empty
    final innerRange =
        player == BaoPlayer.north ? List.generate(8, (i) => 8 + i) : List.generate(8, (i) => 16 + i);
    final nonEmpty = innerRange.where((i) => pits[i] > 0).toList();

    // Check which lead to captures
    final capturing = nonEmpty.where((i) => _wouldCapture(player, i, isNamua: true)).toList();
    if (capturing.isNotEmpty) return capturing;
    return nonEmpty;
  }

  List<int> _mtajiLegalMoves(BaoPlayer player) {
    final playerPits = <int>[];
    final range = player == BaoPlayer.north
        ? List.generate(16, (i) => i)
        : List.generate(16, (i) => 16 + i);
    for (final i in range) {
      if (pits[i] >= 2) playerPits.add(i);
    }
    return playerPits;
  }

  /// Check if placing/sowing from [pit] would lead to a capture.
  bool _wouldCapture(BaoPlayer player, int pit, {bool isNamua = false}) {
    final copy_ = copy();
    if (isNamua) {
      // Place 1 seed
      copy_.pits[pit] += 1;
    }
    // Simulate sowing
    return copy_._simulateCapture(player, pit);
  }

  bool _simulateCapture(BaoPlayer player, int startPit) {
    int seeds = pits[startPit];
    if (seeds == 0) return false;

    final path = _sowingPath(player, startPit);
    int pathIdx = 0;
    int currentPit = startPit;
    // Don't pick up from start in simulation, just trace where last seed lands
    int remaining = seeds;
    while (remaining > 0 && pathIdx < path.length * 3) {
      currentPit = path[pathIdx % path.length];
      remaining--;
      pathIdx++;
    }
    // Check if last seed lands on player's inner row with opposite non-empty
    if (_isPlayerInner(player, currentPit)) {
      final opp = oppositePit(currentPit);
      // +1 because we'd be adding a seed there
      if (pits[currentPit] >= 0 && pits[opp] > 0) return true;
    }
    return false;
  }

  // ── Make move ────────────────────────────────────────────

  /// Execute a move and return animation steps.
  List<BaoAnimStep> makeMove(int pitIndex) {
    final steps = <BaoAnimStep>[];
    final player = currentPlayer;

    if (phase == BaoPhase.namua) {
      // Place 1 seed from stock
      if (player == BaoPlayer.north) {
        northStock--;
      } else {
        southStock--;
      }
      pits[pitIndex] += 1;
      steps.add(BaoAnimStep(
          pitIndex: pitIndex,
          action: 'place',
          pitsSnapshot: List<int>.from(pits)));
    }

    // Sow from the pit
    _sow(player, pitIndex, steps);

    // Check phase transition
    if (phase == BaoPhase.namua && northStock <= 0 && southStock <= 0) {
      phase = BaoPhase.mtaji;
    }

    // Switch player
    currentPlayer = currentPlayer.opponent;

    return steps;
  }

  void _sow(BaoPlayer player, int startPit, List<BaoAnimStep> steps) {
    int seeds = pits[startPit];
    pits[startPit] = 0;
    steps.add(BaoAnimStep(
        pitIndex: startPit,
        action: 'pickup',
        pitsSnapshot: List<int>.from(pits)));

    final path = _sowingPath(player, startPit);
    int pathIdx = 0;

    // Safety: prevent infinite loops
    int iterations = 0;
    const maxIterations = 500;

    while (seeds > 0 && iterations < maxIterations) {
      iterations++;
      final target = path[pathIdx % path.length];
      pits[target] += 1;
      seeds--;
      pathIdx++;

      steps.add(BaoAnimStep(
          pitIndex: target,
          action: 'sow',
          pitsSnapshot: List<int>.from(pits)));

      if (seeds == 0) {
        // Last seed landed
        if (_isPlayerInner(player, target)) {
          final opp = oppositePit(target);
          final outerOpp = outerBehind(opp);

          if (pits[opp] > 0) {
            // CAPTURE: take opponent's inner + outer pit seeds
            int captured = pits[opp];
            pits[opp] = 0;
            if (outerOpp >= 0 && outerOpp < 32) {
              captured += pits[outerOpp];
              pits[outerOpp] = 0;
            }
            steps.add(BaoAnimStep(
                pitIndex: opp,
                action: 'capture',
                pitsSnapshot: List<int>.from(pits)));

            // Continue sowing captured seeds from the landing pit
            pits[target] += captured;
            seeds = pits[target];
            pits[target] = 0;
            // Reset path from capture pit
            final newPath = _sowingPath(player, target);
            // We need to restart sowing from target
            pathIdx = 0;
            // Replace path reference — use a closure-like approach
            for (int i = 0; i < newPath.length; i++) {
              if (i < path.length) {
                path[i] = newPath[i];
              }
            }
            continue;
          }
        }

        // Relay sowing: if last seed lands in non-empty pit, pick up and continue
        if (pits[target] > 1) {
          seeds = pits[target];
          pits[target] = 0;
          steps.add(BaoAnimStep(
              pitIndex: target,
              action: 'pickup',
              pitsSnapshot: List<int>.from(pits)));
          // Continue sowing from this pit
          final newPath = _sowingPath(player, target);
          pathIdx = 0;
          for (int i = 0; i < newPath.length; i++) {
            if (i < path.length) {
              path[i] = newPath[i];
            }
          }
          continue;
        }
        // Landed in empty pit (now has 1 seed) → turn ends
        break;
      }
    }
  }

  // ── Game end ─────────────────────────────────────────────

  bool isGameOver() {
    return legalMoves(currentPlayer).isEmpty;
  }

  BaoPlayer? winner() {
    if (!isGameOver()) return null;
    return currentPlayer.opponent;
  }

  // ── Serialization ────────────────────────────────────────

  BaoBoard copy() {
    return BaoBoard(
      pits: List<int>.from(pits),
      northStock: northStock,
      southStock: southStock,
      phase: phase,
      currentPlayer: currentPlayer,
    );
  }

  Map<String, dynamic> toJson() => {
        'pits': pits,
        'northStock': northStock,
        'southStock': southStock,
        'phase': phase.name,
        'currentPlayer': currentPlayer.name,
      };

  factory BaoBoard.fromJson(Map<String, dynamic> json) {
    return BaoBoard(
      pits: List<int>.from(json['pits']),
      northStock: json['northStock'] as int,
      southStock: json['southStock'] as int,
      phase: json['phase'] == 'namua' ? BaoPhase.namua : BaoPhase.mtaji,
      currentPlayer: json['currentPlayer'] == 'north'
          ? BaoPlayer.north
          : BaoPlayer.south,
    );
  }
}
