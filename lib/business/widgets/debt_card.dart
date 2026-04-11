// lib/business/widgets/debt_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/business_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class DebtCard extends StatelessWidget {
  final Debt debt;
  final VoidCallback? onTap;
  final VoidCallback? onPayTap;
  final VoidCallback? onRemindTap;

  const DebtCard({
    super.key,
    required this.debt,
    this.onTap,
    this.onPayTap,
    this.onRemindTap,
  });

  Color _statusColor(DebtStatus s) {
    switch (s) {
      case DebtStatus.paid:
        return Colors.green.shade700;
      case DebtStatus.overdue:
        return Colors.red.shade700;
      case DebtStatus.partial:
        return Colors.orange.shade700;
      case DebtStatus.pending:
        return _kSecondary;
    }
  }

  IconData _statusIcon(DebtStatus s) {
    switch (s) {
      case DebtStatus.paid:
        return Icons.check_circle_rounded;
      case DebtStatus.overdue:
        return Icons.error_rounded;
      case DebtStatus.partial:
        return Icons.timelapse_rounded;
      case DebtStatus.pending:
        return Icons.schedule_rounded;
    }
  }

  String _statusLabel(DebtStatus s) {
    switch (s) {
      case DebtStatus.paid:
        return 'Paid';
      case DebtStatus.overdue:
        return 'Overdue';
      case DebtStatus.partial:
        return 'Partial';
      case DebtStatus.pending:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy');
    final remaining = debt.remainingAmount;
    final progress = debt.amount > 0 ? debt.paidAmount / debt.amount : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: customer + status
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _kPrimary.withValues(alpha: 0.08),
                  child: Text(
                    (debt.customerName ?? '?')[0].toUpperCase(),
                    style: const TextStyle(
                        color: _kPrimary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.customerName ?? 'Customer',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (debt.customerPhone != null)
                        Text(
                          debt.customerPhone!,
                          style: const TextStyle(
                              fontSize: 12, color: _kSecondary),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(debt.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(debt.status),
                          size: 14, color: _statusColor(debt.status)),
                      const SizedBox(width: 4),
                      Text(
                        _statusLabel(debt.status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(debt.status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            if (debt.description != null && debt.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  debt.description!,
                  style: const TextStyle(fontSize: 13, color: _kSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Amount info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Amount',
                          style:
                              TextStyle(fontSize: 11, color: _kSecondary)),
                      Text(
                        'TZS ${nf.format(debt.amount)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Balance',
                          style:
                              TextStyle(fontSize: 11, color: _kSecondary)),
                      Text(
                        'TZS ${nf.format(remaining)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: remaining > 0
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (debt.dueDate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Due',
                          style:
                              TextStyle(fontSize: 11, color: _kSecondary)),
                      Text(
                        df.format(debt.dueDate!),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: debt.dueDate!.isBefore(DateTime.now()) &&
                                  debt.status != DebtStatus.paid
                              ? Colors.red.shade700
                              : _kPrimary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Progress bar for partial payments
            if (debt.status == DebtStatus.partial ||
                (debt.paidAmount > 0 &&
                    debt.status != DebtStatus.paid)) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.green.shade600),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Paid TZS ${nf.format(debt.paidAmount)} / ${nf.format(debt.amount)}',
                style:
                    const TextStyle(fontSize: 11, color: _kSecondary),
              ),
            ],

            // Action buttons
            if (debt.status != DebtStatus.paid) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: onPayTap,
                        icon: const Icon(Icons.payment_rounded,
                            size: 16),
                        label: const Text('Record Payment',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimary,
                          side: const BorderSide(color: _kPrimary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      onPressed: onRemindTap,
                      icon: const Icon(
                          Icons.notifications_active_rounded,
                          size: 16),
                      label: const Text('Remind',
                          style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kSecondary,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
