// lib/traffic/widgets/congestion_banner.dart
import 'package:flutter/material.dart';
import '../models/traffic_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class CongestionBanner extends StatelessWidget {
  final CongestionAlert alert;
  final bool isSwahili;

  const CongestionBanner({
    super.key,
    required this.alert,
    required this.isSwahili,
  });

  Color get _levelColor {
    switch (alert.level) {
      case 'gridlock':
        return Colors.red.shade800;
      case 'heavy':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String get _levelLabel {
    if (isSwahili) {
      switch (alert.level) {
        case 'gridlock':
          return 'Kuziba Kabisa';
        case 'heavy':
          return 'Msongamano Mkubwa';
        case 'moderate':
          return 'Wastani';
        default:
          return 'Kawaida';
      }
    }
    return alert.level[0].toUpperCase() + alert.level.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _levelColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _levelColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.traffic_rounded, color: _levelColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.roadName,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$_levelLabel  ${alert.direction}',
                  style: TextStyle(fontSize: 11, color: _levelColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (alert.delayMinutes > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _levelColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${alert.delayMinutes}m',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _levelColor),
              ),
            ),
        ],
      ),
    );
  }
}
