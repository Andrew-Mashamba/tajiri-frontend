import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/shop_models.dart';
import '../../data/repositories/shop_repository.dart';

const Color _kBg = Color(0xFFFAFAFA);

/// Quick stock adjustments (`shop.md` inventory_screen).
class SellerInventoryScreen extends StatefulWidget {
  const SellerInventoryScreen({super.key, required this.sellerId});

  final int sellerId;

  @override
  State<SellerInventoryScreen> createState() => _SellerInventoryScreenState();
}

enum _StockFilter { all, inStock, lowStock, outOfStock }

class _SellerInventoryScreenState extends State<SellerInventoryScreen> {
  final ShopRepository _repo = ShopRepository.instance;
  final TextEditingController _searchCtrl = TextEditingController();
  List<Product> _products = [];
  bool _loading = true;
  _StockFilter _filter = _StockFilter.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final r = await _repo.getSellerProducts(widget.sellerId, perPage: 100);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.success) _products = r.products;
    });
  }

  List<Product> get _filtered {
    return _products.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.title.toLowerCase().contains(_searchQuery);
      final matchesFilter = switch (_filter) {
        _StockFilter.all => true,
        _StockFilter.inStock => p.stockQuantity > 4,
        _StockFilter.lowStock => p.stockQuantity > 0 && p.stockQuantity <= 4,
        _StockFilter.outOfStock => p.stockQuantity == 0,
      };
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _editStock(Product p) async {
    final ctrl = TextEditingController(text: '${p.stockQuantity}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Stock quantity'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final qty = int.tryParse(ctrl.text.trim()) ?? p.stockQuantity;
    ctrl.dispose();
    final res = await _repo.updateProduct(
      productId: p.id,
      sellerId: widget.sellerId,
      stockQuantity: qty,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.success ? 'Updated' : (res.message ?? 'Failed'))),
    );
    if (res.success) _load();
  }

  Color _stockColor(int qty) {
    if (qty == 0) return Colors.red;
    if (qty <= 4) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _filtered;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: const Color(0xFF1A1A1A),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A)))
            : RefreshIndicator(
                color: const Color(0xFF1A1A1A),
                onRefresh: _load,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Search products…',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1A1A1A)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: Row(
                          children: _StockFilter.values.map((f) {
                            final label = switch (f) {
                              _StockFilter.all => 'All',
                              _StockFilter.inStock => 'In Stock',
                              _StockFilter.lowStock => 'Low Stock',
                              _StockFilter.outOfStock => 'Out of Stock',
                            };
                            final selected = _filter == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(label),
                                selected: selected,
                                onSelected: (_) => setState(() => _filter = f),
                                selectedColor: const Color(0xFF1A1A1A),
                                labelStyle: TextStyle(
                                  color: selected ? Colors.white : const Color(0xFF1A1A1A),
                                  fontSize: 13,
                                ),
                                showCheckmark: false,
                                backgroundColor: Colors.white,
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    if (displayed.isEmpty)
                      SliverFillRemaining(
                        child: _buildEmptyState(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final p = displayed[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _editStock(p),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  p.title,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF1A1A1A),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: BoxDecoration(
                                                        color: _stockColor(p.stockQuantity),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Stock: ${p.stockQuantity}',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: _stockColor(p.stockQuantity),
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(
                                            Icons.edit_outlined,
                                            color: Color(0xFF1A1A1A),
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: displayed.length,
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
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _filter != _StockFilter.all
                ? 'No matching products'
                : 'No products yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty || _filter != _StockFilter.all
                ? 'Try a different filter or search term'
                : 'Add products to manage inventory',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
