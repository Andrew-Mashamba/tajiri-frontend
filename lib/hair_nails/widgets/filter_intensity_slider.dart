import 'package:flutter/material.dart';

/// A compact vertical slider displayed on the right edge of the camera preview.
class FilterIntensitySlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final String label;

  const FilterIntensitySlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),
          Text(
            '${(value * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 160,
            child: RotatedBox(
              quarterTurns: -1,
              child: SliderTheme(
                data: const SliderThemeData(
                  trackHeight: 3,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Color(0x40FFFFFF), // white24
                  thumbColor: Colors.white,
                  overlayColor: Color(0x20FFFFFF),
                ),
                child: Slider(
                  value: value,
                  min: 0.0,
                  max: 1.0,
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
