// lib/pharmacy/widgets/medicine_card.dart
import 'package:flutter/material.dart';
import '../models/pharmacy_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final int cartQuantity;

  const MedicineCard({super.key, required this.medicine, this.onTap, this.onAddToCart, this.cartQuantity = 0});

  String _fmt(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(medicine.dosageIcon, size: 22, color: _kPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${medicine.strength} • ${medicine.dosageFormLabel}',
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                    ),
                    if (medicine.genericName != null)
                      Text(
                        medicine.genericName!,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TZS ${_fmt(medicine.price)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (medicine.prescriptionRequired)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Rx', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.orange)),
                        ),
                      if (!medicine.inStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Imeisha', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.red)),
                        ),
                    ],
                  ),
                ],
              ),
              if (onAddToCart != null && medicine.inStock) ...[
                const SizedBox(width: 8),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: onAddToCart,
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: _kPrimary.withValues(alpha: 0.08),
                        foregroundColor: _kPrimary,
                        minimumSize: const Size(36, 36),
                      ),
                    ),
                    if (cartQuantity > 0)
                      Positioned(
                        right: 0, top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: _kPrimary, shape: BoxShape.circle),
                          child: Text(
                            '$cartQuantity',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
