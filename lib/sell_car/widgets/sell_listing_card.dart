// lib/sell_car/widgets/sell_listing_card.dart
import 'package:flutter/material.dart';
import '../models/sell_car_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class SellListingCard extends StatelessWidget {
  final SellListing listing;
  final bool isSwahili;
  final VoidCallback? onTap;

  const SellListingCard({
    super.key,
    required this.listing,
    this.isSwahili = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(listing.status);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14)),
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: listing.thumbnailUrl.isNotEmpty
                        ? Image.network(listing.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder())
                        : _placeholder(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(listing.displayName,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _kPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(listing.status.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor)),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Text(
                            'TZS ${listing.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _kPrimary)),
                        const SizedBox(height: 6),
                        Row(children: [
                          _stat(Icons.visibility_rounded,
                              '${listing.viewCount}'),
                          const SizedBox(width: 12),
                          _stat(Icons.chat_bubble_rounded,
                              '${listing.inquiryCount}'),
                          const SizedBox(width: 12),
                          _stat(Icons.bookmark_rounded,
                              '${listing.saveCount}'),
                          const Spacer(),
                          if (listing.hasInspection)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_rounded,
                                        size: 10,
                                        color: Color(0xFF4CAF50)),
                                    const SizedBox(width: 2),
                                    Text(
                                        isSwahili
                                            ? 'Imekaguliwa'
                                            : 'Inspected',
                                        style: const TextStyle(
                                            fontSize: 9,
                                            color: Color(0xFF4CAF50))),
                                  ]),
                            ),
                        ]),
                      ]),
                ),
              ]),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: _kPrimary.withValues(alpha: 0.06),
      child: const Center(
          child: Icon(Icons.directions_car_rounded,
              size: 40, color: _kSecondary)),
    );
  }

  Widget _stat(IconData icon, String value) {
    return Row(children: [
      Icon(icon, size: 13, color: _kSecondary),
      const SizedBox(width: 3),
      Text(value,
          style: const TextStyle(fontSize: 11, color: _kSecondary)),
    ]);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF4CAF50);
      case 'sold':
        return Colors.blue;
      case 'paused':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      default:
        return _kSecondary;
    }
  }
}
