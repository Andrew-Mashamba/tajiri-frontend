// lib/food/widgets/restaurant_card.dart
import 'package:flutter/material.dart';
import '../../widgets/cached_media_image.dart';
import '../models/food_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;

  const RestaurantCard({super.key, required this.restaurant, this.onTap});

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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Image
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _kPrimary.withValues(alpha: 0.08),
                ),
                clipBehavior: Clip.antiAlias,
                child: restaurant.imageUrl != null
                    ? CachedMediaImage(
                        imageUrl: restaurant.imageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Text(
                          restaurant.initials,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: restaurant.isOpen
                                ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            restaurant.isOpen ? 'Wazi' : 'Imefungwa',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: restaurant.isOpen ? const Color(0xFF4CAF50) : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (restaurant.address != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        restaurant.address!,
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (restaurant.rating > 0) ...[
                          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            restaurant.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
                          ),
                          Text(
                            ' (${restaurant.totalReviews})',
                            style: const TextStyle(fontSize: 11, color: _kSecondary),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Icon(Icons.access_time_rounded, size: 13, color: _kSecondary),
                        const SizedBox(width: 2),
                        Text(
                          '${restaurant.deliveryTimeMinutes} dk',
                          style: const TextStyle(fontSize: 11, color: _kSecondary),
                        ),
                        const SizedBox(width: 10),
                        if (restaurant.minOrder > 0)
                          Text(
                            'Min TZS ${_fmtPrice(restaurant.minOrder)}',
                            style: const TextStyle(fontSize: 11, color: _kSecondary),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
