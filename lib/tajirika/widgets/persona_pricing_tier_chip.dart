import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';

/// Spec line 1278 — auto-assigned per-persona pricing tier (Budget /
/// Standard / Premium) computed from price band relative to cluster median.
class PersonaPricingTierChip extends StatelessWidget {
  final String? tier; // budget | standard | premium
  const PersonaPricingTierChip({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    if (tier == null || tier!.isEmpty) return const SizedBox.shrink();
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final (bg, fg, label, icon) = _classify(tier!, isSw);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, String, IconData) _classify(String t, bool isSw) {
    switch (t.toLowerCase()) {
      case 'premium':
        return (
          const Color(0xFFEDE7F6),
          const Color(0xFF4527A0),
          isSw ? 'Premium' : 'Premium',
          Icons.workspace_premium_rounded,
        );
      case 'budget':
        return (
          const Color(0xFFE8F5E9),
          const Color(0xFF1B5E20),
          isSw ? 'Bei nafuu' : 'Budget',
          Icons.savings_rounded,
        );
      default:
        return (
          const Color(0xFFE3F2FD),
          const Color(0xFF0D47A1),
          isSw ? 'Wastani' : 'Standard',
          Icons.balance_rounded,
        );
    }
  }
}
