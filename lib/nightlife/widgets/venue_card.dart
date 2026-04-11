// lib/nightlife/widgets/venue_card.dart
import 'package:flutter/material.dart';
import '../models/nightlife_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class VenueCard extends StatelessWidget {
  final Venue venue;
  final bool isSwahili;
  final VoidCallback? onTap;

  const VenueCard({
    super.key,
    required this.venue,
    required this.isSwahili,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            // Image placeholder
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.06),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                image: venue.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(venue.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: venue.imageUrl == null
                  ? const Center(
                      child: Icon(Icons.nightlife_rounded,
                          size: 36, color: _kSecondary))
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(venue.name,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _kPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (venue.isOpen)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isSwahili ? 'Wazi' : 'Open',
                            style: const TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(venue.address,
                      style:
                          const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(venue.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 12, color: _kPrimary)),
                      Text(' (${venue.reviewCount})',
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary)),
                      const Spacer(),
                      Text(
                        venue.type[0].toUpperCase() + venue.type.substring(1),
                        style:
                            const TextStyle(fontSize: 11, color: _kSecondary),
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
