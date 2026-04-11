// lib/newton/widgets/difficulty_selector.dart
import 'package:flutter/material.dart';
import '../models/newton_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class DifficultySelector extends StatelessWidget {
  final DifficultyLevel selected;
  final ValueChanged<DifficultyLevel> onChanged;
  final bool isSwahili;

  const DifficultySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.isSwahili = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: DifficultyLevel.values.map((level) {
        final isSelected = level == selected;
        final label =
            isSwahili ? level.displayNameSw : level.displayName;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Material(
            color: isSelected ? _kPrimary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => onChanged(level),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                constraints: const BoxConstraints(minHeight: 32),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
