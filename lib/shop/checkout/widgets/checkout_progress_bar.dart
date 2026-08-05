import 'package:flutter/material.dart';

/// Lightweight step indicator for checkout (`shop.md` checkout/flow).
class CheckoutProgressBar extends StatelessWidget {
  const CheckoutProgressBar({
    super.key,
    this.stepIndex = 0,
  });

  /// Lit segments are `0..stepIndex` inclusive. On the monolithic checkout screen, `2`
  /// marks Review+Shipping+Payment as active before tapping Pay (Done = success dialog).
  final int stepIndex;

  static const _labels = ['Review', 'Shipping', 'Payment', 'Done'];

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1A1A1A);
    const muted = Color(0xFFCCCCCC);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: List.generate(_labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final seg = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: seg < stepIndex ? primary : muted,
              ),
            );
          }
          final idx = i ~/ 2;
          final done = idx <= stepIndex;
          return Column(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: done ? primary : muted,
                child: Text(
                  '${idx + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    color: done ? Colors.white : const Color(0xFF666666),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _labels[idx],
                style: TextStyle(
                  fontSize: 10,
                  color: done ? primary : const Color(0xFF666666),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
