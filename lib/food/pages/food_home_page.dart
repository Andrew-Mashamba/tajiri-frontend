// lib/food/pages/food_home_page.dart
import 'package:flutter/material.dart';
import '../models/food_models.dart';
import '../services/food_service.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/order_card.dart';
import 'restaurant_page.dart';
import 'food_orders_page.dart';
import 'cart_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class FoodHomePage extends StatefulWidget {
  final int userId;
  const FoodHomePage({super.key, required this.userId});
  @override
  State<FoodHomePage> createState() => _FoodHomePageState();
}

class _FoodHomePageState extends State<FoodHomePage> {
  final FoodService _service = FoodService();

  List<Restaurant> _featuredRestaurants = [];
  List<FoodOrder> _activeOrders = [];
  bool _isLoading = true;

  // Simple in-memory cart
  final List<CartItem> _cart = [];
  int? _cartRestaurantId;
  String? _cartRestaurantName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _service.getRestaurants(openOnly: true, perPage: 10),
      _service.getMyOrders(userId: widget.userId, status: 'active'),
    ]);

    if (mounted) {
      final restaurantsResult = results[0] as FoodListResult<Restaurant>;
      final ordersResult = results[1] as FoodListResult<FoodOrder>;

      setState(() {
        _isLoading = false;
        if (restaurantsResult.success) _featuredRestaurants = restaurantsResult.items;
        if (ordersResult.success) _activeOrders = ordersResult.items;
      });
    }
  }

  void _openRestaurant(Restaurant restaurant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantPage(
          userId: widget.userId,
          restaurant: restaurant,
          cart: _cart,
          cartRestaurantId: _cartRestaurantId,
          onCartUpdated: (items, restaurantId, restaurantName) {
            setState(() {
              _cart
                ..clear()
                ..addAll(items);
              _cartRestaurantId = restaurantId;
              _cartRestaurantName = restaurantName;
            });
          },
        ),
      ),
    ).then((_) {
      if (mounted) _loadData();
    });
  }

  void _openCart() {
    if (_cart.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartPage(
          userId: widget.userId,
          cart: _cart,
          restaurantId: _cartRestaurantId!,
          restaurantName: _cartRestaurantName ?? '',
          onOrderPlaced: () {
            setState(() {
              _cart.clear();
              _cartRestaurantId = null;
              _cartRestaurantName = null;
            });
            _loadData();
          },
        ),
      ),
    );
  }

  void _openOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FoodOrdersPage(userId: widget.userId)),
    ).then((_) {
      if (mounted) _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadData,
          color: _kPrimary,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Quick actions
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.restaurant_menu_rounded,
                      label: 'Mikahawa',
                      subtitle: 'Restaurants',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.receipt_long_rounded,
                      label: 'Oda Zangu',
                      subtitle: 'My Orders',
                      onTap: _openOrders,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.shopping_cart_rounded,
                      label: 'Kikapu',
                      subtitle: 'Cart (${_cart.length})',
                      onTap: _openCart,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Categories
              const Text(
                'Aina za Vyakula',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: FoodCategory.values.take(10).map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {},
                        child: SizedBox(
                          width: 70,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _kPrimary.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(cat.icon, size: 22, color: _kPrimary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cat.displayName,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Active orders
              if (_activeOrders.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Oda Zinazoendelea', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                    GestureDetector(
                      onTap: _openOrders,
                      child: const Text('Zote', style: TextStyle(fontSize: 13, color: _kSecondary)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ..._activeOrders.take(3).map((order) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FoodOrderCard(order: order, onTap: () {}),
                    )),
                const SizedBox(height: 16),
              ],

              // Nearby restaurants
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Mikahawa ya Karibu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                  GestureDetector(
                    onTap: () {},
                    child: const Text('Tazama Zote', style: TextStyle(fontSize: 13, color: _kSecondary)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_featuredRestaurants.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Icon(Icons.restaurant_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('Hakuna mikahawa kwa sasa', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                    ],
                  ),
                )
              else
                ..._featuredRestaurants.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RestaurantCard(restaurant: r, onTap: () => _openRestaurant(r)),
                    )),
              const SizedBox(height: 32),
            ],
          ),
        ),
        // Floating cart indicator
        if (_cart.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Material(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(14),
              elevation: 4,
              child: InkWell(
                onTap: _openCart,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_cart.fold<int>(0, (sum, i) => sum + i.quantity)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Tazama Kikapu',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                      Text(
                        'TZS ${_cart.fold<double>(0, (sum, i) => sum + i.total).toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: _kPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 9, color: _kSecondary),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
