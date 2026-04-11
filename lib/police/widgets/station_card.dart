// lib/police/widgets/station_card.dart
import 'package:flutter/material.dart';
import '../models/police_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class StationCard extends StatelessWidget {
  final PoliceStation station;
  final bool isSwahili;
  final VoidCallback? onTap;
  final VoidCallback? onCall;

  const StationCard({
    super.key,
    required this.station,
    required this.isSwahili,
    this.onTap,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                  Icons.local_police_rounded, color: _kPrimary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${station.districtName}, ${station.regionName}',
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (station.distance != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${station.distance!.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (station.phone != null)
              IconButton(
                icon: const Icon(Icons.phone_rounded, size: 20),
                color: _kPrimary,
                onPressed: onCall,
              ),
          ],
        ),
      ),
    );
  }
}
