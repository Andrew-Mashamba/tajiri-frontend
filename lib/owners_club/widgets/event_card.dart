// lib/owners_club/widgets/event_card.dart
import 'package:flutter/material.dart';
import '../models/owners_club_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class EventCard extends StatelessWidget {
  final CommunityEvent event;
  final VoidCallback? onRsvp;

  const EventCard({super.key, required this.event, this.onRsvp});

  IconData _typeIcon() {
    switch (event.type) {
      case 'meetup': return Icons.groups_rounded;
      case 'drive': return Icons.directions_car_rounded;
      case 'show': return Icons.emoji_events_rounded;
      case 'rally': return Icons.flag_rounded;
      default: return Icons.event_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Date block
            if (event.eventDate != null)
              Container(
                width: 50,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _monthAbbr(event.eventDate!.month),
                      style: const TextStyle(fontSize: 11, color: _kSecondary, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${event.eventDate!.day}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: 50,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_rounded, color: _kSecondary),
              ),
            const SizedBox(width: 12),
            // Event info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_typeIcon(), size: 16, color: _kSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(event.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (event.location != null)
                    Text(event.location!,
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people_rounded, size: 14, color: _kSecondary),
                      const SizedBox(width: 4),
                      Text(
                        event.maxCapacity != null
                            ? '${event.rsvpCount}/${event.maxCapacity}'
                            : '${event.rsvpCount} going',
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // RSVP button
            if (!event.hasRsvped && onRsvp != null)
              SizedBox(
                height: 34,
                child: FilledButton(
                  onPressed: onRsvp,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('RSVP'),
                ),
              )
            else if (event.hasRsvped)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Going',
                    style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.w500)),
              ),
          ],
        ),
      ),
    );
  }

  String _monthAbbr(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }
}
