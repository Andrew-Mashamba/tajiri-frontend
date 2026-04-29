// lib/invoices/widgets/invoice_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../business/models/business_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final bool isSwahili;
  final VoidCallback? onTap;
  final VoidCallback? onSendTap;
  final VoidCallback? onMarkPaidTap;
  final VoidCallback? onEmailTap;

  const InvoiceCard({
    super.key,
    required this.invoice,
    this.isSwahili = false,
    this.onTap,
    this.onSendTap,
    this.onMarkPaidTap,
    this.onEmailTap,
  });

  Color _statusColor(InvoiceStatus s) {
    switch (s) {
      case InvoiceStatus.draft:
        return _kSecondary;
      case InvoiceStatus.sent:
        return Colors.blue.shade700;
      case InvoiceStatus.delivered:
        return Colors.blue.shade500;
      case InvoiceStatus.viewed:
        return Colors.indigo.shade600;
      case InvoiceStatus.partially_paid:
        return Colors.orange.shade700;
      case InvoiceStatus.paid:
        return Colors.green.shade700;
      case InvoiceStatus.overdue:
        return Colors.red.shade700;
      case InvoiceStatus.cancelled:
        return Colors.grey;
      case InvoiceStatus.credit_noted:
        return Colors.purple.shade600;
      case InvoiceStatus.void_status:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy');
    final overdue = isInvoiceOverdue(invoice);
    final overdueDays = invoiceOverdueDays(invoice);
    final hasPartialPayment =
        invoice.amountPaid > 0 && invoice.status != InvoiceStatus.paid;
    final balance = invoice.balanceRemaining;
    final showBalance = balance > 0 &&
        invoice.status != InvoiceStatus.paid &&
        invoice.status != InvoiceStatus.void_status &&
        invoice.status != InvoiceStatus.cancelled;

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
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      size: 20, color: _kPrimary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.invoiceNumber.isNotEmpty
                            ? invoice.invoiceNumber
                            : (isSwahili ? 'Ankara' : 'Invoice'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        invoice.customerName ??
                            (isSwahili ? 'Mteja' : 'Customer'),
                        style: const TextStyle(
                            fontSize: 12, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(invoice.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    invoiceStatusLabel(invoice.status, swahili: isSwahili),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(invoice.status),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Amount and date
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isSwahili ? 'Jumla' : 'Total',
                          style:
                              const TextStyle(fontSize: 11, color: _kSecondary)),
                      Text(
                        'TZS ${nf.format(invoice.totalAmount)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (invoice.vatAmount > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('VAT (18%)',
                            style:
                                TextStyle(fontSize: 11, color: _kSecondary)),
                        Text(
                          'TZS ${nf.format(invoice.vatAmount)}',
                          style: const TextStyle(
                              fontSize: 13, color: _kSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                if (invoice.dueDate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(isSwahili ? 'Tarehe ya Mwisho' : 'Due Date',
                          style:
                              const TextStyle(fontSize: 11, color: _kSecondary)),
                      Text(
                        df.format(invoice.dueDate!),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: overdue ? Colors.red.shade700 : _kPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
              ],
            ),

            // Payment progress bar
            if (hasPartialPayment) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (invoice.totalAmount > 0
                          ? invoice.amountPaid / invoice.totalAmount
                          : 0.0)
                      .clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'TZS ${nf.format(invoice.amountPaid)} / TZS ${nf.format(invoice.totalAmount)} '
                '(${invoice.totalAmount > 0 ? (invoice.amountPaid / invoice.totalAmount * 100).toStringAsFixed(0) : '0'}%)',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Balance remaining
            if (showBalance) ...[
              const SizedBox(height: 6),
              Text(
                isSwahili
                    ? 'Baki: TZS ${nf.format(balance)}'
                    : 'Balance: TZS ${nf.format(balance)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Overdue days indicator
            if (overdue && overdueDays > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 14, color: Colors.red.shade700),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      isSwahili
                          ? 'Imechelewa siku $overdueDays'
                          : 'Overdue $overdueDays days',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Items count
            if (invoice.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                isSwahili
                    ? '${invoice.items.length} bidhaa'
                    : '${invoice.items.length} item${invoice.items.length > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 12, color: _kSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Action buttons
            if (onSendTap != null ||
                onEmailTap != null ||
                onMarkPaidTap != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (invoice.status == InvoiceStatus.draft &&
                      onSendTap != null)
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton.icon(
                          onPressed: onSendTap,
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: Text(isSwahili ? 'Tuma' : 'Send',
                              style: const TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                  if (invoice.status == InvoiceStatus.draft &&
                      onSendTap != null)
                    const SizedBox(width: 8),
                  if (onEmailTap != null)
                    SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: onEmailTap,
                        icon: const Icon(Icons.email_rounded, size: 16),
                        label: const Text('Email',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimary,
                          side: const BorderSide(color: _kPrimary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  if (onEmailTap != null) const SizedBox(width: 8),
                  if (invoice.status != InvoiceStatus.paid &&
                      onMarkPaidTap != null)
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: OutlinedButton.icon(
                          onPressed: onMarkPaidTap,
                          icon: const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 16),
                          label: Text(isSwahili ? 'Imelipwa' : 'Paid',
                              style: const TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green.shade700,
                            side:
                                BorderSide(color: Colors.green.shade700),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
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
