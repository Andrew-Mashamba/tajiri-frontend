import 'package:flutter/material.dart';

class StreakIndicator extends StatelessWidget {
  final int days;
  final bool isFrozen;
  final double size;

  const StreakIndicator({
    super.key,
    required this.days,
    this.isFrozen = false,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (days <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_fire_department_rounded,
          size: size,
          color: isFrozen ? const Color(0xFF999999) : const Color(0xFF1A1A1A),
        ),
        const SizedBox(width: 3),
        Text(
          '$days',
          style: TextStyle(
            fontSize: size - 2,
            fontWeight: FontWeight.w700,
            color: isFrozen ? const Color(0xFF999999) : const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}
