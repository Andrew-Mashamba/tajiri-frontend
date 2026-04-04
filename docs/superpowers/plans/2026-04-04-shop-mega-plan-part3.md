# TAJIRI Shop Mega Plan — Part 3: Seller Tools, Retention, Polish

> **Continuation of:** `docs/superpowers/plans/2026-04-04-shop-mega-plan.md`
> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

---

## SUB-PROJECT F: Seller Tools & Analytics

**Goal:** Wire the existing `getSellerStats()` API into a visual analytics dashboard, add bulk order actions, and draft auto-save for product creation.

---

### Task F1: Seller analytics dashboard screen

**Files:**
- Create: `lib/screens/shop/seller_analytics_screen.dart`
- Modify: `lib/widgets/gallery/shop_gallery_widget.dart`

- [ ] **Step 1: Create the analytics screen**

```dart
// lib/screens/shop/seller_analytics_screen.dart
import 'package:flutter/material.dart';
import '../../models/shop_models.dart';
import '../../services/shop_service.dart';

const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kTertiaryText = Color(0xFF999999);

class SellerAnalyticsScreen extends StatefulWidget {
  final int sellerId;
  const SellerAnalyticsScreen({super.key, required this.sellerId});

  @override
  State<SellerAnalyticsScreen> createState() => _SellerAnalyticsScreenState();
}

class _SellerAnalyticsScreenState extends State<SellerAnalyticsScreen> {
  final ShopService _shopService = ShopService();
  SellerStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final result = await _shopService.getSellerStats(widget.sellerId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _stats = result.stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text('Shop Analytics', style: TextStyle(color: _kPrimaryText)),
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimaryText),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _stats == null
              ? const Center(child: Text('Failed to load analytics', style: TextStyle(color: _kTertiaryText)))
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Revenue card
                      _buildStatCard(
                        title: 'Revenue',
                        value: '${_stats!.currency} ${_stats!.totalRevenue.toStringAsFixed(0)}',
                        icon: Icons.account_balance_wallet_outlined,
                        color: const Color(0xFF4CAF50),
                      ),
                      const SizedBox(height: 12),

                      // Stats grid
                      Row(
                        children: [
                          Expanded(child: _buildMiniCard('Products', '${_stats!.totalProducts}', Icons.inventory_2_outlined)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMiniCard('Active', '${_stats!.activeProducts}', Icons.check_circle_outline)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildMiniCard('Orders', '${_stats!.totalOrders}', Icons.shopping_bag_outlined)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMiniCard('Pending', '${_stats!.pendingOrders}', Icons.pending_outlined)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildMiniCard('Views', '${_stats!.totalViews}', Icons.visibility_outlined)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMiniCard('Rating', _stats!.averageRating.toStringAsFixed(1), Icons.star_outline)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildMiniCard('Reviews', '${_stats!.totalReviews}', Icons.rate_review_outlined)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMiniCard('Completed', '${_stats!.completedOrders}', Icons.done_all)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Product status breakdown
                      const Text('Product Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimaryText)),
                      const SizedBox(height: 12),
                      _buildStatusBar(),

                      const SizedBox(height: 24),

                      // Conversion rate
                      _buildStatCard(
                        title: 'Conversion Rate',
                        value: _stats!.totalViews > 0
                            ? '${(_stats!.totalOrders / _stats!.totalViews * 100).toStringAsFixed(1)}%'
                            : '0%',
                        subtitle: '${_stats!.totalOrders} orders from ${_stats!.totalViews} views',
                        icon: Icons.trending_up,
                        color: const Color(0xFF2196F3),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard({required String title, required String value, String? subtitle, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: _kSecondaryText)),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _kPrimaryText)),
                if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 11, color: _kTertiaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _kTertiaryText),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kPrimaryText)),
          Text(label, style: const TextStyle(fontSize: 12, color: _kSecondaryText)),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    final total = _stats!.totalProducts;
    if (total == 0) return const Text('No products yet', style: TextStyle(color: _kTertiaryText));

    final segments = [
      ('Active', _stats!.activeProducts, const Color(0xFF4CAF50)),
      ('Draft', _stats!.draftProducts, const Color(0xFFFF9800)),
      ('Sold Out', _stats!.soldOutProducts, const Color(0xFFE53935)),
      ('Archived', _stats!.archivedProducts, const Color(0xFF9E9E9E)),
    ];

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: segments.where((s) => s.$2 > 0).map((s) {
              return Expanded(
                flex: s.$2,
                child: Container(height: 8, color: s.$3),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          children: segments.map((s) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: s.$3, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Text('${s.$1}: ${s.$2}', style: const TextStyle(fontSize: 12, color: _kSecondaryText)),
            ],
          )).toList(),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Wire analytics button from ShopGalleryWidget**

In `shop_gallery_widget.dart`, import and add navigation:

```dart
import '../../screens/shop/seller_analytics_screen.dart';

