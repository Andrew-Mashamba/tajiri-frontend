// lib/my_circle/widgets/cycle_status_card.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/my_circle_models.dart';

const Color _kCardBg = Color(0xFF1A1A1A);
const Color _kPeriodRed = Color(0xFFEF5350);
const Color _kFertileGreen = Color(0xFF66BB6A);
const Color _kOvulationGreen = Color(0xFF43A047);

class CycleStatusCard extends StatelessWidget {
  final CyclePrediction? prediction;
  final int? currentCycleDay;
  final bool isSwahili;

  const CycleStatusCard({
    super.key,
    this.prediction,
    this.currentCycleDay,
    this.isSwahili = false,
  });

  @override
  Widget build(BuildContext context) {
    final pred = prediction ?? CyclePrediction();
    final cycleLen = pred.cycleLength;
    final currentDay = currentCycleDay?.clamp(1, cycleLen) ?? 0;
    final periodLen = pred.periodLength;

    // Calculate fertile window as day-of-cycle
    int fertileStartDay = 0;
    int fertileEndDay = 0;
    int ovulationDay = 0;

    if (pred.nextPeriodDate != null) {
      final periodStart = pred.nextPeriodDate!.subtract(Duration(days: cycleLen));

      if (pred.fertileWindowStart != null) {
        fertileStartDay = pred.fertileWindowStart!.difference(periodStart).inDays + 1;
        fertileStartDay = fertileStartDay.clamp(1, cycleLen);
      }
      if (pred.fertileWindowEnd != null) {
        fertileEndDay = pred.fertileWindowEnd!.difference(periodStart).inDays + 1;
        fertileEndDay = fertileEndDay.clamp(1, cycleLen);
      }
      if (pred.ovulationDate != null) {
        ovulationDay = pred.ovulationDate!.difference(periodStart).inDays + 1;
        ovulationDay = ovulationDay.clamp(1, cycleLen);
      }
    }

    // Fallback defaults if no prediction data
    if (fertileStartDay == 0) fertileStartDay = cycleLen ~/ 2 - 2;
    if (fertileEndDay == 0) fertileEndDay = cycleLen ~/ 2 + 2;
    if (ovulationDay == 0) ovulationDay = cycleLen ~/ 2;

    // Determine current phase
    final phase = _getPhase(
      currentDay: currentDay,
      periodLen: periodLen,
      fertileStart: fertileStartDay,
      fertileEnd: fertileEndDay,
      ovulationDay: ovulationDay,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kCardBg.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // The cycle wheel
          SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Painted ring
                CustomPaint(
                  size: const Size(240, 240),
                  painter: CycleWheelPainter(
                    cycleLength: cycleLen,
                    currentDay: currentDay,
                    periodLength: periodLen,
                    fertileStart: fertileStartDay,
                    fertileEnd: fertileEndDay,
                    ovulationDay: ovulationDay,
                  ),
                ),
                // Day labels around the ring
                ..._buildDayLabels(
                  cycleLen: cycleLen,
                  currentDay: currentDay,
                  ovulationDay: ovulationDay,
                  fertileStart: fertileStartDay,
                ),
                // Center content
                _CenterContent(
                  currentDay: currentDay,
                  phase: phase,
                  daysUntilPeriod: pred.daysUntilNextPeriod,
                  isSwahili: isSwahili,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Info chips row
          _InfoChipsRow(
            prediction: pred,
            isSwahili: isSwahili,
          ),
          const SizedBox(height: 16),

          // Mini stats row
          Row(
            children: [
              _MiniStat(
                value: pred.daysUntilNextPeriod >= 0
                    ? '${pred.daysUntilNextPeriod}'
                    : '--',
                label: isSwahili ? 'Siku hadi hedhi' : 'Days until period',
              ),
              _MiniStat(
                value: '$cycleLen',
                label: isSwahili ? 'Urefu wa duru' : 'Cycle length',
              ),
              _MiniStat(
                value: pred.ovulationDate != null
                    ? '${pred.ovulationDate!.day}/${pred.ovulationDate!.month}'
                    : '--',
                label: isSwahili ? 'Ovulesheni' : 'Ovulation',
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDayLabels({
    required int cycleLen,
    required int currentDay,
    required int ovulationDay,
    required int fertileStart,
  }) {
    final labels = <_DayLabel>[];
    const radius = 108.0; // just outside the ring

    // Day 1 always shown
    labels.add(_DayLabel(day: 1, cycleLength: cycleLen, radius: radius));

    // Ovulation day
    if (ovulationDay > 1) {
      labels.add(_DayLabel(day: ovulationDay, cycleLength: cycleLen, radius: radius));
    }

    // Fertile start (if not too close to ovulation)
    if (fertileStart > 1 && (fertileStart - ovulationDay).abs() > 2) {
      labels.add(_DayLabel(day: fertileStart, cycleLength: cycleLen, radius: radius));
    }

    // Current day (if not too close to existing labels)
    if (currentDay > 0) {
      final tooClose = labels.any((l) => (l.day - currentDay).abs() <= 1 ||
          (l.day - currentDay).abs() >= cycleLen - 1);
      if (!tooClose) {
        labels.add(_DayLabel(day: currentDay, cycleLength: cycleLen, radius: radius, isCurrent: true));
      }
    }

    return labels;
  }

  _CyclePhase _getPhase({
    required int currentDay,
    required int periodLen,
    required int fertileStart,
    required int fertileEnd,
    required int ovulationDay,
  }) {
    if (currentDay <= 0) return _CyclePhase.none;
    if (currentDay <= periodLen) return _CyclePhase.period;
    if (currentDay == ovulationDay) return _CyclePhase.ovulation;
    if (currentDay >= fertileStart && currentDay <= fertileEnd) return _CyclePhase.fertile;
    return _CyclePhase.normal;
  }
}

// ─── Cycle Phase Enum ─────────────────────────────────────────

enum _CyclePhase { none, period, fertile, ovulation, normal }

// ─── Cycle Wheel Painter ──────────────────────────────────────

class CycleWheelPainter extends CustomPainter {
  final int cycleLength;
  final int currentDay; // 1-based, 0 = unknown
  final int periodLength;
  final int fertileStart;
  final int fertileEnd;
  final int ovulationDay;

  CycleWheelPainter({
    required this.cycleLength,
    required this.currentDay,
    required this.periodLength,
    required this.fertileStart,
    required this.fertileEnd,
    required this.ovulationDay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius - 18;
    final degreesPerDay = 360.0 / cycleLength;
    // Start at -90 degrees (12 o'clock position)
    const startAngle = -90.0;
    const gapDegrees = 1.2; // gap between segments

    // Draw each day segment
    for (int day = 1; day <= cycleLength; day++) {
      final segStart = startAngle + (day - 1) * degreesPerDay + gapDegrees / 2;
      final segSweep = degreesPerDay - gapDegrees;

      final color = _colorForDay(day);
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round;

      final midRadius = (outerRadius + innerRadius) / 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: midRadius),
        _degToRad(segStart),
        _degToRad(segSweep),
        false,
        paint,
      );
    }

    // Draw ovulation marker (bright dot on the ring)
    if (ovulationDay > 0) {
      final ovAngle = startAngle + (ovulationDay - 0.5) * degreesPerDay;
      final midRadius = (outerRadius + innerRadius) / 2;
      final ovPos = Offset(
        center.dx + midRadius * cos(_degToRad(ovAngle)),
        center.dy + midRadius * sin(_degToRad(ovAngle)),
      );
      final ovPaint = Paint()..color = _kOvulationGreen;
      canvas.drawCircle(ovPos, 5, ovPaint);
      // White inner dot
      canvas.drawCircle(ovPos, 2, Paint()..color = Colors.white);
    }

    // Draw current day marker
    if (currentDay > 0 && currentDay <= cycleLength) {
      final cdAngle = startAngle + (currentDay - 0.5) * degreesPerDay;
      final midRadius = (outerRadius + innerRadius) / 2;
      final cdPos = Offset(
        center.dx + midRadius * cos(_degToRad(cdAngle)),
        center.dy + midRadius * sin(_degToRad(cdAngle)),
      );

      // Glow shadow
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(cdPos, 10, glowPaint);

      // White filled circle marker
      final markerPaint = Paint()..color = Colors.white;
      canvas.drawCircle(cdPos, 7, markerPaint);

      // Inner dot with phase color
      final innerColor = _colorForDay(currentDay) == Colors.white.withValues(alpha: 0.15)
          ? _kCardBg
          : _colorForDay(currentDay);
      canvas.drawCircle(cdPos, 3.5, Paint()..color = innerColor);
    }
  }

  Color _colorForDay(int day) {
    if (day <= periodLength) return _kPeriodRed;
    if (day == ovulationDay) return _kOvulationGreen;
    if (day >= fertileStart && day <= fertileEnd) return _kFertileGreen;
    return Colors.white.withValues(alpha: 0.15);
  }

  double _degToRad(double degrees) => degrees * pi / 180;

  @override
  bool shouldRepaint(covariant CycleWheelPainter oldDelegate) {
    return oldDelegate.currentDay != currentDay ||
        oldDelegate.cycleLength != cycleLength ||
        oldDelegate.periodLength != periodLength ||
        oldDelegate.fertileStart != fertileStart ||
        oldDelegate.fertileEnd != fertileEnd ||
        oldDelegate.ovulationDay != ovulationDay;
  }
}

// ─── Day Label Widget (positioned around ring) ────────────────

class _DayLabel extends StatelessWidget {
  final int day;
  final int cycleLength;
  final double radius;
  final bool isCurrent;

  const _DayLabel({
    required this.day,
    required this.cycleLength,
    required this.radius,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    final degreesPerDay = 360.0 / cycleLength;
    final angle = -90.0 + (day - 0.5) * degreesPerDay;
    final radians = angle * pi / 180;

    // Position relative to center of 240x240 area
    final dx = radius * cos(radians);
    final dy = radius * sin(radians);

    return Positioned(
      left: 120 + dx - 12,
      top: 120 + dy - 10,
      child: SizedBox(
        width: 24,
        height: 20,
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              color: isCurrent ? Colors.white : Colors.white54,
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ─── Center Content ───────────────────────────────────────────

class _CenterContent extends StatelessWidget {
  final int currentDay;
  final _CyclePhase phase;
  final int daysUntilPeriod;
  final bool isSwahili;

  const _CenterContent({
    required this.currentDay,
    required this.phase,
    required this.daysUntilPeriod,
    required this.isSwahili,
  });

  @override
  Widget build(BuildContext context) {
    String dayText;
    String phaseLabel;
    Color phaseColor;
    String subLabel;

    if (currentDay <= 0) {
      dayText = '--';
      phaseLabel = isSwahili ? 'Anza kufuatilia' : 'Start tracking';
      phaseColor = Colors.white70;
      subLabel = '';
    } else {
      dayText = '$currentDay';
      switch (phase) {
        case _CyclePhase.period:
          phaseLabel = isSwahili ? 'Hedhi' : 'Period';
          phaseColor = _kPeriodRed;
        case _CyclePhase.fertile:
          phaseLabel = isSwahili ? 'Rutuba' : 'Fertile';
          phaseColor = _kFertileGreen;
        case _CyclePhase.ovulation:
          phaseLabel = isSwahili ? 'Ovulesheni' : 'Ovulation';
          phaseColor = _kFertileGreen;
        case _CyclePhase.normal:
          phaseLabel = isSwahili ? 'Siku ya $currentDay' : 'Day $currentDay';
          phaseColor = Colors.white;
        case _CyclePhase.none:
          phaseLabel = isSwahili ? 'Anza kufuatilia' : 'Start tracking';
          phaseColor = Colors.white70;
      }

      if (daysUntilPeriod >= 0) {
        subLabel = isSwahili
            ? 'Siku $daysUntilPeriod hadi hedhi'
            : '$daysUntilPeriod days until period';
      } else {
        subLabel = '';
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          dayText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          phaseLabel,
          style: TextStyle(
            color: phaseColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        if (subLabel.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Info Chips Row ───────────────────────────────────────────

class _InfoChipsRow extends StatelessWidget {
  final CyclePrediction prediction;
  final bool isSwahili;

  const _InfoChipsRow({
    required this.prediction,
    required this.isSwahili,
  });

  String _formatDate(DateTime? dt) {
    if (dt == null) return '--';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoChip(
            dotColor: _kPeriodRed,
            label: isSwahili ? 'Hedhi' : 'Period',
            value: _formatDate(prediction.nextPeriodDate),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _InfoChip(
            dotColor: _kFertileGreen,
            label: isSwahili ? 'Rutuba' : 'Fertile',
            value: prediction.fertileWindowStart != null && prediction.fertileWindowEnd != null
                ? '${_formatDate(prediction.fertileWindowStart)} - ${_formatDate(prediction.fertileWindowEnd)}'
                : '--',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _InfoChip(
            dotColor: _kOvulationGreen,
            label: isSwahili ? 'Ovulesheni' : 'Ovulation',
            value: _formatDate(prediction.ovulationDate),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final Color dotColor;
  final String label;
  final String value;

  const _InfoChip({
    required this.dotColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Mini Stat ────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;

  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
