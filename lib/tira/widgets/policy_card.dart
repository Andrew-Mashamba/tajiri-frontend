// lib/tira/widgets/policy_card.dart
import 'package:flutter/material.dart';
import '../models/tira_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class PolicyCard extends StatelessWidget {
  final InsurancePolicy policy;
  final bool isSwahili;

  const PolicyCard({
    super.key,
    required this.policy,
    required this.isSwahili,
  });

  Color get _statusColor {
    switch (policy.status) {
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(policy.insurerName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  policy.status.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow(
              isSwahili ? 'Namba ya Bima' : 'Policy No.', policy.policyNumber),
          _InfoRow(isSwahili ? 'Aina' : 'Type',
              policy.type[0].toUpperCase() + policy.type.substring(1)),
          _InfoRow(isSwahili ? 'Ada' : 'Premium',
              'TZS ${policy.premium.toStringAsFixed(0)}'),
          _InfoRow(
              isSwahili ? 'Inaisha' : 'Expires',
              policy.endDate.toString().substring(0, 10)),
          if (policy.status == 'active' && policy.daysRemaining <= 30)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isSwahili
                      ? 'Inaisha siku ${policy.daysRemaining}'
                      : 'Expires in ${policy.daysRemaining} days',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.orange),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: _kSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12, color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
