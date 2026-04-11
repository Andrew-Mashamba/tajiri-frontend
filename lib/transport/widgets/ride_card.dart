// lib/transport/widgets/ride_card.dart
import 'package:flutter/material.dart';
import '../models/transport_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class RideCard extends StatelessWidget {
  final RideRequest ride;
  final VoidCallback? onTap;

  const RideCard({super.key, required this.ride, this.onTap});

  String _fmtPrice(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  String _fmtDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ride.status.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(ride.vehicleType.icon, size: 18, color: ride.status.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.vehicleType.displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ride.status.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: ride.status.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TZS ${_fmtPrice(ride.actualFare ?? ride.estimatedFare)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _fmtDate(ride.createdAt),
                        style: const TextStyle(fontSize: 10, color: _kSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Route
              Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(width: 1, height: 16, color: Colors.grey.shade300),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.pickup,
                          style: const TextStyle(fontSize: 12, color: _kPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ride.dropoff,
                          style: const TextStyle(fontSize: 12, color: _kPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (ride.driverName != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person_rounded, size: 14, color: _kSecondary),
                    const SizedBox(width: 4),
                    Text(
                      ride.driverName!,
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                    ),
                    if (ride.vehiclePlate != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        ride.vehiclePlate!,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kSecondary),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