// In the stats header section, add an "Analytics" button:
  IconButton(
    icon: const Icon(Icons.analytics_outlined, color: Color(0xFF1A1A1A)),
    onPressed: () => Navigator.push(context, MaterialPageRoute(
      builder: (_) => SellerAnalyticsScreen(sellerId: widget.userId),
    )),
  ),
```

- [ ] **Step 3: Verify and commit**

```bash
flutter analyze lib/screens/shop/seller_analytics_screen.dart lib/widgets/gallery/shop_gallery_widget.dart
git add lib/screens/shop/seller_analytics_screen.dart lib/widgets/gallery/shop_gallery_widget.dart
git commit -m "feat(shop): add seller analytics dashboard — revenue, stats, conversion rate, product status"
```

---

### Task F2: Bulk order actions (confirm/ship multiple)

**Files:**
- Modify: `lib/screens/shop/seller_orders_screen.dart`
- Modify: `lib/services/shop_service.dart`

- [ ] **Step 1: Add multi-select state to SellerOrdersScreen**

Add state fields:

```dart
  bool _multiSelectMode = false;
  final Set<int> _selectedOrderIds = {};
```

- [ ] **Step 2: Add selection UI to order cards**

Wrap each order card's leading widget with a checkbox when in multi-select mode:

```dart
  Widget _buildOrderCard(Order order) {
    return GestureDetector(
      onLongPress: () {
        setState(() {
          _multiSelectMode = true;
          _selectedOrderIds.add(order.id);
        });
      },
      child: Container(
        // existing order card...
        // Add at the start of the Row:
        if (_multiSelectMode)
          Checkbox(
            value: _selectedOrderIds.contains(order.id),
            onChanged: (v) {
              setState(() {
                if (v == true) _selectedOrderIds.add(order.id);
                else _selectedOrderIds.remove(order.id);
                if (_selectedOrderIds.isEmpty) _multiSelectMode = false;
              });
            },
            activeColor: const Color(0xFF1A1A1A),
          ),
      ),
    );
  }
```

- [ ] **Step 3: Add bulk action bar**

Add a bottom bar when multi-select mode is active:

```dart
  Widget? _buildBulkActionBar() {
    if (!_multiSelectMode || _selectedOrderIds.isEmpty) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Text('${_selectedOrderIds.length} selected', style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() { _multiSelectMode = false; _selectedOrderIds.clear(); }),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _bulkUpdateStatus(OrderStatus.confirmed),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A)),
              child: const Text('Confirm All', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _bulkUpdateStatus(OrderStatus.shipped),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A)),
              child: const Text('Ship All', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bulkUpdateStatus(OrderStatus newStatus) async {
    setState(() => _isLoading = true);
    int successCount = 0;
    for (final orderId in _selectedOrderIds) {
      final result = await _shopService.updateOrderStatus(orderId, newStatus, userId: widget.sellerId);
      if (result.success) successCount++;
    }
    if (!mounted) return;
    setState(() {
      _multiSelectMode = false;
      _selectedOrderIds.clear();
    });
    _loadOrders();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Updated $successCount orders to ${newStatus.label}')),
    );
  }
