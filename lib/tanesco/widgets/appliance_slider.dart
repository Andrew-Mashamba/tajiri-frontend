// lib/tanesco/widgets/appliance_slider.dart
import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class ApplianceSlider extends StatelessWidget {
  final String name;
  final IconData icon;
  final double watts;
  final double hoursPerDay;
  final ValueChanged<double> onHoursChanged;

  const ApplianceSlider({
    super.key,
    required this.name,
    required this.icon,
    required this.watts,
    required this.hoursPerDay,
    required this.onHoursChanged,
  });

  double get monthlyKwh => (watts * hoursPerDay * 30) / 1000;

  double get monthlyCost {
    final kwh = monthlyKwh;
    // Domestic D1 tariff
    if (kwh <= 75) return kwh * 100;
    return 75 * 100 + (kwh - 75) * 350;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: _kPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${watts.toStringAsFixed(0)}W',
                        style: const TextStyle(fontSize: 11, color: _kSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${monthlyKwh.toStringAsFixed(1)} kWh',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
                  Text('TZS ${monthlyCost.toStringAsFixed(0)}/mwezi',
                      style: const TextStyle(fontSize: 10, color: _kSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${hoursPerDay.toStringAsFixed(1)}h/siku',
                  style: const TextStyle(fontSize: 11, color: _kSecondary)),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: _kPrimary,
                    inactiveTrackColor: _kPrimary.withValues(alpha: 0.15),
                    thumbColor: _kPrimary,
                    overlayColor: _kPrimary.withValues(alpha: 0.1),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    value: hoursPerDay,
                    min: 0, max: 24,
                    divisions: 48,
                    onChanged: onHoursChanged,
                  ),
                ),
              ),
              Text('24h', style: const TextStyle(fontSize: 11, color: _kSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
