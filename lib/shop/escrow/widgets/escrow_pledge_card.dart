import 'package:flutter/material.dart';

const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kDivider = Color(0xFFE0E0E0);

class _Guarantee {
  final String emoji;
  final String text;
  const _Guarantee(this.emoji, this.text);
}

const _kGuarantees = [
  _Guarantee('🔒', 'Funds held until you confirm delivery'),
  _Guarantee('✅', 'Auto-released after 7 days if no dispute'),
  _Guarantee('🔄', 'Full refund if item not received or not as described'),
  _Guarantee('👤', 'Dispute resolution within 24 hours'),
];

/// Trust card displayed during checkout to explain the escrow guarantees.
class EscrowPledgeCard extends StatelessWidget {
  const EscrowPledgeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.shield_outlined, size: 18, color: _kPrimaryText),
              SizedBox(width: 8),
              Text(
                'Payment Protection',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kPrimaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: _kDivider),
          const SizedBox(height: 12),
          ..._kGuarantees.map(
            (g) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(g.emoji, style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      g.text,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kSecondaryText,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
