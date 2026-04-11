// lib/buy_car/widgets/dealer_card.dart
import 'package:flutter/material.dart';
import '../models/buy_car_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class DealerCard extends StatelessWidget {
  final CarDealer dealer;
  final bool isSwahili;
  final VoidCallback? onTap;

  const DealerCard({
    super.key,
    required this.dealer,
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: dealer.logoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(dealer.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.store_rounded,
                              size: 24,
                              color: _kPrimary)))
                  : const Icon(Icons.store_rounded,
                      size: 24, color: _kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(dealer.name,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _kPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (dealer.isVerified)
                        const Icon(Icons.verified_rounded,
                            size: 16, color: Color(0xFF4CAF50)),
                    ]),
                    const SizedBox(height: 2),
                    if (dealer.location != null)
                      Text(dealer.location!,
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(dealer.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary)),
                      const SizedBox(width: 10),
                      Text(
                          '${dealer.listingCount} ${isSwahili ? 'magari' : 'cars'}',
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary)),
                    ]),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }
}
