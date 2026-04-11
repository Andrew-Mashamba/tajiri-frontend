import 'package:flutter/material.dart';
import '../models/event_strings.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class PriceTag extends StatelessWidget {
  final double? price;
  final String currency;
  final bool isFree;

  const PriceTag({
    super.key,
    this.price,
    this.currency = 'TZS',
    this.isFree = false,
  });

  @override
  Widget build(BuildContext context) {
    final strings = EventStrings(isSwahili: true);
    return Text(
      isFree || (price == null || price! <= 0)
          ? '${strings.free} / Free'
          : strings.formatPrice(price!, currency),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _kPrimary,
      ),
    );
  }
}
