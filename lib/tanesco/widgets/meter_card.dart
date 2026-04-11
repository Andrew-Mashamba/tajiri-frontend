// lib/tanesco/widgets/meter_card.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tanesco_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class MeterCardWidget extends StatelessWidget {
  final Meter meter;
  final VoidCallback? onBuy;
  final VoidCallback? onCheckBalance;
  final VoidCallback? onTap;
  const MeterCardWidget({super.key, required this.meter, this.onBuy, this.onCheckBalance, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.electric_bolt_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(meter.alias ?? meter.type.toUpperCase(),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (meter.autoRechargeEnabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.autorenew_rounded, size: 10, color: Color(0xFF81C784)),
                  SizedBox(width: 2),
                  Text('Auto', style: TextStyle(fontSize: 8, color: Color(0xFF81C784), fontWeight: FontWeight.w600)),
                ]),
              ),
            const SizedBox(width: 6),
            Text(meter.type == 'prepaid' ? 'LUKU' : 'Postpaid',
                style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ]),
          const SizedBox(height: 8),
          Text(meter.meterNumber, style: const TextStyle(color: Colors.white, fontSize: 16,
              fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${meter.balance.toStringAsFixed(1)} kWh',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                if (meter.isLowBalance)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.warning_amber_rounded, size: 10, color: Colors.orangeAccent),
                      const SizedBox(width: 3),
                      Text((AppStringsScope.of(context)?.isSwahili ?? false) ? 'Salio la chini' : 'Low balance',
                          style: const TextStyle(fontSize: 9, color: Colors.orangeAccent, fontWeight: FontWeight.w500)),
                    ]),
                  ),
              ]),
            ),
            if (onCheckBalance != null)
              GestureDetector(
                onTap: onCheckBalance,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white70),
                ),
              ),
            if (onBuy != null)
              GestureDetector(onTap: onBuy,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: Text((AppStringsScope.of(context)?.isSwahili ?? false) ? 'Nunua' : 'Buy',
                      style: const TextStyle(color: _kPrimary, fontSize: 12, fontWeight: FontWeight.w600)))),
          ]),
        ])),
    );
  }
}
