// lib/dawasco/widgets/account_card.dart
import 'package:flutter/material.dart';
import '../models/dawasco_models.dart';
import 'supply_status_indicator.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class DawascoAccountCard extends StatelessWidget {
  final WaterAccount account;
  final SupplyStatus? supplyStatus;
  final VoidCallback? onPay;
  final bool isSwahili;
  const DawascoAccountCard({super.key, required this.account, this.supplyStatus,
    this.onPay, this.isSwahili = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.water_drop_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Text('DAWASCO', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2)),
          const Spacer(),
          if (supplyStatus != null)
            SupplyStatusIndicator(isAvailable: supplyStatus!.isAvailable, isSwahili: isSwahili),
        ]),
        const SizedBox(height: 12),
        Text(account.accountNumber,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        if (account.meterNumber != null)
          Text('${isSwahili ? 'Mita' : 'Meter'}: ${account.meterNumber}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isSwahili ? 'Salio' : 'Balance',
                style: const TextStyle(color: Colors.white54, fontSize: 10)),
            Text('TZS ${account.balance.toStringAsFixed(0)}',
                style: TextStyle(color: account.balance > 0 ? Colors.orange : Colors.white,
                    fontSize: 18, fontWeight: FontWeight.w700)),
          ]),
          const Spacer(),
          if (onPay != null && account.balance > 0)
            GestureDetector(
              onTap: onPay,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Text(isSwahili ? 'Lipa' : 'Pay',
                    style: const TextStyle(color: _kPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
        ]),
      ]),
    );
  }
}
