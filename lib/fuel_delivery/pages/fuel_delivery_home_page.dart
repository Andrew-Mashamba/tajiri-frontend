// lib/fuel_delivery/pages/fuel_delivery_home_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/fuel_delivery_models.dart';
import '../services/fuel_delivery_service.dart';
import '../widgets/order_card.dart';
import 'order_fuel_page.dart';
import 'order_tracking_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class FuelDeliveryHomePage extends StatefulWidget {
  final int userId;
  const FuelDeliveryHomePage({super.key, required this.userId});
  @override
  State<FuelDeliveryHomePage> createState() => _FuelDeliveryHomePageState();
}

class _FuelDeliveryHomePageState extends State<FuelDeliveryHomePage> {
  List<FuelPrice> _prices = [];
  List<FuelOrder> _orders = [];
  bool _isLoading = true;
  late final bool _isSwahili;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final pRes = await FuelDeliveryService.getFuelPrices();
    final oRes = await FuelDeliveryService.getMyOrders();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (pRes.success) _prices = pRes.items;
      if (oRes.success) _orders = oRes.items;
    });
  }

  void _nav(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child:
                CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
        : RefreshIndicator(
            onRefresh: _loadData,
            color: _kPrimary,
            child: ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              children: [
                  // Prices banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.local_gas_station_rounded,
                                color: Colors.white, size: 24),
                            const SizedBox(width: 10),
                            Text(
                                _isSwahili
                                    ? 'Bei za Mafuta (EWURA)'
                                    : 'Fuel Prices (EWURA)',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                          ]),
                          const SizedBox(height: 12),
                          if (_prices.isEmpty)
                            Text(
                                _isSwahili
                                    ? 'Bei hazijapakiwa'
                                    : 'Prices not available',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12))
                          else
                            Row(
                                children: _prices
                                    .take(3)
                                    .map((p) => Expanded(
                                          child: Column(children: [
                                            Text(p.fuelLabel,
                                                style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.6),
                                                    fontSize: 11)),
                                            const SizedBox(height: 2),
                                            Text(
                                                'TZS ${p.pricePerLiter.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            Text('/L',
                                                style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.5),
                                                    fontSize: 10)),
                                          ]),
                                        ))
                                    .toList()),
                        ]),
                  ),
                  const SizedBox(height: 16),

                  // Active orders
                  if (_orders.any((o) => o.isActive)) ...[
                    Text(
                        _isSwahili
                            ? 'Agizo Zinazoendelea'
                            : 'Active Orders',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary)),
                    const SizedBox(height: 8),
                    ..._orders.where((o) => o.isActive).map((o) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: OrderCard(
                            order: o,
                            isSwahili: _isSwahili,
                            onTap: () =>
                                _nav(OrderTrackingPage(order: o)),
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // Past orders
                  Text(
                      _isSwahili ? 'Historia ya Agizo' : 'Order History',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary)),
                  const SizedBox(height: 8),
                  if (_orders.where((o) => !o.isActive).isEmpty)
                    _emptyState()
                  else
                    ..._orders
                        .where((o) => !o.isActive)
                        .take(10)
                        .map((o) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: OrderCard(
                                order: o,
                                isSwahili: _isSwahili,
                              ),
                            )),
                  const SizedBox(height: 80),
                ],
              ),
            );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(children: [
          const Icon(Icons.local_gas_station_rounded,
              size: 48, color: _kSecondary),
          const SizedBox(height: 12),
          Text(
              _isSwahili
                  ? 'Hujafanya agizo bado'
                  : 'No orders yet',
              style: const TextStyle(fontSize: 14, color: _kSecondary)),
          const SizedBox(height: 4),
          Text(
              _isSwahili
                  ? 'Agiza mafuta yaletewe mahali ulipo'
                  : 'Get fuel delivered to your location',
              style: const TextStyle(fontSize: 12, color: _kSecondary)),
        ]),
      ),
    );
  }
}
