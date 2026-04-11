// lib/neighbourhood_watch/widgets/alert_card.dart
import 'package:flutter/material.dart';
import '../models/neighbourhood_watch_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class AlertCard extends StatelessWidget {
  final CommunityAlert alert;
  final bool isSwahili;
  final VoidCallback? onConfirm;

  const AlertCard({
    super.key,
    required this.alert,
    required this.isSwahili,
    this.onConfirm,
  });

  Color get _urgencyColor {
    switch (alert.urgency) {
      case 'critical':
        return Colors.red.shade800;
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData get _typeIcon {
    switch (alert.type) {
      case 'suspicious':
        return Icons.visibility_rounded;
      case 'theft':
        return Icons.money_off_rounded;
      case 'break_in':
        return Icons.door_front_door_rounded;
      case 'noise':
        return Icons.volume_up_rounded;
      case 'fire':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.notification_important_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ago = DateTime.now().difference(alert.createdAt);
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
        border: Border.all(
          color: alert.urgency == 'critical'
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
                  color: _urgencyColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_typeIcon, color: _urgencyColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('${alert.userName}  $timeStr',
                        style:
                            const TextStyle(fontSize: 11, color: _kSecondary)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _urgencyColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  alert.urgency.toUpperCase(),
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _urgencyColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(alert.description,
              style: const TextStyle(fontSize: 13, color: _kSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (alert.location != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on_rounded,
                  size: 12, color: _kSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(alert.location!,
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: onConfirm,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded,
                          size: 14, color: _kPrimary),
                      const SizedBox(width: 4),
                      Text(
                        '${isSwahili ? 'Thibitisha' : 'Confirm'} (${alert.confirmations})',
                        style: const TextStyle(fontSize: 12, color: _kPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
