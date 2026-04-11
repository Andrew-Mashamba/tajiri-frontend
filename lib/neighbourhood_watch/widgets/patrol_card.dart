// lib/neighbourhood_watch/widgets/patrol_card.dart
import 'package:flutter/material.dart';
import '../models/neighbourhood_watch_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class PatrolCard extends StatelessWidget {
  final PatrolSchedule patrol;
  final bool isSwahili;
  final VoidCallback? onJoin;

  const PatrolCard({
    super.key,
    required this.patrol,
    required this.isSwahili,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_rounded,
                color: _kPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patrol.zone,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${patrol.dayOfWeek}  ${patrol.startTime} - ${patrol.endTime}',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${patrol.volunteers.length} ${isSwahili ? 'wajitolea' : 'volunteers'}',
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                ),
              ],
            ),
          ),
          if (patrol.isActive)
            GestureDetector(
              onTap: onJoin,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isSwahili ? 'Jiunge' : 'Join',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
