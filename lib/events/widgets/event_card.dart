import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/event_strings.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;
  const EventCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    final strings = EventStrings(isSwahili: lang == 'sw');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            Container(
              height: 140,
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
              child: Stack(
                children: [
                  if (event.coverPhotoUrl == null)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${event.startDate.day}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _kPrimary,
                            ),
                          ),
                          Text(
                            strings.formatDateShort(event.startDate),
                            style: const TextStyle(fontSize: 13, color: _kSecondary),
                          ),
                        ],
                      ),
                    ),
                  // Date badge when cover exists
                  if (event.coverPhotoUrl != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          strings.formatDateShort(event.startDate),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                        ),
                      ),
                    ),
                  // Happening now badge
                  if (event.isHappeningNow)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 8, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      event.category.displayName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    event.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Location
                  if (event.locationName != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: _kSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.locationName!,
                            style: const TextStyle(fontSize: 13, color: _kSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  // Friends going
                  if (event.friendsGoingCount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.people_outline_rounded, size: 14, color: _kSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${event.friendsGoingCount} ${strings.friendsGoing.toLowerCase()}',
                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Price + going count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event.isFree
                            ? '${strings.free} / Free'
                            : strings.formatPrice(
                                event.ticketPrice ?? 0,
                                event.ticketCurrency,
                              ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      ),
                      Text(
                        '${event.goingCount} ${strings.going.toLowerCase()}',
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                      ),
                    ],
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
