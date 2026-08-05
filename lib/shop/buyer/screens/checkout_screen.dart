import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../../l10n/app_strings_scope.dart';
import '../../../models/shop_models.dart';
import '../../checkout/flow/confirmation_step.dart';
import '../../checkout/flow/payment_step.dart';
import '../../checkout/flow/review_step.dart';
import '../../checkout/flow/shipping_step.dart';
import '../../checkout/widgets/checkout_progress_bar.dart';
import '../../data/repositories/shop_repository.dart';
import '../../../services/affiliate_service.dart';
import '../../../services/shop_service.dart' show CheckoutItem;
import '../../../widgets/budget_context_banner.dart';
import '../../../widgets/cached_media_image.dart';
import '../../escrow/widgets/escrow_pledge_card.dart';

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
  final ShopRepository _repo = ShopRepository.instance;
  final AffiliateService _affiliateService = AffiliateService();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _promoController = TextEditingController();
  final TextEditingController _affiliateController = TextEditingController();

  String _paymentMethod = 'wallet'; // 'wallet' | 'cod'
  String? _appliedPromo;
  double _discount = 0;
  bool _validatingPromo = false;

  /// UN-014 — affiliate code resolution. When set, the order persists
  /// `affiliate_user_id` and the backend fires affiliate_conversion·author
  /// on completion.
  int? _affiliateUserId;
  String? _affiliateName;
  bool _affiliateValidating = false;
  String? _affiliateError;

  // Delivery method per product (for cart checkout)
  final Map<int, DeliveryMethod> _deliveryMethods = {};
  final Map<int, String?> _deliveryAddresses = {};

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

  double get _total => (_subtotal + _deliveryFee - _discount).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    _initializeDeliveryMethods();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _affiliateController.dispose();
    _pinController.dispose();
    _promoController.dispose();
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

    if (_paymentMethod == 'cod') {
      _processCodOrder();
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

  Future<void> _processCodOrder() async {
    final s = AppStringsScope.of(context);
    setState(() => _isProcessing = true);

    try {
      if (widget.product != null) {
        final result = await _repo.createOrder(
          buyerId: widget.currentUserId,
          productId: widget.product!.id,
          quantity: widget.quantity ?? 1,
          deliveryMethod: widget.deliveryMethod ?? DeliveryMethod.pickup,
          deliveryAddress:
              _addressController.text.isNotEmpty ? _addressController.text : null,
          deliveryNotes:
              _notesController.text.isNotEmpty ? _notesController.text : null,
          paymentMethod: 'cod',
          promoCode: _appliedPromo,
          affiliateUserId: _affiliateUserId,
        );

        if (!mounted) return;
        if (result.success) {
          _showCodSuccessDialog(result.order);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    result.message ?? s?.paymentFailed ?? 'Order failed')),
          );
        }
      } else if (widget.cart != null) {
        final items = widget.cart!.items.map((item) {
          return CheckoutItem(
            productId: item.productId,
            quantity: item.quantity,
            deliveryMethod:
                _deliveryMethods[item.productId] ?? DeliveryMethod.pickup,
            deliveryAddress:
                _deliveryAddresses[item.productId] ?? _addressController.text,
            deliveryNotes: _notesController.text,
          );
        }).toList();

        final result = await _repo.checkout(
          buyerId: widget.currentUserId,
          items: items,
          paymentMethod: 'cod',
          promoCode: _appliedPromo,
        );

        if (!mounted) return;
        if (result.success) {
          _showCodSuccessDialog(
              result.orders.isNotEmpty ? result.orders.first : null);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    result.message ?? s?.paymentFailed ?? 'Order failed')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s?.error ?? 'Error'}: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// UN-014 — affiliate code field. Resolves a code to a user_id and
  /// includes it on order create so the backend can fire
  /// affiliate_conversion·author on order completion.
  Widget _buildAffiliateSection() {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final applied = _affiliateUserId != null;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: _kSurface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSw ? 'Msimbo wa Mshirika' : 'Affiliate code',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _kPrimaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isSw
                  ? 'Hiari. Kama mtu alikutambulisha kwa hii bidhaa, weka msimbo wao.'
                  : 'Optional. If a creator referred you to this product, enter their code.',
              style: const TextStyle(fontSize: 12, color: _kSecondaryText),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _affiliateController,
                    enabled: !applied,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: isSw ? 'TAJIRI-MSANII' : 'TAJIRI-CREATOR',
                      hintStyle: const TextStyle(color: _kTertiaryText),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      errorText: _affiliateError,
                      suffixIcon: applied
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() {
                                  _affiliateUserId = null;
                                  _affiliateName = null;
                                  _affiliateController.clear();
                                  _affiliateError = null;
                                });
                              },
                              constraints: const BoxConstraints(
                                  minWidth: 48, minHeight: 48),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed:
                      applied || _affiliateValidating ? null : _validateAffiliate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    minimumSize: const Size(72, 48),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  child: _affiliateValidating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          applied ? 'Applied ✓' : 'Apply',
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ],
            ),
            if (applied && _affiliateName != null) ...[
              const SizedBox(height: 6),
              Text(
                isSw ? 'Mshirika: ${_affiliateName!}' : 'Affiliate: ${_affiliateName!}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kPrimaryText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCodeSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: _kSurface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Promo Code',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _kPrimaryText,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    decoration: InputDecoration(
                      hintText: 'Enter promo code',
                      hintStyle: const TextStyle(color: _kTertiaryText),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: _appliedPromo != null
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() {
                                  _appliedPromo = null;
                                  _discount = 0;
                                  _promoController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    enabled: _appliedPromo == null,
                    textCapitalization: TextCapitalization.characters,
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
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _appliedPromo != null ? 'Applied ✓' : 'Apply',
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validateAffiliate() async {
    final code = _affiliateController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _affiliateUserId = null;
        _affiliateName = null;
        _affiliateError = null;
      });
      return;
    }
    setState(() {
      _affiliateValidating = true;
      _affiliateError = null;
    });
    final lookup = await _affiliateService.lookup(code);
    if (!mounted) return;
    setState(() {
      _affiliateValidating = false;
      if (lookup == null) {
        _affiliateUserId = null;
        _affiliateName = null;
        _affiliateError = 'Code not found';
      } else if (lookup.userId == widget.currentUserId) {
        _affiliateUserId = null;
        _affiliateName = null;
        _affiliateError = 'Cannot use your own code';
      } else {
        _affiliateUserId = lookup.userId;
        _affiliateName = lookup.name;
        _affiliateError = null;
      }
    });
  }

  Future<void> _validatePromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;
    setState(() => _validatingPromo = true);
    try {
      final result = await _repo.validatePromoCode(code: code, userId: widget.currentUserId);
      if (!mounted) return;
      setState(() => _validatingPromo = false);
      if (result.success) {
        setState(() {
          _appliedPromo = code;
          _discount = result.discount ?? 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Promo applied: ${result.description ?? 'Discount applied'}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Invalid promo code')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _validatingPromo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to validate promo code: $e')),
      );
    }
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
          const SizedBox(height: 12),
          BudgetContextBanner(
            category: 'ununuzi',
            paymentAmount: _total,
            isSwahili: s?.isSwahili ?? false,
          ),
          const SizedBox(height: 12),
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
        final result = await _repo.createOrder(
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
          paymentMethod: 'wallet',
          promoCode: _appliedPromo,
          affiliateUserId: _affiliateUserId,
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

        final result = await _repo.checkout(
          buyerId: widget.currentUserId,
          items: items,
          pin: _pinController.text,
          paymentMethod: 'wallet',
          promoCode: _appliedPromo,
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
                if (order != null) {
                  Navigator.popUntil(context, (route) => route.isFirst);
                  Navigator.pushNamed(
                    context,
                    '/shop/order',
                    arguments: {'orderId': order.id},
                  );
                } else {
                  Navigator.popUntil(context, (route) => route.isFirst);
                }
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

  void _showCodSuccessDialog(Order? order) {
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
              child: const Icon(
                Icons.money_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Order Placed!',
              style: TextStyle(
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
            const Text(
              'Pay cash when your delivery arrives.',
              style: TextStyle(
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
                Navigator.pop(context);
                if (order != null) {
                  Navigator.popUntil(context, (route) => route.isFirst);
                  Navigator.pushNamed(
                    context,
                    '/shop/order',
                    arguments: {'orderId': order.id},
                  );
                } else {
                  Navigator.popUntil(context, (route) => route.isFirst);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryText,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(s?.viewOrders ?? 'View Order'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
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
            // Conceptual step 2 of 4 on one page (Review/Shipping/Payment visible; Done = success dialog).
            const CheckoutProgressBar(stepIndex: 2),
            ShippingStep(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderSummary(),
                  if (_needsAddress()) _buildDeliveryAddress(),
                  _buildNotes(),
                ],
              ),
            ),
            PaymentStep(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPaymentMethod(),
                  _buildPromoCodeSection(),
                  _buildAffiliateSection(),
                ],
              ),
            ),
            ReviewStep(child: _buildPriceBreakdown()),
            ConfirmationStep(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEscrowNotice(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: BudgetContextBanner(
                      category: 'ununuzi',
                      paymentAmount: _total,
                      isSwahili: s?.isSwahili ?? false,
                    ),
                  ),
                ],
              ),
            ),

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
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: _kSurface,
      child: _buildPaymentMethodSelector(),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _kPrimaryText,
            ),
          ),
        ),
        RadioGroup<String>(
          groupValue: _paymentMethod,
          onChanged: (v) {
            if (v != null) setState(() => _paymentMethod = v);
          },
          child: Column(
            children: [
              RadioListTile<String>(
                value: 'wallet',
                title: const Text(
                  'Tajiri Pay',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _kPrimaryText,
                  ),
                ),
                subtitle: const Text(
                  'Pay with your Tajiri wallet balance',
                  style: TextStyle(color: _kSecondaryText),
                ),
                secondary: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: _kPrimaryText,
                ),
                activeColor: _kPrimaryText,
              ),
              RadioListTile<String>(
                value: 'cod',
                title: const Text(
                  'Cash on Delivery',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _kPrimaryText,
                  ),
                ),
                subtitle: const Text(
                  'Pay cash when your order arrives',
                  style: TextStyle(color: _kSecondaryText),
                ),
                secondary: const Icon(
                  Icons.money_rounded,
                  color: _kPrimaryText,
                ),
                activeColor: _kPrimaryText,
              ),
            ],
          ),
        ),
      ],
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
          if (_discount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Promo${_appliedPromo != null ? ' ($_appliedPromo)' : ''}',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 14,
                  ),
                ),
                Text(
                  '-TZS ${_discount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: _kDivider, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _paymentMethod == 'cod'
                    ? 'Pay on delivery'
                    : (s?.total ?? 'Total'),
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

  Widget _buildEscrowNotice() => const EscrowPledgeCard();

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
          onPressed: _isProcessing ? null : _showPinDialog,
          icon: _isProcessing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : (_paymentMethod == 'cod'
                  ? const Icon(Icons.money_rounded, size: 22)
                  : const HeroIcon(HeroIcons.wallet, size: 22)),
          label: Text(
            _paymentMethod == 'cod'
                ? 'Place Order — Pay on Delivery'
                : '${s?.pay ?? 'Pay'} TZS ${_total.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
