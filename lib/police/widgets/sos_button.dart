// lib/police/widgets/sos_button.dart
import 'package:flutter/material.dart';

class SosButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isSwahili;

  const SosButton({
    super.key,
    required this.onPressed,
    required this.isSwahili,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onPressed,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.shade700,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.4),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_rounded, color: Colors.white, size: 36),
            const SizedBox(height: 4),
            const Text(
              'SOS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              isSwahili ? 'Bonyeza & shikilia' : 'Long press',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
