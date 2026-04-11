// lib/car_insurance/widgets/policy_card.dart
import 'package:flutter/material.dart';
import '../models/car_insurance_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class PolicyCard extends StatelessWidget {
  final InsurancePolicy policy;
  final bool isSwahili;
  final VoidCallback? onTap;

  const PolicyCard({
    super.key,
    required this.policy,
    this.isSwahili = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = policy.isActive && !policy.isExpired
        ? const Color(0xFF4CAF50)
        : policy.isExpired
            ? Colors.red
            : Colors.orange;
    final statusLabel = policy.isExpired
        ? (isSwahili ? 'Imeisha' : 'Expired')
        : policy.isActive
            ? (isSwahili ? 'Hai' : 'Active')
            : (isSwahili ? 'Imesitishwa' : 'Cancelled');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: policy.providerLogo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(policy.providerLogo!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.shield_rounded,
                                size: 20,
                                color: _kPrimary)))
                    : const Icon(Icons.shield_rounded,
                        size: 20, color: _kPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(policy.providerName,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(policy.policyNumber,
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary)),
                    ]),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor)),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _info(Icons.directions_car_rounded, policy.vehicleDisplay),
              const SizedBox(width: 12),
              _info(Icons.calendar_today_rounded,
                  '${policy.endDate.day}/${policy.endDate.month}/${policy.endDate.year}'),
            ]),
            if (policy.plateNumber != null) ...[
              const SizedBox(height: 4),
              _info(Icons.confirmation_number_rounded, policy.plateNumber!),
            ],
            const SizedBox(height: 8),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      _coverageLabel(policy.coverageType),
                      style:
                          const TextStyle(fontSize: 11, color: _kSecondary)),
                  Text('TZS ${policy.premium.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary)),
                ]),
          ]),
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 14, color: _kSecondary),
      const SizedBox(width: 4),
      Text(text,
          style: const TextStyle(fontSize: 11, color: _kSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    ]);
  }

  String _coverageLabel(String type) {
    switch (type) {
      case 'tpo':
        return isSwahili ? 'Mtu wa Tatu' : 'Third Party Only';
      case 'tpft':
        return isSwahili ? 'Mtu wa Tatu + Moto' : 'TP Fire & Theft';
      case 'comprehensive':
        return isSwahili ? 'Kamili' : 'Comprehensive';
      default:
        return type;
    }
  }
}
