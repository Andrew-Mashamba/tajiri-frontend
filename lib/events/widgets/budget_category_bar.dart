import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/event_strings.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class BudgetCategoryBar extends StatelessWidget {
  final BudgetCategory category;
  final String currency;
  const BudgetCategoryBar({super.key, required this.category, this.currency = 'TZS'});

  @override
  Widget build(BuildContext context) {
    final strings = EventStrings(isSwahili: true);
    final progress = category.utilization.clamp(0.0, 1.5);
    final isOver = category.isOverspent;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isOver ? Colors.red.shade200 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
              Text(
                '${strings.formatPrice(category.spent, currency)} / ${strings.formatPrice(category.allocated, currency)}',
                style: TextStyle(fontSize: 12, color: isOver ? Colors.red : _kSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(isOver ? Colors.red : _kPrimary),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isOver
                ? '${strings.isSwahili ? "Imezidi kwa" : "Over by"} ${strings.formatPrice(category.spent - category.allocated, currency)}'
                : '${strings.isSwahili ? "Imebaki" : "Remaining"}: ${strings.formatPrice(category.remaining, currency)}',
            style: TextStyle(fontSize: 11, color: isOver ? Colors.red : _kSecondary),
          ),
        ],
      ),
    );
  }
}
