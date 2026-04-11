// lib/tanesco/widgets/bill_card.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tanesco_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class BillCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback? onPay;
  final VoidCallback? onDispute;

  const BillCard({super.key, required this.bill, this.onPay, this.onDispute});

  Color _statusColor() {
    if (bill.isPaid) return const Color(0xFF4CAF50);
    if (bill.isOverdue) return Colors.red;
    return _kSecondary;
  }

  String _statusLabel(bool isSwahili) {
    if (bill.isPaid) return isSwahili ? 'Imelipwa' : 'Paid';
    if (bill.isOverdue) return isSwahili ? 'Imechelewa' : 'Overdue';
    return isSwahili ? 'Haijalipwa' : 'Unpaid';
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      padding: const EdgeInsets.all(14),
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
                child: Text(bill.billingPeriod,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_statusLabel(isSwahili),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor())),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoCol(label: 'kWh', value: bill.consumption.toStringAsFixed(0)),
              const SizedBox(width: 20),
              _InfoCol(label: 'TZS', value: _formatAmount(bill.amount)),
              const SizedBox(width: 20),
              _InfoCol(label: isSwahili ? 'Mwisho' : 'Due',
                  value: '${bill.dueDate.day}/${bill.dueDate.month}/${bill.dueDate.year}'),
            ],
          ),
          if (!bill.isPaid) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onDispute != null)
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: onDispute,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kSecondary,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(isSwahili ? 'Ping\'amisha' : 'Dispute',
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ),
                if (onDispute != null) const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: onPay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(isSwahili ? 'Lipa' : 'Pay',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatAmount(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

class _InfoCol extends StatelessWidget {
  final String label; final String value;
  const _InfoCol({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 10, color: _kSecondary)),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis),
    ],
  );
}
