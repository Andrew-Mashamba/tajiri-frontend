import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/event_strings.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Smaller horizontal card designed for use in horizontal scroll lists.
/// Shows cover image (or category icon fallback), event name, and date.
class EventCardCompact extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;
  const EventCardCompact({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final strings = EventStrings(isSwahili: true);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image / icon fallback
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                image: event.coverPhotoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(event.coverPhotoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: event.coverPhotoUrl == null
                  ? Center(
                      child: Icon(
                        event.category.icon,
                        size: 32,
                        color: _kSecondary,
                      ),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    strings.formatDateShort(event.startDate),
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
