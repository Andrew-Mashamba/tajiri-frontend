import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/property_listing.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kMuted = Color(0xFF9E9E9E);

/// Card widget for the new `PropertyListing` model.
/// Replaces `PropertyCard` which only accepted the old `Property` model.
class PropertyListingCard extends StatelessWidget {
  final PropertyListing listing;
  final VoidCallback? onTap;

  const PropertyListingCard({super.key, required this.listing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final photo = listing.photos.isNotEmpty
        ? ApiConfig.sanitizeUrl(listing.photos.first)
        : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: photo != null
                    ? Image.network(photo, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.home_work_rounded, color: _kMuted, size: 48),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (listing.photoVerificationStatus == 'verified')
                        const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF1B5E20)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_fmtPrice(listing.priceTzs)} ${listing.priceFrequency != null ? '/ ${isSw ? listing.priceFrequency!.labelSwahili : listing.priceFrequency!.label}' : ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    children: [
                      if (listing.bedrooms != null)
                        _meta(Icons.bed_rounded, '${listing.bedrooms}'),
                      if (listing.bathrooms != null)
                        _meta(Icons.bathroom_rounded, '${listing.bathrooms}'),
                      if (listing.areaSqm != null)
                        _meta(Icons.square_foot_rounded, '${listing.areaSqm} m²'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place_rounded, size: 14, color: _kMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          [listing.district, listing.region]
                              .where((s) => s != null && s.isNotEmpty)
                              .join(', '),
                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _kMuted),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: _kSecondary)),
      ],
    );
  }

  String _fmtPrice(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'TSh ${buf.toString()}';
  }
}
