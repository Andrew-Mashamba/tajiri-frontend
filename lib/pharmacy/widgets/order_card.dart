// lib/pharmacy/widgets/order_card.dart
import 'package:flutter/material.dart';
import '../models/pharmacy_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class OrderCard extends StatelessWidget {
  final PharmacyOrder order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  String _fmt(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: order.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      order.isDelivery ? Icons.delivery_dining_rounded : Icons.store_rounded,
                      size: 20, color: order.status.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.pharmacyName ?? 'Duka #${order.pharmacyId}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                        ),
                        Text(
                          '${order.items.length} bidhaa • ${_formatDate(order.createdAt)}',
                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TZS ${_fmt(order.totalAmount)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: order.status.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.status.displayName,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: order.status.color),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (order.items.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  order.items.map((i) => '${i.medicineName} ×${i.quantity}').join(', '),
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
