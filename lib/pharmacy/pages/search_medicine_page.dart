// lib/pharmacy/pages/search_medicine_page.dart
import 'package:flutter/material.dart';
import '../models/pharmacy_models.dart';
import '../services/pharmacy_service.dart';
import '../widgets/medicine_card.dart';
import 'cart_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class SearchMedicinePage extends StatefulWidget {
  final int userId;
  final String? initialCategory;
  const SearchMedicinePage({super.key, required this.userId, this.initialCategory});
  @override
  State<SearchMedicinePage> createState() => _SearchMedicinePageState();
}

class _SearchMedicinePageState extends State<SearchMedicinePage> {
  final PharmacyService _service = PharmacyService();
  final TextEditingController _searchController = TextEditingController();

  List<Medicine> _medicines = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  // Cart state
  final Map<int, int> _cart = {};
  final Map<int, Medicine> _cartMedicines = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _searchByCategory(widget.initialCategory!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() { _isLoading = true; _hasSearched = true; });

    final result = await _service.searchMedicine(query: query);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _medicines = result.items;
      });
    }
  }

  Future<void> _searchByCategory(String category) async {
    setState(() { _isLoading = true; _hasSearched = true; });
    final result = await _service.searchMedicine(query: category, category: category);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _medicines = result.items;
      });
    }
  }

  void _addToCart(Medicine medicine) {
    if (medicine.prescriptionRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dawa hii inahitaji agizo la daktari. Tumia "Daktari Wangu" kwanza.')),
      );
      return;
    }
    setState(() {
      _cart[medicine.id] = (_cart[medicine.id] ?? 0) + 1;
      _cartMedicines[medicine.id] = medicine;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${medicine.name} imeongezwa kwenye kikapu'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  int get _cartItemCount => _cart.values.fold(0, (a, b) => a + b);

  double get _cartTotal {
    double total = 0;
    _cart.forEach((id, qty) {
      final med = _cartMedicines[id];
      if (med != null) total += med.price * qty;
    });
    return total;
  }

  String _fmt(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  void _openCart() async {
    if (_cart.isEmpty) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CartPage(
          userId: widget.userId,
          cart: Map.from(_cart),
          cartMedicines: Map.from(_cartMedicines),
        ),
      ),
    );
    if (result == true && mounted) {
      setState(() { _cart.clear(); _cartMedicines.clear(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Tafuta Dawa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          if (_cartItemCount > 0)
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(icon: const Icon(Icons.shopping_cart_rounded), onPressed: _openCart),
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('$_cartItemCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _search(),
              autofocus: widget.initialCategory == null,
              decoration: InputDecoration(
                hintText: 'Jina la dawa, mfano: Paracetamol...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: _kSecondary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded, size: 20),
                  onPressed: _search,
                  color: _kPrimary,
                ),
                filled: true, fillColor: _kCardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Rx warning
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dawa zenye alama ya Rx zinahitaji agizo la daktari. Dawa nyingine unaweza kununua moja kwa moja.',
                      style: TextStyle(fontSize: 11, color: Colors.amber.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                : !_hasSearched
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.medication_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('Tafuta dawa kwa jina', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : _medicines.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text('Hakuna dawa iliyopatikana', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _medicines.length,
                            itemBuilder: (context, index) {
                              final med = _medicines[index];
                              final qtyInCart = _cart[med.id] ?? 0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: MedicineCard(
                                  medicine: med,
                                  onAddToCart: med.inStock && !med.prescriptionRequired
                                      ? () => _addToCart(med)
                                      : null,
                                  cartQuantity: qtyInCart,
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      // Cart FAB
      floatingActionButton: _cartItemCount > 0
          ? FloatingActionButton.extended(
              onPressed: _openCart,
              backgroundColor: _kPrimary,
              icon: const Icon(Icons.shopping_cart_rounded),
              label: Text('Kikapu ($_cartItemCount) — TZS ${_fmt(_cartTotal)}'),
            )
          : null,
    );
  }
}
