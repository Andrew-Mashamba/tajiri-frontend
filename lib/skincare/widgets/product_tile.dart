// lib/skincare/widgets/product_tile.dart
import 'package:flutter/material.dart';
import '../models/skincare_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class ProductTile extends StatelessWidget {
  final SkinProduct product;
  final VoidCallback? onTap;

  const ProductTile({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product image
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, e, s) => const Icon(
                            Icons.face_retouching_natural_rounded,
                            color: _kSecondary,
                            size: 28,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.face_retouching_natural_rounded,
                        color: _kSecondary,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.brand != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.brand!,
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Rating
                        if (product.rating > 0) ...[
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB300)),
                          const SizedBox(width: 2),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Price
                        Text(
                          'TZS ${_formatPrice(product.price)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // TMDA badge
              Column(
                children: [
                  if (product.isTmdaApproved)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 12, color: Color(0xFF4CAF50)),
                          SizedBox(width: 3),
                          Text(
                            'TMDA',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF4CAF50)),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Hakuna TMDA',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.orange),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Icon(Icons.chevron_right_rounded, size: 20, color: _kSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)}k';
    }
    return price.toStringAsFixed(0);
  }
}
