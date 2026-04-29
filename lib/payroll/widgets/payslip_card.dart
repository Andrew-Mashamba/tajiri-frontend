// lib/payroll/widgets/payslip_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payroll_models.dart';
import '../pages/payslip_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCard = Color(0xFFFFFFFF);

class PayslipCard extends StatelessWidget {
  final PayrollEntry entry;
  final int month;
  final int year;
  final String token;
  final String businessName;

  const PayslipCard({
    super.key,
    required this.entry,
    required this.month,
    required this.year,
    required this.token,
    this.businessName = '',
  });

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'en');
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PayslipPage(
            entry: entry,
            month: month,
            year: year,
            businessName: businessName,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _kPrimary.withValues(alpha: 0.08),
              child: Text(
                entry.employeeName.isNotEmpty
                    ? entry.employeeName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: _kPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.employeeName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Gross: TZS ${nf.format(entry.grossSalary)}',
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'TZS ${nf.format(entry.netSalary)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _kPrimary,
                      fontSize: 14),
                ),
                Text(
                  'PAYE: ${nf.format(entry.paye)}',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: _kSecondary),
          ],
        ),
      ),
    );
  }
}
