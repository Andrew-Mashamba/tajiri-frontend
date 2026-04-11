import 'package:flutter/material.dart' hide Badge;
import '../models/tajirika_models.dart';

class BadgeChip extends StatelessWidget {
  final Badge badge;
  final bool isSwahili;

  const BadgeChip({
    super.key,
    required this.badge,
    this.isSwahili = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge.iconUrl != null && badge.iconUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Image.network(
                badge.iconUrl!,
                width: 16,
                height: 16,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF1A1A1A)),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.verified_rounded, size: 14, color: Color(0xFF1A1A1A)),
            ),
          Text(
            isSwahili && badge.nameSwahili.isNotEmpty ? badge.nameSwahili : badge.name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}
