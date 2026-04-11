// lib/alerts/widgets/checkin_card.dart
import 'package:flutter/material.dart';
import '../models/alerts_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class CheckInCard extends StatelessWidget {
  final FamilyCheckIn checkIn;
  final bool isSwahili;

  const CheckInCard({
    super.key,
    required this.checkIn,
    required this.isSwahili,
  });

  Color get _statusColor {
    switch (checkIn.status) {
      case 'safe':
        return Colors.green;
      case 'need_help':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (checkIn.status) {
      case 'safe':
        return Icons.check_circle_rounded;
      case 'need_help':
        return Icons.sos_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String get _statusLabel {
    if (isSwahili) {
      switch (checkIn.status) {
        case 'safe':
          return 'Salama';
        case 'need_help':
          return 'Anahitaji Msaada';
        default:
          return 'Hajajibu';
      }
    }
    switch (checkIn.status) {
      case 'safe':
        return 'Safe';
      case 'need_help':
        return 'Needs Help';
      default:
        return 'No Response';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(_statusIcon, color: _statusColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(checkIn.userName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(_statusLabel,
                    style: TextStyle(fontSize: 12, color: _statusColor)),
                if (checkIn.message != null) ...[
                  const SizedBox(height: 2),
                  Text(checkIn.message!,
                      style:
                          const TextStyle(fontSize: 11, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          Text(
            checkIn.checkedAt.toString().substring(11, 16),
            style: const TextStyle(fontSize: 11, color: _kSecondary),
          ),
        ],
      ),
    );
  }
}
