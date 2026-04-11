// lib/tra/widgets/tin_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tra_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class TinCard extends StatelessWidget {
  final TaxProfile profile;
  const TinCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimary, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Text('TIN', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: profile.tin));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('TIN imekopishwa'),
                    duration: Duration(seconds: 1)),
              );
            },
            child: const Icon(Icons.copy_rounded, color: Colors.white54, size: 16),
          ),
        ]),
        const SizedBox(height: 8),
        Text(profile.tin,
            style: const TextStyle(color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.w700, letterSpacing: 2)),
        if (profile.ownerName != null) ...[
          const SizedBox(height: 4),
          Text(profile.ownerName!,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: profile.isCompliant ? const Color(0xFF4CAF50) : Colors.orange,
            borderRadius: BorderRadius.circular(6)),
          child: Text(
            profile.isCompliant ? 'Compliant' : profile.complianceStatus.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
