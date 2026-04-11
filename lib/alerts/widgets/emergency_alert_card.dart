// lib/alerts/widgets/emergency_alert_card.dart
import 'package:flutter/material.dart';
import '../models/alerts_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class EmergencyAlertCard extends StatelessWidget {
  final EmergencyAlert alert;
  final bool isSwahili;
  final VoidCallback? onTap;

  const EmergencyAlertCard({
    super.key,
    required this.alert,
    required this.isSwahili,
    this.onTap,
  });

  Color get _severityColor {
    switch (alert.severity) {
      case 'emergency':
        return Colors.red.shade800;
      case 'warning':
        return Colors.red;
      case 'watch':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData get _typeIcon {
    switch (alert.type) {
      case 'weather':
        return Icons.cloud_rounded;
      case 'flood':
        return Icons.water_rounded;
      case 'earthquake':
        return Icons.landscape_rounded;
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'tsunami':
        return Icons.waves_rounded;
      default:
        return Icons.warning_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alert.severity == 'emergency'
                ? Colors.red.withValues(alpha: 0.3)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _severityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_typeIcon, color: _severityColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(alert.title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _severityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    alert.severity.toUpperCase(),
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _severityColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(alert.description,
                style: const TextStyle(fontSize: 13, color: _kSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            if (alert.region != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_rounded,
                    size: 12, color: _kSecondary),
                const SizedBox(width: 4),
                Text(alert.region!,
                    style: const TextStyle(fontSize: 11, color: _kSecondary)),
              ]),
            ],
            const SizedBox(height: 4),
            Text(
              alert.issuedAt.toString().substring(0, 16),
              style: const TextStyle(fontSize: 11, color: _kSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
