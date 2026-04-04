import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../models/shop_models.dart';
import '../../services/shop_database.dart';
import '../../widgets/shop/product_card.dart';

const Color _kBackground = Color(0xFFFAFAFA);
const Color _kPrimaryText = Color(0xFF1A1A1A);

class WishlistScreen extends StatefulWidget {
  final int currentUserId;
  const WishlistScreen({super.key, required this.currentUserId});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final ShopDatabase _db = ShopDatabase.instance;
  List<(Product, bool)> _items = []; // (product, priceDropped)
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _db.getWishlistWithPriceDrops();
    final items = <(Product, bool)>[];
    for (final row in rows) {
      final jsonStr = row['product_json'] as String?;
      if (jsonStr == null) continue;
      final product = Product.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      final dropped = (row['price_dropped'] as int?) == 1;
      items.add((product, dropped));
    }
    if (mounted) setState(() { _items = items; _isLoading = false; });
  }

  Future<void> _removeItem(int productId) async {
    await _db.removeFromWishlist(productId);
    setState(() => _items.removeWhere((item) => item.$1.id == productId));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from wishlist')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(
          'Wishlist (${_items.length})',
          style: const TextStyle(color: _kPrimaryText),
        ),
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimaryText),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HeroIcon(
                        HeroIcons.heart,
                        size: 48,
                        color: Color(0xFFE0E0E0),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your wishlist is empty',
                        style: TextStyle(color: Color(0xFF999999)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimaryText,
                        ),
                        child: const Text(
                          'Browse Shop',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final (product, priceDropped) = _items[index];
                    return Stack(
                      children: [
                        ProductCard(
                          product: product,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/shop/product',
                            arguments: {'productId': product.id},
                          ),
                        ),
                        if (priceDropped)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Price Dropped!',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _removeItem(product.id),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Color(0xFF999999),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
