// lib/insurance/widgets/policy_card.dart
import 'package:flutter/material.dart';
import '../models/insurance_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class PolicyCard extends StatelessWidget {
  final InsurancePolicy policy;
  final VoidCallback? onTap;

  const PolicyCard({super.key, required this.policy, this.onTap});

  String _fmt(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  String _fmtDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: policy.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(policy.category.icon, size: 20, color: policy.status.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(policy.productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(policy.providerName, style: const TextStyle(fontSize: 12, color: _kSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: policy.status.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(policy.status.displayName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: policy.status.color)),
                      ),
                      if (policy.isExpiringSoon)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Siku ${policy.daysRemaining} zimebaki', style: TextStyle(fontSize: 10, color: Colors.orange.shade700)),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Detail(label: 'Bima', value: 'TZS ${_fmt(policy.coverLimit)}'),
                  const SizedBox(width: 16),
                  _Detail(label: 'Malipo', value: 'TZS ${_fmt(policy.premiumAmount)}/${policy.premiumFrequency == 'monthly' ? 'mwezi' : 'mwaka'}'),
                  const SizedBox(width: 16),
                  _Detail(label: 'Hadi', value: _fmtDate(policy.endDate)),
                ],
              ),
              if (policy.policyNumber.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Namba: ${policy.policyNumber}', style: const TextStyle(fontSize: 11, color: _kSecondary)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final String label;
  final String value;
  const _Detail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: _kSecondary)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
      ],
    );
  }
}
