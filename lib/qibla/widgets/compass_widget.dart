// lib/qibla/widgets/compass_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// A mini compass widget for embedding in other screens.
class MiniCompassWidget extends StatelessWidget {
  final double qiblaBearing;
  final double heading;
  final double size;

  const MiniCompassWidget({
    super.key,
    required this.qiblaBearing,
    this.heading = 0,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final angle = (qiblaBearing - heading) * math.pi / 180;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Needle
          Transform.rotate(
            angle: angle,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.navigation_rounded,
                  color: _kPrimary,
                  size: size * 0.4,
                ),
              ],
            ),
          ),
          // Center dot
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: _kSecondary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
