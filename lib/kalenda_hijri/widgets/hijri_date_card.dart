// lib/kalenda_hijri/widgets/hijri_date_card.dart
import 'package:flutter/material.dart';
import '../models/kalenda_hijri_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class HijriDateCard extends StatelessWidget {
  final HijriDate date;
  final bool compact;

  const HijriDateCard({super.key, required this.date, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          date.formatted,
          style: const TextStyle(
            color: _kPrimary, fontSize: 12, fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '${date.day}',
            style: const TextStyle(
              color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            date.monthNameSwahili.isNotEmpty
                ? date.monthNameSwahili
                : date.monthName,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${date.year} AH',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            date.gregorianDate,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
