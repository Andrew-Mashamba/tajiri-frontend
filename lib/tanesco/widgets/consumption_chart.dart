// lib/tanesco/widgets/consumption_chart.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tanesco_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class ConsumptionChart extends StatelessWidget {
  final List<ConsumptionRecord> records;
  final String period; // daily, weekly, monthly
  final int? selectedIndex;
  final ValueChanged<int>? onBarTap;

  const ConsumptionChart({
    super.key,
    required this.records,
    required this.period,
    this.selectedIndex,
    this.onBarTap,
  });

  String _formatLabel(DateTime date) {
    switch (period) {
      case 'daily':
        return '${date.day}/${date.month}';
      case 'weekly':
        return 'W${_weekOfYear(date)}';
      case 'monthly':
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return months[date.month - 1];
      default:
        return '${date.day}';
    }
  }

  int _weekOfYear(DateTime date) {
    final firstDay = DateTime(date.year, 1, 1);
    return ((date.difference(firstDay).inDays) / 7).ceil();
  }

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text((AppStringsScope.of(context)?.isSwahili ?? false) ? 'Hakuna data' : 'No data',
            style: const TextStyle(color: _kSecondary, fontSize: 13)),
      );
    }

    final maxUnits = records.fold<double>(0, (m, r) => r.unitsUsed > m ? r.unitsUsed : m);
    final safeMax = maxUnits == 0 ? 1.0 : maxUnits;

    return SizedBox(
      height: 220,
      child: Column(
        children: [
          // Y-axis label
          Row(
            children: [
              Text('${safeMax.toStringAsFixed(0)} kWh',
                  style: const TextStyle(fontSize: 9, color: _kSecondary)),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 4),
          // Bars
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(records.length, (i) {
                final r = records[i];
                final ratio = r.unitsUsed / safeMax;
                final isSelected = selectedIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: onBarTap != null ? () => onBarTap!(i) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isSelected)
                            Text(r.unitsUsed.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: _kPrimary)),
                          const SizedBox(height: 2),
                          Flexible(
                            child: FractionallySizedBox(
                              heightFactor: ratio.clamp(0.02, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _kPrimary
                                      : _kPrimary.withValues(alpha: 0.25),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 4),
          // X-axis labels
          Row(
            children: List.generate(records.length, (i) {
              final showLabel = records.length <= 12 || i % (records.length ~/ 6 + 1) == 0;
              return Expanded(
                child: Text(
                  showLabel ? _formatLabel(records[i].date) : '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 8,
                    color: selectedIndex == i ? _kPrimary : _kSecondary,
                    fontWeight: selectedIndex == i ? FontWeight.w700 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
