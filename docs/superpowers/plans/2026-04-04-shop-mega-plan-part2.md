# TAJIRI Shop Mega Plan — Part 2: Payments, Discovery, Checkout & Orders

> **Continuation of:** `docs/superpowers/plans/2026-04-04-shop-mega-plan.md`
> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

---

## SUB-PROJECT C: Payments & Buyer Protection

**Goal:** Add M-Pesa direct payment, escrow/buyer protection, and return/refund initiation. Currently only TAJIRI Wallet PIN is supported.

---

### Task C1: Add M-Pesa payment option to checkout

**Files:**
- Modify: `lib/screens/shop/checkout_screen.dart`
- Modify: `lib/services/shop_service.dart`

- [ ] **Step 1: Add payment method enum and state**

In `checkout_screen.dart`, add at the top of `_CheckoutScreenState`:

```dart
  String _paymentMethod = 'wallet'; // 'wallet' | 'mpesa'
  final TextEditingController _mpesaPhoneController = TextEditingController();
```

- [ ] **Step 2: Add payment method selector UI**

Add a payment method picker section before the PIN/payment button. Insert in the build method:

```dart
  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        ),
        RadioListTile<String>(
          value: 'wallet',
          groupValue: _paymentMethod,
          onChanged: (v) => setState(() => _paymentMethod = v!),
          title: const Text('TAJIRI Wallet'),
          subtitle: const Text('Pay with your wallet balance'),
          secondary: const Icon(Icons.account_balance_wallet_outlined),
          activeColor: const Color(0xFF1A1A1A),
        ),
        RadioListTile<String>(
          value: 'mpesa',
          groupValue: _paymentMethod,
          onChanged: (v) => setState(() => _paymentMethod = v!),
          title: const Text('M-Pesa'),
          subtitle: const Text('Pay via Vodacom M-Pesa'),
          secondary: const Icon(Icons.phone_android_outlined),
          activeColor: const Color(0xFF1A1A1A),
        ),
        if (_paymentMethod == 'mpesa')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _mpesaPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'M-Pesa Phone Number',
                hintText: '+255 7XX XXX XXX',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ),
      ],
    );
  }
```

- [ ] **Step 3: Modify _processPayment to handle M-Pesa**

Update the `_processPayment()` method to branch on `_paymentMethod`:

```dart
  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    try {
      if (_paymentMethod == 'mpesa') {
        // M-Pesa payment via STK push
        final phone = _mpesaPhoneController.text.trim();
        if (phone.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter M-Pesa phone number')),
          );
          return;
        }
        // Call M-Pesa checkout endpoint
        final result = widget.cart != null
            ? await _shopService.checkout(
                userId: widget.currentUserId,
                items: _buildCheckoutItems(),
                paymentMethod: 'mpesa',
                mpesaPhone: phone,
              )
            : await _shopService.createOrder(
                userId: widget.currentUserId,
                productId: widget.product!.id,
                quantity: widget.quantity ?? 1,
                deliveryMethod: widget.deliveryMethod ?? DeliveryMethod.pickup,
                deliveryAddress: _addressController.text.isNotEmpty ? _addressController.text : null,
                deliveryNotes: _notesController.text.isNotEmpty ? _notesController.text : null,
                paymentMethod: 'mpesa',
                mpesaPhone: phone,
              );
        if (!mounted) return;
        if ((result is OrderListResult && result.success) || (result is OrderResult && result.success)) {
          _showSuccessDialog(result);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? 'Payment failed')),
          );
        }
      } else {
        // Existing wallet PIN flow
        _showPinDialog();
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
```

- [ ] **Step 4: Update ShopService.createOrder() and checkout() to accept paymentMethod and mpesaPhone**

In `shop_service.dart`, update `createOrder()` signature and body:

