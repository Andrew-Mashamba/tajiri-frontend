// lib/food/pages/food_orders_page.dart
import 'package:flutter/material.dart';
import '../models/food_models.dart';
import '../services/food_service.dart';
import '../widgets/order_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class FoodOrdersPage extends StatefulWidget {
  final int userId;
  const FoodOrdersPage({super.key, required this.userId});
  @override
  State<FoodOrdersPage> createState() => _FoodOrdersPageState();
}

class _FoodOrdersPageState extends State<FoodOrdersPage> with SingleTickerProviderStateMixin {
  final FoodService _service = FoodService();
  late TabController _tabController;

  List<FoodOrder> _activeOrders = [];
  List<FoodOrder> _pastOrders = [];
  bool _isLoading = true;

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

    final activeResult = await _service.getMyOrders(userId: widget.userId, status: 'active');
    final pastResult = await _service.getMyOrders(userId: widget.userId, status: 'completed');

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (activeResult.success) _activeOrders = activeResult.items;
        if (pastResult.success) _pastOrders = pastResult.items;
      });
    }
  }

  Widget _buildOrderList(List<FoodOrder> orders, String emptyMessage) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(emptyMessage, style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: _kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => FoodOrderCard(order: orders[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Oda Zangu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: 'Zinazoendelea'),
            Tab(text: 'Zilizopita'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(_activeOrders, 'Hakuna oda zinazoendelea'),
                _buildOrderList(_pastOrders, 'Hakuna oda zilizopita'),
              ],
            ),
    );
  }
}
