// lib/faith/widgets/worship_place_card.dart
import 'package:flutter/material.dart';
import '../models/faith_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class WorshipPlaceCard extends StatelessWidget {
  final PlaceOfWorship place;
  final VoidCallback? onTap;

  const WorshipPlaceCard({
    super.key,
    required this.place,
    this.onTap,
  });

  IconData get _typeIcon {
    switch (place.type) {
      case WorshipPlaceType.mosque:
        return Icons.mosque_rounded;
      case WorshipPlaceType.church:
        return Icons.church_rounded;
      case WorshipPlaceType.temple:
        return Icons.temple_hindu_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon, color: _kPrimary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.address,
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (place.distanceKm != null) ...[
              const SizedBox(width: 8),
              Text(
                '${place.distanceKm!.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _kSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
