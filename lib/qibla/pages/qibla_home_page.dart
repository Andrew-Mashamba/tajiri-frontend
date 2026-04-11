// lib/qibla/pages/qibla_home_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/qibla_models.dart';
import '../services/qibla_service.dart';
import 'calibration_page.dart';
import 'qibla_map_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class QiblaHomePage extends StatefulWidget {
  final int userId;
  const QiblaHomePage({super.key, required this.userId});

  @override
  State<QiblaHomePage> createState() => _QiblaHomePageState();
}

class _QiblaHomePageState extends State<QiblaHomePage>
    with SingleTickerProviderStateMixin {
  QiblaDirection? _direction;
  final CalibrationQuality _calibration = CalibrationQuality.good;
  bool _locked = false;
  final double _compassHeading = 0;

  @override
  void initState() {
    super.initState();
    _calculateQibla();
  }

  void _calculateQibla() {
    // Default: Dar es Salaam
    _direction = QiblaService.calculateOffline(
      latitude: -6.7924,
      longitude: 39.2083,
      locationName: 'Dar es Salaam',
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final dir = _direction;
    final bearing = dir?.bearing ?? 0;

    return Column(
      children: [
        // Map action
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.map_rounded, color: _kPrimary),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QiblaMapPage(direction: _direction),
                ),
              ),
            ),
          ),
        ),

        // ─── Calibration Indicator ────────────────────
        _buildCalibrationBadge(),
        const SizedBox(height: 24),

        // ─── Compass ─────────────────────────────────
        Expanded(child: _buildCompass(bearing)),

        // ─── Bearing Info ────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                '${bearing.toStringAsFixed(1)}\u00B0',
                style: const TextStyle(
                  color: _kPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dir != null
                    ? 'Umbali: ${dir.distanceKm.toStringAsFixed(0)} km hadi Makkah'
                    : '',
                style: const TextStyle(color: _kSecondary, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _actionButton(
                    icon: _locked
                        ? Icons.lock_rounded
                        : Icons.lock_open_rounded,
                    label: _locked ? 'Imefungwa' : 'Funga',
                    onTap: () => setState(() => _locked = !_locked),
                  ),
                  const SizedBox(width: 16),
                  _actionButton(
                    icon: Icons.tune_rounded,
                    label: 'Sahihisha',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CalibrationPage(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCalibrationBadge() {
    Color badgeColor;
    switch (_calibration) {
      case CalibrationQuality.good:
        badgeColor = Colors.green;
      case CalibrationQuality.fair:
        badgeColor = Colors.orange;
      case CalibrationQuality.poor:
        badgeColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sensors_rounded, color: badgeColor, size: 16),
          const SizedBox(width: 6),
          Text(
            'Usahihi: ${_calibration.label}',
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompass(double bearing) {
    return Center(
      child: SizedBox(
        width: 280,
        height: 280,
        child: CustomPaint(
          painter: _CompassPainter(
            bearing: bearing,
            heading: _compassHeading,
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _kPrimary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _kPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Compass Painter ──────────────────────────────────────────
class _CompassPainter extends CustomPainter {
  final double bearing;
  final double heading;

  _CompassPainter({required this.bearing, required this.heading});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Outer circle
    final outerPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, outerPaint);

    // Direction ticks
    final tickPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 1.5;
    for (int i = 0; i < 360; i += 30) {
      final angle = (i - heading) * math.pi / 180;
      final inner = i % 90 == 0 ? radius - 20 : radius - 10;
      final start = Offset(
        center.dx + inner * math.sin(angle),
        center.dy - inner * math.cos(angle),
      );
      final end = Offset(
        center.dx + radius * math.sin(angle),
        center.dy - radius * math.cos(angle),
      );
      canvas.drawLine(start, end, tickPaint);
    }

    // Qibla needle
    final qiblaAngle = (bearing - heading) * math.pi / 180;
    final needlePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    final needlePath = Path()
      ..moveTo(
        center.dx + (radius - 30) * math.sin(qiblaAngle),
        center.dy - (radius - 30) * math.cos(qiblaAngle),
      )
      ..lineTo(
        center.dx + 6 * math.sin(qiblaAngle + math.pi / 2),
        center.dy - 6 * math.cos(qiblaAngle + math.pi / 2),
      )
      ..lineTo(
        center.dx - 6 * math.sin(qiblaAngle + math.pi / 2),
        center.dy + 6 * math.cos(qiblaAngle + math.pi / 2),
      )
      ..close();
    canvas.drawPath(needlePath, needlePaint);

    // Kaaba dot
    final kaabaDot = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(
        center.dx + (radius - 30) * math.sin(qiblaAngle),
        center.dy - (radius - 30) * math.cos(qiblaAngle),
      ),
      8,
      kaabaDot,
    );

    // Center dot
    canvas.drawCircle(center, 5, Paint()..color = const Color(0xFF666666));

    // Cardinal labels
    final labels = ['N', 'E', 'S', 'W'];
    for (int i = 0; i < 4; i++) {
      final angle = (i * 90 - heading) * math.pi / 180;
      final pos = Offset(
        center.dx + (radius + 14) * math.sin(angle),
        center.dy - (radius + 14) * math.cos(angle),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: i == 0 ? const Color(0xFF1A1A1A) : const Color(0xFF999999),
            fontSize: 14,
            fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) =>
      old.bearing != bearing || old.heading != heading;
}
