import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../services/cart_service.dart';
import '../services/delivery_fee_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF4CAF50);
const Color _kError = Color(0xFFE53935);

/// Cross-vertical cart page. Displays items added via [CartService].
class CartPage extends StatefulWidget {
  final int userId;

  const CartPage({super.key, required this.userId});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService _cart = CartService();
  bool _calculatingDelivery = false;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? true;

  String _fmtTzs(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'TSh ${buf.toString()}';
  }

  void _removeItem(int index) {
    setState(() => _cart.removeItem(index));
    if (_cart.items.isEmpty && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _calculateDeliveryFees() async {
    setState(() => _calculatingDelivery = true);
    for (final item in _cart.items) {
      final lat = item.product.pickupLat;
      final lng = item.product.pickupLng;
      final perKm = item.product.deliveryFeePerKmTzs ?? 0;
      final radius = item.product.deliveryRadiusKm ?? 1;
      if (lat != null && lng != null && perKm > 0) {
        final res = await DeliveryFeeService.calculate(
          partnerLat: lat,
          partnerLng: lng,
          perKmTzs: perKm,
          maxFeeTzs: perKm * radius * 2,
        );
        if (res.success && res.feeTzs != null) {
          item.deliveryFeeTzs = res.feeTzs;
        }
      }
    }
    if (mounted) setState(() => _calculatingDelivery = false);
  }

  void _checkout() {
    // Checkout flow wired to payment sheet / order placement later.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSwahili
            ? 'Kulipa kutaunganishwa hivi karibuni'
            : 'Checkout will be wired shortly'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = _isSwahili;
    final items = _cart.items;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          sw ? 'Kikapu' : 'Cart',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: items.isEmpty
          ? _EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: sw ? 'Kikapu kiko tupu' : 'Your cart is empty',
              subtitle: sw
                  ? 'Ongeza bidhaa kutoka kwa wafanyabiashara.'
                  : 'Add items from partners.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                if (index == items.length) {
                  return _buildTotal(sw);
                }
                final item = items[index];
                return _CartItemTile(
                  item: item,
                  onRemove: () => _removeItem(index),
                  fmtTzs: _fmtTzs,
                );
              },
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ElevatedButton(
                  onPressed: _checkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    sw
                        ? 'Endelea na Malipo — ${_fmtTzs(_cart.totalTzs)}'
                        : 'Checkout — ${_fmtTzs(_cart.totalTzs)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTotal(bool sw) {
    final hasDeliveryFees = _cart.totalDeliveryFeeTzs > 0;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _row(sw ? 'Kiasi' : 'Subtotal', _fmtTzs(_cart.subtotalTzs)),
          if (hasDeliveryFees) ...[
            const SizedBox(height: 6),
            _row(sw ? 'Usafiri' : 'Delivery', _fmtTzs(_cart.totalDeliveryFeeTzs)),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: _kBorder),
          ),
          _row(
            sw ? 'Jumla' : 'Total',
            _fmtTzs(_cart.totalTzs),
            bold: true,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _calculatingDelivery ? null : _calculateDeliveryFees,
              icon: _calculatingDelivery
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.route_rounded, size: 16),
              label: Text(sw ? 'Kokotoa usafiri halisi' : 'Calculate real delivery'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: const BorderSide(color: _kBorder),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String left, String right, {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            left,
            style: TextStyle(
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? _kPrimary : _kSecondary,
            ),
          ),
        ),
        Text(
          right,
          style: TextStyle(
            fontSize: bold ? 16 : 13,
            fontWeight: FontWeight.w700,
            color: bold ? _kAccent : _kPrimary,
          ),
        ),
      ],
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final String Function(int) fmtTzs;

  const _CartItemTile({
    required this.item,
    required this.onRemove,
    required this.fmtTzs,
  });

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final variant = item.variant;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (variant != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    variant.displayLabel(true),
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '${item.quantity} x ${fmtTzs(item.unitPriceTzs)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmtTzs(item.totalTzs),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    'Ondoa',
                    style: TextStyle(
                      fontSize: 12,
                      color: _kError.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: _kSecondary),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: _kSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
