import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class QuantitySelector extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const QuantitySelector({
    super.key,
    required this.value,
    this.min = 1,
    this.max = 10,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(Icons.remove_rounded, value > min, () => onChanged(value - 1)),
        Container(
          width: 40,
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
        ),
        _button(Icons.add_rounded, value < max, () => onChanged(value + 1)),
      ],
    );
  }

  Widget _button(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? _kPrimary : Colors.grey.shade200,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.white : Colors.grey.shade400,
        ),
      ),
    );
  }
}
