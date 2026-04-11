// lib/fuel_delivery/widgets/fuel_price_card.dart
import 'package:flutter/material.dart';
import '../models/fuel_delivery_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class FuelPriceCard extends StatelessWidget {
  final FuelPrice price;
  final bool isSwahili;
  final bool isSelected;
  final VoidCallback? onTap;

  const FuelPriceCard({
    super.key,
    required this.price,
    this.isSwahili = true,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected ? _kPrimary : Colors.grey.shade200),
        ),
        child: Column(children: [
          Icon(
            _iconFor(price.fuelType),
            size: 28,
            color: isSelected ? Colors.white : _kPrimary,
          ),
          const SizedBox(height: 8),
          Text(price.fuelLabel,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : _kPrimary)),
          const SizedBox(height: 4),
          Text('TZS ${price.pricePerLiter.toStringAsFixed(0)}',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : _kPrimary)),
          Text(isSwahili ? '/lita' : '/liter',
              style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.6)
                      : _kSecondary)),
          const SizedBox(height: 4),
          Text(price.region,
              style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.6)
                      : _kSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'diesel':
        return Icons.local_gas_station_rounded;
      case 'premium':
        return Icons.star_rounded;
      default:
        return Icons.local_gas_station_rounded;
    }
  }
}
