// lib/faith/widgets/prayer_time_card.dart
import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class PrayerTimeCard extends StatelessWidget {
  final String name;
  final String time;
  final bool isCurrent;

  const PrayerTimeCard({
    super.key,
    required this.name,
    required this.time,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrent ? _kPrimary : _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? _kPrimary : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isCurrent
                    ? Icons.notifications_active_rounded
                    : Icons.access_time_rounded,
                size: 20,
                color: isCurrent ? Colors.white : _kSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: isCurrent ? Colors.white : _kPrimary,
                ),
              ),
            ],
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isCurrent ? Colors.white : _kPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
