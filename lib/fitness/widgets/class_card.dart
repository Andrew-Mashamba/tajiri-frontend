// lib/fitness/widgets/class_card.dart
import 'package:flutter/material.dart';
import '../models/fitness_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class ClassCard extends StatelessWidget {
  final FitnessClass fitnessClass;
  final VoidCallback? onTap;

  const ClassCard({super.key, required this.fitnessClass, this.onTap});

  String _formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final fc = fitnessClass;
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Type icon with live badge
              Stack(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: fc.workoutType.icon == Icons.fitness_center_rounded
                          ? _kPrimary.withValues(alpha: 0.08)
                          : fc.difficultyColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(fc.workoutType.icon, size: 24, color: _kPrimary),
                  ),
                  if (fc.isLive)
                    Positioned(
                      right: -2, top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                        child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fc.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      '${fc.gymName} • ${fc.trainerName ?? 'Kocha'}',
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 13, color: _kSecondary),
                        Text(' ${_formatTime(fc.scheduledAt)} • ${fc.durationMinutes} dk', style: const TextStyle(fontSize: 11, color: _kSecondary)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: fc.difficultyColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(fc.difficultyLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: fc.difficultyColor)),
                        ),
                        if (fc.isLive && fc.viewerCount > 0) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.visibility_rounded, size: 12, color: _kSecondary),
                          Text(' ${fc.viewerCount}', style: const TextStyle(fontSize: 11, color: _kSecondary)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(fc.isLive ? Icons.play_circle_rounded : Icons.play_arrow_rounded, size: 28, color: fc.isLive ? Colors.red : _kPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
