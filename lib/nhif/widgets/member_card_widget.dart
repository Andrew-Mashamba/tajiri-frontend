// lib/nhif/widgets/member_card_widget.dart
import 'package:flutter/material.dart';
import '../models/nhif_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class NhifMemberCard extends StatelessWidget {
  final NhifMembership membership;
  const NhifMemberCard({super.key, required this.membership});

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text('NHIF', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2)),
        ]),
        const SizedBox(height: 12),
        Text(membership.memberNumber,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2)),
        if (membership.plan != null) Text(membership.plan!,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: membership.isActive ? const Color(0xFF4CAF50) : Colors.red,
              borderRadius: BorderRadius.circular(6)),
            child: Text(membership.isActive ? 'Active' : 'Inactive',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
          const Spacer(),
          if (membership.validTo != null) Text(
            'Exp: ${membership.validTo!.day}/${membership.validTo!.month}/${membership.validTo!.year}',
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
      ]));
  }
}
