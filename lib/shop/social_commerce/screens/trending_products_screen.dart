import 'package:flutter/material.dart';
import '../../../models/shop_models.dart';
import '../../data/repositories/shop_repository.dart';
import '../../shared/widgets/product_card.dart';

const Color _kBg = Color(0xFFFAFAFA);

/// Trending grid (`shop.md` trending_products_screen).
class TrendingProductsScreen extends StatefulWidget {
  const TrendingProductsScreen({super.key, required this.currentUserId});

  final int currentUserId;

  @override
  State<TrendingProductsScreen> createState() => _TrendingProductsScreenState();
}

class _TrendingProductsScreenState extends State<TrendingProductsScreen> {
  final ShopRepository _repo = ShopRepository.instance;
  List<Product> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await _repo.getTrendingProducts(currentUserId: widget.currentUserId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.success) _items = r.products;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Trending'),
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: const Color(0xFF1A1A1A),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A)))
            : _items.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: const Color(0xFF1A1A1A),
                    onRefresh: _load,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 20,
                                  color: Color(0xFF1A1A1A),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Trending Now',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => _buildRankedCard(ctx, i),
                              childCount: _items.length,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildRankedCard(BuildContext ctx, int i) {
    final product = _items[i];
    final isTopThree = i < 3;
    return Stack(
      children: [
        ProductCard(
          product: product,
          onTap: () => Navigator.pushNamed(
            ctx,
            '/shop/product',
            arguments: {'productId': product.id},
          ),
        ),
        if (isTopThree)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                '#${i + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Nothing trending yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check back soon',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
