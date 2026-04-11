// lib/wakati_wa_sala/widgets/prayer_time_tile.dart
import 'package:flutter/material.dart';
import '../models/wakati_wa_sala_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class PrayerTimeTile extends StatelessWidget {
  final PrayerTime prayer;
  final VoidCallback? onTap;

  const PrayerTimeTile({super.key, required this.prayer, this.onTap});

  IconData _iconForPrayer(String name) {
    switch (name.toLowerCase()) {
      case 'fajr':
        return Icons.wb_twilight_rounded;
      case 'dhuhr':
        return Icons.wb_sunny_rounded;
      case 'asr':
        return Icons.sunny_snowing;
      case 'maghrib':
        return Icons.nightlight_round;
      case 'isha':
        return Icons.nights_stay_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = prayer.status == PrayerStatus.onTime ||
        prayer.status == PrayerStatus.late_ ||
        prayer.status == PrayerStatus.qada;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green.shade50
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _iconForPrayer(prayer.name),
            color: isCompleted ? Colors.green : _kSecondary,
            size: 20,
          ),
        ),
        title: Text(
          '${prayer.nameSwahili} (${prayer.name})',
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: prayer.iqamahTime != null
            ? Text(
                'Iqamah: ${prayer.iqamahTime}',
                style: const TextStyle(color: _kSecondary, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Text(
          prayer.time,
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
