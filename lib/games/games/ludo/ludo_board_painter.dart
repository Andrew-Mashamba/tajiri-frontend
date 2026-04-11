// lib/games/games/ludo/ludo_board_painter.dart

import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Paints the cross-shaped Ludo board.
/// Tokens are overlaid as widgets (not painted here).
class LudoBoardPainter extends CustomPainter {
  LudoBoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 15;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw 15x15 grid
    for (int i = 0; i <= 15; i++) {
      canvas.drawLine(
          Offset(i * cellSize, 0), Offset(i * cellSize, size.height), gridPaint);
      canvas.drawLine(
          Offset(0, i * cellSize), Offset(size.width, i * cellSize), gridPaint);
    }

    // Player 1 home base (top-left 6x6)
    _fillRect(canvas, 0, 0, 6, 6, cellSize,
        _kPrimary.withValues(alpha: 0.1));
    _strokeRect(canvas, 0, 0, 6, 6, cellSize, _kPrimary);

    // Player 2 home base (bottom-right 6x6)
    _fillRect(canvas, 9, 9, 6, 6, cellSize,
        _kSecondary.withValues(alpha: 0.1));
    _strokeRect(canvas, 9, 9, 6, 6, cellSize, _kSecondary);

    // Top-right area (neutral)
    _fillRect(canvas, 9, 0, 6, 6, cellSize,
        Colors.grey.shade100);
    _strokeRect(canvas, 9, 0, 6, 6, cellSize, Colors.grey.shade400);

    // Bottom-left area (neutral)
    _fillRect(canvas, 0, 9, 6, 6, cellSize,
        Colors.grey.shade100);
    _strokeRect(canvas, 0, 9, 6, 6, cellSize, Colors.grey.shade400);

    // Center home triangle for player 1
    final centerX = 7.5 * cellSize;
    final centerY = 7.5 * cellSize;
    final triPaint1 = Paint()
      ..color = _kPrimary.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final path1 = Path()
      ..moveTo(6 * cellSize, 6 * cellSize)
      ..lineTo(centerX, centerY)
      ..lineTo(9 * cellSize, 6 * cellSize)
      ..close();
    canvas.drawPath(path1, triPaint1);

    // Center home triangle for player 2
    final triPaint2 = Paint()
      ..color = _kSecondary.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final path2 = Path()
      ..moveTo(6 * cellSize, 9 * cellSize)
      ..lineTo(centerX, centerY)
      ..lineTo(9 * cellSize, 9 * cellSize)
      ..close();
    canvas.drawPath(path2, triPaint2);

    // Side triangles (neutral)
    final triNeutral = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;
    // Left
    final pathL = Path()
      ..moveTo(6 * cellSize, 6 * cellSize)
      ..lineTo(centerX, centerY)
      ..lineTo(6 * cellSize, 9 * cellSize)
      ..close();
    canvas.drawPath(pathL, triNeutral);
    // Right
    final pathR = Path()
      ..moveTo(9 * cellSize, 6 * cellSize)
      ..lineTo(centerX, centerY)
      ..lineTo(9 * cellSize, 9 * cellSize)
      ..close();
    canvas.drawPath(pathR, triNeutral);

    // Player 1 home column (top center column, rows 1-6, col 7)
    for (int r = 1; r <= 6; r++) {
      _fillRect(canvas, 7, r, 1, 1, cellSize,
          _kPrimary.withValues(alpha: 0.15));
    }

    // Player 2 home column (bottom center column, rows 8-13, col 7)
    for (int r = 8; r <= 13; r++) {
      _fillRect(canvas, 7, r, 1, 1, cellSize,
          _kSecondary.withValues(alpha: 0.15));
    }