```dart
  Future<OrderResult> createOrder({
    required int userId,
    required int productId,
    required int quantity,
    required DeliveryMethod deliveryMethod,
    String? deliveryAddress,
    String? deliveryNotes,
    String? pin,
    String paymentMethod = 'wallet',
    String? mpesaPhone,
  }) async {
    // ... existing code ...
    // Add to body map:
    // 'payment_method': paymentMethod,
    // if (mpesaPhone != null) 'mpesa_phone': mpesaPhone,
  }
```

Similarly update `checkout()`:

```dart
  Future<OrderListResult> checkout({
    required int userId,
    required List<CheckoutItem> items,
    String? pin,
    String paymentMethod = 'wallet',
    String? mpesaPhone,
  }) async {
    // ... existing code ...
    // Add to body map:
    // 'payment_method': paymentMethod,
    // if (mpesaPhone != null) 'mpesa_phone': mpesaPhone,
  }
```

- [ ] **Step 5: Backend request**

```bash
./scripts/ask_backend.sh "Add M-Pesa payment support to POST /shop/orders and POST /shop/checkout.
Accept optional 'payment_method' field ('wallet' or 'mpesa') and 'mpesa_phone' field.
When payment_method is 'mpesa':
1. Initiate M-Pesa STK push to the provided phone number for the order total
2. Create order with status 'pending_payment'
3. On M-Pesa callback confirmation, update order status to 'pending'
4. Return order with payment_status field
Keep existing wallet PIN flow as default."
```

- [ ] **Step 6: Verify and commit**

```bash
flutter analyze lib/screens/shop/checkout_screen.dart lib/services/shop_service.dart
git add lib/screens/shop/checkout_screen.dart lib/services/shop_service.dart
git commit -m "feat(shop): add M-Pesa payment option alongside TAJIRI Wallet"
```

---

### Task C2: Buyer protection badge and escrow indicator

**Files:**
- Modify: `lib/screens/shop/product_detail_screen.dart`
- Modify: `lib/screens/shop/checkout_screen.dart`

- [ ] **Step 1: Add buyer protection banner to PDP**

In `product_detail_screen.dart`, add after the seller card section:

```dart
  Widget _buildBuyerProtectionBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: Color(0xFF4CAF50), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Buyer Protection', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                SizedBox(height: 2),
                Text('Money held securely until you confirm delivery', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
              ],
            ),
          ),
        ],
      ),
    );
  }
```

Insert `_buildBuyerProtectionBanner()` in the PDP body after the price section.

- [ ] **Step 2: Add escrow notice to checkout**

In `checkout_screen.dart`, add before the payment button:

```dart
  Widget _buildEscrowNotice() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: const [
          Icon(Icons.lock_outline, size: 20, color: Color(0xFF666666)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your payment is protected. Funds are held securely and released to the seller only after you confirm delivery.',
              style: TextStyle(fontSize: 12, color: Color(0xFF666666), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 3: Verify and commit**

```bash
flutter analyze lib/screens/shop/product_detail_screen.dart lib/screens/shop/checkout_screen.dart
git add lib/screens/shop/product_detail_screen.dart lib/screens/shop/checkout_screen.dart
git commit -m "feat(shop): add buyer protection badge on PDP and escrow notice on checkout"
```

---

### Task C3: Return/refund initiation flow

**Files:**
- Modify: `lib/screens/shop/order_detail_screen.dart`
- Modify: `lib/services/shop_service.dart`

- [ ] **Step 1: Add return request method to ShopService**

```dart
  /// Request a return/refund for an order
  Future<OrderResult> requestReturn({
    required int orderId,
    required int userId,
    required String reason,
    List<String>? imageUrls,
  }) async {
    final url = '$_baseUrl/shop/orders/$orderId/return';
    _logRequest('POST', url);
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.authHeaders(await _getToken()),
        body: jsonEncode({
          'user_id': userId,
          'reason': reason,
          if (imageUrls != null) 'images': imageUrls,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _logResponse(response.statusCode, data);
      if (response.statusCode == 200 && data['success'] == true) {
        return OrderResult(success: true, order: Order.fromJson(data['data']), message: data['message']?.toString());
      }
      return OrderResult(success: false, message: data['message']?.toString() ?? 'Return request failed');
    } catch (e) {
      _logError('POST', url, e);
      return OrderResult(success: false, message: 'Failed to submit return request: $e');
    }
  }
```

- [ ] **Step 2: Add return request dialog to OrderDetailScreen**

In `order_detail_screen.dart`, add the method:

```dart
  void _showReturnDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Return/Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please describe why you want to return this item:', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Reason for return...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A)),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _isActioning = true);
              final result = await _shopService.requestReturn(
                orderId: widget.orderId,
                userId: widget.currentUserId,
                reason: reasonController.text.trim(),
              );
              if (!mounted) return;
              setState(() => _isActioning = false);
              if (result.success && result.order != null) {
                setState(() => _order = result.order);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Return request submitted')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.message ?? 'Failed')),
                );
              }
            },
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 3: Add "Request Return" button to order detail**

