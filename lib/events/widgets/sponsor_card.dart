import 'package:flutter/material.dart';
import '../models/event_session.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class SponsorCard extends StatelessWidget {
  final EventSponsor sponsor;
  const SponsorCard({super.key, required this.sponsor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
            child: sponsor.logoUrl != null
                ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(sponsor.logoUrl!, fit: BoxFit.cover))
                : Center(child: Text(sponsor.name.isNotEmpty ? sponsor.name[0] : '?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kSecondary))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sponsor.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                Text(sponsor.tier.displayName, style: const TextStyle(fontSize: 12, color: _kSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
