import 'package:flutter/material.dart';
import '../models/travel_models.dart';

class ModeIcon extends StatelessWidget {
  final TransportMode mode;
  final double size;
  final Color? color;

  const ModeIcon({
    super.key,
    required this.mode,
    this.size = 24,
    this.color,
  });

  static IconData iconFor(TransportMode mode) {
    switch (mode) {
      case TransportMode.bus:
        return Icons.directions_bus_rounded;
      case TransportMode.flight:
        return Icons.flight_rounded;
      case TransportMode.train:
        return Icons.train_rounded;
      case TransportMode.ferry:
        return Icons.directions_boat_rounded;
    }
  }

  static Widget modeRow(List<String> modes, {double size = 18, Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: modes.map((m) {
        final mode = TransportMode.fromString(m);
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: ModeIcon(mode: mode, size: size, color: color),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Icon(
      iconFor(mode),
      size: size,
      color: color ?? const Color(0xFF1A1A1A),
    );
  }
}