In the action buttons section of order_detail_screen.dart, add the return button for delivered/completed orders (buyer only):

```dart
if (_order != null &&
    _order!.buyerId == widget.currentUserId &&
    (_order!.status == OrderStatus.delivered || _order!.status == OrderStatus.completed))
  OutlinedButton.icon(
    onPressed: _isActioning ? null : _showReturnDialog,
    icon: const Icon(Icons.assignment_return_outlined),
    label: const Text('Request Return'),
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFE53935),
      side: const BorderSide(color: Color(0xFFE53935)),
    ),
  ),
```

- [ ] **Step 4: Backend request**

```bash
./scripts/ask_backend.sh "Add return/refund endpoint: POST /shop/orders/{orderId}/return.
Accept: user_id (buyer), reason (text), optional images[] (URLs).
Validation: only buyer can request, order must be delivered or completed, max 1 active return per order.
Create a 'returns' table: id, order_id, user_id, reason, status (pending/approved/rejected/refunded), images JSON, created_at.
Update order status to 'return_requested' on creation.
Return the updated order with return details."
```

- [ ] **Step 5: Verify and commit**

```bash
flutter analyze lib/screens/shop/order_detail_screen.dart lib/services/shop_service.dart
git add lib/screens/shop/order_detail_screen.dart lib/services/shop_service.dart
git commit -m "feat(shop): add return/refund request flow for buyers on delivered orders"
```

---

## SUB-PROJECT D: Discovery & Search

**Goal:** Add advanced filters, FTS5-powered search autocomplete, recently viewed products, and a dedicated wishlist screen. Depends on Sub-project A (SQLite).

---

### Task D1: Advanced filter bottom sheet

**Files:**
- Create: `lib/widgets/shop/filter_bottom_sheet.dart`
- Modify: `lib/screens/shop/shop_screen.dart`

- [ ] **Step 1: Create the filter bottom sheet**

