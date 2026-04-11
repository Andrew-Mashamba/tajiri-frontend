// lib/food/pages/restaurant_page.dart
import 'package:flutter/material.dart';
import '../models/food_models.dart';
import '../services/food_service.dart';
import '../widgets/menu_item_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class RestaurantPage extends StatefulWidget {
  final int userId;
  final Restaurant restaurant;
  final List<CartItem> cart;
  final int? cartRestaurantId;
  final void Function(List<CartItem> items, int restaurantId, String restaurantName) onCartUpdated;

  const RestaurantPage({
    super.key,
    required this.userId,
    required this.restaurant,
    required this.cart,
    this.cartRestaurantId,
    required this.onCartUpdated,
  });

  @override
  State<RestaurantPage> createState() => _RestaurantPageState();
}

class _RestaurantPageState extends State<RestaurantPage> {
  final FoodService _service = FoodService();
  List<MenuItem> _menu = [];
  bool _isLoading = true;
  late List<CartItem> _cart;

  @override
  void initState() {
    super.initState();
    _cart = widget.cartRestaurantId == widget.restaurant.id
        ? List.from(widget.cart)
        : [];
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() => _isLoading = true);
    final result = await _service.getMenu(widget.restaurant.id);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _menu = result.items;
      });
    }
  }

  void _addToCart(MenuItem item) {
    // If cart has items from different restaurant, clear it
    if (_cart.isNotEmpty && widget.cartRestaurantId != null && widget.cartRestaurantId != widget.restaurant.id) {
      _showClearCartDialog(item);
      return;
    }

    setState(() {
      final existing = _cart.where((c) => c.menuItem.id == item.id).toList();
      if (existing.isNotEmpty) {
        existing.first.quantity++;
      } else {
        _cart.add(CartItem(menuItem: item));
      }
    });
    widget.onCartUpdated(_cart, widget.restaurant.id, widget.restaurant.name);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} imeongezwa kwenye kikapu'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showClearCartDialog(MenuItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ondoa bidhaa za awali?'),
        content: const Text('Kikapu chako kina bidhaa kutoka mkahawa mwingine. Je, ungependa kuondoa na kuanza upya?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hapana'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _cart.clear();
                _cart.add(CartItem(menuItem: item));
              });
              widget.onCartUpdated(_cart, widget.restaurant.id, widget.restaurant.name);
            },
            child: const Text('Ndio, Ondoa'),
          ),
        ],
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.restaurant.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            if (widget.restaurant.address != null)
              Text(
                widget.restaurant.address!,
                style: const TextStyle(fontSize: 11, color: _kSecondary),
              ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _menu.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restaurant_menu_rounded, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('Menyu haipo kwa sasa', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMenu,
                  color: _kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _menu.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final item = _menu[i];
                      return MenuItemCard(
                        menuItem: item,
                        onAdd: item.isAvailable ? () => _addToCart(item) : null,
                      );
                    },
                  ),
                ),
    );
  }
}
