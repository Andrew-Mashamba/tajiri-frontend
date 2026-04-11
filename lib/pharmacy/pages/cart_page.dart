// lib/pharmacy/pages/cart_page.dart
import 'package:flutter/material.dart';
import '../../widgets/budget_context_banner.dart';
import '../models/pharmacy_models.dart';
import '../services/pharmacy_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class CartPage extends StatefulWidget {
  final int userId;
  final Map<int, int> cart;
  final Map<int, Medicine> cartMedicines;

  const CartPage({
    super.key,
    required this.userId,
    required this.cart,
    required this.cartMedicines,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final PharmacyService _service = PharmacyService();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  late Map<int, int> _cart;
  late Map<int, Medicine> _cartMedicines;
  bool _isDelivery = false;
  bool _isOrdering = false;

  @override
  void initState() {
    super.initState();
    _cart = Map.from(widget.cart);
    _cartMedicines = Map.from(widget.cartMedicines);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  double get _subtotal {
    double total = 0;
    _cart.forEach((id, qty) {
      final med = _cartMedicines[id];
      if (med != null) total += med.price * qty;
    });
    return total;
  }

  int get _itemCount => _cart.values.fold(0, (a, b) => a + b);

  String _fmt(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  void _updateQuantity(int medicineId, int delta) {
    setState(() {
      final newQty = (_cart[medicineId] ?? 0) + delta;
      if (newQty <= 0) {
        _cart.remove(medicineId);
        _cartMedicines.remove(medicineId);
      } else {
        _cart[medicineId] = newQty;
      }
    });
  }

  Future<void> _placeOrder() async {
    if (_cart.isEmpty) return;
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingiza nambari ya M-Pesa')),
      );
      return;
    }
    if (_isDelivery && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingiza anwani ya usafirishaji')),
      );
      return;
    }

    setState(() => _isOrdering = true);

    final items = _cart.entries.map((e) => {
          'medicine_id': e.key,
          'quantity': e.value,
        }).toList();

    final result = await _service.placeOrder(
      userId: widget.userId,
      items: items,
      isDelivery: _isDelivery,
      deliveryAddress: _isDelivery ? _addressController.text.trim() : null,
      paymentMethod: 'mobile_money',
      phoneNumber: _phoneController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isOrdering = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agizo limetumwa! Thibitisha malipo kwenye simu yako.')),
      );
      Navigator.pop(context, true); // true = order placed, clear cart in parent
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa kuagiza'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: Text('Kikapu ($_itemCount)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Kikapu chako ni tupu', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Cart items
                ..._cart.entries.map((entry) {
                  final med = _cartMedicines[entry.key];
                  if (med == null) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(med.dosageIcon, size: 22, color: _kPrimary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(med.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                              Text('${med.strength} • TZS ${_fmt(med.price)}/moja', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                            ],
                          ),
                        ),
                        // Quantity controls
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _QtyButton(
                              icon: entry.value <= 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
                              color: entry.value <= 1 ? Colors.red : _kPrimary,
                              onTap: () => _updateQuantity(entry.key, -1),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('${entry.value}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                            ),
                            _QtyButton(
                              icon: Icons.add_rounded,
                              color: _kPrimary,
                              onTap: () => _updateQuantity(entry.key, 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                // Summary
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Dawa', style: TextStyle(fontSize: 13, color: _kSecondary)),
                          Text('TZS ${_fmt(_subtotal)}', style: const TextStyle(fontSize: 13, color: _kPrimary)),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Jumla', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                          Text('TZS ${_fmt(_subtotal)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Delivery option
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 24, height: 24,
                            child: Checkbox(
                              value: _isDelivery,
                              onChanged: (v) => setState(() => _isDelivery = v ?? false),
                              activeColor: _kPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Peleka Nyumbani', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                                Text('Dawa zitapelekwa kwenye anwani yako', style: TextStyle(fontSize: 12, color: _kSecondary)),
                              ],
                            ),
                          ),
                          const Icon(Icons.delivery_dining_rounded, color: _kSecondary),
                        ],
                      ),
                      if (_isDelivery) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            hintText: 'Anwani kamili, mfano: Kinondoni, Dar es Salaam',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            filled: true, fillColor: _kBackground,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Payment
                const Text('Malipo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Nambari ya M-Pesa',
                    hintText: '0712 345 678',
                    prefixIcon: const Icon(Icons.phone_outlined, color: _kSecondary),
                    filled: true, fillColor: _kCardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
                  ),
                ),
                const SizedBox(height: 12),

                // Budget context
                BudgetContextBanner(
                  category: 'afya',
                  paymentAmount: _subtotal,
                  isSwahili: true,
                ),

                const SizedBox(height: 12),

                // Place order
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _isOrdering ? null : _placeOrder,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isOrdering
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Agiza — TZS ${_fmt(_subtotal)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
  final Color color;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