```

Set `bottomNavigationBar: _buildBulkActionBar()` in the Scaffold.

- [ ] **Step 4: Verify and commit**

```bash
flutter analyze lib/screens/shop/seller_orders_screen.dart
git add lib/screens/shop/seller_orders_screen.dart
git commit -m "feat(shop): add bulk order actions — multi-select to confirm/ship orders"
```

---

### Task F3: Draft auto-save for product creation

**Files:**
- Modify: `lib/screens/shop/create_product_screen.dart`

- [ ] **Step 1: Add auto-save with debounce**

In `_CreateProductScreenState`, add:

```dart
  Timer? _autoSaveTimer;
  static const _draftKey = 'shop_product_draft';

  @override
  void initState() {
    super.initState();
    _loadDraft();
    // Add listeners for auto-save
    _titleController.addListener(_scheduleSave);
    _descriptionController.addListener(_scheduleSave);
    _priceController.addListener(_scheduleSave);
  }

  void _scheduleSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 3), _saveDraft);
  }

  Future<void> _saveDraft() async {
    final draft = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'price': _priceController.text,
      'compare_price': _comparePriceController.text,
      'stock': _stockController.text,
      'type': _productType.value,
      'condition': _condition.value,
      'category_id': _selectedCategoryId,
      'allow_pickup': _allowPickup,
      'allow_delivery': _allowDelivery,
      'allow_shipping': _allowShipping,
      'delivery_fee': _deliveryFeeController.text,
      'location': _locationController.text,
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode(draft));
    debugPrint('[CreateProduct] Draft auto-saved');
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_draftKey);
    if (json == null) return;
    try {
      final draft = jsonDecode(json) as Map<String, dynamic>;
      setState(() {
        _titleController.text = draft['title'] ?? '';
        _descriptionController.text = draft['description'] ?? '';
        _priceController.text = draft['price'] ?? '';
        _comparePriceController.text = draft['compare_price'] ?? '';
        _stockController.text = draft['stock'] ?? '';
        if (draft['type'] != null) _productType = ProductType.fromString(draft['type']);
        if (draft['condition'] != null) _condition = ProductCondition.fromString(draft['condition']);
        _selectedCategoryId = draft['category_id'];
        _allowPickup = draft['allow_pickup'] ?? true;
        _allowDelivery = draft['allow_delivery'] ?? false;
        _allowShipping = draft['allow_shipping'] ?? false;
        _deliveryFeeController.text = draft['delivery_fee'] ?? '';
        _locationController.text = draft['location'] ?? '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft restored'), duration: Duration(seconds: 2)),
      );
    } catch (_) {}
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }
```

Add import:

```dart
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
```

- [ ] **Step 2: Clear draft on successful submission**

In the existing `_submitProduct()` success handler, add:

```dart
    await _clearDraft();
```

- [ ] **Step 3: Dispose timer**

In `dispose()`:

```dart
    _autoSaveTimer?.cancel();
```

- [ ] **Step 4: Verify and commit**

```bash
flutter analyze lib/screens/shop/create_product_screen.dart
git add lib/screens/shop/create_product_screen.dart
git commit -m "feat(shop): add auto-save draft for product creation — survives back navigation and restarts"
```

---

## SUB-PROJECT G: Retention & Social Commerce

**Goal:** Add flash deals with countdown timers, reorder/buy-again, product sharing via deep links, and first-purchase coupon.

---

### Task G1: Flash deals screen with countdown timers

**Files:**
- Create: `lib/screens/shop/flash_deals_screen.dart`
- Modify: `lib/screens/shop/shop_screen.dart`
- Modify: `lib/services/shop_service.dart`

- [ ] **Step 1: Add getFlashDeals to ShopService**

```dart
  /// Get active flash deals
  Future<ProductListResult> getFlashDeals({int page = 1, int perPage = 20}) async {
    final url = '$_baseUrl/shop/flash-deals?page=$page&per_page=$perPage';
    _logRequest('GET', url);
    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _logResponse(response.statusCode, data);
      if (response.statusCode == 200 && data['success'] == true) {
        final items = data['data'] is List ? data['data'] as List : (data['data']?['items'] as List?) ?? [];
        final products = items.map((j) => Product.fromJson(j as Map<String, dynamic>)).toList();
        return ProductListResult(success: true, products: products);
      }
      return ProductListResult(success: false, message: data['message']?.toString());
    } catch (e) {
      return ProductListResult(success: false, message: 'Failed to load deals: $e');
    }
  }
