// lib/nida/widgets/office_card.dart
import 'package:flutter/material.dart';
import '../models/nida_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class OfficeCard extends StatelessWidget {
  final NidaOffice office;
  const OfficeCard({super.key, required this.office});

  Color get _queueColor {
    final m = office.queueEstimateMinutes;
    if (m == null) return _kSecondary;
    if (m < 60) return const Color(0xFF4CAF50);
    if (m < 180) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on_rounded, size: 20, color: _kPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(office.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (office.district != null)
                      Text(office.district!,
                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              // Queue indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _queueColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_rounded, size: 12, color: _queueColor),
                    const SizedBox(width: 4),
                    Text(office.queueLabel,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _queueColor)),
                  ],
                ),
              ),
            ],
          ),
          if (office.address != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place_rounded, size: 14, color: _kSecondary),
                const SizedBox(width: 4),
                Expanded(child: Text(office.address!,
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
          if (office.hours != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 14, color: _kSecondary),
                const SizedBox(width: 4),
                Text(office.hours!, style: const TextStyle(fontSize: 12, color: _kSecondary)),
              ],
            ),
          ],
          if (office.distanceKm != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.directions_rounded, size: 14, color: _kSecondary),
                const SizedBox(width: 4),
                Text('${office.distanceKm!.toStringAsFixed(1)} km',
                    style: const TextStyle(fontSize: 12, color: _kSecondary)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
