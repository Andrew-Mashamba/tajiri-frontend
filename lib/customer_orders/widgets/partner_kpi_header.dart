import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/wave_i_services.dart';

/// Spec F3 — KPI score header on partner inbox (response 40 / completion 30 /
/// rating 20 / recency 10) + tier badge.
class PartnerKpiHeader extends StatefulWidget {
  final int partnerUserId;
  const PartnerKpiHeader({super.key, required this.partnerUserId});

  @override
  State<PartnerKpiHeader> createState() => _PartnerKpiHeaderState();
}

class _PartnerKpiHeaderState extends State<PartnerKpiHeader> {
  Map<String, dynamic>? _kpi;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await PartnerKpiService.show(widget.partnerUserId);
    if (mounted) setState(() => _kpi = res);
  }

  @override
  Widget build(BuildContext context) {
    final k = _kpi;
    if (k == null) return const SizedBox.shrink();
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final score = (k['kpi_score'] as num?)?.toInt() ?? 0;
    final tier = k['tier']?.toString() ?? '';
    Color accent = const Color(0xFFB71C1C);
    if (score >= 70) {
      accent = const Color(0xFF1B5E20);
    } else if (score >= 50) {
      accent = const Color(0xFFE65100);
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_rounded, size: 16, color: accent),
          const SizedBox(width: 6),
          Text(
            isSw ? 'KPI: $score/100' : 'KPI: $score/100',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tier,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
