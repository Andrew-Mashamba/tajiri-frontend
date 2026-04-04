import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSurface = Color(0xFFFFFFFF);

class StickyCartBar extends StatelessWidget {
  final double price;
  final double? compareAtPrice;
  final String currency;
  final bool isInStock;
  final bool isAddingToCart;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  const StickyCartBar({
    super.key,
    required this.price,
    this.compareAtPrice,
    this.currency = 'TZS',
    required this.isInStock,
    this.isAddingToCart = false,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    final priceStr = '$currency ${price.toStringAsFixed(0)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (compareAtPrice != null && compareAtPrice! > price)
                    Text(
                      '$currency ${compareAtPrice!.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF999999), decoration: TextDecoration.lineThrough),
                    ),
                  Text(priceStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimaryText)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isInStock && !isAddingToCart ? () { HapticFeedback.lightImpact(); onAddToCart(); } : null,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _kPrimaryText),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isAddingToCart
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Add to Cart', style: TextStyle(color: _kPrimaryText, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isInStock ? () { HapticFeedback.mediumImpact(); onBuyNow(); } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryText,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isInStock ? 'Buy Now' : 'Out of Stock', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