```dart
// lib/widgets/shop/filter_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../../models/shop_models.dart';

const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kDivider = Color(0xFFE0E0E0);

class ShopFilterResult {
  final double? minPrice;
  final double? maxPrice;
  final ProductCondition? condition;
  final double? minRating;
  final ProductType? type;

  const ShopFilterResult({this.minPrice, this.maxPrice, this.condition, this.minRating, this.type});
}

class FilterBottomSheet extends StatefulWidget {
  final ShopFilterResult? currentFilters;
  final void Function(ShopFilterResult) onApply;

  const FilterBottomSheet({super.key, this.currentFilters, required this.onApply});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late RangeValues _priceRange;
  ProductCondition? _condition;
  double? _minRating;
  ProductType? _type;

  @override
  void initState() {
    super.initState();
    _priceRange = RangeValues(
      widget.currentFilters?.minPrice ?? 0,
      widget.currentFilters?.maxPrice ?? 5000000,
    );
    _condition = widget.currentFilters?.condition;
    _minRating = widget.currentFilters?.minRating;
    _type = widget.currentFilters?.type;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimaryText)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _priceRange = const RangeValues(0, 5000000);
                    _condition = null;
                    _minRating = null;
                    _type = null;
                  });
                },
                child: const Text('Clear All', style: TextStyle(color: Color(0xFF999999))),
              ),
            ],
          ),
          const Divider(color: _kDivider),

          // Price range
          const SizedBox(height: 8),
          const Text('Price Range (TZS)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 5000000,
            divisions: 100,
            activeColor: _kPrimaryText,
            labels: RangeLabels(
              '${(_priceRange.start / 1000).toStringAsFixed(0)}K',
              '${(_priceRange.end / 1000).toStringAsFixed(0)}K',
            ),
            onChanged: (v) => setState(() => _priceRange = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(_priceRange.start / 1000).toStringAsFixed(0)}K TZS', style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
              Text('${(_priceRange.end / 1000).toStringAsFixed(0)}K TZS', style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
            ],
          ),

          // Condition
          const SizedBox(height: 16),
          const Text('Condition', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [null, ...ProductCondition.values].map((c) {
              final selected = _condition == c;
              final label = c == null ? 'All' : c == ProductCondition.brandNew ? 'New' : c == ProductCondition.used ? 'Used' : 'Refurbished';
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                selectedColor: _kPrimaryText,
                labelStyle: TextStyle(color: selected ? Colors.white : _kPrimaryText),
                onSelected: (_) => setState(() => _condition = c),
              );
            }).toList(),
          ),

          // Rating
          const SizedBox(height: 16),
          const Text('Minimum Rating', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [null, 4.0, 3.0, 2.0, 1.0].map((r) {
              final selected = _minRating == r;
              final label = r == null ? 'Any' : '${r.toStringAsFixed(0)}+ ★';
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                selectedColor: _kPrimaryText,
                labelStyle: TextStyle(color: selected ? Colors.white : _kPrimaryText),
                onSelected: (_) => setState(() => _minRating = r),
              );
            }).toList(),
          ),

          // Apply button
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(ShopFilterResult(
                  minPrice: _priceRange.start > 0 ? _priceRange.start : null,
                  maxPrice: _priceRange.end < 5000000 ? _priceRange.end : null,
                  condition: _condition,
                  minRating: _minRating,
                  type: _type,
                ));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryText,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Wire filter into ShopScreen**

In `shop_screen.dart`, import:

```dart
import '../../widgets/shop/filter_bottom_sheet.dart';
```

Add state field:

```dart
  ShopFilterResult? _activeFilters;
```

Add filter button next to sort button and wire to show bottom sheet:

```dart
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(
        currentFilters: _activeFilters,
        onApply: (filters) {
          setState(() => _activeFilters = filters);
          _loadProducts(refresh: true);
        },
      ),
    );
  }
```

Update `_loadProducts()` to pass filter values to `loadProductsCached()` or `getProducts()`:

```dart
    minPrice: _activeFilters?.minPrice,
    maxPrice: _activeFilters?.maxPrice,
    condition: _activeFilters?.condition?.value,
```

- [ ] **Step 3: Verify and commit**

```bash
flutter analyze lib/widgets/shop/filter_bottom_sheet.dart lib/screens/shop/shop_screen.dart
git add lib/widgets/shop/filter_bottom_sheet.dart lib/screens/shop/shop_screen.dart
git commit -m "feat(shop): add advanced filter bottom sheet — price range, condition, rating"
```

---

### Task D2: Search suggestions with FTS5 + search history

**Files:**
- Create: `lib/widgets/shop/search_suggestions.dart`
- Modify: `lib/screens/shop/shop_screen.dart`

- [ ] **Step 1: Create search suggestions overlay widget**

```dart
// lib/widgets/shop/search_suggestions.dart
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../services/shop_database.dart';
import '../../models/shop_models.dart';

