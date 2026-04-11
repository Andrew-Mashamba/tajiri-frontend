// lib/ambulance/widgets/insurance_card_widget.dart
import 'package:flutter/material.dart';
import '../models/ambulance_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kGreen = Color(0xFF2E7D32);

class InsuranceCardWidget extends StatelessWidget {
  final InsuranceInfo insurance;
  final bool isSwahili;

  const InsuranceCardWidget({
    super.key,
    required this.insurance,
    this.isSwahili = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_rounded,
                    color: Color(0xFF1565C0), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insurance.provider,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      insurance.coverageType ?? (isSwahili ? 'Kawaida' : 'Standard'),
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (insurance.isVerified)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded,
                          size: 14, color: _kGreen),
                      const SizedBox(width: 4),
                      Text(
                        isSwahili ? 'Imethibitishwa' : 'Verified',
                        style: const TextStyle(
                            fontSize: 11,
                            color: _kGreen,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSwahili ? 'Nambari ya Sera' : 'Policy Number',
                      style:
                          const TextStyle(fontSize: 11, color: _kSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      insurance.policyNumber,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (insurance.memberId != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSwahili ? 'Nambari ya Mwanachama' : 'Member ID',
                        style:
                            const TextStyle(fontSize: 11, color: _kSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        insurance.memberId!,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _kPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (insurance.expiryDate != null) ...[
            const SizedBox(height: 8),
            Text(
              '${isSwahili ? 'Inaisha' : 'Expires'}: ${insurance.expiryDate!.day}/${insurance.expiryDate!.month}/${insurance.expiryDate!.year}',
              style: const TextStyle(fontSize: 12, color: _kSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
