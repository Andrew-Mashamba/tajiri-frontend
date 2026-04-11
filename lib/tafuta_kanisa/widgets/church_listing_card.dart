// lib/tafuta_kanisa/widgets/church_listing_card.dart
import 'package:flutter/material.dart';
import '../models/tafuta_kanisa_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class ChurchListingCard extends StatelessWidget {
  final ChurchListing church;
  final VoidCallback? onTap;

  const ChurchListingCard({super.key, required this.church, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.church_rounded, size: 24, color: _kPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(church.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(church.denomination,
                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (church.distanceKm != null) ...[
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${church.distanceKm!.toStringAsFixed(1)} km',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(5, (i) => Icon(
                                i < church.rating.round()
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 12, color: _kPrimary,
                              )),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (church.address != null) ...[
                  const Icon(Icons.location_on_rounded, size: 14, color: _kSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(church.address!,
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
            if (church.serviceTimes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 14, color: _kSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(church.serviceTimes.join(' | '),
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
