// lib/spare_parts/widgets/condition_badge.dart
import 'package:flutter/material.dart';
import '../models/spare_parts_models.dart';

class ConditionBadge extends StatelessWidget {
  final PartCondition condition;
  final double fontSize;

  const ConditionBadge({super.key, required this.condition, this.fontSize = 11});

  Color _color() {
    switch (condition) {
      case PartCondition.newGenuine: return const Color(0xFF2E7D32);
      case PartCondition.newAftermarket: return const Color(0xFF1565C0);
      case PartCondition.usedA: return const Color(0xFFE65100);
      case PartCondition.usedB: return const Color(0xFFEF6C00);
      case PartCondition.usedC: return const Color(0xFFBF360C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color().withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        condition.label,
        style: TextStyle(fontSize: fontSize, color: _color(), fontWeight: FontWeight.w600),
      ),
    );
  }
}
