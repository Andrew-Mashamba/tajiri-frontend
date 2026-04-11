// lib/ramadan/widgets/iftar_countdown.dart
import 'dart:async';
import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class IftarCountdownWidget extends StatefulWidget {
  final DateTime iftarTime;

  const IftarCountdownWidget({super.key, required this.iftarTime});

  @override
  State<IftarCountdownWidget> createState() => _IftarCountdownWidgetState();
}

class _IftarCountdownWidgetState extends State<IftarCountdownWidget> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    final diff = widget.iftarTime.difference(DateTime.now());
    if (mounted) {
      setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Muda hadi Iftar',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _timeBlock(h, 'Saa'),
              const SizedBox(width: 12),
              const Text(':',
                  style: TextStyle(
                      color: Colors.white, fontSize: 28,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              _timeBlock(m, 'Dak'),
              const SizedBox(width: 12),
              const Text(':',
                  style: TextStyle(
                      color: Colors.white, fontSize: 28,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              _timeBlock(s, 'Sek'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeBlock(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
