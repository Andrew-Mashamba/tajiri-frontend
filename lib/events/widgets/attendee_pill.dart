import 'package:flutter/material.dart';
import '../models/event_rsvp.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class AttendeePill extends StatelessWidget {
  final EventAttendee attendee;
  final VoidCallback? onTap;
  const AttendeePill({super.key, required this.attendee, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: attendee.avatarUrl != null ? NetworkImage(attendee.avatarUrl!) : null,
              child: attendee.avatarUrl == null ? Text(attendee.firstName.isNotEmpty ? attendee.firstName[0] : '?', style: const TextStyle(fontSize: 10, color: _kSecondary)) : null,
            ),
            const SizedBox(width: 6),
            Text(attendee.firstName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _kPrimary)),
          ],
        ),
      ),
    );
  }
}
