// lib/dawasco/widgets/bill_card.dart
import 'package:flutter/material.dart';
import '../models/dawasco_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kGreen = Color(0xFF4CAF50);

class BillCardWidget extends StatelessWidget {
  final WaterBill bill;
  final VoidCallback? onTap;
  final bool isSwahili;
  const BillCardWidget({super.key, required this.bill, this.onTap, this.isSwahili = false});

  @override
  Widget build(BuildContext context) {
    final statusLabel = bill.isPaid
        ? (isSwahili ? 'Imelipwa' : 'Paid')
        : bill.isOverdue
            ? (isSwahili ? 'Imechelewa' : 'Overdue')
            : (isSwahili ? 'Haijalipwa' : 'Unpaid');
    final statusColor = bill.isPaid ? _kGreen : Colors.red;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: bill.isPaid ? _kGreen.withValues(alpha: 0.12) : _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(bill.isPaid ? Icons.check_circle_rounded : Icons.receipt_rounded,
                  size: 22, color: bill.isPaid ? _kGreen : _kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(bill.billingPeriod,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${bill.consumption.toStringAsFixed(1)} m\u00B3',
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('TZS ${bill.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(statusLabel,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
