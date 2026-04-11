// lib/loans/widgets/active_loan_card.dart
import 'package:flutter/material.dart';
import '../models/loan_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class ActiveLoanCard extends StatelessWidget {
  final BoostLoan loan;
  final VoidCallback? onTap;

  const ActiveLoanCard({super.key, required this.loan, this.onTap});

  String _fmt(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: loan.tier.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(loan.tier.icon, size: 22, color: loan.tier.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TAJIRI Boost — ${loan.tier.displayName}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                        ),
                        Text(
                          loan.loanId,
                          style: const TextStyle(fontSize: 11, color: _kSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: loan.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      loan.status.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: loan.status.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (loan.repaidPercent / 100).clamp(0.0, 1.0),
                  backgroundColor: _kPrimary.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(loan.tier.color),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),

              // Amount details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Umelipa: TZS ${_fmt(loan.amountRepaid)}',
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                  ),
                  Text(
                    '${loan.repaidPercent.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: loan.tier.color),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Jumla: TZS ${_fmt(loan.totalRepayable)}',
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                  ),
                  Text(
                    'Baki: TZS ${_fmt(loan.remainingAmount)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
                  ),
                ],
              ),

              if (loan.dueDate != null && loan.daysToMaturity > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Siku ${loan.daysToMaturity} hadi mwisho',
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                ),
              ],

              if (loan.graceDaysRemaining != null && loan.graceDaysRemaining! > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Siku ${loan.graceDaysRemaining} za neema zimebaki',
                    style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
