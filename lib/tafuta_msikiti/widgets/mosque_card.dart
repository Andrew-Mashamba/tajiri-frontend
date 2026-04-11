// lib/tafuta_msikiti/widgets/mosque_card.dart
import 'package:flutter/material.dart';
import '../models/tafuta_msikiti_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class MosqueCard extends StatelessWidget {
  final Mosque mosque;
  final VoidCallback? onTap;

  const MosqueCard({super.key, required this.mosque, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
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
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10)),
              child: mosque.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(mosque.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.mosque_rounded,
                                  color: _kPrimary, size: 24)),
                    )
                  : const Icon(Icons.mosque_rounded,
                      color: _kPrimary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mosque.name,
                      style: const TextStyle(color: _kPrimary, fontSize: 15,
                          fontWeight: FontWeight.w500),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(mosque.address,
                      style: const TextStyle(
                          color: _kSecondary, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (mosque.distanceKm != null)
                    Text('${mosque.distanceKm!.toStringAsFixed(1)} km',
                        style: const TextStyle(
                            color: _kSecondary, fontSize: 11)),
                ],
              ),
            ),
            if (mosque.rating != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFFC107), size: 16),
                  const SizedBox(width: 2),
                  Text(mosque.rating!.toStringAsFixed(1),
                      style: const TextStyle(color: _kPrimary, fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
