import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';

/// Spec line 311 — read-only availability mode chip surfaced on customer-side
/// partner cards/profile. Tap-to-edit support belongs on the partner-side
/// dashboard, not the customer view, so this widget is display-only.
class PartnerStatusChip extends StatelessWidget {
  final String mode; // open | busy | closed
  final int busyEtaExtraMinutes;
  const PartnerStatusChip({
    super.key,
    required this.mode,
    this.busyEtaExtraMinutes = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    if (mode == 'open' && busyEtaExtraMinutes == 0) {
      return const SizedBox.shrink();
    }
    final (bg, fg, label) = _classify(isSw);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  (Color, Color, String) _classify(bool isSw) {
    switch (mode) {
      case 'busy':
        final extra = busyEtaExtraMinutes > 0
            ? (isSw ? ' +$busyEtaExtraMinutes daka' : ' +${busyEtaExtraMinutes}m')
            : '';
        return (
          const Color(0xFFFFF8E1),
          const Color(0xFFE65100),
          (isSw ? 'Wenye shughuli' : 'Busy') + extra,
        );
      case 'closed':
        return (
          const Color(0xFFFFEBEE),
          const Color(0xFFB71C1C),
          isSw ? 'Imefungwa' : 'Closed',
        );
      default:
        return (
          const Color(0xFFE8F5E9),
          const Color(0xFF1B5E20),
          isSw ? 'Iko wazi' : 'Open',
        );
    }
  }
}