const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kTertiaryText = Color(0xFF999999);

class SearchSuggestions extends StatefulWidget {
  final String query;
  final void Function(String query) onSelect;
  final VoidCallback? onClearHistory;

  const SearchSuggestions({super.key, required this.query, required this.onSelect, this.onClearHistory});

  @override
  State<SearchSuggestions> createState() => _SearchSuggestionsState();
}

class _SearchSuggestionsState extends State<SearchSuggestions> {
  final ShopDatabase _db = ShopDatabase.instance;
  List<String> _history = [];
  List<Product> _localResults = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(SearchSuggestions old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query) _load();
  }

  Future<void> _load() async {
    if (widget.query.isEmpty) {
      final history = await _db.getSearchHistory(limit: 10);
      if (mounted) setState(() { _history = history; _localResults = []; });
    } else {
      final results = await _db.searchProducts(widget.query, limit: 5);
      if (mounted) setState(() { _localResults = results; _history = []; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.query.isEmpty && _history.isEmpty) return const SizedBox.shrink();
    if (widget.query.isNotEmpty && _localResults.isEmpty) return const SizedBox.shrink();

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          children: [
            if (widget.query.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Row(
                  children: [
                    const Text('Recent Searches', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondaryText)),
                    const Spacer(),
                    if (widget.onClearHistory != null)
                      GestureDetector(
                        onTap: widget.onClearHistory,
                        child: const Text('Clear', style: TextStyle(fontSize: 12, color: _kTertiaryText)),
                      ),
                  ],
                ),
              ),
              ..._history.map((q) => ListTile(
                dense: true,
                leading: const HeroIcon(HeroIcons.clock, size: 18, color: _kTertiaryText),
                title: Text(q, style: const TextStyle(fontSize: 14, color: _kPrimaryText)),
                onTap: () => widget.onSelect(q),
              )),
            ] else ...[
              ..._localResults.map((p) => ListTile(
                dense: true,
                leading: const HeroIcon(HeroIcons.magnifyingGlass, size: 18, color: _kTertiaryText),
                title: Text(p.title, style: const TextStyle(fontSize: 14, color: _kPrimaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text('${p.currency} ${p.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: _kSecondaryText)),
                onTap: () => widget.onSelect(p.title),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Wire into ShopScreen search field**

In `shop_screen.dart`, import:

```dart
import '../../widgets/shop/search_suggestions.dart';
```

Add state:

```dart
  bool _showSuggestions = false;
```

Wrap the search TextField in a Column and add suggestions below it:

```dart
  // In the search field's onChanged:
  _showSuggestions = true;

  // Below the search field:
  if (_showSuggestions)
    SearchSuggestions(
      query: _searchController.text,
      onSelect: (query) {
        _searchController.text = query;
        setState(() => _showSuggestions = false);
        _onSearchChanged(query);
      },
      onClearHistory: () async {
        await ShopDatabase.instance.clearSearchHistory();
        setState(() {});
      },
    ),
```

- [ ] **Step 3: Verify and commit**

```bash
flutter analyze lib/widgets/shop/search_suggestions.dart lib/screens/shop/shop_screen.dart
git add lib/widgets/shop/search_suggestions.dart lib/screens/shop/shop_screen.dart
git commit -m "feat(shop): add FTS5-powered search suggestions with search history"
```

---

### Task D3: Recently viewed products bar

**Files:**
- Modify: `lib/screens/shop/shop_screen.dart`
- Modify: `lib/screens/shop/product_detail_screen.dart`

- [ ] **Step 1: Record product view when PDP opens**

In `product_detail_screen.dart`, in `_loadProduct()` after successful load, add:

```dart
    // Record view in SQLite for recently viewed
    ShopDatabase.instance.markViewed(_product!.id);
```

Add import:

```dart
import '../../services/shop_database.dart';
```

- [ ] **Step 2: Add recently viewed section to ShopScreen**

In `shop_screen.dart`, add state:

```dart
  List<Product> _recentlyViewed = [];
```

In `_loadInitialData()`, add:

```dart
  _loadRecentlyViewed();
```

Add method:

```dart
  Future<void> _loadRecentlyViewed() async {
    try {
      final products = await ShopDatabase.instance.getRecentlyViewed(limit: 10);
      if (mounted) setState(() => _recentlyViewed = products);
    } catch (_) {}
  }
```

Add horizontal scroll section in the build method (after categories, before product grid):

```dart
  Widget _buildRecentlyViewed() {
    if (_recentlyViewed.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text('Recently Viewed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _recentlyViewed.length,
            itemBuilder: (context, index) {
              final product = _recentlyViewed[index];
              return SizedBox(
                width: 140,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ProductCard(
                    product: product,
                    compact: true,
                    onTap: () => Navigator.pushNamed(context, '/shop/product/${product.id}', arguments: {'productId': product.id, 'currentUserId': widget.currentUserId}),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
```

- [ ] **Step 3: Verify and commit**

```bash
flutter analyze lib/screens/shop/shop_screen.dart lib/screens/shop/product_detail_screen.dart
git add lib/screens/shop/shop_screen.dart lib/screens/shop/product_detail_screen.dart
git commit -m "feat(shop): add recently viewed products bar on Shop home"
```

---

### Task D4: Wishlist screen with price-drop badges

**Files:**
- Create: `lib/screens/shop/wishlist_screen.dart`

- [ ] **Step 1: Create WishlistScreen**

```dart
// lib/screens/shop/wishlist_screen.dart
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
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from wishlist')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text('Wishlist (${_items.length})', style: const TextStyle(color: _kPrimaryText)),
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
                      const HeroIcon(HeroIcons.heart, size: 48, color: Color(0xFFE0E0E0)),
                      const SizedBox(height: 12),
                      const Text('Your wishlist is empty', style: TextStyle(color: Color(0xFF999999))),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: _kPrimaryText),
                        child: const Text('Browse Shop', style: TextStyle(color: Colors.white)),
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
                          onTap: () => Navigator.pushNamed(context, '/shop/product/${product.id}',
                              arguments: {'productId': product.id, 'currentUserId': widget.currentUserId}),
                        ),
                        if (priceDropped)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Price Dropped!', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _removeItem(product.id),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 16, color: Color(0xFF999999)),
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
```

- [ ] **Step 2: Add route for wishlist**

In `lib/main.dart`, add the route:

```dart
  '/shop/wishlist': (context) => FutureBuilder<int>(
    future: LocalStorageService.instance.getCurrentUserId(),
    builder: (context, snap) => snap.hasData
        ? WishlistScreen(currentUserId: snap.data!)
        : const Scaffold(body: Center(child: CircularProgressIndicator())),
  ),
```

Add import:

```dart
import 'screens/shop/wishlist_screen.dart';
```

- [ ] **Step 3: Add wishlist icon to ShopScreen AppBar**

In `shop_screen.dart` AppBar actions, add:

```dart
  IconButton(
    icon: const HeroIcon(HeroIcons.heart, style: HeroIconStyle.outline),
    onPressed: () => Navigator.pushNamed(context, '/shop/wishlist'),
  ),
```

- [ ] **Step 4: Verify and commit**

```bash
flutter analyze lib/screens/shop/wishlist_screen.dart lib/screens/shop/shop_screen.dart
git add lib/screens/shop/wishlist_screen.dart lib/screens/shop/shop_screen.dart lib/main.dart
git commit -m "feat(shop): add dedicated wishlist screen with price-drop badges"
```

---

## SUB-PROJECT E: Checkout & Orders

**Goal:** Add promo code field, saved delivery addresses, and order tracking timeline. Depends on Sub-project C for payment methods.

---

### Task E1: Promo code input in checkout

**Files:**
- Modify: `lib/screens/shop/checkout_screen.dart`
- Modify: `lib/services/shop_service.dart`

- [ ] **Step 1: Add promo code state and UI**

In `checkout_screen.dart`, add state:

```dart
  final TextEditingController _promoController = TextEditingController();
  String? _appliedPromo;
  double _discount = 0;
  bool _validatingPromo = false;
```

Add promo code section widget:

```dart
  Widget _buildPromoCodeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promoController,
              decoration: InputDecoration(
                hintText: 'Enter promo code',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _appliedPromo != null
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() { _appliedPromo = null; _discount = 0; _promoController.clear(); });
                        },
                      )
                    : null,
              ),
              enabled: _appliedPromo == null,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _appliedPromo != null || _validatingPromo ? null : _validatePromo,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: _validatingPromo
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_appliedPromo != null ? 'Applied ✓' : 'Apply', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _validatePromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;
    setState(() => _validatingPromo = true);
    final result = await _shopService.validatePromoCode(code: code, userId: widget.currentUserId);
    if (!mounted) return;
    setState(() => _validatingPromo = false);
    if (result.success) {
      setState(() { _appliedPromo = code; _discount = result.discount ?? 0; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Promo applied: ${result.description ?? 'Discount applied'}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Invalid promo code')));
    }
  }
```

- [ ] **Step 2: Add validatePromoCode to ShopService**

```dart
  Future<PromoCodeResult> validatePromoCode({required String code, required int userId}) async {
    final url = '$_baseUrl/shop/promo/validate';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code, 'user_id': userId}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        return PromoCodeResult(
          success: true,
          discount: double.tryParse(data['discount']?.toString() ?? '0') ?? 0,
          description: data['description']?.toString(),
        );
      }
      return PromoCodeResult(success: false, message: data['message']?.toString() ?? 'Invalid code');
    } catch (e) {
      return PromoCodeResult(success: false, message: 'Failed to validate: $e');
    }
  }
```

Add model class in `shop_models.dart`:

```dart
class PromoCodeResult {
  final bool success;
  final double? discount;
  final String? description;
  final String? message;
  const PromoCodeResult({required this.success, this.discount, this.description, this.message});
}
```

- [ ] **Step 3: Pass promo code to checkout API**

In `_processPayment()`, add `promoCode: _appliedPromo` to both `createOrder()` and `checkout()` calls. Update their signatures to accept `String? promoCode`.

- [ ] **Step 4: Verify and commit**

```bash
flutter analyze lib/screens/shop/checkout_screen.dart lib/services/shop_service.dart lib/models/shop_models.dart
git add lib/screens/shop/checkout_screen.dart lib/services/shop_service.dart lib/models/shop_models.dart
git commit -m "feat(shop): add promo code validation and discount in checkout"
```

---

### Task E2: Order tracking timeline

**Files:**
- Create: `lib/screens/shop/order_tracking_screen.dart`
- Modify: `lib/screens/shop/order_detail_screen.dart`

- [ ] **Step 1: Create order tracking timeline screen**

```dart
// lib/screens/shop/order_tracking_screen.dart
import 'package:flutter/material.dart';
import '../../models/shop_models.dart';

const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kTertiaryText = Color(0xFF999999);

class OrderTrackingScreen extends StatelessWidget {
  final Order order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps();
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text('Order #${order.orderNumber ?? order.id}', style: const TextStyle(color: _kPrimaryText)),
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimaryText),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _statusColor(order.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                order.status.label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _statusColor(order.status)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Timeline
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == steps.length - 1;
            return _buildTimelineStep(step, isLast: isLast);
          }),
          // Tracking number
          if (order.trackingNumber != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, color: _kSecondaryText),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tracking Number', style: TextStyle(fontSize: 12, color: _kTertiaryText)),
                      Text(order.trackingNumber!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimaryText)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<_TimelineStep> _buildSteps() {
    final steps = <_TimelineStep>[];
    final history = order.statusHistory ?? [];

    // Always show standard flow
    final standardFlow = [
      (OrderStatus.pending, 'Order Placed'),
      (OrderStatus.confirmed, 'Seller Confirmed'),
      (OrderStatus.shipped, 'Shipped'),
      (OrderStatus.delivered, 'Delivered'),
      (OrderStatus.completed, 'Completed'),
    ];

    for (final (status, label) in standardFlow) {
      final historyEntry = history.where((h) => h.status == status).firstOrNull;
      final isReached = order.status.index >= status.index;
      steps.add(_TimelineStep(
        label: label,
        timestamp: historyEntry?.createdAt,
        isCompleted: isReached && order.status != OrderStatus.cancelled,
        isCurrent: order.status == status,
      ));
    }

    if (order.status == OrderStatus.cancelled) {
      steps.add(_TimelineStep(
        label: 'Cancelled',
        timestamp: order.cancelledAt,
        isCompleted: true,
        isCurrent: true,
        isError: true,
      ));
    }

    return steps;
  }

  Widget _buildTimelineStep(_TimelineStep step, {bool isLast = false}) {
    final color = step.isError
        ? const Color(0xFFE53935)
        : step.isCompleted
            ? const Color(0xFF4CAF50)
            : const Color(0xFFE0E0E0);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: step.isCurrent ? 16 : 12,
                  height: step.isCurrent ? 16 : 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: step.isCurrent ? Border.all(color: color.withValues(alpha: 0.3), width: 3) : null,
                  ),
                  child: step.isCompleted && !step.isError
                      ? const Icon(Icons.check, size: 8, color: Colors.white)
                      : null,
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: color.withValues(alpha: 0.3))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.label, style: TextStyle(
                    fontSize: 14,
                    fontWeight: step.isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: step.isCompleted ? _kPrimaryText : _kTertiaryText,
                  )),
                  if (step.timestamp != null)
                    Text(
                      _formatTimestamp(step.timestamp!),
                      style: const TextStyle(fontSize: 12, color: _kTertiaryText),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return const Color(0xFFFF9800);
      case OrderStatus.confirmed: return const Color(0xFF2196F3);
      case OrderStatus.processing: return const Color(0xFF2196F3);
      case OrderStatus.shipped: return const Color(0xFF9C27B0);
      case OrderStatus.delivered: return const Color(0xFF4CAF50);
      case OrderStatus.completed: return const Color(0xFF4CAF50);
      case OrderStatus.cancelled: return const Color(0xFFE53935);
      case OrderStatus.refunded: return const Color(0xFFE53935);
    }
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _TimelineStep {
  final String label;
  final DateTime? timestamp;
  final bool isCompleted;
  final bool isCurrent;
  final bool isError;

  const _TimelineStep({
    required this.label,
    this.timestamp,
    this.isCompleted = false,
    this.isCurrent = false,
    this.isError = false,
  });
}
```

- [ ] **Step 2: Wire "Track Order" button in order_detail_screen**

In `order_detail_screen.dart`, add import and navigation:

```dart
import 'order_tracking_screen.dart';

// In the action buttons area:
  ElevatedButton.icon(
    onPressed: () => Navigator.push(context, MaterialPageRoute(
      builder: (_) => OrderTrackingScreen(order: _order!),
    )),
    icon: const Icon(Icons.timeline_outlined, size: 18),
    label: const Text('Track Order'),
    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A), foregroundColor: Colors.white),
  ),
```

- [ ] **Step 3: Verify and commit**

```bash
flutter analyze lib/screens/shop/order_tracking_screen.dart lib/screens/shop/order_detail_screen.dart
git add lib/screens/shop/order_tracking_screen.dart lib/screens/shop/order_detail_screen.dart
git commit -m "feat(shop): add order tracking timeline screen with visual step indicators"
```

---

*Sub-projects F, G, H continue in Part 3.*