```

- [ ] **Step 2: Create FlashDealsScreen**

```dart
// lib/screens/shop/flash_deals_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/shop_models.dart';
import '../../services/shop_service.dart';
import '../../widgets/shop/product_card.dart';

const Color _kBackground = Color(0xFFFAFAFA);
const Color _kPrimaryText = Color(0xFF1A1A1A);

class FlashDealsScreen extends StatefulWidget {
  final int currentUserId;
  const FlashDealsScreen({super.key, required this.currentUserId});

  @override
  State<FlashDealsScreen> createState() => _FlashDealsScreenState();
}

class _FlashDealsScreenState extends State<FlashDealsScreen> {
  final ShopService _shopService = ShopService();
  List<Product> _deals = [];
  bool _isLoading = true;
  Timer? _countdownTimer;
  Duration _timeLeft = const Duration(hours: 12); // Placeholder — get from API

  @override
  void initState() {
    super.initState();
    _loadDeals();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeLeft.inSeconds > 0) {
        setState(() => _timeLeft -= const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDeals() async {
    final result = await _shopService.getFlashDeals();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _deals = result.products ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = _timeLeft.inHours.toString().padLeft(2, '0');
    final minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text('Flash Deals', style: TextStyle(color: _kPrimaryText)),
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimaryText),
      ),
      body: Column(
        children: [
          // Countdown banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: _kPrimaryText,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flash_on, color: Color(0xFFFFB800), size: 20),
                const SizedBox(width: 8),
                const Text('Ends in  ', style: TextStyle(color: Colors.white, fontSize: 14)),
                _buildTimeBox(hours),
                const Text(' : ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                _buildTimeBox(minutes),
                const Text(' : ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                _buildTimeBox(seconds),
              ],
            ),
          ),
          // Deals grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _deals.isEmpty
                    ? const Center(child: Text('No active deals', style: TextStyle(color: Color(0xFF999999))))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _deals.length,
                        itemBuilder: (context, index) {
                          return ProductCard(
                            product: _deals[index],
                            onTap: () => Navigator.pushNamed(context, '/shop/product/${_deals[index].id}',
                                arguments: {'productId': _deals[index].id, 'currentUserId': widget.currentUserId}),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(4)),
      child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'monospace')),
    );
  }
}
```

- [ ] **Step 3: Add flash deals banner to ShopScreen**

In `shop_screen.dart`, add a "Flash Deals" banner section between the featured banner and product grid:

```dart
  Widget _buildFlashDealsBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => FlashDealsScreen(currentUserId: widget.currentUserId),
      )),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: const [
            Icon(Icons.flash_on, color: Color(0xFFFFB800), size: 24),
            SizedBox(width: 8),
            Text('Flash Deals', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Spacer(),
            Text('View All →', style: TextStyle(color: Color(0xFFFFB800), fontSize: 13)),
          ],
        ),
      ),
    );
  }
```

Add import:

```dart
import 'flash_deals_screen.dart';
```

- [ ] **Step 4: Verify and commit**

```bash
flutter analyze lib/screens/shop/flash_deals_screen.dart lib/screens/shop/shop_screen.dart lib/services/shop_service.dart
git add lib/screens/shop/flash_deals_screen.dart lib/screens/shop/shop_screen.dart lib/services/shop_service.dart
git commit -m "feat(shop): add flash deals screen with countdown timer and shop home banner"
```

---

### Task G2: Product sharing via WhatsApp/system share

**Files:**
- Modify: `lib/screens/shop/product_detail_screen.dart`
- Modify: `lib/widgets/shop/product_card.dart`

- [ ] **Step 1: The share button was already added in Task B4. Enhance it with a deep link:**

In `product_detail_screen.dart`, update the share onPressed:

```dart
  void _shareProduct() {
    if (_product == null) return;
    final url = 'https://tajiri.co.tz/shop/product/${_product!.id}';
    final text = '${_product!.title}\n${_product!.currency} ${_product!.price.toStringAsFixed(0)}\n\n$url';
    Share.share(text, subject: _product!.title);
  }
```

- [ ] **Step 2: Add share to product card long-press**

In `product_card.dart`, wrap the existing `GestureDetector`/`InkWell` with a long-press handler:

```dart
  onLongPress: () {
    Share.share(
      '${product.title}\n${product.currency} ${product.price.toStringAsFixed(0)}\nhttps://tajiri.co.tz/shop/product/${product.id}',
      subject: product.title,
    );
  },
