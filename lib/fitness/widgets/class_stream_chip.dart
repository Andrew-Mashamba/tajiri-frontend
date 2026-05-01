import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/wave_h_services.dart';

/// Spec F6 #45 — Live + on-demand class chip. When the session has at least
/// one stream attached (`class_session_streams`), show a small Live or VOD
/// badge. Stays hidden if no streams.
class ClassStreamChip extends StatefulWidget {
  final int classSessionId;
  const ClassStreamChip({super.key, required this.classSessionId});

  @override
  State<ClassStreamChip> createState() => _ClassStreamChipState();
}

class _ClassStreamChipState extends State<ClassStreamChip> {
  List<Map<String, dynamic>> _streams = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await ClassStreamService.list(widget.classSessionId);
    if (mounted) setState(() => _streams = s);
  }

  @override
  Widget build(BuildContext context) {
    if (_streams.isEmpty) return const SizedBox.shrink();
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final hasLive = _streams.any((s) => (s['mode'] as String?) == 'live');
    final hasVod = _streams.any((s) => (s['mode'] as String?) == 'ondemand');
    return Wrap(
      spacing: 4,
      children: [
        if (hasLive)
          _Chip(
            color: const Color(0xFFB71C1C),
            icon: Icons.fiber_manual_record_rounded,
            label: isSw ? 'Moja kwa moja' : 'Live',
          ),
        if (hasVod)
          _Chip(
            color: const Color(0xFF1976D2),
            icon: Icons.video_library_rounded,
            label: isSw ? 'Rekodi ipo' : 'Recording',
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  const _Chip({required this.color, required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
