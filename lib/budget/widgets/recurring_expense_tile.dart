import 'package:flutter/material.dart';
import '../models/budget_models.dart';

/// Recurring expense row with description, amount, frequency, next date,
/// and confirm/dismiss actions.
class RecurringExpenseTile extends StatelessWidget {
  final RecurringExpense expense;
  final bool isSwahili;
  final VoidCallback? onConfirm;
  final VoidCallback? onDismiss;

  const RecurringExpenseTile({
    super.key,
    required this.expense,
    this.isSwahili = false,
    this.onConfirm,
    this.onDismiss,
  });

  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);
  static const Color _kError = Color(0xFFE53935);

  String _formatTZS(double amount) {
    if (amount >= 1000000) {
      return 'TZS ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return 'TZS ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return 'TZS ${amount.toStringAsFixed(0)}';
  }

  String get _frequencyLabel {
    switch (expense.frequency) {
      case 'weekly':
        return isSwahili ? 'Kila wiki' : 'Weekly';
      case 'yearly':
        return isSwahili ? 'Kila mwaka' : 'Yearly';
      default:
        return isSwahili ? 'Kila mwezi' : 'Monthly';
    }
  }

  String? get _nextDateLabel {
    final next = expense.nextExpected;
    if (next == null) return null;
    final day = next.day.toString().padLeft(2, '0');
    final month = next.month.toString().padLeft(2, '0');
    return '$day/$month/${next.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kError.withValues(alpha:0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.repeat_rounded,
              color: _kError.withValues(alpha:0.7),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      _formatTZS(expense.amount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _kSecondary.withValues(alpha:0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _frequencyLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (_nextDateLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    isSwahili
                        ? 'Inayofuata: $_nextDateLabel'
                        : 'Next: $_nextDateLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _kSecondary.withValues(alpha:0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
                // Confirm/dismiss buttons for unconfirmed expenses
                if (!expense.isConfirmed) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        height: 48,
                        child: TextButton.icon(
                          onPressed: onConfirm,
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: Text(
                            isSwahili ? 'Thibitisha' : 'Confirm',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: _kPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        height: 48,
                        child: TextButton.icon(
                          onPressed: onDismiss,
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: Text(
                            isSwahili ? 'Ondoa' : 'Dismiss',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: _kSecondary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
