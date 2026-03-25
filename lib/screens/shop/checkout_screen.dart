import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/shop_models.dart';
import '../../services/shop_service.dart';
import '../../widgets/cached_media_image.dart';

// DESIGN.md tokens
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kTertiaryText = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

/// Checkout screen for completing purchases with TAJIRI Wallet.
class CheckoutScreen extends StatefulWidget {
  final int currentUserId;
  final Product? product;
  final int? quantity;
  final DeliveryMethod? deliveryMethod;
  final Cart? cart;

  const CheckoutScreen({
    super.key,
    required this.currentUserId,
    this.product,
    this.quantity,
    this.deliveryMethod,
    this.cart,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final ShopService _shopService = ShopService();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  // Delivery method per product (for cart checkout)
  Map<int, DeliveryMethod> _deliveryMethods = {};
  Map<int, String?> _deliveryAddresses = {};

  bool _isProcessing = false;

  double get _subtotal {
    if (widget.product != null) {
      return widget.product!.price * (widget.quantity ?? 1);
    } else if (widget.cart != null) {
      return widget.cart!.subtotal;
    }
    return 0;
  }

  double get _deliveryFee {
    if (widget.product != null) {
      final method = widget.deliveryMethod ?? DeliveryMethod.pickup;
      if (method == DeliveryMethod.pickup || method == DeliveryMethod.digital) {
        return 0;
      }
      return widget.product!.deliveryFee ?? 0;
    } else if (widget.cart != null) {
      double total = 0;
      for (final item in widget.cart!.items) {
        final method = _deliveryMethods[item.productId];
        if (method != DeliveryMethod.pickup && method != DeliveryMethod.digital) {
          total += item.product?.deliveryFee ?? 0;
        }
      }
      return total;
    }
    return 0;
  }

  double get _total => _subtotal + _deliveryFee;

  @override
  void initState() {
    super.initState();
    _initializeDeliveryMethods();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _initializeDeliveryMethods() {
    if (widget.cart != null) {
      for (final item in widget.cart!.items) {
        final product = item.product;
        if (product != null) {
          if (product.isDigital) {
            _deliveryMethods[item.productId] = DeliveryMethod.digital;
          } else if (product.allowDelivery) {
            _deliveryMethods[item.productId] = DeliveryMethod.delivery;
          } else if (product.allowShipping) {
            _deliveryMethods[item.productId] = DeliveryMethod.shipping;
          } else {
            _deliveryMethods[item.productId] = DeliveryMethod.pickup;
          }
        }
      }
    }
  }

  bool _needsAddress() {
    if (widget.product != null) {
      final method = widget.deliveryMethod ?? DeliveryMethod.pickup;
      return method == DeliveryMethod.delivery || method == DeliveryMethod.shipping;
    } else if (widget.cart != null) {
      return _deliveryMethods.values.any(
        (m) => m == DeliveryMethod.delivery || m == DeliveryMethod.shipping,
      );
    }
    return false;
  }

  void _showPinDialog() {
    final s = AppStringsScope.of(context);
    if (_needsAddress() && _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.pleaseEnterAddress ?? 'Please enter delivery address')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildPinSheet(),
    ).whenComplete(() {
      _pinController.clear();
    });
  }

  Widget _buildPinSheet() {
    final s = AppStringsScope.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _kDivider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const HeroIcon(
            HeroIcons.lockClosed,
            size: 48,
            color: _kPrimaryText,
          ),
          const SizedBox(height: 16),
          Text(
            s?.enterWalletPin ?? 'Enter TAJIRI Wallet PIN',
            style: const TextStyle(
              color: _kPrimaryText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${s?.total ?? 'Total'}: TZS ${_total.toStringAsFixed(0)}',
            style: const TextStyle(
              color: _kSecondaryText,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 16,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••',
              hintStyle: TextStyle(
                color: _kTertiaryText.withValues(alpha: 0.5),
                letterSpacing: 16,
              ),
              filled: true,
              fillColor: _kBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryText,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      s?.confirmPayment ?? 'Confirm Payment',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    final s = AppStringsScope.of(context);
    if (_pinController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.enter4DigitPin ?? 'Please enter a 4-digit PIN')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      if (widget.product != null) {
        // Single product order
        final result = await _shopService.createOrder(
          buyerId: widget.currentUserId,
          productId: widget.product!.id,
          quantity: widget.quantity ?? 1,
          deliveryMethod: widget.deliveryMethod ?? DeliveryMethod.pickup,
          deliveryAddress: _addressController.text.isNotEmpty
              ? _addressController.text
              : null,
          deliveryNotes: _notesController.text.isNotEmpty
              ? _notesController.text
              : null,
          pin: _pinController.text,
        );

        if (!mounted) return;
        Navigator.pop(context); // Close PIN sheet

        if (result.success) {
          _showSuccessDialog(result.order);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? s?.paymentFailed ?? 'Payment failed')),
          );
        }
      } else if (widget.cart != null) {
        // Cart checkout
        final items = widget.cart!.items.map((item) {
          return CheckoutItem(
            productId: item.productId,
            quantity: item.quantity,
            deliveryMethod: _deliveryMethods[item.productId] ?? DeliveryMethod.pickup,
            deliveryAddress: _deliveryAddresses[item.productId] ?? _addressController.text,
            deliveryNotes: _notesController.text,
          );
        }).toList();

        final result = await _shopService.checkout(
          buyerId: widget.currentUserId,
          items: items,
          pin: _pinController.text,
        );

        if (!mounted) return;
        Navigator.pop(context); // Close PIN sheet

        if (result.success) {
          _showSuccessDialog(result.orders.isNotEmpty ? result.orders.first : null);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? s?.paymentFailed ?? 'Payment failed')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close PIN sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s?.error ?? 'Error'}: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(Order? order) {
    final s = AppStringsScope.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const HeroIcon(
                HeroIcons.check,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              s?.paymentSuccessful ?? 'Payment Successful!',
              style: const TextStyle(
                color: _kPrimaryText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (order != null)
              Text(
                '${s?.orderNumber ?? 'Order Number'}: #${order.orderNumber}',
                style: const TextStyle(
                  color: _kSecondaryText,
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              s?.sellerWillContact ?? 'The seller will contact you about shipping.',
              style: const TextStyle(
                color: _kSecondaryText,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.popUntil(context, (route) => route.isFirst);
                Navigator.pushNamed(context, '/shop/orders');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryText,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(s?.viewOrders ?? 'View Orders'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Text(
                s?.continueShopping ?? 'Continue Shopping',
                style: const TextStyle(color: _kSecondaryText),
              ),
            ),
          ),
        ],
      ),
    );
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
          s?.checkout ?? 'Checkout',
          style: const TextStyle(
            color: _kPrimaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            _buildOrderSummary(),

            // Delivery address (if needed)
            if (_needsAddress()) _buildDeliveryAddress(),

            // Notes
            _buildNotes(),

            // Payment method
            _buildPaymentMethod(),

            // Price breakdown
            _buildPriceBreakdown(),

            const SizedBox(height: 100),
          ],
        ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildOrderSummary() {
    final s = AppStringsScope.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      color: _kSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s?.orderSummary ?? 'Order Summary',
            style: const TextStyle(
              color: _kPrimaryText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (widget.product != null)
            _buildProductItem(widget.product!, widget.quantity ?? 1)
          else if (widget.cart != null)
            ...widget.cart!.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildProductItem(item.product!, item.quantity),
                )),
        ],
      ),
    );
  }

  Widget _buildProductItem(Product product, int quantity) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 60,
            height: 60,
            child: product.thumbnailUrl.isNotEmpty
                ? CachedMediaImage(
                    imageUrl: product.thumbnailUrl,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: _kDivider,
                    child: const Center(
                      child: HeroIcon(
                        HeroIcons.photo,
                        size: 24,
                        color: _kTertiaryText,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.title,
                style: const TextStyle(
                  color: _kPrimaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'x$quantity',
                style: const TextStyle(
                  color: _kSecondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          'TZS ${(product.price * quantity).toStringAsFixed(0)}',
          style: const TextStyle(
            color: _kPrimaryText,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryAddress() {
    final s = AppStringsScope.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: _kSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HeroIcon(
                HeroIcons.mapPin,
                size: 20,
                color: _kPrimaryText,
              ),
              const SizedBox(width: 8),
              Text(
                s?.deliveryAddress ?? 'Delivery Address',
                style: const TextStyle(
                  color: _kPrimaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: s?.enterFullAddress ?? 'Enter your full address...',
              hintStyle: const TextStyle(color: _kTertiaryText),
              filled: true,
              fillColor: _kBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotes() {
    final s = AppStringsScope.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: _kSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HeroIcon(
                HeroIcons.chatBubbleBottomCenterText,
                size: 20,
                color: _kPrimaryText,
              ),
              const SizedBox(width: 8),
              Text(
                s?.instructionsOptional ?? 'Instructions (Optional)',
                style: const TextStyle(
                  color: _kPrimaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: s?.specialInstructionsHint ?? 'Special instructions for the seller...',
              hintStyle: const TextStyle(color: _kTertiaryText),
              filled: true,
              fillColor: _kBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    final s = AppStringsScope.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: _kSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HeroIcon(
                HeroIcons.wallet,
                size: 20,
                color: _kPrimaryText,
              ),
              const SizedBox(width: 8),
              Text(
                s?.paymentMethod ?? 'Payment Method',
                style: const TextStyle(
                  color: _kPrimaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kPrimaryText.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kPrimaryText, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kPrimaryText,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const HeroIcon(
                    HeroIcons.wallet,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TAJIRI Wallet',
                        style: TextStyle(
                          color: _kPrimaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        s?.fastSecurePayment ?? 'Fast and secure payment',
                        style: const TextStyle(
                          color: _kSecondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const HeroIcon(
                  HeroIcons.checkCircle,
                  style: HeroIconStyle.solid,
                  size: 24,
                  color: Color(0xFF10B981),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    final s = AppStringsScope.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: _kSurface,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s?.subtotal ?? 'Subtotal',
                style: const TextStyle(
                  color: _kSecondaryText,
                  fontSize: 14,
                ),
              ),
              Text(
                'TZS ${_subtotal.toStringAsFixed(0)}',
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
                s?.shipping ?? 'Shipping',
                style: const TextStyle(
                  color: _kSecondaryText,
                  fontSize: 14,
                ),
              ),
              Text(
                _deliveryFee > 0 ? 'TZS ${_deliveryFee.toStringAsFixed(0)}' : s?.free ?? 'Free',
                style: TextStyle(
                  color: _deliveryFee > 0 ? _kPrimaryText : const Color(0xFF10B981),
                  fontSize: 14,
                  fontWeight: _deliveryFee > 0 ? FontWeight.normal : FontWeight.w600,
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
                s?.total ?? 'Total',
                style: const TextStyle(
                  color: _kPrimaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'TZS ${_total.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: _kPrimaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showPinDialog,
          icon: const HeroIcon(HeroIcons.wallet, size: 22),
          label: Text(
            '${s?.pay ?? 'Pay'} TZS ${_total.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimaryText,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
