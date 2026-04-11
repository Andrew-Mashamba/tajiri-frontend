import 'package:flutter/material.dart';
import '../models/event_enums.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;
  final double? walletBalance;
  const PaymentMethodSelector({super.key, required this.selected, required this.onChanged, this.walletBalance});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: PaymentMethod.values.map((m) {
        final isSelected = m == selected;
        return GestureDetector(
          onTap: () => onChanged(m),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? _kPrimary.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? _kPrimary : Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, size: 20, color: isSelected ? _kPrimary : _kSecondary),
                const SizedBox(width: 12),
                Icon(m.icon, size: 20, color: _kPrimary),
                const SizedBox(width: 10),
                Expanded(child: Text(m.displayName, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: _kPrimary))),
                if (m == PaymentMethod.wallet && walletBalance != null)
                  Text('TZS ${walletBalance!.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
