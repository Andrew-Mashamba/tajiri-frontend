import 'package:flutter/material.dart';
import '../models/tajirika_models.dart';

class ReferralCard extends StatelessWidget {
  final Referral referral;
  final bool isSwahili;

  const ReferralCard({
    super.key,
    required this.referral,
    this.isSwahili = false,
  });

  Color get _statusColor {
    switch (referral.status) {
      case 'verified': return const Color(0xFF4CAF50);
      case 'registered': return const Color(0xFF1A1A1A);
      default: return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: referral.photoUrl.isNotEmpty
                ? NetworkImage(referral.photoUrl)
                : null,
            child: referral.photoUrl.isEmpty
                ? const Icon(Icons.person_rounded, color: Color(0xFF9E9E9E))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referral.referredName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (referral.referredSkills.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    referral.referredSkills
                        .map((s) => isSwahili ? s.labelSwahili : s.label)
                        .join(', '),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isSwahili ? referral.statusLabelSwahili : referral.statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
              if (referral.bonus > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'TZS ${referral.bonus.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
