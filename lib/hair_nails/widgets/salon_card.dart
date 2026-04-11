// lib/hair_nails/widgets/salon_card.dart
import 'package:flutter/material.dart';
import '../models/hair_nails_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class SalonCard extends StatelessWidget {
  final Salon salon;
  final VoidCallback? onTap;

  const SalonCard({super.key, required this.salon, this.onTap});

  String _fmtPrice(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 120,
              width: double.infinity,
              child: salon.imageUrl != null
                  ? Image.network(salon.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + badges
                  Row(
                    children: [
                      Expanded(
                        child: Text(salon.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (salon.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.verified_rounded, size: 16, color: _kPrimary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Badges row
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (salon.isHomeBased) _badge('Mama Salon', Icons.home_rounded),
                      if (salon.isMobile) _badge('Mtaalamu Anakuja', Icons.directions_walk_rounded),
                      if (salon.isWalkIn) _badge('Walk-in', Icons.door_front_door_outlined),
                    ],
                  ),

                  if (salon.address != null) ...[
                    const SizedBox(height: 4),
                    Text(salon.address!, style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 6),

                  // Rating, distance, price
                  Row(
                    children: [
                      if (salon.rating > 0) ...[
                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        Text(' ${salon.rating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
                        Text(' (${salon.totalReviews})', style: const TextStyle(fontSize: 11, color: _kSecondary)),
                        const SizedBox(width: 10),
                      ],
                      if (salon.distanceKm != null) ...[
                        const Icon(Icons.location_on_outlined, size: 13, color: _kSecondary),
                        Text(' ${salon.distanceKm!.toStringAsFixed(1)}km', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                      ],
                      const Spacer(),
                      if (salon.services.isNotEmpty)
                        Text(
                          'TZS ${_fmtPrice(salon.minPrice)} - ${_fmtPrice(salon.maxPrice)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
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

  Widget _placeholder() {
    return Container(
      color: _kPrimary.withValues(alpha: 0.06),
      child: const Center(child: Icon(Icons.content_cut_rounded, size: 40, color: _kSecondary)),
    );
  }

  Widget _badge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: _kPrimary),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _kPrimary)),
        ],
      ),
    );
  }
}
