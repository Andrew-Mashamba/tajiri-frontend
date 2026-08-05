import 'package:flutter/material.dart';
import '../../../models/shop_models.dart';
import '../../data/repositories/shop_repository.dart';
import '../../../services/local_storage_service.dart';
import './barcode_stocktake_screen.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kText = Color(0xFF1A1A1A);
const Color _kSubtext = Color(0xFF666666);
const Color _kMuted = Color(0xFF999999);

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  final _repo = ShopRepository.instance;
  final _searchCtrl = TextEditingController();
  List<Product> _products = [];
  final Map<int, int> _pendingChanges = {};
  bool _loading = true;
  int _filterIndex = 0; // 0=All, 1=In Stock, 2=Low, 3=Out
  int? _sellerId;

  static const _filterLabels = ['All', 'In Stock', 'Low', 'Out of Stock'];

  @override
  void initState() {
    super.initState();
    _initAndLoad();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
      if (r.success) _products = r.products;
    });
  }

  List<Product> get _filtered {
    var list = _products.where((p) {
      final q = _searchCtrl.text.toLowerCase();
      return q.isEmpty || p.title.toLowerCase().contains(q);
    }).toList();

    switch (_filterIndex) {
      case 1:
        list = list.where((p) => p.stockQuantity >= 5).toList();
        break;
      case 2:
        list = list
            .where((p) => p.stockQuantity > 0 && p.stockQuantity < 5)
            .toList();
        break;
      case 3:
        list = list.where((p) => p.stockQuantity == 0).toList();
        break;
    }
    return list;
  }

  Future<void> _openScanner() async {
    final result = await Navigator.push<Map<int, int>>(
      context,
      MaterialPageRoute(builder: (_) => BarcodeStocktakeScreen(
        mode: ScanMode.quickUpdate,
        preloadedProducts: _products,
      )),
    );
    if (result != null && mounted) _load();
  }

  Future<void> _openStocktake() async {
    final result = await Navigator.push<Map<int, int>>(
      context,
      MaterialPageRoute(builder: (_) => BarcodeStocktakeScreen(
        mode: ScanMode.stocktake,
        preloadedProducts: _products,
      )),
    );
    if (result != null && mounted) {
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stocktake applied — ${result.length} products updated')),
        );
      }
    }
  }

  void _adjust(Product p, int delta) {
    final base = _pendingChanges.containsKey(p.id)
        ? _pendingChanges[p.id]!
        : p.stockQuantity;
    final next = (base + delta).clamp(0, 99999);
    setState(() => _pendingChanges[p.id] = next);
  }

  int _currentQty(Product p) =>
      _pendingChanges.containsKey(p.id) ? _pendingChanges[p.id]! : p.stockQuantity;

  Future<void> _bulkUpdate() async {
    if (_pendingChanges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to save')),
      );
      return;
    }
    final entries = Map.of(_pendingChanges);
    int successCount = 0;
    for (final entry in entries.entries) {
      final res = await _repo.updateProduct(
        productId: entry.key,
        sellerId: _sellerId!,
        stockQuantity: entry.value,
      );
      if (res.success) successCount++;
    }
    if (!mounted) return;
    _pendingChanges.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Updated $successCount/${entries.length} products')),
    );
    _load();
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: 8,
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
          Icon(Icons.inventory_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No products found',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          Text('Try adjusting your filter or search',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final hasPending = _pendingChanges.isNotEmpty;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Stock Management',
            style: TextStyle(
                color: _kText, fontSize: 17, fontWeight: FontWeight.w600)),
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: _kText,
        actions: [
          // Barcode scanner — quick update
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan to update',
            onPressed: _openScanner,
          ),
          // Stocktake mode
          IconButton(
            icon: const Icon(Icons.fact_check_rounded),
            tooltip: 'Stocktake mode',
            onPressed: _openStocktake,
          ),
          if (hasPending)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: _bulkUpdate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _kText,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Save ${_pendingChanges.length}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _kText,
          onRefresh: _load,
          child: Column(
            children: [
              _buildSearchBar(),
              _buildFilterRow(),
              Expanded(
                child: _loading
                    ? _buildShimmer()
                    : filtered.isEmpty
                        ? _buildEmpty()
                        : ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (ctx, i) {
                              final p = filtered[i];
                              return _StockTile(
                                product: p,
                                currentQty: _currentQty(p),
                                isDirty: _pendingChanges.containsKey(p.id),
                                onIncrement: () => _adjust(p, 1),
                                onDecrement: () => _adjust(p, -1),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search products…',
          hintStyle: TextStyle(color: _kMuted, fontSize: 14),
          prefixIcon:
              const Icon(Icons.search_rounded, color: _kMuted, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: _kMuted, size: 18),
                  onPressed: () => _searchCtrl.clear(),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            borderSide: const BorderSide(color: _kText),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filterLabels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => setState(() => _filterIndex = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _filterIndex == i ? _kText : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _filterIndex == i ? _kText : Colors.grey.shade300,
              ),
            ),
            child: Text(
              _filterLabels[i],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _filterIndex == i ? Colors.white : _kSubtext,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  const _StockTile({
    required this.product,
    required this.currentQty,
    required this.isDirty,
    required this.onIncrement,
    required this.onDecrement,
  });

  final Product product;
  final int currentQty;
  final bool isDirty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  Color get _statusColor {
    if (currentQty == 0) return const Color(0xFFD32F2F);
    if (currentQty < 5) return const Color(0xFFE65100);
    return const Color(0xFF2E7D32);
  }

  String get _statusLabel {
    if (currentQty == 0) return 'Out of Stock';
    if (currentQty < 5) return 'Low Stock';
    return 'In Stock';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        border: isDirty
            ? Border.all(color: _kText.withValues(alpha: 0.3), width: 1.5)
            : null,
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
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kText),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'TZS ${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 12, color: _kSubtext),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _statusLabel,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _statusColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _QtyControl(
              qty: currentQty,
              onIncrement: onIncrement,
              onDecrement: onDecrement,
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  const _QtyControl({
    required this.qty,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int qty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ControlBtn(icon: Icons.remove_rounded, onTap: onDecrement),
        SizedBox(
          width: 36,
          child: Text(
            '$qty',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: _kText),
          ),
        ),
        _ControlBtn(icon: Icons.add_rounded, onTap: onIncrement),
      ],
    );
  }
}

class _ControlBtn extends StatelessWidget {
  const _ControlBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: _kText),
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
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        width: 52,
        height: 52,
        color: Colors.grey.shade100,
        child: Icon(Icons.image_rounded, color: Colors.grey.shade400, size: 22),
      );
}
