// lib/housing/widgets/property_card.dart
import 'package:flutter/material.dart';
import '../models/housing_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;

  const PropertyCard({super.key, required this.property, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: property.photos.isNotEmpty
                    ? Image.network(
                        property.photos.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    property.title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: _kSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.location,
                          style:
                              const TextStyle(fontSize: 12, color: _kSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Price + details
                  Row(
                    children: [
                      Text(
                        property.priceFormatted,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary),
                      ),
                      const Spacer(),
                      if (property.bedrooms != null) ...[
                        const Icon(Icons.bed_rounded,
                            size: 14, color: _kSecondary),
                        const SizedBox(width: 3),
                        Text('${property.bedrooms}',
                            style: const TextStyle(
                                fontSize: 12, color: _kSecondary)),
                        const SizedBox(width: 10),
                      ],
                      if (property.bathrooms != null) ...[
                        const Icon(Icons.bathtub_rounded,
                            size: 14, color: _kSecondary),
                        const SizedBox(width: 3),
                        Text('${property.bathrooms}',
                            style: const TextStyle(
                                fontSize: 12, color: _kSecondary)),
                        const SizedBox(width: 10),
                      ],
                      if (property.areaSqm != null)
                        Text(
                          '${property.areaSqm!.toStringAsFixed(0)} m\u00B2',
                          style:
                              const TextStyle(fontSize: 12, color: _kSecondary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Type badge + featured
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          property.type.displayName,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary),
                        ),
                      ),
                      if (property.isFeatured) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _kPrimary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Pendekeza',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                      ],
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
      color: _kPrimary.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(Icons.home_rounded, size: 40, color: _kSecondary),
      ),
    );
  }
}
