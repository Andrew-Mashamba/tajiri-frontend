// lib/necta/widgets/school_stats_card.dart
import 'package:flutter/material.dart';
import '../models/necta_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class SchoolStatsCard extends StatelessWidget {
  final SchoolStats stats;
  final bool isSwahili;

  const SchoolStatsCard({
    super.key,
    required this.stats,
    required this.isSwahili,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(stats.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: stats.passRate >= 80
                      ? Colors.green.withValues(alpha: 0.1)
                      : stats.passRate >= 50
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${stats.passRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: stats.passRate >= 80
                        ? Colors.green
                        : stats.passRate >= 50
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${stats.district}, ${stats.region}',
              style: const TextStyle(fontSize: 12, color: _kSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            children: [
              _DivBadge('I', stats.divisionI, Colors.green),
              const SizedBox(width: 6),
              _DivBadge('II', stats.divisionII, Colors.blue),
              const SizedBox(width: 6),
              _DivBadge('III', stats.divisionIII, Colors.orange),
              const SizedBox(width: 6),
              _DivBadge('IV', stats.divisionIV, Colors.deepOrange),
              const SizedBox(width: 6),
              _DivBadge('0', stats.divisionZero, Colors.red),
              const Spacer(),
              Text(
                '${stats.totalCandidates} ${isSwahili ? 'wanafunzi' : 'students'}',
                style: const TextStyle(fontSize: 11, color: _kSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DivBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _DivBadge(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label:$count',
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
