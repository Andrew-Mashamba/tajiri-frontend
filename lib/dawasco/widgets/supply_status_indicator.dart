// lib/dawasco/widgets/supply_status_indicator.dart
import 'package:flutter/material.dart';

class SupplyStatusIndicator extends StatelessWidget {
  final bool isAvailable;
  final bool isSwahili;
  final VoidCallback? onTap;
  const SupplyStatusIndicator({super.key, required this.isAvailable, this.isSwahili = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? const Color(0xFF4CAF50) : Colors.red;
    final label = isAvailable
        ? (isSwahili ? 'Maji YAPO' : 'Water ON')
        : (isSwahili ? 'Maji HAYAPO' : 'Water OFF');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
