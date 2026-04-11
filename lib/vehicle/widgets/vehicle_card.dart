// lib/vehicle/widgets/vehicle_card.dart
import 'package:flutter/material.dart';
import '../models/vehicle_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;

  const VehicleCard({super.key, required this.vehicle, this.onTap});

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
              // Photo or icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: vehicle.photoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          vehicle.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.directions_car_rounded,
                              size: 28,
                              color: _kPrimary),
                        ),
                      )
                    : const Icon(Icons.directions_car_rounded,
                        size: 28, color: _kPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.displayName,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.plateNumber,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                          letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _tag(vehicle.fuelType.displayName),
                        if (vehicle.color != null) ...[
                          const SizedBox(width: 6),
                          _tag(vehicle.color!),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  if (vehicle.hasInsurance)
                    const Icon(Icons.verified_rounded,
                        size: 20, color: Color(0xFF4CAF50))
                  else
                    const Icon(Icons.warning_rounded,
                        size: 20, color: Colors.orange),
                  const SizedBox(height: 4),
                  Text(
                    vehicle.hasInsurance ? 'Bima' : 'Haina Bima',
                    style: TextStyle(
                        fontSize: 10,
                        color: vehicle.hasInsurance
                            ? const Color(0xFF4CAF50)
                            : Colors.orange),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11, color: _kSecondary, fontWeight: FontWeight.w500)),
    );
  }
}
