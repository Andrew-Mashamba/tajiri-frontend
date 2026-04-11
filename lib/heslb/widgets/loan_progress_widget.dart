// lib/heslb/widgets/loan_progress_widget.dart
import 'package:flutter/material.dart';
import '../models/heslb_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class LoanProgressWidget extends StatelessWidget {
  final LoanStatus loan;
  final bool isSwahili;

  const LoanProgressWidget({
    super.key,
    required this.loan,
    required this.isSwahili,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  loan.university,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: loan.repaymentProgress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(loan.repaymentProgress * 100).toStringAsFixed(1)}% ${isSwahili ? 'imelipwa' : 'repaid'}',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              _Stat(isSwahili ? 'Mkopo' : 'Total Loan',
                  'TZS ${_fmt(loan.totalLoan)}'),
              const SizedBox(width: 16),
              _Stat(isSwahili ? 'Imelipwa' : 'Repaid',
                  'TZS ${_fmt(loan.repaid)}'),
              const SizedBox(width: 16),
              _Stat(isSwahili ? 'Baki' : 'Outstanding',
                  'TZS ${_fmt(loan.outstanding)}'),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
        ],
      ),
    );
  }
}
