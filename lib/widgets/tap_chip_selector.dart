import 'package:flutter/material.dart';

/// Single-select chip picker. Vertical by default, horizontal optional.
/// Used for gender, education level, degree level, and other enumerated choices.
class TapChipSelector<T> extends StatelessWidget {
  final List<T> options;
  final T? selectedOption;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onSelected;
  final bool horizontal;

  const TapChipSelector({
    super.key,
    required this.options,
    this.selectedOption,
    required this.labelBuilder,
    required this.onSelected,
    this.horizontal = false,
  });

  static const Color _primary = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) => _buildChip(option)).toList(),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: options
          .map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildChip(option),
              ))
          .toList(),
    );
  }

  Widget _buildChip(T option) {
    final isSelected = option == selectedOption;
    return GestureDetector(
      onTap: () => onSelected(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? _primary : Colors.white,
          border: Border.all(
            color: isSelected ? _primary : const Color(0xFFE0E0E0),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          labelBuilder(option),
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : _primary,
          ),
        ),
      ),
    );
  }
}
