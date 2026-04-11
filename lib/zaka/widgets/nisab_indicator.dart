// lib/zaka/widgets/nisab_indicator.dart
import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class NisabIndicator extends StatelessWidget {
  final double currentWealth;
  final double nisabThreshold;

  const NisabIndicator({
    super.key,
    required this.currentWealth,
    required this.nisabThreshold,
  });

  bool get isAboveNisab => currentWealth >= nisabThreshold;

  @override
  Widget build(BuildContext context) {
    final ratio = nisabThreshold > 0
        ? (currentWealth / nisabThreshold).clamp(0.0, 2.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAboveNisab ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAboveNisab
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: isAboveNisab ? Colors.green : _kSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isAboveNisab
                    ? 'Umepita Nisab - Zaka Inapaswa'
                    : 'Chini ya Nisab',
                style: TextStyle(
                  color: isAboveNisab ? Colors.green.shade700 : _kSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: ratio / 2,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isAboveNisab ? Colors.green : _kPrimary,
            ),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('0',
                  style: TextStyle(color: _kSecondary, fontSize: 11)),
              Text('Nisab',
                  style: TextStyle(
                    color: isAboveNisab ? Colors.green : _kSecondary,
                    fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
