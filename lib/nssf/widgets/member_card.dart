// lib/nssf/widgets/member_card.dart
import 'package:flutter/material.dart';
import '../models/nssf_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class NssfMemberCard extends StatelessWidget {
  final NssfMembership membership;
  const NssfMemberCard({super.key, required this.membership});

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.shield_rounded, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text('NSSF', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2)),
        ]),
        const SizedBox(height: 12),
        Text(membership.memberNumber,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2)),
        const SizedBox(height: 8),
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Jumla', style: TextStyle(color: Colors.white54, fontSize: 10)),
            Text('TZS ${(membership.totalContributions / 1000000).toStringAsFixed(1)}M',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(width: 24),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Miezi', style: TextStyle(color: Colors.white54, fontSize: 10)),
            Text('${membership.monthsContributed}',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
        ]),
      ]));
  }
}
