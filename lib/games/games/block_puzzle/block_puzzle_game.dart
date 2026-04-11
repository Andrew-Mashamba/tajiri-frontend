// lib/games/games/block_puzzle/block_puzzle_game.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/game_context.dart' as gc;
import '../../core/game_interface.dart';
import 'block_puzzle_engine.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const double _kCellSize = 30.0;

class BlockPuzzleGame extends StatefulWidget {
  final gc.GameContext gameContext;
  const BlockPuzzleGame({super.key, required this.gameContext});

  @override
  State<BlockPuzzleGame> createState() => BlockPuzzleGameState();
}

class BlockPuzzleGameState extends State<BlockPuzzleGame>
    implements GameInterface {
  gc.GameContext get _ctx => widget.gameContext;

  late BlockPuzzleEngine _engine;
  bool _gameOver = false;

  // Drag state
  int? _draggingIndex; // which shape (0,1,2) is being dragged
  int? _previewRow;
  int? _previewCol;
  bool _previewValid = false;

  // Grid key for computing positions
  final GlobalKey _gridKey = GlobalKey();

  // Line clear flash
  bool _flashing = false;

  @override
  String get gameId => 'block_puzzle';

  @override
  void initState() {
    super.initState();
    _engine = BlockPuzzleEngine(_ctx.gameSeed);
  }

  void _onShapeDragStart(int index) {
    if (_gameOver || _engine.currentShapes[index] == null) return;
    setState(() {
      _draggingIndex = index;
    });
  }

  void _onShapeDragUpdate(DragUpdateDetails details, int index) {
    if (_draggingIndex != index) return;

    // Compute grid position
    final gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null) return;

    final gridPos = gridBox.localToGlobal(Offset.zero);
    final shape = _engine.currentShapes[index];
    if (shape == null) return;

    // Offset so the shape center is at the finger
    final relX = details.globalPosition.dx - gridPos.dx - (shape.cols * _kCellSize / 2);
    final relY = details.globalPosition.dy - gridPos.dy - (shape.rows * _kCellSize / 2) - 60; // offset above finger

    final col = (relX / _kCellSize).round();
    final row = (relY / _kCellSize).round();

    setState(() {
      _previewRow = row;
      _previewCol = col;
      _previewValid = _engine.canPlace(shape, row, col);
    });
  }

  void _onShapeDragEnd(int index) {
    if (_draggingIndex != index) return;

    final shape = _engine.currentShapes[index];
    if (shape != null &&
        _previewRow != null &&
        _previewCol != null &&
        _previewValid) {
      final cleared = _engine.placeShape(shape, _previewRow!, _previewCol!);
      _engine.consumeShape(index);

      if (cleared > 0) {
        setState(() => _flashing = true);
        Timer(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _flashing = false);
        });
      }

      // Check game over
      if (_engine.isGameOver) {
        _endGame();
      }
    }

    setState(() {
      _draggingIndex = null;
      _previewRow = null;
      _previewCol = null;
      _previewValid = false;
    });
  }

  void _endGame() {
    setState(() => _gameOver = true);
    _ctx.onGameComplete({
      'winner_id': _engine.score > 0 ? _ctx.userId : null,
      'player_1_score': _engine.score,
      'player_2_score': 0,
    });
  }

  // ─── GameInterface ─────────────────────────────────────────

  @override
  void onOpponentMove(Map<String, dynamic> moveData) {}

  @override
  void onReconnect(Map<String, dynamic> savedState) {
    setState(() {
      _engine = BlockPuzzleEngine.fromJson(savedState, _ctx.gameSeed);
    });
  }

  @override
  Map<String, dynamic> getCurrentState() => _engine.toJson();

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_gameOver) return _buildGameOver();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildHeader(),
            const SizedBox(height: 12),
            _buildGrid(),
            const SizedBox(height: 16),
            _buildShapeTray(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Block Puzzle',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary)),
              Text('Fumbo la Vitalu',
                  style: TextStyle(fontSize: 13, color: _kSecondary)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_engine.score}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final gridWidth = BlockPuzzleEngine.size * _kCellSize;

    return Center(
      child: Container(
        key: _gridKey,
        width: gridWidth,
        height: gridWidth,
        decoration: BoxDecoration(
          color: _flashing ? Colors.amber.withAlpha(30) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Stack(
          children: [
            // Grid cells
            for (int r = 0; r < BlockPuzzleEngine.size; r++)
              for (int c = 0; c < BlockPuzzleEngine.size; c++)
                Positioned(
                  left: c * _kCellSize,
                  top: r * _kCellSize,
                  child: Container(
                    width: _kCellSize,
                    height: _kCellSize,
                    decoration: BoxDecoration(
                      color: _engine.grid[r][c]
                          ? _kPrimary
                          : Colors.transparent,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
            // Preview overlay
            if (_draggingIndex != null &&
                _previewRow != null &&
                _previewCol != null)
              ..._buildPreview(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPreview() {
    final shape = _engine.currentShapes[_draggingIndex!];
    if (shape == null) return [];

    final widgets = <Widget>[];
    for (int r = 0; r < shape.rows; r++) {
      for (int c = 0; c < shape.cols; c++) {
        if (!shape.cells[r][c]) continue;
        final gr = _previewRow! + r;
        final gc = _previewCol! + c;
        if (gr < 0 ||
            gr >= BlockPuzzleEngine.size ||
            gc < 0 ||
            gc >= BlockPuzzleEngine.size) {
          continue;
        }
        widgets.add(Positioned(
          left: gc * _kCellSize,
          top: gr * _kCellSize,
          child: Container(
            width: _kCellSize,
            height: _kCellSize,
            decoration: BoxDecoration(
              color: _previewValid
                  ? Colors.green.withAlpha(80)
                  : Colors.red.withAlpha(80),
              border: Border.all(
                color: _previewValid ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
          ),
        ));
      }
    }
    return widgets;
  }

  Widget _buildShapeTray() {
    return SizedBox(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (i) => _buildDraggableShape(i)),
      ),
    );
  }

  Widget _buildDraggableShape(int index) {
    final shape = _engine.currentShapes[index];
    if (shape == null) {
      return const SizedBox(width: 80, height: 80);
    }

    final miniCell = 16.0;
    final w = shape.cols * miniCell;
    final h = shape.rows * miniCell;

    final shapeWidget = SizedBox(
      width: w,
      height: h,
      child: Stack(
        children: [
          for (int r = 0; r < shape.rows; r++)
            for (int c = 0; c < shape.cols; c++)
              if (shape.cells[r][c])
                Positioned(
                  left: c * miniCell,
                  top: r * miniCell,
                  child: Container(
                    width: miniCell - 1,
                    height: miniCell - 1,
                    decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
        ],
      ),
    );

    return GestureDetector(
      onPanStart: (_) => _onShapeDragStart(index),
      onPanUpdate: (d) => _onShapeDragUpdate(d, index),
      onPanEnd: (_) => _onShapeDragEnd(index),
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: _draggingIndex == index
              ? Colors.grey.shade200
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: shapeWidget,
      ),
    );
  }

  Widget _buildGameOver() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.view_module_rounded,
                    size: 64, color: _kPrimary),
                const SizedBox(height: 16),
                const Text('Game Over!',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary)),
                const Text('Mchezo Umekwisha!',
                    style: TextStyle(fontSize: 14, color: _kSecondary)),
                const SizedBox(height: 24),
                Text('${_engine.score}',
                    style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary)),
                const Text('points / pointi',
                    style: TextStyle(fontSize: 14, color: _kSecondary)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Done / Maliza'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
