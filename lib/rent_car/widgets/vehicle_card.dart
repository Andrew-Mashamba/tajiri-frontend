// lib/rent_car/widgets/vehicle_card.dart
import 'package:flutter/material.dart';
import '../models/rent_car_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class VehicleCard extends StatelessWidget {
  final RentalVehicle vehicle;
  final VoidCallback? onTap;
  final bool horizontal;

  const VehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    if (horizontal) return _buildHorizontal();
    return _buildVertical();
  }

  Widget _buildVertical() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            AspectRatio(
              aspectRatio: 1.4,
              child: vehicle.photos.isNotEmpty
                  ? Image.network(vehicle.photos.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${vehicle.make} ${vehicle.model}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.airline_seat_recline_normal_rounded, size: 14, color: _kSecondary),
                      const SizedBox(width: 2),
                      Text('${vehicle.seats}', style: const TextStyle(fontSize: 11, color: _kSecondary)),
                      const Spacer(),
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB300)),
                      const SizedBox(width: 2),
                      Text(vehicle.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 11, color: _kSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('TZS ${vehicle.dailyRate.toStringAsFixed(0)}/day',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontal() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 90,
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: vehicle.photos.isNotEmpty
                    ? Image.network(vehicle.photos.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(vehicle.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('${vehicle.seats} seats | ${vehicle.transmission}',
                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('TZS ${vehicle.dailyRate.toStringAsFixed(0)}/day',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE8E8E8),
      child: const Center(
        child: Icon(Icons.directions_car_rounded, size: 32, color: _kSecondary),
      ),
    );
  }
}
