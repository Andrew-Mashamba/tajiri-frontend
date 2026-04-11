// lib/dawasco/widgets/consumption_chart.dart
import 'package:flutter/material.dart';
import '../models/dawasco_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class ConsumptionChart extends StatelessWidget {
  final List<ConsumptionRecord> records;
  final bool isSwahili;
  const ConsumptionChart({super.key, required this.records, this.isSwahili = false});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(isSwahili ? 'Hakuna data ya matumizi' : 'No consumption data',
            style: const TextStyle(color: _kSecondary, fontSize: 13)),
      );
    }

    final maxVal = records.fold<double>(0, (prev, r) => r.consumptionM3 > prev ? r.consumptionM3 : prev);
    final safeMax = maxVal == 0 ? 1.0 : maxVal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isSwahili ? 'Matumizi ya Maji (m\u00B3)' : 'Water Usage (m\u00B3)',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: records.map((r) {
              final ratio = r.consumptionM3 / safeMax;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(r.consumptionM3.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _kPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: (ratio * 130).clamp(4.0, 130.0),
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.15 + (ratio * 0.7)),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(_shortMonth(r.month),
                          style: const TextStyle(fontSize: 9, color: _kSecondary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _shortMonth(String month) {
    if (month.length >= 7) return month.substring(5, 7);
    return month.length > 3 ? month.substring(0, 3) : month;
  }
}