    // Safe squares markers
    _drawSafeMarkers(canvas, cellSize);
  }

  void _fillRect(Canvas canvas, int col, int row, int w, int h,
      double cellSize, Color color) {
    canvas.drawRect(
      Rect.fromLTWH(
          col * cellSize, row * cellSize, w * cellSize, h * cellSize),
      Paint()..color = color,
    );
  }

  void _strokeRect(Canvas canvas, int col, int row, int w, int h,
      double cellSize, Color color) {
    canvas.drawRect(
      Rect.fromLTWH(
          col * cellSize, row * cellSize, w * cellSize, h * cellSize),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawSafeMarkers(Canvas canvas, double cellSize) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw small stars on safe squares
    // We'll just mark them with a circle for simplicity
    final safePositions = _getSafeSquarePositions(cellSize);
    for (final pos in safePositions) {
      canvas.drawCircle(
        Offset(pos.dx + cellSize / 2, pos.dy + cellSize / 2),
        cellSize * 0.15,
        paint,
      );
    }
  }

  List<Offset> _getSafeSquarePositions(double cellSize) {
    // Map safe square indices to grid positions
    // This is approximate — real positions depend on path layout
    return [
      Offset(6 * cellSize, 1 * cellSize),   // sq 0
      Offset(2 * cellSize, 6 * cellSize),   // sq 8
      Offset(6 * cellSize, 4 * cellSize),   // sq 13
      Offset(10 * cellSize, 6 * cellSize),  // sq 21
      Offset(8 * cellSize, 13 * cellSize),  // sq 26
      Offset(12 * cellSize, 8 * cellSize),  // sq 34
      Offset(8 * cellSize, 10 * cellSize),  // sq 39
      Offset(4 * cellSize, 8 * cellSize),   // sq 47
    ];
  }

  @override
  bool shouldRepaint(covariant LudoBoardPainter oldDelegate) => false;
}

/// Maps a main-path square index (0-51) to grid coordinates (col, row) on 15x15.
/// Returns top-left of the cell.
Offset squareToGridPosition(int square, double cellSize) {
  // Simplified Ludo path layout on a 15x15 grid.
  // The path goes clockwise starting from top-center.
  const List<List<int>> pathGrid = [
    // Segment 1: top column going down (squares 0-5) — col 6, rows 1-6
    [6, 1], [6, 2], [6, 3], [6, 4], [6, 5], [6, 6],
    // Segment 2: top-left going right (squares 6-11) — row 6, cols 5-0
    [5, 6], [4, 6], [3, 6], [2, 6], [1, 6], [0, 6],
    // Segment 3: left column going down (square 12) — col 0, row 7
    [0, 7],
    // Segment 4: bottom-left going right (squares 13-18) — row 8, cols 0-5
    [0, 8], [1, 8], [2, 8], [3, 8], [4, 8], [5, 8],
    // Segment 5: bottom column going down (squares 19-24) — col 6, rows 9-14
    [6, 9], [6, 10], [6, 11], [6, 12], [6, 13], [6, 14],
    // Segment 6: bottom going right (square 25) — row 14, col 7
    [7, 14],
    // Segment 7: bottom-right going up (squares 26-31) — col 8, rows 14-9
    [8, 14], [8, 13], [8, 12], [8, 11], [8, 10], [8, 9],
    // Segment 8: right going left (squares 32-37) — row 8, cols 9-14
    [9, 8], [10, 8], [11, 8], [12, 8], [13, 8], [14, 8],
    // Segment 9: right column going up (square 38) — col 14, row 7
    [14, 7],
    // Segment 10: top-right going left (squares 39-44) — row 6, cols 14-9
    [14, 6], [13, 6], [12, 6], [11, 6], [10, 6], [9, 6],
    // Segment 11: top column going up (squares 45-50) — col 8, rows 5-0
    [8, 5], [8, 4], [8, 3], [8, 2], [8, 1], [8, 0],
    // Segment 12: top going left (square 51) — row 0, col 7
    [7, 0],
  ];

  if (square < 0 || square >= pathGrid.length) {
    return Offset.zero;
  }
  final coords = pathGrid[square];
  return Offset(coords[0] * cellSize, coords[1] * cellSize);
}

/// Maps a home column position (1-6) for a player to grid coordinates.
Offset homeColumnPosition(int player, int progress, double cellSize) {
  if (player == 0) {
    // Player 1: top center, col 7, rows 1-6
    return Offset(7 * cellSize, progress * cellSize);
  } else {
    // Player 2: bottom center, col 7, rows 13 down to 8
    return Offset(7 * cellSize, (14 - progress) * cellSize);
  }
}

/// Home base positions for tokens still at home.
Offset homeBasePosition(int player, int tokenIndex, double cellSize) {
  // 2x2 grid inside home base
  final baseCol = player == 0 ? 1.5 : 10.5;
  final baseRow = player == 0 ? 1.5 : 10.5;
  final offsets = [
    [0.0, 0.0],
    [2.0, 0.0],
    [0.0, 2.0],
    [2.0, 2.0],
  ];
  return Offset(
    (baseCol + offsets[tokenIndex][0]) * cellSize,
    (baseRow + offsets[tokenIndex][1]) * cellSize,
  );
}
