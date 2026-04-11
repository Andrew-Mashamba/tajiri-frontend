// lib/games/widgets/game_timer.dart
import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

/// Circular countdown timer with animated ring.
/// Changes color at warning (<=10s) and critical (<=5s) thresholds.
class GameTimer extends StatefulWidget {
  final int totalSeconds;
  final VoidCallback? onComplete;
  final double size;

  const GameTimer({
    super.key,
    required this.totalSeconds,
    this.onComplete,
    this.size = 64,
  });

  @override
  State<GameTimer> createState() => GameTimerState();
}

class GameTimerState extends State<GameTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.totalSeconds),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Pause the timer.
  void pause() => _controller.stop();

  /// Resume the timer.
  void resume() => _controller.forward();

  /// Reset and restart the timer.
  void reset() {
    _controller.reset();
    _controller.forward();
  }

  Color _getColor(int remaining) {
    if (remaining <= 5) return const Color(0xFFEF4444);
    if (remaining <= 10) return const Color(0xFFF59E0B);
    return _kPrimary;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final remaining =
            ((1.0 - _controller.value) * widget.totalSeconds).ceil();
        final color = _getColor(remaining);
        final progress = 1.0 - _controller.value;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 4,
                  color: Colors.grey.shade200,
                ),
              ),
              // Animated ring
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Seconds text
              Text(
                '$remaining',
                style: TextStyle(
                  fontSize: widget.size * 0.3,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
