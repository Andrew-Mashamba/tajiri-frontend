// lib/skincare/widgets/routine_step_card.dart
import 'package:flutter/material.dart';
import '../models/skincare_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class RoutineStepCard extends StatelessWidget {
  final RoutineStep step;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback? onTap;
  final VoidCallback? onTimerTap;

  const RoutineStepCard({
    super.key,
    required this.step,
    this.isActive = false,
    this.isCompleted = false,
    this.onTap,
    this.onTimerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? _kPrimary.withValues(alpha: 0.05) : _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isActive ? Border.all(color: _kPrimary, width: 1.5) : null,
          ),
          child: Row(
            children: [
              // Step number / check
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF4CAF50)
                      : _kPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: isCompleted
                    ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                    : Center(
                        child: Text(
                          '${step.order}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isActive ? _kPrimary : _kSecondary,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Step type icon
              Icon(step.stepType.icon, size: 20, color: _kPrimary),
              const SizedBox(width: 10),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.stepType.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (step.productName != null && step.productName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        step.productName!,
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (step.instructions != null && step.instructions!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        step.instructions!,
                        style: TextStyle(fontSize: 11, color: _kSecondary.withValues(alpha: 0.7)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Timer badge
              if (step.waitTimeSeconds > 0) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onTimerTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_rounded, size: 14, color: _kPrimary),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(step.waitTimeSeconds),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
                        ),
                      ],
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

  String _formatTime(int seconds) {
    if (seconds >= 60) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return s > 0 ? '${m}dk ${s}s' : '${m}dk';
    }
    return '${seconds}s';
  }
}