```

Add import:

```dart
import 'package:share_plus/share_plus.dart';
```

- [ ] **Step 3: Verify and commit**

```bash
flutter analyze lib/screens/shop/product_detail_screen.dart lib/widgets/shop/product_card.dart
git add lib/screens/shop/product_detail_screen.dart lib/widgets/shop/product_card.dart
git commit -m "feat(shop): enhance product sharing with deep links — tap to share on PDP, long-press on cards"
```

---

### Task G3: Reorder / Buy Again

**Files:**
- Modify: `lib/screens/shop/order_detail_screen.dart`

- [ ] **Step 1: Add "Buy Again" button to completed/delivered orders**

In `order_detail_screen.dart`, add the buy again action:

```dart
  void _buyAgain() {
    if (_order?.product == null) return;
    Navigator.pushNamed(context, '/shop/checkout', arguments: {
      'product': _order!.product,
      'quantity': _order!.quantity,
    });
  }
```

Add the button in the actions section for delivered/completed orders:

```dart
  if (_order != null &&
      _order!.buyerId == widget.currentUserId &&
      (_order!.status == OrderStatus.delivered || _order!.status == OrderStatus.completed))
    ElevatedButton.icon(
      onPressed: _buyAgain,
      icon: const Icon(Icons.replay, size: 18),
      label: const Text('Buy Again'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
```

- [ ] **Step 2: Verify and commit**

```bash
flutter analyze lib/screens/shop/order_detail_screen.dart
git add lib/screens/shop/order_detail_screen.dart
git commit -m "feat(shop): add 'Buy Again' reorder button on completed order detail"
```

---

## SUB-PROJECT H: Polish & UX

**Goal:** Add optimistic UI for cart/favorite, haptic feedback, hero transitions, and skeleton loaders across Shop screens.

---

### Task H1: Add Product.copyWith() and optimistic favorite toggle

**Files:**
- Modify: `lib/models/shop_models.dart` (add `copyWith()` to Product)
- Modify: `lib/screens/shop/product_detail_screen.dart`

- [ ] **Step 1: Add `copyWith()` method to Product class**

In `lib/models/shop_models.dart`, add this method to the `Product` class (after `toJson()`):

```dart
  Product copyWith({
    int? id,
    int? sellerId,
    String? title,
    String? description,
    String? slug,
    ProductType? type,
    ProductStatus? status,
    double? price,
    double? compareAtPrice,
    String? currency,
    int? stockQuantity,
    List<String>? images,
    String? thumbnailPath,
    int? categoryId,
    List<String>? tags,
    ProductCondition? condition,
    String? locationName,
    double? latitude,
    double? longitude,
    bool? allowPickup,
    bool? allowDelivery,
    bool? allowShipping,
    double? deliveryFee,
    String? deliveryNotes,
    String? pickupAddress,
    String? downloadUrl,
    int? downloadLimit,
    int? durationMinutes,
    String? serviceLocation,
    int? viewsCount,
    int? favoritesCount,
    int? ordersCount,
    double? rating,
    int? reviewsCount,
    ProductSeller? seller,
    ProductCategory? category,
    bool? isFavorited,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      description: description ?? this.description,
      slug: slug ?? this.slug,
      type: type ?? this.type,
      status: status ?? this.status,
      price: price ?? this.price,
      compareAtPrice: compareAtPrice ?? this.compareAtPrice,
      currency: currency ?? this.currency,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      images: images ?? this.images,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      condition: condition ?? this.condition,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      allowPickup: allowPickup ?? this.allowPickup,
      allowDelivery: allowDelivery ?? this.allowDelivery,
      allowShipping: allowShipping ?? this.allowShipping,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      downloadLimit: downloadLimit ?? this.downloadLimit,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      serviceLocation: serviceLocation ?? this.serviceLocation,
      viewsCount: viewsCount ?? this.viewsCount,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      ordersCount: ordersCount ?? this.ordersCount,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      seller: seller ?? this.seller,
      category: category ?? this.category,
      isFavorited: isFavorited ?? this.isFavorited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
```

- [ ] **Step 2: Make favorite toggle optimistic in PDP**

In `product_detail_screen.dart`, add imports and update the favorite toggle:

```dart
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../services/shop_database.dart';
```

```dart
  Future<void> _toggleFavorite() async {
    if (_product == null) return;
    final wasFavorited = _product!.isFavorited;

    // Optimistic update
    setState(() {
      _product = _product!.copyWith(
        isFavorited: !wasFavorited,
        favoritesCount: _product!.favoritesCount + (wasFavorited ? -1 : 1),
      );
    });
    HapticFeedback.lightImpact();

    // API call in background
    final result = await _shopService.toggleFavorite(widget.currentUserId, _product!.id);
    if (!result.success && mounted) {
      // Revert on failure
      setState(() {
        _product = _product!.copyWith(
          isFavorited: wasFavorited,
          favoritesCount: _product!.favoritesCount + (wasFavorited ? 1 : -1),
        );
      });
    }

    // Sync SQLite wishlist
    if (!wasFavorited) {
      await ShopDatabase.instance.addToWishlist(_product!.id, _product!.price, jsonEncode(_product!.toJson()));
    } else {
      await ShopDatabase.instance.removeFromWishlist(_product!.id);
    }
  }
```

- [ ] **Step 3: Verify and commit**

```bash
flutter analyze lib/models/shop_models.dart lib/screens/shop/product_detail_screen.dart
git add lib/models/shop_models.dart lib/screens/shop/product_detail_screen.dart
git commit -m "feat(shop): add Product.copyWith(), optimistic favorite toggle with haptic + SQLite sync"
```

---

### Task H2: Haptic feedback on key actions

**Files:**
- Modify: `lib/screens/shop/cart_screen.dart`
- Modify: `lib/widgets/shop/product_card.dart`

- [ ] **Step 1: Add haptics to cart actions**

In `cart_screen.dart`, add import at the top:

```dart
import 'package:flutter/services.dart';
```

Then add `HapticFeedback.lightImpact()` as the first line in each of these methods/callbacks. For quantity buttons, wrap the existing onPressed:

```dart
// Before each _updateQuantity call (the +/- buttons):
onPressed: () {
  HapticFeedback.lightImpact();
  _updateQuantity(item, newQty);
},

// Before each _removeItem call (swipe dismiss or delete button):
onDismissed: (_) {
  HapticFeedback.mediumImpact();
  _removeItem(item);
},

// At the start of _checkout():
Future<void> _checkout() async {
  HapticFeedback.heavyImpact();
  // ... existing checkout logic
}
```

- [ ] **Step 2: Add haptics to product card favorite**

In `product_card.dart`, add import:

```dart
import 'package:flutter/services.dart';
```

Wrap the existing `onFavorite` callback in the favorite icon button:

```dart
onPressed: () {
  HapticFeedback.selectionClick();
  widget.onFavorite?.call();
},
```

- [ ] **Step 3: Verify and commit**

```bash
flutter analyze lib/screens/shop/cart_screen.dart lib/widgets/shop/product_card.dart
git add lib/screens/shop/cart_screen.dart lib/widgets/shop/product_card.dart
git commit -m "feat(shop): add haptic feedback on cart actions and product card interactions"
```

---

### Task H3: Hero transitions between product grid and PDP

**Files:**
- Modify: `lib/widgets/shop/product_card.dart`
- Modify: `lib/screens/shop/product_detail_screen.dart`

- [ ] **Step 1: Wrap product card image in Hero**

In `product_card.dart`, wrap the image widget with Hero:

```dart
  Hero(
    tag: 'product_image_${product.id}',
    child: // existing CachedMediaImage
  ),
```

- [ ] **Step 2: Wrap PDP image in matching Hero**

In `product_detail_screen.dart`, wrap the first image in the gallery with:

```dart
  Hero(
    tag: 'product_image_${widget.productId}',
    child: // existing image widget
  ),
```

- [ ] **Step 3: Verify and commit**

```bash
flutter analyze lib/widgets/shop/product_card.dart lib/screens/shop/product_detail_screen.dart
git add lib/widgets/shop/product_card.dart lib/screens/shop/product_detail_screen.dart
git commit -m "feat(shop): add Hero transition animation between product grid and detail page"
```

---

### Task H4: Skeleton loaders on all shop screens

**Files:**
- Modify: `lib/screens/shop/shop_screen.dart`
- Modify: `lib/screens/shop/product_detail_screen.dart`
- Modify: `lib/screens/shop/cart_screen.dart`

- [ ] **Step 1: Add shimmer loader helper**

In each screen, replace `CircularProgressIndicator()` with skeleton shimmer. Add a reusable shimmer builder as a private method:

```dart
  Widget _buildShimmer({double width = double.infinity, double height = 16, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildProductGridShimmer() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Expanded(flex: 3, child: _buildShimmer(height: double.infinity, radius: 16)),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmer(width: 120, height: 12),
                    const SizedBox(height: 6),
                    _buildShimmer(width: 80, height: 14),
                    const SizedBox(height: 6),
                    _buildShimmer(width: 60, height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 2: Replace loading spinners with skeletons**

In `shop_screen.dart`, replace `_isLoading ? Center(child: CircularProgressIndicator()) : ...` with `_isLoading ? _buildProductGridShimmer() : ...`.

In `product_detail_screen.dart`, add a PDP shimmer and replace the loading state:

```dart
  Widget _buildPdpShimmer() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmer(height: 300, radius: 0), // image area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmer(width: 200, height: 20),
                const SizedBox(height: 12),
                _buildShimmer(width: 120, height: 24),
                const SizedBox(height: 16),
                _buildShimmer(height: 14),
                const SizedBox(height: 8),
                _buildShimmer(height: 14),
                const SizedBox(height: 8),
                _buildShimmer(width: 180, height: 14),
                const SizedBox(height: 24),
                _buildShimmer(height: 48, radius: 12), // button placeholder
              ],
            ),
          ),
        ],
      ),
    );
  }
```

Replace: `_isLoading ? Center(child: CircularProgressIndicator()) : ...` with `_isLoading ? _buildPdpShimmer() : ...`

In `cart_screen.dart`, add a cart shimmer and replace the loading state:

```dart
  Widget _buildCartShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 3,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            _buildShimmer(width: 80, height: 80, radius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmer(width: 140, height: 14),
                  const SizedBox(height: 8),
                  _buildShimmer(width: 80, height: 16),
                  const SizedBox(height: 8),
                  _buildShimmer(width: 100, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
```

Replace: `_isLoading ? Center(child: CircularProgressIndicator()) : ...` with `_isLoading ? _buildCartShimmer() : ...`

- [ ] **Step 3: Verify and commit**

```bash
flutter analyze lib/screens/shop/shop_screen.dart lib/screens/shop/product_detail_screen.dart lib/screens/shop/cart_screen.dart
git add lib/screens/shop/shop_screen.dart lib/screens/shop/product_detail_screen.dart lib/screens/shop/cart_screen.dart
git commit -m "feat(shop): replace loading spinners with skeleton shimmer loaders on all shop screens"
```

---

## Summary

| Sub-Project | Tasks | Key Deliverable |
|-------------|-------|-----------------|
| **A: SQLite Foundation** | A1-A7 | `ShopDatabase` + `LazyIndexedStack` + SQLite-first reads |
| **B: PDP Quick Wins** | B1-B4 | Sticky CTA, reviews, stock urgency, zoom, share |
| **C: Payments** | C1-C3 | M-Pesa payment, buyer protection, returns |
| **D: Discovery** | D1-D4 | Filters, FTS5 search, recently viewed, wishlist |
| **E: Checkout & Orders** | E1-E2 | Promo codes, order tracking timeline |
| **F: Seller Tools** | F1-F3 | Analytics dashboard, bulk actions, draft auto-save |
| **G: Retention** | G1-G3 | Flash deals, sharing, buy again |
| **H: Polish** | H1-H4 | Optimistic UI, haptics, hero transitions, skeletons |

**Total:** 24 tasks across 3 plan documents.

**Execution order:** A + B parallel → D + C parallel → E + F parallel → G + H parallel.

**Expected outcome:** TAJIRI Shop score from **1.95/10 → ~6/10** with SQLite-powered instant UI, trust signals, multiple payment methods, advanced discovery, seller analytics, retention hooks, and polished UX.
