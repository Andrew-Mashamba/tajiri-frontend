// lib/my_wallet/widgets/balance_card.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/wallet_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class BalanceCard extends StatefulWidget {
  final Wallet wallet;
  final VoidCallback? onTapDetails;

  const BalanceCard({
    super.key,
    required this.wallet,
    this.onTapDetails,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _isHidden = false;

  String _formatFullAmount(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSwahili ? 'Pochi Yangu' : 'My Wallet',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _isHidden = !_isHidden),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    _isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.white60,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main balance
          Text(
            _isHidden
                ? 'TZS ****'
                : 'TZS ${_formatFullAmount(widget.wallet.balance)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Pending + Ad balance row
          Row(
            children: [
              if (widget.wallet.pendingBalance > 0) ...[
                _BalanceChip(
                  label: isSwahili ? 'Inasubiri' : 'Pending',
                  amount: _isHidden
                      ? '****'
                      : 'TZS ${_formatFullAmount(widget.wallet.pendingBalance)}',
                  icon: Icons.hourglass_empty_rounded,
                ),
                const SizedBox(width: 12),
              ],
              if (widget.wallet.adBalance > 0)
                _BalanceChip(
                  label: isSwahili ? 'Matangazo' : 'Ads',
                  amount: _isHidden
                      ? '****'
                      : 'TZS ${_formatFullAmount(widget.wallet.adBalance)}',
                  icon: Icons.ads_click_rounded,
                ),
              const Spacer(),
              if (widget.onTapDetails != null)
                GestureDetector(
                  onTap: widget.onTapDetails,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isSwahili ? 'Historia' : 'History',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 16),
                      ],
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

class _BalanceChip extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;

  const _BalanceChip({
    required this.label,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white54, size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
