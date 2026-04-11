// lib/pharmacy/pages/my_orders_page.dart
import 'package:flutter/material.dart';
import '../models/pharmacy_models.dart';
import '../services/pharmacy_service.dart';
import '../widgets/order_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class MyOrdersPage extends StatefulWidget {
  final int userId;
  const MyOrdersPage({super.key, required this.userId});
  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PharmacyService _service = PharmacyService();

  List<PharmacyOrder> _allOrders = [];
  bool _isLoading = true;

  List<PharmacyOrder> get _active => _allOrders.where((o) => o.isActive).toList();
  List<PharmacyOrder> get _past => _allOrders.where((o) => !o.isActive).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final result = await _service.getMyOrders(widget.userId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _allOrders = result.items;
      });
    }
  }

  Future<void> _cancelOrder(PharmacyOrder order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ghairi Agizo'),
        content: const Text('Una uhakika unataka kughairi agizo hili?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hapana')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ndiyo'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _service.cancelOrder(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.success ? 'Agizo limeghairiwa' : (result.message ?? 'Imeshindwa'))),
        );
        if (result.success) _loadOrders();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Maagizo Yangu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          tabs: [
            Tab(text: 'Hai (${_active.length})'),
            Tab(text: 'Iliyopita (${_past.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_active, canCancel: true),
                _buildList(_past),
              ],
            ),
    );
  }

  Widget _buildList(List<PharmacyOrder> orders, {bool canCancel = false}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Hakuna maagizo', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: _kPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              children: [
                OrderCard(order: order),
                if (canCancel && order.status == PharmacyOrderStatus.pending)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _cancelOrder(order),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Ghairi Agizo', style: TextStyle(fontSize: 12)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
