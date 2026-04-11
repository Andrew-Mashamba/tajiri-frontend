// lib/buy_car/widgets/listing_card.dart
import 'package:flutter/material.dart';
import '../models/buy_car_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class ListingCard extends StatelessWidget {
  final CarListing listing;
  final bool isSwahili;
  final VoidCallback? onTap;

  const ListingCard({
    super.key,
    required this.listing,
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Photo
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: listing.thumbnailUrl.isNotEmpty
                    ? Image.network(listing.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
            ),
            // Details
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
                      if (listing.isFeatured)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Featured',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ]),
                    const SizedBox(height: 4),
                    Text('TZS ${listing.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary)),
                    const SizedBox(height: 6),
                    Row(children: [
                      _spec(Icons.speed_rounded,
                          '${listing.mileage.toStringAsFixed(0)} km'),
                      const SizedBox(width: 10),
                      _spec(Icons.local_gas_station_rounded,
                          listing.fuelType),
                      const SizedBox(width: 10),
                      _spec(Icons.settings_rounded,
                          listing.transmission),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      _tag(listing.sourceLabel),
                      const SizedBox(width: 6),
                      _tag(listing.condition),
                      const Spacer(),
                      if (listing.location != null)
                        Row(children: [
                          const Icon(Icons.location_on_rounded,
                              size: 12, color: _kSecondary),
                          const SizedBox(width: 2),
                          Text(listing.location!,
                              style: const TextStyle(
                                  fontSize: 10, color: _kSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ]),
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
              size: 48, color: _kSecondary)),
    );
  }

  Widget _spec(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 13, color: _kSecondary),
      const SizedBox(width: 3),
      Text(text,
          style: const TextStyle(fontSize: 11, color: _kSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    ]);
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 10, color: _kSecondary, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    );
  }
}
