import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/budget_models.dart';

/// Savings goal card with circular progress, name, amounts, and contribute action.
/// When a goal is complete, the progress ring gets a subtle pulse animation.
class GoalCard extends StatefulWidget {
  final BudgetGoal goal;
  final bool isSwahili;
  final VoidCallback? onTap;
  final VoidCallback? onContribute;

  const GoalCard({
    super.key,
    required this.goal,
    this.isSwahili = false,
    this.onTap,
    this.onContribute,
  });

  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.goal.isComplete) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GoalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.goal.isComplete && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.goal.isComplete && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  BudgetGoal get goal => widget.goal;
  bool get isSwahili => widget.isSwahili;
  VoidCallback? get onTap => widget.onTap;
  VoidCallback? get onContribute => widget.onContribute;

  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);
  static const Color _kSuccess = Color(0xFF4CAF50);

  String _formatTZS(double amount) {
    if (amount >= 1000000) {
      return 'TZS ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return 'TZS ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return 'TZS ${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final percent = goal.percentComplete;
    final monthly = goal.monthlyTarget;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Circular progress (pulses when complete)
                  ScaleTransition(
                    scale: goal.isComplete
                        ? _pulseAnimation
                        : const AlwaysStoppedAnimation(1.0),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: CustomPaint(
                        painter: _GoalProgressPainter(
                          progress: percent / 100,
                          color: goal.isComplete ? _kSuccess : _kPrimary,
                          backgroundColor: const Color(0xFFEEEEEE),
                        ),
                        child: Center(
                          child: Text(
                            '${percent.toStringAsFixed(0)}%',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: goal.isComplete ? _kSuccess : _kPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _kPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatTZS(goal.savedAmount)} / ${_formatTZS(goal.targetAmount)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _kSecondary,
                            fontSize: 13,
                          ),
                        ),
                        if (monthly != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            isSwahili
                                ? '${_formatTZS(monthly)}/mwezi ili kufikia lengo'
                                : '${_formatTZS(monthly)}/mo to reach goal',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _kSecondary.withValues(alpha:0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (!goal.isComplete && onContribute != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: onContribute,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kPrimary,
                      side: const BorderSide(color: Color(0xFFDDDDDD)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      isSwahili ? 'Changia' : 'Contribute',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for a circular progress arc.
class _GoalProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _GoalProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 5.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoalProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
