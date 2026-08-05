import 'package:flutter/material.dart';
import '../../../models/shop_models.dart';
import '../../data/repositories/shop_repository.dart';
import '../../shared/widgets/product_card.dart';

const Color _kBg = Color(0xFFFAFAFA);

/// Personalized picks (`docs/shop/shop_backend_api.md` GET /products/recommended).
class RecommendedProductsScreen extends StatefulWidget {
  const RecommendedProductsScreen({super.key, required this.currentUserId});

  final int currentUserId;

  @override
  State<RecommendedProductsScreen> createState() => _RecommendedProductsScreenState();
}

class _RecommendedProductsScreenState extends State<RecommendedProductsScreen> {
  final ShopRepository _repo = ShopRepository.instance;
  List<Product> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await _repo.getRecommendedProducts(widget.currentUserId);
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
        title: const Text('Recommended for you'),
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
                            child: Text(
                              'Based on your activity',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
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
                              (ctx, i) => ProductCard(
                                product: _items[i],
                                onTap: () => Navigator.pushNamed(
                                  ctx,
                                  '/shop/product',
                                  arguments: {'productId': _items[i].id},
                                ),
                              ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.recommend_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No recommendations yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Keep browsing to get personalized picks',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
