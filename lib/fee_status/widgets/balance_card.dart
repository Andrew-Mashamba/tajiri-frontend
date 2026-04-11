// lib/fee_status/widgets/balance_card.dart
import 'package:flutter/material.dart';
import '../models/fee_status_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class BalanceCard extends StatelessWidget {
  final FeeBalance balance;
  const BalanceCard({super.key, required this.balance});

  String _fmt(double v) => 'TZS ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
          SizedBox(width: 10),
          Text('Ada', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        Text('Deni / Balance', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
        Text(_fmt(balance.balance), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        // Progress
        LinearProgressIndicator(
          value: balance.paidPercent.clamp(0, 1).toDouble(),
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          color: Colors.white,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Uliolipa: ${_fmt(balance.totalPaid)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
          Text('Jumla: ${_fmt(balance.totalFees)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
        ]),
        if (balance.nextDeadline != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.timer_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text('${balance.deadlineLabel ?? 'Deadline'}: ${balance.nextDeadline!.day}/${balance.nextDeadline!.month}/${balance.nextDeadline!.year}',
                  style: const TextStyle(fontSize: 11, color: Colors.white)),
            ]),
          ),
        ],
      ]),
    );
  }
}
