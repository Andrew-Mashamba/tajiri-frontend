// lib/food/pages/cart_page.dart
import 'package:flutter/material.dart';
import '../../widgets/budget_context_banner.dart';
import '../models/food_models.dart';
import '../services/food_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class CartPage extends StatefulWidget {
  final int userId;
  final List<CartItem> cart;
  final int restaurantId;
  final String restaurantName;
  final VoidCallback onOrderPlaced;

  const CartPage({
    super.key,
    required this.userId,
    required this.cart,
    required this.restaurantId,
    required this.restaurantName,
    required this.onOrderPlaced,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FoodService _service = FoodService();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String _paymentMethod = 'wallet';
  bool _isPlacing = false;

  double get _subtotal => widget.cart.fold(0, (sum, i) => sum + i.total);
  double get _deliveryFee => 2000;
  double get _total => _subtotal + _deliveryFee;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _fmtPrice(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  Future<void> _placeOrder() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali weka anwani ya ufikishaji')),
      );
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali weka namba ya simu')),
      );
      return;
    }

    setState(() => _isPlacing = true);

    final result = await _service.placeOrder(
      userId: widget.userId,
      restaurantId: widget.restaurantId,
      items: widget.cart,
      deliveryAddress: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      paymentMethod: _paymentMethod,
    );

    if (mounted) {
      setState(() => _isPlacing = false);
      if (result.success) {
        widget.onOrderPlaced();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Oda imewekwa! Utapata taarifa za hali.')),
          );
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa kuweka oda')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kikapu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
            Text(widget.restaurantName, style: const TextStyle(fontSize: 11, color: _kSecondary)),
          ],
        ),
      ),
      body: widget.cart.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Kikapu chako ni tupu', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Cart items
                ...widget.cart.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.menuItem.name,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'TZS ${_fmtPrice(item.menuItem.price)} x ${item.quantity}',
                                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              _QtyButton(
                                icon: Icons.remove,
                                onTap: () {
                                  setState(() {
                                    if (item.quantity > 1) {
                                      item.quantity--;
                                    } else {
                                      widget.cart.remove(item);
                                    }
                                  });
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '${item.quantity}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
                                ),
                              ),
                              _QtyButton(
                                icon: Icons.add,
                                onTap: () => setState(() => item.quantity++),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'TZS ${_fmtPrice(item.total)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 16),

                // Delivery address
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Anwani ya Ufikishaji', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          hintText: 'Mfano: Mikocheni B, Barabara ya Ali Hassan Mwinyi',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          hintText: 'Namba ya simu (0712...)',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          prefixIcon: const Icon(Icons.phone_rounded, size: 18),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Payment method
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Njia ya Malipo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                      const SizedBox(height: 8),
                      _PaymentOption(
                        label: 'Wallet (TAJIRI)',
                        icon: Icons.account_balance_wallet_rounded,
                        isSelected: _paymentMethod == 'wallet',
                        onTap: () => setState(() => _paymentMethod = 'wallet'),
                      ),
                      const SizedBox(height: 6),
                      _PaymentOption(
                        label: 'M-Pesa',
                        icon: Icons.phone_android_rounded,
                        isSelected: _paymentMethod == 'mpesa',
                        onTap: () => setState(() => _paymentMethod = 'mpesa'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Summary
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _SummaryRow(label: 'Bidhaa', value: 'TZS ${_fmtPrice(_subtotal)}'),
                      const SizedBox(height: 6),
                      _SummaryRow(label: 'Usafiri', value: 'TZS ${_fmtPrice(_deliveryFee)}'),
                      const Divider(height: 16),
                      _SummaryRow(label: 'Jumla', value: 'TZS ${_fmtPrice(_total)}', isBold: true),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Budget context
                BudgetContextBanner(
                  category: 'chakula',
                  paymentAmount: _total,
                  isSwahili: true,
                ),

                const SizedBox(height: 12),

                // Place order button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isPlacing ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isPlacing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Agiza - TZS ${_fmtPrice(_total)}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kPrimary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: _kPrimary),
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? _kPrimary.withValues(alpha: 0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isSelected ? _kPrimary : _kSecondary),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? _kPrimary : _kSecondary,
                ),
              ),
              const Spacer(),
              if (isSelected)
                const Icon(Icons.check_circle_rounded, size: 18, color: _kPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold ? _kPrimary : _kSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: _kPrimary,
          ),
        ),
      ],
    );
  }
}
