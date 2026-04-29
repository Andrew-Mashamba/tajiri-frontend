// lib/payroll/widgets/tax_summary_widget.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class TaxSummaryWidget extends StatelessWidget {
  const TaxSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Viwango vya PAYE (Tanzania)' : 'PAYE Tax Brackets (Tanzania)',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kPrimary),
          ),
          const SizedBox(height: 8),
          _row('0 – 270,000', '0%'),
          _row('270,001 – 520,000', '8%'),
          _row('520,001 – 760,000', '20%'),
          _row('760,001 – 1,000,000', '25%'),
          _row(sw ? 'Zaidi ya 1,000,000' : 'Above 1,000,000', '30%'),
          const SizedBox(height: 8),
          Text(
            sw
                ? 'NSSF: Mwajiri 10% + Mfanyakazi 10% | SDL: 3.5% | WCF: 0.5%'
                : 'NSSF: Employer 10% + Employee 10% | SDL: 3.5% | WCF: 0.5%',
            style: TextStyle(
                fontSize: 10, color: _kSecondary.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _row(String range, String rate) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('TZS $range',
              style: const TextStyle(fontSize: 11, color: _kSecondary)),
          Text(rate,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
        ],
      ),
    );
  }
}
