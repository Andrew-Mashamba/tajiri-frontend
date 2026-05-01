import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';

/// Spec F7 #69 — Dispute window with platform mediation.
///
/// Appears at the top of an engagement page when [windowStartedAt] is non-null.
/// Counts down a 7-day window, shows mediation status, and exposes an
/// "Escalate to Tajiri ops" CTA. Hosts the existing dispute schema fields:
///   - engagements.dispute_window_started_at (started)
///   - engagements.dispute_escalated_at (already escalated)
class DisputeWindowBanner extends StatefulWidget {
  final DateTime windowStartedAt;
  final DateTime? escalatedAt;
  final Future<void> Function()? onEscalate;
  final Future<void> Function()? onOpenMediationChat;

  const DisputeWindowBanner({
    super.key,
    required this.windowStartedAt,
    this.escalatedAt,
    this.onEscalate,
    this.onOpenMediationChat,
  });

  @override
  State<DisputeWindowBanner> createState() => _DisputeWindowBannerState();
}

class _DisputeWindowBannerState extends State<DisputeWindowBanner> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _recalc();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _recalc());
  }

  void _recalc() {
    final deadline = widget.windowStartedAt.add(const Duration(days: 7));
    final now = DateTime.now();
    setState(() {
      _remaining = deadline.isAfter(now) ? deadline.difference(now) : Duration.zero;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _humanRemaining(bool isSw) {
    if (_remaining == Duration.zero) {
      return isSw ? 'Muda umeisha' : 'Window expired';
    }
    final d = _remaining.inDays;
    final h = _remaining.inHours.remainder(24);
    if (d > 0) {
      return isSw ? 'Siku $d, saa $h zimebaki' : '$d day${d == 1 ? '' : 's'}, $h hour${h == 1 ? '' : 's'} left';
    }
    final m = _remaining.inMinutes.remainder(60);
    return isSw ? 'Saa $h, dakika $m zimebaki' : '${h}h ${m}m left';
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final escalated = widget.escalatedAt != null;
    final bgColor = escalated ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0);
    final accent = escalated ? const Color(0xFFB71C1C) : const Color(0xFFE65100);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                escalated ? Icons.gavel_rounded : Icons.flag_rounded,
                color: accent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  escalated
                      ? (isSw ? 'Mzozo unashughulikiwa na Tajiri' : 'Tajiri is mediating')
                      : (isSw ? 'Mzozo umeanzishwa' : 'Dispute opened'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            escalated
                ? (isSw
                    ? 'Mtu wa Tajiri atawasiliana nawe ndani ya saa 24.'
                    : 'A Tajiri rep will reach out within 24 hours.')
                : (isSw
                    ? 'Una siku 7 kujadili na mtoa huduma kabla ya kupandisha kwa Tajiri.'
                    : 'You have 7 days to resolve with the partner before escalating.'),
            style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 6),
          Text(
            _humanRemaining(isSw),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (widget.onOpenMediationChat != null)
                OutlinedButton.icon(
                  onPressed: () => widget.onOpenMediationChat!(),
                  icon: const Icon(Icons.chat_rounded, size: 16),
                  label: Text(
                    isSw ? 'Fungua mazungumzo' : 'Open chat',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1A1A),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                ),
              const SizedBox(width: 8),
              if (!escalated && widget.onEscalate != null)
                FilledButton.icon(
                  onPressed: () => widget.onEscalate!(),
                  icon: const Icon(Icons.gavel_rounded, size: 16),
                  label: Text(
                    isSw ? 'Wasiliana na Tajiri' : 'Escalate',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(backgroundColor: accent),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
