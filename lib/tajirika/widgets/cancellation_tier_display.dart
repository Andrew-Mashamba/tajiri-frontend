import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';

/// Spec F6 #38 — Customer-side display of a partner's cancellation policy
/// tiers. Reads the JSONB column `partner_products.cancellation_policy_tiers`
/// of shape:
/// ```json
/// [
///   {"hours_before": 48, "refund_pct": 100},
///   {"hours_before": 24, "refund_pct": 50},
///   {"hours_before": 0, "refund_pct": 0}
/// ]
/// ```
/// Surfaces a tidy bilingual table on the booking sheet / detail page so
/// customers see what they're agreeing to before they pay.
class CancellationTierDisplay extends StatelessWidget {
  final List<dynamic> tiers;

  const CancellationTierDisplay({super.key, required this.tiers});

  @override
  Widget build(BuildContext context) {
    if (tiers.isEmpty) return const SizedBox.shrink();
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSw ? 'Sera ya kughairi' : 'Cancellation policy',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF666666),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          ...tiers.whereType<Map>().map((raw) {
            final tier = raw.cast<String, dynamic>();
            final hours = (tier['hours_before'] as num?)?.toInt() ?? 0;
            final pct = (tier['refund_pct'] as num?)?.toInt() ?? 0;
            final color = pct >= 75
                ? const Color(0xFF1B5E20)
                : (pct >= 25 ? const Color(0xFFE65100) : const Color(0xFFB00020));
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      _windowLabel(isSw, hours),
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF1A1A1A)),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isSw ? 'Marejesho $pct%' : '$pct% refund',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _windowLabel(bool sw, int hours) {
    if (hours <= 0) return sw ? 'Baada ya hapo' : 'After that';
    if (hours < 24) {
      return sw ? "Mpaka saa $hours kabla" : 'Up to $hours h before';
    }
    final days = (hours / 24).round();
    return sw ? "Mpaka siku $days kabla" : 'Up to $days d before';
  }
}
