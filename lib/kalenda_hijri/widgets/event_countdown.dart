// lib/kalenda_hijri/widgets/event_countdown.dart
import 'package:flutter/material.dart';
import '../models/kalenda_hijri_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class EventCountdownWidget extends StatelessWidget {
  final IslamicEvent event;
  final int daysRemaining;

  const EventCountdownWidget({
    super.key,
    required this.event,
    required this.daysRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text(
              '$daysRemaining',
              style: const TextStyle(color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.nameSwahili.isNotEmpty
                      ? event.nameSwahili : event.name,
                  style: const TextStyle(color: _kPrimary, fontSize: 15,
                      fontWeight: FontWeight.w500),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Siku $daysRemaining zimebaki',
                  style: const TextStyle(color: _kSecondary, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (event.isPublicHoliday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6)),
              child: const Text('Sikukuu',
                  style: TextStyle(color: Colors.green, fontSize: 10,
                      fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }
}
