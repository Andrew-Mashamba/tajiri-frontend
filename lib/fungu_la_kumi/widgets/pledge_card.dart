// lib/fungu_la_kumi/widgets/pledge_card.dart
import 'package:flutter/material.dart';
import '../models/fungu_la_kumi_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class PledgeCard extends StatelessWidget {
  final Pledge pledge;
  final VoidCallback? onTap;

  const PledgeCard({super.key, required this.pledge, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                const Icon(Icons.handshake_rounded, size: 20, color: _kPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(pledge.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pledge.progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TSh ${pledge.paidAmount.toStringAsFixed(0)} / ${pledge.targetAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
                Text(
                  'Baki / Remaining: TSh ${pledge.remaining.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (pledge.deadline != null) ...[
              const SizedBox(height: 4),
              Text('Tarehe ya mwisho / Deadline: ${pledge.deadline}',
                  style: const TextStyle(fontSize: 11, color: _kSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}
