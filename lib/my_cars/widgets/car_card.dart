// lib/my_cars/widgets/car_card.dart
import 'package:flutter/material.dart';
import '../models/my_cars_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class CarCard extends StatelessWidget {
  final Car car;
  final bool isSwahili;
  final VoidCallback? onTap;

  const CarCard({
    super.key,
    required this.car,
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
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: car.photoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(car.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.directions_car_rounded,
                              size: 28,
                              color: _kPrimary)))
                  : const Icon(Icons.directions_car_rounded,
                      size: 28, color: _kPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(car.displayName,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(car.plateNumber,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Row(children: [
                      _tag(car.fuelType),
                      if (car.color != null) ...[
                        const SizedBox(width: 6),
                        _tag(car.color!),
                      ],
                      const SizedBox(width: 6),
                      _tag('${car.mileage.toStringAsFixed(0)} km'),
                    ]),
                  ]),
            ),
            Column(children: [
              Icon(
                car.hasInsurance
                    ? Icons.verified_rounded
                    : Icons.warning_rounded,
                size: 20,
                color: car.hasInsurance
                    ? const Color(0xFF4CAF50)
                    : Colors.orange,
              ),
              const SizedBox(height: 2),
              Text(
                car.hasInsurance
                    ? (isSwahili ? 'Bima' : 'Insured')
                    : (isSwahili ? 'Hakuna' : 'None'),
                style: TextStyle(
                    fontSize: 10,
                    color: car.hasInsurance
                        ? const Color(0xFF4CAF50)
                        : Colors.orange),
              ),
            ]),
          ]),
        ),
      ),
    );
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
