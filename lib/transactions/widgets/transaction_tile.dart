// lib/transactions/widgets/transaction_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class TransactionTile extends StatelessWidget {
  final RecordedTransaction txn;
  final NumberFormat amountFormat;
  final bool swahili;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.txn,
    required this.amountFormat,
    this.swahili = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIn = txn.direction == 'incoming';
    final status = txn.status;
    Color statusColor = _kSecondary;
    if (status == 'pending') statusColor = Colors.orange.shade800;
    if (status == 'failed') statusColor = Colors.red.shade800;
    if (status == 'success') statusColor = Colors.green.shade800;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isIn ? Icons.south_west_rounded : Icons.north_east_rounded,
                  color: isIn ? Colors.green.shade700 : Colors.red.shade700,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      txn.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(txn.sortTime),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (txn.source == TransactionDataSource.composite)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          swahili
                              ? 'Muhtasari: ankara, matumizi, deni, maagizo'
                              : 'Summary: invoices, expenses, debts, POs',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIn ? '+' : '-'} ${txn.currency} ${amountFormat.format(txn.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isIn ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                    ),
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
