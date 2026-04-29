import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

/// Spec line 314 — composite KPI 0–100 with tier badge.
///   90+ Elite   75–89 Top Pro   60–74 Verified   <60 New
class PartnerKpiBadge extends StatelessWidget {
  final int? kpi;
  final int? response;
  final int? completion;
  final int? rating;
  final int? recency;
  const PartnerKpiBadge({
    super.key,
    required this.kpi,
    this.response,
    this.completion,
    this.rating,
    this.recency,
  });

  @override
  Widget build(BuildContext context) {
    if (kpi == null) return const SizedBox.shrink();
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final (bg, fg, label) = _classify(kpi!, isSw);
    return Tooltip(
      message: _tooltip(isSw),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, size: 11, color: fg),
            const SizedBox(width: 3),
            Text(
              'KPI $kpi',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: fg.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _tooltip(bool isSw) {
    final parts = <String>[];
    if (response != null) parts.add(isSw ? 'Jibu $response%' : 'Response $response%');
    if (completion != null) parts.add(isSw ? 'Kukamilisha $completion%' : 'Completion $completion%');
    if (rating != null) parts.add(isSw ? 'Ukadiriaji $rating%' : 'Rating $rating%');
    if (recency != null) parts.add(isSw ? 'Hivi karibuni $recency%' : 'Recency $recency%');
    return parts.join(' · ');
  }

  (Color, Color, String) _classify(int s, bool isSw) {
    if (s >= 90) {
      return (
        const Color(0xFFE8F5E9),
        const Color(0xFF1B5E20),
        isSw ? 'Elite' : 'Elite',
      );
    }
    if (s >= 75) {
      return (
        const Color(0xFFF1F8E9),
        const Color(0xFF558B2F),
        isSw ? 'Top Pro' : 'Top Pro',
      );
    }
    if (s >= 60) {
      return (
        const Color(0xFFE3F2FD),
        const Color(0xFF0D47A1),
        isSw ? 'Imethibitishwa' : 'Verified',
      );
    }
    return (
      const Color(0xFFFFF8E1),
      const Color(0xFFE65100),
      isSw ? 'Mpya' : 'New',
    );
  }

  static Color get fallbackPrimary => _kPrimary;
}
