// lib/creator/widgets/fund_period_card.dart
//
// Reusable tier badge + Phase-1 fund period card for any creator
// surface (report, legacy dashboard). Promoted from private classes
// in `creator_earnings_dashboard_screen.dart` so the new
// `CreatorRevenueReportScreen` can render the same context.

import 'package:flutter/material.dart';

import '../models/creator_earnings_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kSurface = Colors.white;

class EarningsTierBadge extends StatelessWidget {
  final String tier;
  final bool isMwanzoActive;
  final String? mwanzoExpiresAt;
  final bool isSw;

  const EarningsTierBadge({
    super.key,
    required this.tier,
    required this.isMwanzoActive,
    this.mwanzoExpiresAt,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    final tierLabel = {
          'mwanzo': isSw ? 'Mwanzo' : 'Starter',
          'standard': isSw ? 'Kawaida' : 'Standard',
          'verified': isSw ? 'Iliyothibitishwa' : 'Verified',
          'partner': isSw ? 'Mshirika' : 'Partner',
        }[tier] ??
        tier;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            tierLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isMwanzoActive) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isSw
                  ? '2× Nguvu hai · inaisha hivi karibuni'
                  : '2× Mwanzo Boost active',
              style: const TextStyle(fontSize: 12, color: _kSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class FundPeriodCard extends StatelessWidget {
  final FundPeriodSummary period;
  final bool isSw;

  const FundPeriodCard({
    super.key,
    required this.period,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    final fundStr = period.fundSizeTsh >= 1000000
        ? 'TZS ${(period.fundSizeTsh / 1000000).toStringAsFixed(0)}M'
        : 'TZS ${period.fundSizeTsh.toStringAsFixed(0)}';

    final estimatedStr = period.fundPerPoint != null
        ? 'TZS ${(period.yourPoints * period.fundPerPoint!).toStringAsFixed(0)}'
        : '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSw ? 'Kipindi hiki cha mfuko' : 'This fund period',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kTertiary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InfoPill(
                    label: isSw ? 'Mfuko' : 'Fund', value: fundStr),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoPill(
                    label: isSw ? 'Pointi zako' : 'Your points',
                    value: period.yourPoints.toStringAsFixed(1)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoPill(
                    label: isSw ? 'Kadiriwa' : 'Est.',
                    value: estimatedStr),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isSw
                ? 'Makadirio yanasettlika Jumatatu usiku wa manane.'
                : 'Estimates settle Monday at midnight.',
            style: const TextStyle(
              fontSize: 11,
              color: _kTertiary,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  const _InfoPill({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: _kTertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}
