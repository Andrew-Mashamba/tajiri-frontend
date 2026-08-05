import 'package:flutter/material.dart';

class StockUrgencyBadge extends StatelessWidget {
  final int stockQuantity;
  final int threshold;

  const StockUrgencyBadge({
    super.key,
    required this.stockQuantity,
    this.threshold = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (stockQuantity <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text('Out of stock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE53935))),
      );
    }
    if (stockQuantity > threshold) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9800).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('Only $stockQuantity left!', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE65100))),
    );
  }
}
