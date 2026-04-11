// lib/traffic/widgets/traffic_report_card.dart
import 'package:flutter/material.dart';
import '../models/traffic_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class TrafficReportCard extends StatelessWidget {
  final TrafficReport report;
  final bool isSwahili;
  final VoidCallback? onUpvote;

  const TrafficReportCard({
    super.key,
    required this.report,
    required this.isSwahili,
    this.onUpvote,
  });

  Color get _severityColor {
    switch (report.severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData get _typeIcon {
    switch (report.type) {
      case 'accident':
        return Icons.car_crash_rounded;
      case 'roadwork':
        return Icons.construction_rounded;
      case 'closure':
        return Icons.block_rounded;
      case 'hazard':
        return Icons.warning_rounded;
      default:
        return Icons.traffic_rounded;
    }
  }

  String _typeLabel(String type) {
    if (isSwahili) {
      switch (type) {
        case 'accident':
          return 'Ajali';
        case 'roadwork':
          return 'Ujenzi';
        case 'closure':
          return 'Barabara Imefungwa';
        case 'hazard':
          return 'Hatari';
        default:
          return 'Msongamano';
      }
    }
    return type[0].toUpperCase() + type.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final ago = DateTime.now().difference(report.createdAt);
    final timeStr = ago.inMinutes < 60
        ? '${ago.inMinutes}m'
        : ago.inHours < 24
            ? '${ago.inHours}h'
            : '${ago.inDays}d';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _severityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon, color: _severityColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _typeLabel(report.type),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(timeStr,
                        style:
                            const TextStyle(fontSize: 11, color: _kSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(report.description,
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (report.location != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 12, color: _kSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(report.location!,
                            style: const TextStyle(
                                fontSize: 11, color: _kSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onUpvote,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.thumb_up_rounded,
                          size: 14, color: _kSecondary),
                      const SizedBox(width: 4),
                      Text('${report.upvotes}',
                          style: const TextStyle(
                              fontSize: 12, color: _kSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
