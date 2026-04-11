// lib/fuel_delivery/widgets/order_card.dart
import 'package:flutter/material.dart';
import '../models/fuel_delivery_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class OrderCard extends StatelessWidget {
  final FuelOrder order;
  final bool isSwahili;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.order,
    this.isSwahili = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_gas_station_rounded,
                    size: 20, color: _kPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${order.liters.toStringAsFixed(0)}L ${order.fuelType}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(
                          '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary)),
                    ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(order.statusLabel,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor)),
                ),
                const SizedBox(height: 4),
                Text('TZS ${order.totalCost.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary)),
              ]),
            ]),
            if (order.deliveryAddress != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.location_on_rounded,
                    size: 14, color: _kSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(order.deliveryAddress!,
                      style:
                          const TextStyle(fontSize: 11, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ],
            if (order.carName != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.directions_car_rounded,
                    size: 14, color: _kSecondary),
                const SizedBox(width: 4),
                Text(order.carName!,
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ]),
            ],
          ]),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return const Color(0xFF4CAF50);
      case 'en_route':
        return Colors.blue;
      case 'confirmed':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return _kSecondary;
    }
  }
}
