// State badge — pill that renders the 6-state machine.
// Spec §6: earning | live | pending | paused | ready | locked.
// Per ENGINEERING_PLAYBOOK.md the palette stays monochrome with semantic
// accents for status only.

import 'package:flutter/material.dart';
import '../models/income_source.dart';

class StateBadge extends StatelessWidget {
  final SourceState state;
  final String? overrideLabel;
  final bool pulse;

  const StateBadge({
    super.key,
    required this.state,
    this.overrideLabel,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = _themeFor(state);
    final label = overrideLabel ?? _labelFor(state);
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: theme.fg,
          letterSpacing: 0.4,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
    if (!pulse) return pill;
    return _Pulse(child: pill);
  }

  String _labelFor(SourceState s) {
    switch (s) {
      case SourceState.earning:
        return 'EARNING';
      case SourceState.live:
        return 'LIVE NOW';
      case SourceState.pending:
        return 'PENDING';
      case SourceState.paused:
        return 'PAUSED';
      case SourceState.ready:
        return 'READY';
      case SourceState.locked:
        return 'LOCKED';
      case SourceState.unknown:
        return '—';
    }
  }

  static _BadgeTheme _themeFor(SourceState s) {
    switch (s) {
      case SourceState.earning:
        return const _BadgeTheme(bg: Color(0xFFE8F5E9), fg: Color(0xFF1B5E20));
      case SourceState.live:
        return const _BadgeTheme(bg: Color(0xFFFCE4EC), fg: Color(0xFF880E4F));
      case SourceState.pending:
        return const _BadgeTheme(bg: Color(0xFFFFF8E1), fg: Color(0xFF7A5800));
      case SourceState.ready:
        return const _BadgeTheme(bg: Color(0xFFE3F2FD), fg: Color(0xFF0D47A1));
      case SourceState.paused:
      case SourceState.locked:
      case SourceState.unknown:
        return const _BadgeTheme(bg: Color(0xFFF2F2F2), fg: Color(0xFF666666));
    }
  }
}

class _BadgeTheme {
  final Color bg;
  final Color fg;
  const _BadgeTheme({required this.bg, required this.fg});
}

class _Pulse extends StatefulWidget {
  final Widget child;
  const _Pulse({required this.child});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.6, end: 1.0).animate(_c),
      child: widget.child,
    );
  }
}
