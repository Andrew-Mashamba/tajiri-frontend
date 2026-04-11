// lib/my_wallet/widgets/transaction_tile.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/wallet_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class TransactionTile extends StatelessWidget {
  final WalletTransaction transaction;

  const TransactionTile({super.key, required this.transaction});

  IconData get _icon {
    switch (transaction.type) {
      case 'deposit':
        return Icons.arrow_downward_rounded;
      case 'withdrawal':
        return Icons.arrow_upward_rounded;
      case 'transfer_in':
        return Icons.call_received_rounded;
      case 'transfer_out':
        return Icons.call_made_rounded;
      case 'payment':
        return Icons.shopping_bag_rounded;
      case 'refund':
        return Icons.replay_rounded;
      default:
        return Icons.swap_horiz_rounded;
    }
  }

  Color get _iconBgColor {
    if (transaction.isCredit) return const Color(0xFF4CAF50).withValues(alpha: 0.1);
    return Colors.red.withValues(alpha: 0.1);
  }

  Color get _iconColor {
    if (transaction.isCredit) return const Color(0xFF4CAF50);
    return Colors.red;
  }

  Color get _amountColor {
    if (transaction.isCredit) return const Color(0xFF4CAF50);
    return _kPrimary;
  }

  String get _amountPrefix => transaction.isCredit ? '+' : '-';

  String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  String _formatDate(DateTime date, bool isSwahili) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return isSwahili ? 'Leo' : 'Today';
    if (diff.inDays == 1) return isSwahili ? 'Jana' : 'Yesterday';
    if (diff.inDays < 7) return isSwahili ? '${diff.inDays} siku zilizopita' : '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: _iconColor, size: 22),
          ),
          const SizedBox(width: 12),

          // Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.typeName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.description ?? _formatDate(transaction.createdAt, isSwahili),
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_amountPrefix TZS ${_formatAmount(transaction.amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _amountColor,
                ),
              ),
              if (transaction.status != 'completed')
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: transaction.status == 'pending'
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    transaction.status == 'pending'
                        ? (isSwahili ? 'Inasubiri' : 'Pending')
                        : (isSwahili ? 'Imeshindwa' : 'Failed'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: transaction.status == 'pending'
                          ? Colors.orange.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
