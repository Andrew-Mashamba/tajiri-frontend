// lib/qibla/widgets/bearing_display.dart
import 'package:flutter/material.dart';
import '../models/qibla_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Displays bearing angle and distance to Makkah.
class BearingDisplayWidget extends StatelessWidget {
  final QiblaDirection direction;

  const BearingDisplayWidget({super.key, required this.direction});

  String _cardinalDirection(double bearing) {
    const dirs = [
      'Kaskazini', 'Kaskazini-Mashariki', 'Mashariki', 'Kusini-Mashariki',
      'Kusini', 'Kusini-Magharibi', 'Magharibi', 'Kaskazini-Magharibi',
    ];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return dirs[index];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${direction.bearing.toStringAsFixed(1)}\u00B0',
                style: const TextStyle(
                  color: _kPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _cardinalDirection(direction.bearing),
            style: const TextStyle(color: _kSecondary, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _infoCol('Umbali', '${direction.distanceKm.toStringAsFixed(0)} km'),
              _infoCol('Mahali', direction.locationName),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCol(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: _kSecondary, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
