// lib/service_garage/widgets/garage_card.dart
import 'package:flutter/material.dart';
import '../models/service_garage_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class GarageCard extends StatelessWidget {
  final Garage garage;
  final bool isSwahili;
  final VoidCallback? onTap;

  const GarageCard({
    super.key,
    required this.garage,
    this.isSwahili = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: garage.photoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(garage.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.build_rounded,
                              size: 28,
                              color: _kPrimary)))
                  : const Icon(Icons.build_rounded,
                      size: 28, color: _kPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(garage.name,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _kPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (garage.isVerified)
                        const Icon(Icons.verified_rounded,
                            size: 16, color: Color(0xFF4CAF50)),
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                          '${garage.rating.toStringAsFixed(1)} (${garage.reviewCount})',
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary)),
                      if (garage.distanceKm != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on_rounded,
                            size: 12, color: _kSecondary),
                        Text(
                            '${garage.distanceKm!.toStringAsFixed(1)} km',
                            style: const TextStyle(
                                fontSize: 11, color: _kSecondary)),
                      ],
                    ]),
                    const SizedBox(height: 4),
                    if (garage.specializations.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: garage.specializations
                            .take(3)
                            .map((s) => _tag(s))
                            .toList(),
                      ),
                  ]),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: _kSecondary),
          ]),
        ),
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 9, color: _kSecondary, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    );
  }
}
