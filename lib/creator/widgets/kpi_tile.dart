// KPI tile + mini sparkline.
// Spec §3 (IA): three KPIs — This period net / Top source / Sources unlocked.

import 'package:flutter/material.dart';

class KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Widget? trailing;

  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
              letterSpacing: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF666666),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(height: 6),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Tiny sparkline bar chart. Heights are 0..1 normalized.
class MiniSparkline extends StatelessWidget {
  final List<double> bars;
  final double height;
  final Color color;

  const MiniSparkline({
    super.key,
    required this.bars,
    this.height = 18,
    this.color = const Color(0xFF1A1A1A),
  });

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return SizedBox(height: height);
    }
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < bars.length; i++) ...[
            Expanded(
              child: FractionallySizedBox(
                heightFactor: bars[i].clamp(0.05, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
            if (i != bars.length - 1) const SizedBox(width: 1.5),
          ],
        ],
      ),
    );
  }
}

/// Thin progress bar used inside a "Vimefunguliwa 3/9" tile.
class ProgressBar extends StatelessWidget {
  final double pct; // 0..100
  final double height;
  final Color trackColor;
  final Color fillColor;

  const ProgressBar({
    super.key,
    required this.pct,
    this.height = 4,
    this.trackColor = const Color(0xFFF5F5F5),
    this.fillColor = const Color(0xFF1A1A1A),
  });

  @override
  Widget build(BuildContext context) {
    final clamped = pct.clamp(0, 100) / 100;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: trackColor),
            FractionallySizedBox(
              widthFactor: clamped.toDouble(),
              alignment: Alignment.centerLeft,
              child: Container(color: fillColor),
            ),
          ],
        ),
      ),
    );
  }
}
