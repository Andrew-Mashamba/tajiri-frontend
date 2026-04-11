// lib/insurance/widgets/claim_card.dart
import 'package:flutter/material.dart';
import '../models/insurance_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class ClaimCard extends StatelessWidget {
  final InsuranceClaim claim;
  final VoidCallback? onTap;

  const ClaimCard({super.key, required this.claim, this.onTap});

  String _fmt(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: claim.status.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.receipt_long_rounded, size: 20, color: claim.status.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(claim.productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                    Text(claim.reason, style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(claim.claimNumber, style: const TextStyle(fontSize: 11, color: _kSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TZS ${_fmt(claim.claimAmount)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: claim.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(claim.status.displayName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: claim.status.color)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
