import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/shop_models.dart';
import '../../data/repositories/shop_repository.dart';
import '../../../services/local_storage_service.dart';
import './barcode_stocktake_screen.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kText = Color(0xFF1A1A1A);
const Color _kSubtext = Color(0xFF666666);

class RestockAlertsScreen extends StatefulWidget {
  const RestockAlertsScreen({super.key});

  @override
  State<RestockAlertsScreen> createState() => _RestockAlertsScreenState();
}

class _RestockAlertsScreenState extends State<RestockAlertsScreen> {
  final _repo = ShopRepository.instance;
  List<Product> _allProducts = [];
  bool _loading = true;
  int _selectedFilter = 0; // 0=All, 1=Out of Stock, 2=Low Stock
  int? _sellerId;

  static const int _lowStockThreshold = 5;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    final storage = await LocalStorageService.getInstance();
    final user = storage.getUser();
    if (!mounted) return;
    setState(() => _sellerId = user?.userId ?? 1);
    await _load();
  }

  Future<void> _load() async {
    if (_sellerId == null) return;
    setState(() => _loading = true);
    final r = await _repo.getSellerProducts(_sellerId!, perPage: 200);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.success) {
        _allProducts = r.products
            .where((p) =>
                p.stockQuantity == 0 ||
                (p.stockQuantity > 0 && p.stockQuantity < _lowStockThreshold))
            .toList();
      }
    });
  }

  List<Product> get _filtered {
    switch (_selectedFilter) {
      case 1:
        return _allProducts.where((p) => p.stockQuantity == 0).toList();
      case 2:
        return _allProducts
            .where(
                (p) => p.stockQuantity > 0 && p.stockQuantity < _lowStockThreshold)
            .toList();
      default:
        return _allProducts;
    }
  }

  int get _outOfStock =>
      _allProducts.where((p) => p.stockQuantity == 0).length;
  int get _lowStock => _allProducts
      .where((p) => p.stockQuantity > 0 && p.stockQuantity < _lowStockThreshold)
      .length;

  Future<void> _showRestockSheet(Product p) async {
    final ctrl = TextEditingController();
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _kText,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Restock: ${p.title}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _kText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Current stock: ${p.stockQuantity}',
              style: const TextStyle(fontSize: 13, color: _kSubtext),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'New quantity',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kText,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final qty = int.tryParse(ctrl.text.trim());
                  Navigator.pop(ctx, qty);
                },
                child: const Text('Confirm Restock',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    if (result == null || result < 0) return;
    final res = await _repo.updateProduct(
      productId: p.id,
      sellerId: _sellerId!,
      stockQuantity: result,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              res.success ? 'Stock updated to $result' : (res.message ?? 'Failed'))),
    );
    if (res.success) _load();
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No alerts',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          Text('All your products are well stocked',
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Restock Alerts',
            style: TextStyle(
                color: _kText, fontSize: 17, fontWeight: FontWeight.w600)),
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: _kText,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan to restock',
            onPressed: () async {
              final result = await Navigator.push<Map<int, int>>(
                context,
                MaterialPageRoute(builder: (_) => BarcodeStocktakeScreen(
                  mode: ScanMode.quickUpdate,
                  preloadedProducts: _allProducts,
                )),
              );
              if (result != null && mounted) _load();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _kText,
          onRefresh: _load,
          child: _loading
              ? _buildShimmer()
              : Column(
                  children: [
                    if (_allProducts.isNotEmpty) ...[
                      _buildSummaryBar(),
                      _buildFilterChips(),
                    ],
                    Expanded(
                      child: filtered.isEmpty
                          ? _buildEmpty()
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (ctx, i) =>
                                  _ProductAlertTile(
                                    product: filtered[i],
                                    onRestock: () =>
                                        _showRestockSheet(filtered[i]),
                                  ),
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _StatChip(
              label: '$_outOfStock Out of Stock',
              color: const Color(0xFFD32F2F)),
          const SizedBox(width: 8),
          _StatChip(
              label: '$_lowStock Low Stock', color: const Color(0xFFE65100)),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    const labels = ['All Alerts', 'Out of Stock', 'Low Stock'];
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => setState(() => _selectedFilter = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _selectedFilter == i ? _kText : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selectedFilter == i ? _kText : Colors.grey.shade300,
              ),
            ),
            child: Text(
              labels[i],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _selectedFilter == i ? Colors.white : _kSubtext,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _ProductAlertTile extends StatelessWidget {
  const _ProductAlertTile({
    required this.product,
    required this.onRestock,
  });
  final Product product;
  final VoidCallback onRestock;

  @override
  Widget build(BuildContext context) {
    final isOut = product.stockQuantity == 0;
    final badgeColor =
        isOut ? const Color(0xFFD32F2F) : const Color(0xFFE65100);
    final badgeText = isOut ? 'Out of Stock' : 'Low: ${product.stockQuantity}';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _ProductThumb(url: product.thumbnailUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: badgeColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRestock,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: _kText,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Restock',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: url.isNotEmpty
          ? Image.network(
              url,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        width: 56,
        height: 56,
        color: Colors.grey.shade100,
        child: Icon(Icons.image_rounded, color: Colors.grey.shade400, size: 24),
      );
}
