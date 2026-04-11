// lib/my_pregnancy/widgets/kick_counter_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class KickCounterWidget extends StatelessWidget {
  final int count;
  final bool isRunning;
  final VoidCallback onTap;

  const KickCounterWidget({
    super.key,
    required this.count,
    required this.isRunning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reachedGoal = count >= 10;
    final sw =
        LocalStorageService.instanceSync?.getLanguageCode() == 'sw';

    return GestureDetector(
      onTap: isRunning
          ? () {
              HapticFeedback.mediumImpact();
              onTap();
            }
          : null,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRunning
              ? _kPrimary
              : _kPrimary.withValues(alpha: 0.3),
          boxShadow: isRunning
              ? [
                  BoxShadow(
                    color: _kPrimary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              reachedGoal
                  ? (sw ? 'Umefika lengo!' : 'Goal reached!')
                  : (sw ? 'mateke' : 'kicks'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            if (isRunning && !reachedGoal)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  sw ? 'Gusa kuhesabu' : 'Tap to count',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
