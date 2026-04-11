// lib/ambulance/widgets/tracking_status_timeline.dart
import 'package:flutter/material.dart';
import '../models/ambulance_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kRed = Color(0xFFCC0000);
const Color _kGreen = Color(0xFF2E7D32);

class TrackingStatusTimeline extends StatelessWidget {
  final EmergencyStatus currentStatus;
  final bool isSwahili;

  const TrackingStatusTimeline({
    super.key,
    required this.currentStatus,
    required this.isSwahili,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      (
        EmergencyStatus.dispatched,
        isSwahili ? 'Imetumwa' : 'Dispatched',
        Icons.send_rounded,
      ),
      (
        EmergencyStatus.enRoute,
        isSwahili ? 'Njiani' : 'En Route',
        Icons.directions_car_rounded,
      ),
      (
        EmergencyStatus.arrived,
        isSwahili ? 'Inawasili' : 'Arriving',
        Icons.place_rounded,
      ),
      (
        EmergencyStatus.completed,
        isSwahili ? 'Imefika' : 'Arrived',
        Icons.check_circle_rounded,
      ),
    ];

    final currentIdx = steps.indexWhere((s) => s.$1 == currentStatus);

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIdx = i ~/ 2;
          final done = stepIdx < currentIdx;
          return Expanded(
            child: Container(
              height: 3,
              color: done ? _kGreen : const Color(0xFFE0E0E0),
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final step = steps[stepIdx];
        final isActive = stepIdx == currentIdx;
        final isDone = stepIdx < currentIdx;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? _kRed
                    : isDone
                        ? _kGreen
                        : const Color(0xFFE0E0E0),
              ),
              child: Icon(
                step.$3,
                size: 20,
                color: isActive || isDone ? Colors.white : _kSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              step.$2,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? _kPrimary : _kSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      }),
    );
  }
}
