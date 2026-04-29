// lib/team/widgets/kpi_sparkline_chart.dart
import 'package:flutter/material.dart';
import '../models/work_models.dart';

class KpiSparklineChart extends StatelessWidget {
  final List<KpiEntry> entries;
  final double target;

  const KpiSparklineChart({
    super.key,
    required this.entries,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(entries: entries, target: target),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<KpiEntry> entries;
  final double target;

  _SparklinePainter({required this.entries, required this.target});

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;
    final values = entries.map((e) => e.actualValue).toList();
    final maxV = ([...values, target].reduce((a, b) => a > b ? a : b)) * 1.1;
    final minV = values.reduce((a, b) => a < b ? a : b) * 0.9;
    final range = maxV - minV == 0 ? 1.0 : maxV - minV;
    double xOf(int i) => size.width * i / (entries.length - 1).clamp(1, 999);
    double yOf(double v) => size.height - (size.height * (v - minV) / range);
    final tY = yOf(target);
    canvas.drawLine(Offset(0, tY), Offset(size.width, tY),
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.5)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke);
    final path = Path();
    for (int i = 0; i < entries.length; i++) {
      i == 0
          ? path.moveTo(xOf(i), yOf(values[i]))
          : path.lineTo(xOf(i), yOf(values[i]));
    }
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true);
    for (int i = 0; i < entries.length; i++) {
      canvas.drawCircle(Offset(xOf(i), yOf(values[i])), 3,
          Paint()..color = values[i] >= target ? Colors.green : Colors.red);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.entries != entries || old.target != target;
}
