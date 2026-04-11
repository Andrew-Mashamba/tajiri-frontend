// lib/dc/widgets/emergency_banner.dart
import 'package:flutter/material.dart';
import '../models/dc_models.dart';

class EmergencyBanner extends StatelessWidget {
  final EmergencyAlert alert;
  final VoidCallback? onDismiss;

  const EmergencyBanner({super.key, required this.alert, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final bgColor = switch (alert.severity) {
      'critical' => const Color(0xFFB71C1C),
      'high' => const Color(0xFFE53935),
      'medium' => const Color(0xFFFFA000),
      _ => const Color(0xFF1E88E5),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (alert.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    alert.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
              onPressed: onDismiss,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
        ],
      ),
    );
  }
}
