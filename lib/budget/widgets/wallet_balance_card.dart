import 'package:flutter/material.dart';

/// Dark hero card showing wallet balance (read-only in budget context).
/// Money movement (Top Up / Withdraw) lives in Tajiri Pay (wallet module).
/// Optionally displays a streak badge in the top-right corner.
class WalletBalanceCard extends StatelessWidget {
  final double balance;
  final bool isSwahili;
  final int? streakDays;

  const WalletBalanceCard({
    super.key,
    required this.balance,
    this.isSwahili = false,
    this.streakDays,
  });

  static const Color _kPrimary = Color(0xFF1A1A1A);

  String _formatTZSFull(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (var i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(parts[i]);
    }
    return 'TZS $buffer';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _kPrimary,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSwahili ? 'Salio la Pochi' : 'Wallet Balance',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTZSFull(balance),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Streak badge
          if (streakDays != null && streakDays! > 0)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isSwahili
                      ? '\u{1F525} Siku $streakDays'
                      : '\u{1F525} $streakDays days',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
