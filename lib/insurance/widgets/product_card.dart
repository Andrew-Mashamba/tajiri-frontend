// lib/insurance/widgets/product_card.dart
import 'package:flutter/material.dart';
import '../models/insurance_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class InsuranceProductCard extends StatelessWidget {
  final InsuranceProduct product;
  final VoidCallback? onTap;

  const InsuranceProductCard({super.key, required this.product, this.onTap});

  String _fmt(double amount) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(product.category.icon, size: 22, color: _kPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          product.providerName,
                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (product.isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Maarufu', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Benefits preview
              if (product.benefits.isNotEmpty)
                ...product.benefits.take(3).map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF4CAF50)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(b, style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    )),
              const SizedBox(height: 10),
              // Footer: premium + cover
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TZS ${_fmt(product.premiumMonthly)}/mwezi',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
                      ),
                      Text(
                        'Bima: TZS ${_fmt(product.coverLimit)}',
                        style: const TextStyle(fontSize: 11, color: _kSecondary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product.coverageLabel,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
                    ),
                  ),
                  if (product.rating != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    Text(' ${product.rating!.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11, color: _kPrimary)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
