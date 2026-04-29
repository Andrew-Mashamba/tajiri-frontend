import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);

/// Spec line 1031 — migration-season pricing overlay on safari listings.
/// Reads `partner_skill_personas.migration_pricing` JSON map keyed by month
/// number → tier ('peak'|'shoulder'|'low'). Renders a compact 12-month
/// horizontal calendar where each cell is colored by tier.
class MigrationSeasonCalendar extends StatelessWidget {
  /// Map of `{ "1": "low", "7": "peak", … }` — string keys 1-12.
  final Map<String, dynamic> pricingByMonth;
  /// Optional per-tier price band override `{ "peak": 3500000, "shoulder": 2500000, "low": 1800000 }`.
  final Map<String, dynamic>? bandsByTier;
  const MigrationSeasonCalendar({
    super.key,
    required this.pricingByMonth,
    this.bandsByTier,
  });

  @override
  Widget build(BuildContext context) {
    if (pricingByMonth.isEmpty) return const SizedBox.shrink();
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  size: 14, color: _kPrimary),
              const SizedBox(width: 6),
              Text(
                isSw ? 'Bei kwa msimu' : 'Seasonal pricing',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(12, (i) {
                final month = i + 1;
                final tier = pricingByMonth['$month']?.toString() ?? 'shoulder';
                return _monthCell(month, tier);
              }),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _legendDot('peak', isSw ? 'Juu' : 'Peak'),
              _legendDot('shoulder', isSw ? 'Wastani' : 'Shoulder'),
              _legendDot('low', isSw ? 'Chini' : 'Low'),
            ],
          ),
          if (bandsByTier != null && bandsByTier!.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...bandsByTier!.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    _tierDot(e.key.toString()),
                    const SizedBox(width: 4),
                    Text(
                      _tierLabel(e.key.toString(), isSw),
                      style: const TextStyle(
                          fontSize: 11, color: _kSecondary),
                    ),
                    const Spacer(),
                    Text(
                      'TZS ${NumberFormat('#,##0').format(e.value)}',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _monthCell(int m, String tier) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: _tierColor(tier).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          _monthShort(m),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: _tierColor(tier),
          ),
        ),
      ),
    );
  }

  Widget _legendDot(String tier, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _tierDot(tier),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, color: _kSecondary)),
      ],
    );
  }

  Widget _tierDot(String tier) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: _tierColor(tier),
        shape: BoxShape.circle,
      ),
    );
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'peak':
        return const Color(0xFFB71C1C);
      case 'low':
        return const Color(0xFF1B5E20);
      default:
        return const Color(0xFFE65100);
    }
  }

  String _tierLabel(String tier, bool isSw) {
    switch (tier) {
      case 'peak':
        return isSw ? 'Juu' : 'Peak';
      case 'low':
        return isSw ? 'Chini' : 'Low';
      default:
        return isSw ? 'Wastani' : 'Shoulder';
    }
  }

  String _monthShort(int m) {
    const months = [
      'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D',
    ];
    return months[(m - 1).clamp(0, 11)];
  }
}
