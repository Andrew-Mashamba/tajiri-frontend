// lib/loans/widgets/loan_tier_card.dart
import 'package:flutter/material.dart';
import '../models/loan_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class LoanTierCard extends StatelessWidget {
  final LoanTier tier;
  final bool isEligible;
  final double? maxEligibleAmount;
  final VoidCallback? onApply;

  const LoanTierCard({
    super.key,
    required this.tier,
    required this.isEligible,
    this.maxEligibleAmount,
    this.onApply,
  });

  String _fmt(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: isEligible
            ? Border.all(color: tier.color.withValues(alpha: 0.3), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isEligible ? tier.color : _kSecondary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tier.icon, size: 24, color: isEligible ? tier.color : _kSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tier.displayName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: isEligible ? _kPrimary : _kSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tier.subtitle,
                          style: TextStyle(fontSize: 12, color: isEligible ? tier.color : _kSecondary),
                        ),
                      ],
                    ),
                    Text(
                      'TZS ${_fmt(tier.minAmount)} – ${_fmt(tier.maxAmount)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isEligible ? _kPrimary : _kSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isEligible)
                const Icon(Icons.lock_outline_rounded, color: _kSecondary, size: 20),
            ],
          ),
          const SizedBox(height: 14),
          // Details grid
          Row(
            children: [
              _DetailChip(label: 'Ada', value: '${tier.feePercent.toStringAsFixed(0)}%'),
              const SizedBox(width: 8),
              _DetailChip(label: 'Makato', value: '${tier.repaymentPercent.toStringAsFixed(0)}%'),
              const SizedBox(width: 8),
              _DetailChip(label: 'Muda', value: '${tier.termDays} siku'),
              const SizedBox(width: 8),
              _DetailChip(label: 'Alama', value: '${tier.minScore}+'),
            ],
          ),
          if (!isEligible) ...[
            const SizedBox(height: 10),
            Text(
              'Unahitaji: Alama ${tier.minScore}+, miezi ${tier.minTenureMonths}+ kwenye jukwaa',
              style: const TextStyle(fontSize: 11, color: _kSecondary),
            ),
          ],
          if (isEligible && onApply != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: onApply,
                style: FilledButton.styleFrom(
                  backgroundColor: tier.color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  maxEligibleAmount != null
                      ? 'Omba hadi TZS ${_fmt(maxEligibleAmount!)}'
                      : 'Omba Mkopo',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;
  const _DetailChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: _kPrimary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: _kSecondary)),
          ],
        ),
      ),
    );
  }
}
