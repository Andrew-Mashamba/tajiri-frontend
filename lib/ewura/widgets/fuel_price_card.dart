// lib/ewura/widgets/fuel_price_card.dart
import 'package:flutter/material.dart';
import '../models/ewura_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class FuelPriceCard extends StatelessWidget {
  final FuelPrice price;
  final bool isSwahili;

  const FuelPriceCard({
    super.key,
    required this.price,
    required this.isSwahili,
  });

  IconData get _icon {
    switch (price.fuelType) {
      case 'diesel':
        return Icons.local_gas_station_rounded;
      case 'kerosene':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.local_gas_station_rounded;
    }
  }

  Color get _color {
    switch (price.fuelType) {
      case 'diesel':
        return Colors.amber.shade800;
      case 'kerosene':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: _color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price.fuelType[0].toUpperCase() +
                      price.fuelType.substring(1),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary),
                ),
                Text(price.region,
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TZS ${price.price.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary),
              ),
              Text(
                isSwahili ? 'kwa lita' : 'per litre',
                style: const TextStyle(fontSize: 10, color: _kSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
