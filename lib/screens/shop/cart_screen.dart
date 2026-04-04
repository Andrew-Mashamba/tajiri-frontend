import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heroicons/heroicons.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/shop_models.dart';
import '../../services/shop_service.dart';
import '../../widgets/shop/product_card.dart';

// DESIGN.md tokens
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kTertiaryText = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

/// Shopping cart screen displaying cart items and checkout options.
class CartScreen extends StatefulWidget {
  final int currentUserId;

  const CartScreen({super.key, required this.currentUserId});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ShopService _shopService = ShopService();

  Cart? _cart;
  bool _isLoading = true;
  String? _error;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    final result = await _shopService.getCart(widget.currentUserId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _cart = result.cart;
      } else {
        _error = result.message;
      }
    });
  }

  Future<void> _updateQuantity(int productId, int quantity) async {
    if (_isUpdating) return;
    HapticFeedback.lightImpact();
    setState(() => _isUpdating = true);

    final result = await _shopService.updateCartItem(
      widget.currentUserId,
      productId,
      quantity,
    );

    if (!mounted) return;
    setState(() {
      _isUpdating = false;
      if (result.success && result.cart != null) {
        _cart = result.cart;
      }
    });
  }

  Future<void> _removeItem(int productId) async {
    if (_isUpdating) return;
    HapticFeedback.mediumImpact();
    setState(() => _isUpdating = true);

    final result = await _shopService.removeFromCart(
      widget.currentUserId,
      productId,
    );

    if (!mounted) return;
    setState(() {
      _isUpdating = false;
      if (result.success && result.cart != null) {
        _cart = result.cart;
      }
    });

    if (result.success) {
      final s = AppStringsScope.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.productRemoved ?? 'Product removed')),
      );
    }
  }

  Future<void> _clearCart() async {
    final s = AppStringsScope.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s?.clearCart ?? 'Clear Cart'),
        content: Text(s?.clearCartConfirmation ?? 'Are you sure you want to remove all items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s?.no ?? 'No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: Text(s?.yesClear ?? 'Yes, Clear'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUpdating = true);
    final success = await _shopService.clearCart(widget.currentUserId);
    if (!mounted) return;
    setState(() => _isUpdating = false);

    if (success) {
      setState(() {
        _cart = Cart();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.cartCleared ?? 'Cart cleared')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.errorOccurred ?? 'Failed to clear cart')),
      );
    }
  }

  void _checkout() {
    if (_cart == null || _cart!.isEmpty) return;
    HapticFeedback.heavyImpact();
    Navigator.pushNamed(
      context,
      '/shop/checkout',
      arguments: {'cart': _cart},
    );
  }

  void _continueShopping() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimaryText),
        title: Text(
          s?.cart ?? 'Cart',
          style: const TextStyle(
            color: _kPrimaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_cart != null && _cart!.isNotEmpty)
            TextButton(
              onPressed: _isUpdating ? null : _clearCart,
              child: Text(
                s?.clearAll ?? 'Clear All',
                style: const TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? _buildCartShimmer()
          : _error != null
              ? _buildErrorState()
              : _cart == null || _cart!.isEmpty
                  ? _buildEmptyState()
                  : _buildCartContent(),
      bottomNavigationBar: _cart != null && _cart!.isNotEmpty
          ? _buildCheckoutBar()
          : null,
    );
  }

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

  Widget _buildCartShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 3,
      itemBuilder: (context, index) => Padding(
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

  Widget _buildErrorState() {
    final s = AppStringsScope.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const HeroIcon(
            HeroIcons.exclamationTriangle,
            size: 64,
            color: _kTertiaryText,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? s?.errorOccurred ?? 'An error occurred',
            style: const TextStyle(
              color: _kSecondaryText,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryText,
              foregroundColor: Colors.white,
            ),
            child: Text(s?.tryAgain ?? 'Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final s = AppStringsScope.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kDivider.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const HeroIcon(
              HeroIcons.shoppingCart,
              size: 64,
              color: _kTertiaryText,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            s?.yourCartIsEmpty ?? 'Your Cart is Empty',
            style: const TextStyle(
              color: _kPrimaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s?.addProductsToCart ?? 'Add products to cart to continue',
            style: const TextStyle(
              color: _kSecondaryText,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _continueShopping,
            icon: const HeroIcon(HeroIcons.shoppingBag, size: 20),
            label: Text(s?.continueShopping ?? 'Continue Shopping'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryText,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadCart,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _cart!.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _cart!.items[index];
              return Dismissible(
                key: Key('cart_item_${item.productId}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _removeItem(item.productId),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const HeroIcon(
                    HeroIcons.trash,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                child: CartItemCard(
                  item: item,
                  onRemove: () => _removeItem(item.productId),
                  onQuantityChanged: (quantity) =>
                      _updateQuantity(item.productId, quantity),
                ),
              );
            },
          ),
        ),

        // Loading overlay
        if (_isUpdating)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(
                child: CircularProgressIndicator(color: _kPrimaryText),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCheckoutBar() {
    final s = AppStringsScope.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: _kSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Order summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${s?.subtotal ?? 'Subtotal'}:',
                style: const TextStyle(
                  color: _kSecondaryText,
                  fontSize: 14,
                ),
              ),
              Text(
                _cart!.subtotalFormatted,
                style: const TextStyle(
                  color: _kPrimaryText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${s?.shipping ?? 'Shipping'}:',
                style: const TextStyle(
                  color: _kSecondaryText,
                  fontSize: 14,
                ),
              ),
              Text(
                _cart!.deliveryTotal > 0
                    ? _cart!.deliveryTotalFormatted
                    : s?.toBeCalculated ?? 'To be calculated',
                style: const TextStyle(
                  color: _kPrimaryText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: _kDivider, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${s?.total ?? 'Total'}:',
                style: const TextStyle(
                  color: _kPrimaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _cart!.grandTotalFormatted,
                style: const TextStyle(
                  color: _kPrimaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Checkout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _checkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryText,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s?.proceedToPayment ?? 'Proceed to Payment',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_cart!.itemCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
