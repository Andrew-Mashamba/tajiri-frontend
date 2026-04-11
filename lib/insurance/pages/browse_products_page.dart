// lib/insurance/pages/browse_products_page.dart
import 'package:flutter/material.dart';
import '../models/insurance_models.dart';
import '../services/insurance_service.dart';
import '../widgets/product_card.dart';
import 'product_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class BrowseProductsPage extends StatefulWidget {
  final int userId;
  final InsuranceCategory? initialCategory;
  const BrowseProductsPage({super.key, required this.userId, this.initialCategory});
  @override
  State<BrowseProductsPage> createState() => _BrowseProductsPageState();
}

class _BrowseProductsPageState extends State<BrowseProductsPage> {
  final InsuranceService _service = InsuranceService();
  List<InsuranceProduct> _products = [];
  bool _isLoading = true;
  InsuranceCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await _service.getProducts(category: _selectedCategory?.name);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _products = result.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg, elevation: 0, scrolledUnderElevation: 1,
        title: Text(
          _selectedCategory != null ? 'Bima ya ${_selectedCategory!.displayName}' : 'Bidhaa za Bima',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Category filter
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Zote', style: TextStyle(fontSize: 12)),
                    selected: _selectedCategory == null,
                    selectedColor: _kPrimary.withValues(alpha: 0.15),
                    onSelected: (_) { setState(() => _selectedCategory = null); _load(); },
                  ),
                ),
                ...InsuranceCategory.values.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat.icon, size: 14),
                            const SizedBox(width: 4),
                            Text(cat.displayName, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        selected: _selectedCategory == cat,
                        selectedColor: _kPrimary.withValues(alpha: 0.15),
                        onSelected: (_) { setState(() => _selectedCategory = _selectedCategory == cat ? null : cat); _load(); },
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('Hakuna bidhaa za bima', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load, color: _kPrimary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _products.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InsuranceProductCard(
                              product: _products[index],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ProductDetailPage(userId: widget.userId, product: _products[index])),
                              ).then((_) { if (mounted) _load(); }),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
