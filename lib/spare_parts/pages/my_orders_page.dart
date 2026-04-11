// lib/spare_parts/pages/my_orders_page.dart
import 'package:flutter/material.dart';
import '../models/spare_parts_models.dart';
import '../services/spare_parts_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class MyOrdersPage extends StatefulWidget {
  final int userId;
  const MyOrdersPage({super.key, required this.userId});
  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  final SparePartsService _service = SparePartsService();
  List<PartsOrder> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await _service.getMyOrders();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _orders = result.items;
      });
    }
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.confirmed: return const Color(0xFF1565C0);
      case OrderStatus.shipped: return const Color(0xFFE65100);
      case OrderStatus.delivered: return const Color(0xFF2E7D32);
      case OrderStatus.cancelled: return const Color(0xFFC62828);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _orders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_shipping_rounded, size: 48, color: _kSecondary),
                      SizedBox(height: 12),
                      Text('Hakuna orders', style: TextStyle(color: _kSecondary, fontSize: 14)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final o = _orders[i];
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Order #${o.id}',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(o.status).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(o.status.name.toUpperCase(),
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _statusColor(o.status))),
                                  ),
                                ],
                              ),
                              if (o.sellerName != null) ...[
                                const SizedBox(height: 6),
                                Text('Seller: ${o.sellerName}',
                                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                              const SizedBox(height: 6),
                              Text('${o.items.length} item(s)',
                                  style: const TextStyle(fontSize: 13, color: _kSecondary)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(o.deliveryOption,
                                      style: const TextStyle(fontSize: 12, color: _kSecondary)),
                                  Text('TZS ${o.totalCost.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
