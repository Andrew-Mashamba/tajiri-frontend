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

  /// Returns graduated icon size based on streak milestone.
  double get _graduatedSize {
    if (isFrozen) return size;
    if (days >= 100) return 22;
    if (days >= 30) return 20;
    if (days >= 7) return 18;
    return 16;
  }

  /// Returns graduated icon color based on streak milestone.
  Color get _graduatedColor {
    if (isFrozen) return const Color(0xFF999999);
    if (days >= 30) return const Color(0xFF1A1A1A);
    if (days >= 7) return const Color(0xFF666666);
    return const Color(0xFF999999);
  }

  /// Returns graduated font weight for the day count text.
  FontWeight get _graduatedFontWeight {
    if (days >= 100) return FontWeight.w900;
    if (days >= 30) return FontWeight.w800;
    if (days >= 7) return FontWeight.w700;
    return FontWeight.w700;
  }

  @override
  Widget build(BuildContext context) {
    if (days <= 0) return const SizedBox.shrink();
    final iconSize = _graduatedSize;
    final color = _graduatedColor;
    final fontWeight = _graduatedFontWeight;
    final bool showGlow = !isFrozen && days >= 100;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showGlow)
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A1A1A).withOpacity(0.25),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              size: iconSize,
              color: color,
            ),
          )
        else
          Icon(
            Icons.local_fire_department_rounded,
            size: iconSize,
            color: color,
          ),
        const SizedBox(width: 3),
        Text(
          '$days',
          style: TextStyle(
            fontSize: iconSize - 2,
            fontWeight: fontWeight,
            color: color,
          ),
        ),
      ],
    );
  }
}
