import 'package:flutter/material.dart';

/// F3 #20 — "Mteja wa kawaida / Repeat customer" chip.
/// Renders when priorOrdersCount >= 2.
class RepeatCustomerChip extends StatelessWidget {
  final int priorOrdersCount;
  final bool isSwahili;

  const RepeatCustomerChip({
    super.key,
    required this.priorOrdersCount,
    required this.isSwahili,
  });

  @override
  Widget build(BuildContext context) {
    if (priorOrdersCount < 2) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.replay_rounded, size: 10, color: Color(0xFF1B5E20)),
          const SizedBox(width: 3),
          Text(
            isSwahili
                ? 'Mteja wa kawaida · $priorOrdersCount'
                : 'Repeat customer · $priorOrdersCount',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B5E20),
            ),
          ),
        ],
      ),
    );
  }
}
